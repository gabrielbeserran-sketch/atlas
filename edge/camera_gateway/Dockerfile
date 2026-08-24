FROM python:3.12-slim

WORKDIR /opt/atlas-camera-gateway

COPY pyproject.toml ./
COPY atlas_camera_gateway ./atlas_camera_gateway

RUN pip install --no-cache-dir .

ENV ATLAS_CAMERA_GATEWAY_SPOOL_DIR=/data/spool

VOLUME ["/data"]
ENTRYPOINT ["atlas-camera-gateway"]
CMD ["worker"]
