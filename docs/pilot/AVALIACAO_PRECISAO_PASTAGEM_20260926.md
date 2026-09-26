# Precisão de pastagem — avaliação agrupada

Checkpoint: `atlas-pasture-indicator-precision-20260926`. Não altera nem preenche dados reais. Compilação Windows profile oficial, não instalador comercial; Android não atualizado neste pacote.

Executável preservado: `C:/Projetos/Projetos Atlas/release/windows/campo-precisao-20260926/projeto_atlas.exe`. Inclui também resiliência de Campo d95dd12 e formulário de Operações 9f8d671. SHA-256 de data/app.so: D8B7B353CD8D272E1B624DCB8300CE75951998956A5834E943B8F5C113C42972. Identidade com.example/projeto_atlas, entrada main.dart, ATLAS_ENV production e URL oficial conferidas. Salvar/fechar a versão anterior antes de abrir: não usar duas versões no mesmo armazenamento. Nenhum login/PIN automatizado.

Validações: 34 testes de agregação/base/UA/ha/snapshot aprovados e oito de agregação reexecutados após o aviso final; análise de três arquivos finais sem apontamentos, diff e um build Windows profile aprovados (156,9 s). Compilação preservada, não aberta neste pacote.

## Resultado esperado na aba Suporte

- Soma nominal de piquetes continua separada da área efetiva confirmada pelo produtor; não constitui prova de ausência de sobreposição.
- Registros com ID ausente ou repetido não entram na soma nominal, matéria seca ou suporte. A tela informa quantos foram excluídos. Não criar duplicações nos dados reais para testar: esse caso foi reproduzido em testes automatizados.
- Matéria seca válida é somada como kg/ha × hectares; suporte é ponderado apenas pela área dos piquetes com medida válida. A tela mostra quantos piquetes válidos têm cada medida e identifica base parcial. Ausência de medida não é extrapolada para os demais.
- Zero válido continua distinto de ausência de base. Valores fora do intervalo de cálculo não aparecem como infinito ou NaN; a tela pede revisão.
- Esses controles não verificam geometria/GIS, atualidade de medições técnicas ou qualidade física da coleta. Cobertura corresponde aos valores presentes e válidos no modelo, não a uma auditoria de medição em campo.

## Casos reproduzidos sem dados reais

1. IDs a/a/vazio/b com áreas 10/20/30/5: soma é 5 ha, não 65 ha; três registros ambíguos ficam fora.
2. Piquetes de 10 e 30 ha, suporte 2 e 4: média ponderada é 3,5, não 3.
3. Piquetes de 10 e 30 ha, medidas válidas só no primeiro: matéria seca a 1.000 kg/ha resulta em 10.000 kg registrados; suporte 2 UA/ha permanece 2 apenas sobre a base medida. Cobertura 1/2, sem extrapolação.
4. Soma ou produto que excede o intervalo numérico: indicador indisponível com aviso, sem resultado infinito.
5. UA/ha continua exigindo base efetiva atual, seleção individual e pesagens confirmadas para todos os animais, sem extrapolar amostras parciais; regra já existente conferida em regressão.

## Avaliação humana pendente

Após salvar e fechar a versão anterior, abrir a compilação agrupada e conferir Campo → Piquetes e pastagens → Suporte. Usar apenas dados autorizados, sem apagar PIN ou armazenamento para simular falhas. Confirmar leitura offline e clareza dos avisos. Testes mockados e build não substituem essa homologação nem sincronização em dois dispositivos.
