"""Unitários sem conftest, sem Docker e sem banco da aplicação."""
import copy
import unittest
from unittest.mock import patch

import run_isolated_postgres_bootstrap as runner

IDENTITY = "a" * 32
CONTAINER = "b" * 64


def description():
    return {
        "Config": {"Image": "postgres:16", "Labels": {runner.LABEL: IDENTITY}},
        "NetworkSettings": {"Ports": {"5432/tcp": [
            {"HostIp": "127.0.0.1", "HostPort": "55432"}]}},
        "Mounts": [],
    }


class IsolatedPostgresRunnerTest(unittest.TestCase):
    def test_docker_ignores_remote_context_environment(self):
        with patch.dict(runner.os.environ, {"DOCKER_HOST": "tcp://remote:2375", "DOCKER_CONTEXT": "remote"}), patch.object(runner.subprocess, "run") as call:
            call.return_value.returncode = 0
            call.return_value.stdout = "ok"
            runner.command(["docker", "info"])
            self.assertEqual(call.call_args.args[0], ["docker", "--host", runner.LOCAL_DOCKER_PIPE, "info"])
            self.assertNotIn("DOCKER_HOST", call.call_args.kwargs["env"])
            self.assertNotIn("DOCKER_CONTEXT", call.call_args.kwargs["env"])

    def test_accepts_only_owned_loopback_container(self):
        self.assertEqual(runner.isolated_port(description(), IDENTITY), 55432)

    def test_rejects_another_container_or_image(self):
        item = description()
        item["Config"]["Labels"][runner.LABEL] = "other"
        with self.assertRaises(ValueError):
            runner.isolated_port(item, IDENTITY)
        item = description()
        item["Config"]["Image"] = "other"
        with self.assertRaises(ValueError):
            runner.isolated_port(item, IDENTITY)

    def test_rejects_external_bindings_multiple_ports_and_invalid_port(self):
        for binding in [None, [], [{"HostIp": "0.0.0.0", "HostPort": "55432"}],
                        [{"HostIp": "127.0.0.1", "HostPort": "0"}],
                        [{"HostIp": "127.0.0.1", "HostPort": "55432"}] * 2]:
            item = description()
            item["NetworkSettings"]["Ports"]["5432/tcp"] = binding
            with self.assertRaises(ValueError):
                runner.isolated_port(item, IDENTITY)

    def test_rejects_host_directory_mount(self):
        item = description()
        item["Mounts"] = [{"Type": "bind", "Destination": "/var/lib/postgresql/data"}]
        with self.assertRaises(ValueError):
            runner.isolated_port(item, IDENTITY)

    def test_url_cannot_target_existing_database_or_remote_host(self):
        self.assertEqual(runner.database_url(55432, IDENTITY),
                         f"postgresql+psycopg://atlas_probe@127.0.0.1:55432/atlas_probe_{IDENTITY}")
        for identity in ["production", "a/../b", "", "x" * 32]:
            with self.assertRaises(ValueError):
                runner.database_url(55432, identity)

    def test_unavailable_docker_never_starts_or_migrates(self):
        with patch.object(runner, "command", side_effect=RuntimeError("unavailable")) as call:
            with self.assertRaises(RuntimeError):
                runner.run()
            self.assertEqual(call.call_count, 1)
            self.assertEqual(call.call_args.args[0][1], "info")

    def test_migration_failure_stops_only_created_container(self):
        import json
        commands = []

        def invoke(args, **kwargs):
            commands.append(copy.deepcopy(args))
            if args[1] == "run":
                return CONTAINER
            if args[1] == "inspect":
                return json.dumps([description()])
            if "alembic" in args:
                self.assertIn("127.0.0.1", kwargs["env"]["ATLAS_DATABASE_URL"])
                raise RuntimeError("migration failure")
            return "ready"

        with patch.object(runner, "command", side_effect=invoke), patch.object(
                runner.uuid, "uuid4") as identity:
            identity.return_value.hex = IDENTITY
            with self.assertRaises(RuntimeError):
                runner.run()
        self.assertEqual(commands[-1], ["docker", "stop", CONTAINER])
        self.assertFalse(any("atlas_test.db" in part for c in commands for part in c))


if __name__ == "__main__":
    unittest.main()
