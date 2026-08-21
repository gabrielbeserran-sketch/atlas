from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCREEN = ROOT / 'lib/features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart'
text = SCREEN.read_text(encoding='utf-8')
checks = {
    'Área de ações explícita': "class _ModuleActionBar extends StatelessWidget" in text,
    'Área de ações está na árvore principal': "_ModuleActionBar(" in text and text.index("_ModuleActionBar(") < text.index("if (_loading && data == null)"),
    'Chave estável da área': "ValueKey('atlas_module_action_area')" in text,
    'Botão criar real': "FilledButton.icon(" in text and "ValueKey('atlas_module_create_button')" in text,
    'Botão gerenciar real': "OutlinedButton.icon(" in text and "ValueKey('atlas_module_manage_button')" in text,
    'Ação não some sem permissão': "if (canWrite)" not in text[text.index('class _ModuleActionBar'):text.index('class _MetricCard')],
    'Reprodução': 'Novo evento reprodutivo' in text,
    'Sanidade': 'Novo evento sanitário' in text,
    'Nutrição': 'Nova dieta' in text,
    'Estoque': 'Novo produto' in text,
    'Financeiro': 'Novo lançamento' in text,
    'Criação reutiliza fluxo operacional': '_openOperational(create: true)' in text,
    'Gestão reutiliza fluxo operacional': '_openOperational(create: false)' in text,
    'Retorno recarrega backend': 'await _load();' in text,
}
failed=[]
for label, ok in checks.items():
    print(f"[{'OK' if ok else 'FAIL'}] {label}")
    if not ok: failed.append(label)
print(f"\nV19.4 explicit module action area: {len(checks)-len(failed)}/{len(checks)}")
if failed: raise SystemExit(1)
