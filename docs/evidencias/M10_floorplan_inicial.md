# KUIDAMOS 6C — floorplan inicial

Execução em 2026-11-24 no Fusion Compiler `X-2025.06-SP2`, em uma cópia
do checkpoint M9 `scan_inserted`. O FC inicializou o floorplan, salvou
`kuidamos_preview.dlib:floorplan_initial.design` e reabriu o bloco em
outra sessão. Build e readback retornaram 0.

## Geometria

A área lógica reportada pelo FC foi **3.757,2649 µm²**. Para utilização
nominal de 50%, a área alvo foi 7.514,5298 µm². O script calculou a raiz
quadrada, arredondou a altura para o múltiplo mais próximo da altura do
site e arredondou a largura para cima na grade X para cobrir a área alvo.
O site `unit` mede 0,152 × 1,672 µm. A margem exploratória de 6,688 µm
em cada lado corresponde a quatro alturas de row e cobre pelo menos
dois pitches M9. O dimensionamento final da alimentação e do acesso a
pinos deverá validar essa margem.

| Métrica | Resultado |
|---|---:|
| Core | 86,488 × 86,944 µm |
| Área do core | 7.519,612672 µm² |
| Die | 99,864 × 100,320 µm |
| Área do die | 10.018,356480 µm² |
| Aspect ratio do core (largura/altura) | 0,99476 |
| Utilização calculada (área das células / área do core) | 49,9662% |
| Ocupação por células posicionadas | 0% |
| Site rows | 52 × 569 sites, 29.588 sites |
| Trilhas no DEF | 20 registros, X/Y para M1–M9 e MRDL |

O die vai de (0, 0) a (99,864, 100,320) µm. O core vai de
(6,688, 6,688) a (93,176, 93,632) µm. O validador cruzou os objetos do
FC com o DEF em 1.000 DBU/µm. Conferiu contornos retangulares, margens,
alinhamento das rows sem lacunas ou sobreposição e alternância
`MX/R0` dos sites (`FS/N` no DEF). O DEF reexportado no readback
diferiu apenas na data do cabeçalho. Nas duas exportações,
os 1.256 componentes constam como `UNPLACED`. O FC encontrou zero
referências não resolvidas.

## Portas, integridade e tecnologia

O checkpoint guarda restrições para todas as 126 portas. As bordas
verticais recebem acesso em M3 e as horizontais em M4.

| Borda | Grupo | Portas | Capacidade inicial estimada |
|---|---|---:|---:|
| Esquerda | Entrada RGB e marcadores | 29 | 108 |
| Superior | `clk`, `reset_n` e 3 portas scan | 5 | 107 |
| Direita | Saída de pixels, marcadores e `cfg_error` | 14 | 108 |
| Inferior | Entradas de configuração | 78 | 107 |

A capacidade usa as trilhas do DEF, desconta quatro por canto e
reserva duas trilhas livres entre pinos como aproximação conservadora.
É uma estimativa geométrica sem obstáculos PG. Os pinos continuam
sem posição ou shapes físicos. `place_pins` ficou para outra etapa
porque pode tentar roteamento global.

`check_scan_chain` registrou 1 cadeia validada e 0 falhas no build e
no readback. Os 115 `SDFFX1_RVT` e a conectividade foram preservados.
O corpo da netlist de ambos coincide byte a byte com o original M9.
O Scan DEF físico registra uma cadeia com os mesmos endpoints e 115
membros. O verificador M9 conferiu também o SPF e a ordem no handoff.
Os manifestos SHA-256 antes/depois coincidiram para 1.938 arquivos
protegidos, incluindo RTL, M8, M9 e execuções físicas anteriores.

A cópia usou `saed32_rvt.ndm`, a tecnologia de
`saed32nm_1p9m.tf` e 45 definições de vias. As direções de roteamento
ficaram horizontais nas camadas ímpares e verticais nas pares. MRDL
tem direção vertical e permanece fora do limite M9. Cmin/Cmax
foram associados ao corner `ss0p95v125c` como early/late e
conferidos após reabrir a base.

- **TLUP-012, duas ocorrências.** O mapa TLU+ inclui `DIFF`, que tem
  máscara `active` no arquivo de tecnologia e não aparece no FC como
  camada de metal, corte de via ou poli. A validação avançada emitiu
  um aviso em cada arquivo, aceitou ambos e o timer calculou RC médio.
  A geometria e os checks do floorplan não foram afetados. A validade
  da extração pós-route continua pendente. O mapa original foi usado
  e os avisos permaneceram habilitados.
- **Checks de design.** `check_design -checks {netlist unbound dp_floorplan_rules}`
  reportou zero erros, 139 avisos estruturais já presentes no diagnóstico
  e um `DPCHK-008` pela ausência de uma grade FinFET. As linhas, o site
  e a grade do DEF foram verificados diretamente. O Verilog Writer
  registrou três `VW-007` de aliases já observados no M9.

## Timing, PG e próxima etapa

O cenário funcional `functional::ss0p95v125c` manteve `clk` em 10 ns,
com waveform {0 5}. Com `scan_enable=0` aplicado só ao diagnóstico,
o pior setup foi **+3,1640 ns** e o pior hold **+0,2239 ns**. O FC
reportou estimativa RC no modo VR, clock ideal e zero redes roteadas
ou com parasitas anotados. Os valores são estimativas pré-placement.
`check_timing` registrou 231 endpoints sem restrição (TCK-001) e
1.256 avisos de biblioteca de scaling (TCK-014).

O domínio `DEFAULT_POWER_DOMAIN` referencia VDD/VSS. Antes de avançar
para placement, planejar trilhos e malha, conferir orientação dos
pares de rows e validar conectividade, acesso aos pinos e DRC de PG.
A consulta à NDM encontrou `DCAP_RVT` como endcap, oito fillers
e `TIEH_RVT`/`TIEL_RVT`. A consulta por `is_tap_cell` retornou
zero referências. A necessidade de taps dedicados e a política de
inserção de endcaps, fillers e ties dependem das regras da biblioteca
e dos requisitos do bloco. Nenhuma dessas células foi inserida.

Manter a ordem scan M9 na primeira passagem. Completar o STA de shift
e captura com budgets externos de scan, cenários e corners adequados.
O SPF fornece clock de shift de 100 ns e reset inativo. Hold de shift
depende de skew, caminhos curtos e parasitas. Depois de CTS, medir
skew/latência e reavaliar hold com clocks propagados. Se houver
reordenação, revalidar os 115 membros e SEs, exportar netlist/Scan DEF/SPF
consistentes e repetir as verificações de scan com a ordem final.

**Próxima etapa:** power planning em cópia do checkpoint. Placement
fica condicionado à validação da alimentação e dos cenários de STA.
Placement, CTS, PG routing e signal routing ficaram fora desta execução.

## Reprodução e arquivos locais

```bash
export SAED32_REF_ROOT=/caminho/da/instalacao/ref
./scripts/physical/run_floorplan.sh outputs/dft/runs/20261120T142703Z-insertion-jTvumJ
```

Execução validada em `outputs/physical/runs/20261124T180302Z-floorplan-n4qeIQ/`.
O wrapper cria outro diretório em cada execução. A ajuda nativa do FC
fica em `build/help_*.rpt`. Os relatórios, os manifestos, o DEF, a
planta `floorplan.svg` gerada a partir da geometria conferida com o DEF
e o checkpoint ficam locais. O marcador final é
`FLOORPLAN_GEOMETRY_VALIDATED` em `validation.txt`.
[Fluxo M10](../../scripts/physical/README.md).
