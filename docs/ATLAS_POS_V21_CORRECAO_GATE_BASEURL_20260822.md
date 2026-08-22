# Atlas Pós-V21 — correção estrutural do encaminhamento BaseUrl

## Causa raiz

O wrapper `run_post_v21_package1_homologation.ps1` criava:

```powershell
$Args = @("-BaseUrl", $BaseUrl)
& "...\run_v21_ux_homologation.ps1" @Args
```

Em PowerShell, **array splatting é posicional**. Os elementos `"-BaseUrl"` e a URL
não são reinterpretados como um par `nome do parâmetro -> valor`. Como `BaseUrl`
é o primeiro parâmetro posicional do script filho, ele recebeu literalmente
`-BaseUrl`.

O smoke então montou:

```text
-BaseUrl/health/ready
```

e o Windows tentou resolver `-baseurl` como nome de host, produzindo exatamente
o erro observado.

## Correção

O wrapper passou a usar **hashtable splatting**:

```powershell
$V21Parameters = @{
    BaseUrl = $BaseUrl
}
if ($SkipProductionSmoke) {
    $V21Parameters["SkipProductionSmoke"] = $true
}
& "...\run_v21_ux_homologation.ps1" @V21Parameters
```

Hashtable splatting preserva nomes de parâmetros.

## Prevenção em três camadas

1. `atlas_powershell_parameter_forwarding_gate.py` varre todos os `.ps1` e rejeita:
   - atribuição customizada a `$Args`;
   - array splatting contendo nomes como `"-BaseUrl"`;
   - regressão do wrapper para `@Args`.

2. `run_post_v21_package1_homologation.ps1`, `run_v21_ux_homologation.ps1` e
   `gate_v16_v17_production.ps1` validam `BaseUrl` antes de rede/build:
   - não vazia;
   - não pode começar com `-`;
   - URL absoluta;
   - apenas HTTP/HTTPS;
   - host obrigatório;
   - remove `/` final.

3. O gate V21.5 de higiene PowerShell também passa a auditar o wrapper Pós-V21.

Assim, mesmo que um encaminhamento semelhante seja introduzido futuramente,
o processo deve falhar **imediatamente e com diagnóstico explícito**, antes de
esperar cinco retries de rede.
