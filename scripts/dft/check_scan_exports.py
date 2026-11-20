"""Cruza o grafo medido pelo FC com os arquivos exportados da cadeia."""

import csv
import re
import sys
from collections import Counter
from pathlib import Path


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_table(path):
    with path.open() as source:
        return list(csv.DictReader(source, delimiter="\t"))


def validate(run):
    post = run / "post"
    log = (run / "insertion.log").read_text()
    require((run / "tool_exit_code.txt").read_text().strip() == "0", "Execução FC incompleta")
    for marker in ("M9_INSERT_DFT_RETURN 1", "M9_CHAIN_VERIFIED endpoints=2 internal_links=114 enable_pins=115",
                   "M9_POST_DRC_RETURN 1", "M9_INSERTION_REPORTS_SAVED"):
        require(marker in log.splitlines(), "Marcador de execução ausente: " + marker)
    require(not re.search(r"^\s*(?:Error|Fatal):", log, re.M), "Erro no log da inserção")
    require(not re.search(r"^Information: Starting .*\b(?:compile_fusion|place_opt|clock_opt|"
                          r"route_auto|route_opt|Early Placement|Auto-Floorplan)\b", log, re.M),
            "Estágio físico ou de compilação inesperado")

    actual = read_table(post / "actual_chain.tsv")
    names = [row["instance"] for row in actual]
    baseline = read_table(run / "reports" / "sequential_input.tsv")
    require(len(set(names)) == 115 and Counter(names) == Counter(row["instance"] for row in baseline),
            "Inventário da cadeia diferente da base pré-scan")
    require([int(row["position"]) for row in actual] == list(range(1, 116)), "Posições fora de ordem")
    scan_report = (post / "scan_paths.rpt").read_text()
    require(re.search(r"^KUIDAMOS_CHAIN\s+115\s+D_\d+\s+scan_in\s+scan_out\s+scan_enable\s*$",
                      scan_report, re.M), "Resumo do report_scan_path incorreto")
    reported = re.findall(r"^(\w+) \(SI (Q|QN)\) (\d+)", scan_report, re.M)
    require(reported == [(row["instance"], row["SO_pin"], str(i)) for i, row in enumerate(actual)],
            "Ordem do report_scan_path difere da conectividade medida")

    netlist = (post / "scan_netlist.v").read_text()
    parsed = re.findall(r"^\s*SDFFX1_RVT\s+(\w+)\s*\((.*?)\)\s*;", netlist, re.M | re.S)
    require(Counter(name for name, _ in parsed) == Counter(names),
            "Netlist não contém exatamente os SDFFs da cadeia")
    pins = {name: dict(re.findall(r"\.(\w+)\s*\(\s*(\S+)\s*\)", connections))
            for name, connections in parsed}
    signal = "scan_in"
    for row in actual:
        instance = row["instance"]
        require(pins[instance].get("SI") == signal and pins[instance].get("SE") == "scan_enable" and
                pins[instance].get("CLK") == "clk", "SI, SE ou CLK inválido na netlist: " + instance)
        signal = pins[instance].get(row["SO_pin"])
        require(signal and signal not in {"m9_scan_disabled", "1'b0", "1'b1"},
                "Saída de scan sem rede ou constante: " + instance)
    require(signal == "scan_out", "Saída serial da netlist não termina em scan_out")

    protocol = (post / "scan_protocol.spf").read_text()
    require(re.findall(r'^\s*ScanChain "([^"]+)"', protocol, re.M) == ["KUIDAMOS_CHAIN"],
            "SPF não descreve exatamente KUIDAMOS_CHAIN")
    for entry in ("ScanLength 115;", 'ScanIn "scan_in";', 'ScanOut "scan_out";',
                  'ScanEnable "scan_enable";', 'ScanMasterClock "clk";'):
        require(entry in protocol, "SPF sem " + entry)
    reset_values = re.findall(r'^\s*"reset_n"\s*=\s*([^;]+);', protocol, re.M)
    require(set(reset_values) == {"1"}, "SPF não mantém o reset inativo")
    scandef = (post / "scan.def").read_text()
    require(re.search(r"^SCANCHAINS 1\s*;", scandef, re.M) and
            "+ START PIN scan_in" in scandef and "+ STOP PIN scan_out" in scandef,
            "Endpoints ou contagem no SCANDEF diferentes")
    def_rows = re.findall(r"^\s*(\w+)\s*\(\s*IN SI\s*\)\s*\(\s*OUT (Q|QN)\s*\)", scandef, re.M)
    require(Counter(def_rows) == Counter(zip(names, (row["SO_pin"] for row in actual))),
            "Instâncias ou pinos no SCANDEF diferentes da cadeia")

    drc = (post / "dft_drc.rpt").read_text()
    require(re.search(r"^\s*0 TOTAL VIOLATIONS\s*$", drc, re.M), "Violação no resumo pós-DFT")
    require(re.search(r"Traced Scan Elements.*?:\s*115\s", drc),
            "DFT DRC não rastreou os 115 SDFFs pós-inserção")
    require(re.search(r"^115 SEQUENTIAL CELLS WITHOUT VIOLATIONS\s*$", drc, re.M) and
            re.search(r"^\s*115 CELLS ON SCAN CHAIN\(S\)\s*$", drc, re.M),
            "Relatório pós-scan não confirma todos os sequenciais na cadeia e sem violações")
    for metric in ("Non-Scan Elements", "Excluded Scan Elements", "Violated Scan Elements"):
        # A tabela compacta pós-inserção omite as linhas de exclusão zeradas.
        counts = re.findall(r"^\s*" + metric + r".*?:\s*(\d+)\s", drc, re.M)
        require(all(count == "0" for count in counts), "Elemento excluído ou violado: " + metric)
    details = (post / "dft_violations_details.rpt").read_text()
    warnings = Counter(re.findall(r"\(([A-Z]\d+)-\d+\)\s*$", details, re.M))
    require(not warnings["B12"] and not re.search(r"(?:scan_out|scan_in|scan_enable)\s*\)\. \(B[78]-", details),
            "A cadeia ainda contém pinos sem driver ou portas de teste sem conexão")
    planned = read_table(run / "reports" / "planned_chain.tsv")
    print("SCAN_EXPORTS_OK length=115 internal_links=114 enable_pins=115")
    print("Ordem real coincide com o preview: {}".format(names == [row["instance"] for row in planned]))
    print("Avisos DRC: {}".format(dict(sorted(warnings.items()))))


if __name__ == "__main__":
    try:
        validate(Path(sys.argv[1]))
    except (IndexError, KeyError, OSError, ValueError) as error:
        sys.exit("Artefatos pós-scan não validados: " + str(error))
