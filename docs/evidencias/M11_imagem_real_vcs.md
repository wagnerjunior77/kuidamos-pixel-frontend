# M11 — imagem real no VCS

Execução de 25/11/2026, em `outputs/m11/real-image-v52IBa/`. O mesmo
caso passou no RTL e na netlist gate-level de `physical_final`.
Ambas as saídas foram reconstruídas a partir de amostras do DUT.
A regressão oficial M2/M7 permanece como evidência separada.

## Entrada e configuração

A entrada foi [carro.jpeg](../experimentos/estacionamento/carro.jpeg),
a mesma fotografia usada na demonstração Python de M1. SHA-256
`06a4bb6782f9c13060762c294cc0f731d6ad74adf3cb6bc0a42caa620a9171a4`.
A preparação converteu a imagem para RGB888 e reduziu proporcionalmente
de 2.268 × 4.032 para **144 × 256** com Pillow/Lanczos, usando
`fit_for_model` com limite de 256 pixels no maior eixo. Essa etapa
ocorre antes do fornecimento dos pixels ao IP.
[Experimento M1](M1_imagem_real.md) · [Especificação V1](../spec_v1.md)

| Parâmetro | Valor |
|---|---:|
| Pixels válidos de entrada | 36.864 |
| ROI em coordenadas da entrada preparada | x=18, y=32, largura 107, altura 191 |
| Fator nearest-neighbor V1 em X e Y | 2 e 2 |
| Threshold | Habilitado, T=128 |
| Dimensão esperada da saída | 53 × 95 |
| Pixels esperados | 5.035 |
| Ciclos do scoreboard | 36.872 |
| Clock da simulação | 100 MHz (10 ns) |

O caso tem dois ciclos de reset, três bolhas de entrada e três
ciclos finais ociosos. A ROI ímpar exercita o piso nas duas
dimensões. O Golden Model calcula luminância inteira, crop,
nearest-neighbor e threshold. O gerador M2 foi reutilizado para
escalonar as entradas, as saídas esperadas e os marcadores por
ciclo. Os arquivos foram gerados em uma pasta isolada.

## Execução e reconstrução

O wrapper gerou uma cópia temporária do testbench M7, acrescentando
uma captura dos sinais reais após a atualização dos registradores.
O caso foi selecionado por `+CASE`, com `+EXPECT_CYCLES=36872`.
O scoreboard original conferiu a amostra registrada e a transferência
para o consumidor em todos os ciclos, incluindo ciclos inválidos.
`captured.tsv` contém ciclo, valid, valor, SOF, SOL, EOL, EOF e erro
vindos do DUT. O verificador reconstruiu `dut.png` colocando os
pixels válidos capturados em ordem raster, após conferir comprimento,
ordem dos ciclos e marcadores. O mapa binário marca em branco
qualquer valor diferente do PNG de referência do Golden Model.

| Verificação | RTL | Gate-level |
|---|---:|---:|
| Casos aprovados | 1/1 | 1/1 |
| Ciclos verificados | 36.872 | 36.872 |
| Pixels gerados, consumidos e comparados | 5.035 | 5.035 |
| Pixels brancos / pretos | 2.078 / 2.957 | 2.078 / 2.957 |
| Divergências de valor ou marcador | 0 | 0 |
| Ciclos divergentes e pixels extras | 0 | 0 |
| SOF / SOL / EOL / EOF | 1 / 95 / 95 / 1 | 1 / 95 / 95 / 1 |
| Checagens pós-borda do monitor SVA | 36.871 | — |
| Erros do scoreboard e pulsos `cfg_error` | 0 | 0 |

No RTL, as oito propriedades concorrentes do M7 permaneceram ativas,
com zero erros. No gate-level, o modelo SAED32 RVT foi compilado com
a netlist final. SE e SI foram fixados em zero. A cópia removeu apenas
o monitor que depende de sinais internos RTL e usou `+notimingcheck`.
O scoreboard completo e a comparação dos pixels e marcadores
continuaram ativos. O ensaio gate-level tem escopo funcional lógico.
A anotação SDF e a validação temporal continuam com as limitações
registradas no M10. [M7](M3_M7_verificacao_vcs.md) · [M10](M10_resultado_final.md)

## Reprodução e artefatos

A execução usou VCS `X-2025.06-SP2_Full64`, Python 3.11.13,
NumPy 2.2.6 e Pillow 10.2.0. Na raiz do projeto:

```bash
export PYTHON_BIN="$PWD/.venv/bin/python"
./scripts/verification/run_m11_real_image.sh docs/experimentos/estacionamento/carro.jpeg

# Extensão gate-level com a netlist final disponível localmente.
export SAED32_REF_ROOT=/caminho/saed32/ref
PHYSICAL_FINAL_RUN=/caminho/da/execucao-physical-final
./scripts/verification/run_m11_real_image.sh docs/experimentos/estacionamento/carro.jpeg \
  "$PHYSICAL_FINAL_RUN/signals/reports/netlist.v"
```

Em cada execução, `rtl/comparativo.png` contém a entrada RGB, o
resultado esperado, a captura RTL e o mapa de diferenças. A opção
gate-level produz também `gate/comparativo.png`. As imagens
individuais mantêm a resolução real. As montagens, a fotografia
preparada e as capturas ficam locais em `outputs/m11/`. A autoria
e a licença da fotografia original não estão identificadas nas
fontes do repositório.

| Arquivo local | SHA-256 |
|---|---|
| `rtl/captured.tsv` e `gate/captured.tsv` | `8eb59501a2eadc8f199fdb52829dea70d15fc50ac2e1d4f7a899daf06f41442d` |
| `rtl/dut.png`, `gate/dut.png` e `vectors/golden.png` | `66e1b9af962eab98af13e43cc1d36dc05ed49eea3f5658c30ff609d37a899b80` |
| `rtl/diferencas.png` e `gate/diferencas.png` | `93e9162a83fefaccd051ffc71bf90f06bdc3c84edb0bf89cb65f7242d143671c` |
| `rtl/comparativo.png` | `717dbf0e4d28d6ad479eb83af6e7b0239c986c40142f439a571fd70723001bf5` |

Os logs locais têm os resumos do VCS, `result.json` registra as
contagens verificadas e `inputs.sha256` identifica os insumos.
Um teste negativo alterou um único pixel em uma cópia da captura.
O verificador retornou erro e contou exatamente uma divergência.
Os 32 testes Python passaram, e a checagem confirmou os 28 arquivos
M2 byte a byte. A comparação demonstra um quadro e uma configuração
real de estímulo.
