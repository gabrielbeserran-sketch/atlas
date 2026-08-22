from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
theme = (ROOT / 'lib/shared/theme/app_theme.dart').read_text(encoding='utf-8')
feedback = (ROOT / 'lib/core/widgets/atlas_feedback.dart').read_text(encoding='utf-8')
load_error = (ROOT / 'lib/core/widgets/atlas_operational_feedback.dart').read_text(encoding='utf-8')
animal = (ROOT / 'lib/features/animal/presentation/screens/animal_detail_screen.dart').read_text(encoding='utf-8')
weight = (ROOT / 'lib/features/animal_weight/presentation/screens/animal_weight_form_screen.dart').read_text(encoding='utf-8')
movement = (ROOT / 'lib/features/animal_movement/presentation/screens/animal_movement_form_screen.dart').read_text(encoding='utf-8')

checks = []
def check(name, condition):
    checks.append((name, bool(condition)))

check('Material 3 preservado', 'useMaterial3: true' in theme)
check('alvo mínimo 48', '_minimumTouchTarget = 48' in theme)
check('tap target padded', 'MaterialTapTargetSize.padded' in theme)
check('appbar 64', 'toolbarHeight: 64' in theme)
check('botão preenchido acessível', 'filledButtonTheme' in theme and '_minimumTouchTarget' in theme)
check('botão contornado acessível', 'outlinedButtonTheme' in theme)
check('botão texto acessível', 'textButtonTheme' in theme)
check('icon button acessível', 'iconButtonTheme' in theme)
check('campos com foco reforçado', 'focusedBorder' in theme and 'width: 2' in theme)
check('erros multilinha', 'errorMaxLines: 3' in theme)
check('feedback live region', 'liveRegion: true' in feedback)
check('feedback sucesso semântico', "semanticLabel: 'Sucesso'" in feedback)
check('feedback atenção semântico', "semanticLabel: 'Atenção'" in feedback)
check('feedback erro semântico', "semanticLabel: 'Erro'" in feedback)
check('erro de carga semântico', "semanticLabel: 'Falha ao carregar'" in load_error)
check('retry ocupa largura', 'width: double.infinity' in load_error)
check('refresh animal descritivo', "'Atualizar dados do animal'" in animal)
check('pesagem usa AtlasFormActions', 'AtlasFormActions(' in weight)
check('movimentação usa AtlasFormActions', 'AtlasFormActions(' in movement)
check('movimentação explica lote', "'Escolha para qual lote o animal será movido.'" in movement)
check('central preserva ações simples', "'O que você quer fazer?'" in animal)
check('central preserva navegação simples', "'Desempenho'" in animal and "'Arquivos'" in animal)
check('central preserva responsividade', 'constraints.maxWidth < 420' in animal)
check('sem botão elevado customizado na pesagem', 'ElevatedButton.icon(' not in weight)
check('sem botão salvar isolado na movimentação', "'Salvar movimentação'" in movement and 'AtlasFormActions(' in movement)

bad_tokens = ('Ã§','Ã£','Ã©','Ã³','Ãª','Ã¡','Ã­','Ãº','Â')
check('arquivos alterados sem mojibake', not any(
    token in (theme + feedback + load_error + animal + weight + movement)
    for token in bad_tokens
))

failed = [name for name, ok in checks if not ok]
print(f'ATLAS V20.9 ACCESSIBILITY: {len(checks)-len(failed)}/{len(checks)}')
for name in failed:
    print('FAIL:', name)
raise SystemExit(1 if failed else 0)
