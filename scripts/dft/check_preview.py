"""Confere a cobertura e a integridade dos relatórios do preview do FC."""

import csv
import re
import sys
from collections import Counter
from pathlib import Path


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inventory(path):
    with path.open() as source:
        rows = list(csv.DictReader(source, delimiter="\t"))
    require(len(rows) == 115, "Inventário deve conter 115 instâncias")
    require(len({row["instance"] for row in rows}) == 115, "Instância duplicada no inventário")
    require(all(row["reference"] == "SDFFX1_RVT" and row["CLK"] == "clk" for row in rows),
            "Referência ou clock inesperado no inventário")
    return rows


def verilog_body(path):
    return [line for line in path.read_text().splitlines()
            if not line.startswith(("// Generated on ", "// Write Command: "))]


def validate(run):
    log = (run / "preview.log").read_text()
    require((run / "tool_exit_code.txt").read_text().strip() == "0",
            "O processo FC não concluiu com código zero")
    for marker in ("SCAN_TIE_TERMINALS_DISCONNECTED 230", "PREVIEW_INPUT_DRC_RETURN 1",
                   "PREVIEW_DFT_RETURN 1", "M9_PREVIEW_COMMAND_COMPLETED"):
        require(marker in log.splitlines(), "Marcador ausente: " + marker)
    require(not re.search(r"^\s*(?:Error|Fatal):", log, re.M), "Erro no log do FC")
    validate_reports(run / "reports")


def validate_reports(reports):
    original = inventory(reports / "sequential_input.tsv")
    before = inventory(reports / "sequential_preview_input.tsv")
    after = inventory(reports / "sequential_after_preview.tsv")
    require(before == after, "O preview mudou o inventário ou as redes")
    for old, new in zip(original, before):
        require(all(old[key] == new[key] for key in ("instance", "reference", "CLK", "D", "Q", "QN")),
                "Conectividade funcional mudou em " + old["instance"])
        require((old["SE"], old["SI"], new["SE"], new["SI"]) ==
                ("m9_scan_disabled", "m9_scan_disabled", "-", "-"),
                "Rede temporária inesperada em " + old["instance"])
    require(verilog_body(reports / "before_preview.v") == verilog_body(reports / "after_preview.v"),
            "O preview modificou o corpo da netlist")
    require("No scan chains available." in (reports / "physical_scan_paths.rpt").read_text(),
            "O relatório do bloco não confirma ausência de cadeias conectadas")

    preview = (reports / "preview_dft.rpt").read_text()
    require(re.findall(r"^Number of chains:\s*(\d+)\s*$", preview, re.M) == ["1"],
            "Número de cadeias previsto diferente de um")
    chain = re.search(
        r"^Scan chain 'KUIDAMOS_CHAIN' \(scan_in --> scan_out\) contains 115 cells:\n"
        r"(.*?)^\s*Scan signals:\s*$", preview, re.M | re.S,
    )
    require(chain is not None, "Cadeia completa de 115 células ausente do preview")
    cells = [line.split()[0] for line in chain.group(1).splitlines() if line.strip()]
    expected = [row["instance"] for row in before]
    require(Counter(cells) == Counter(expected),
            "Instâncias ausentes, extras ou duplicadas na cadeia")
    require("(clk, 45, rising)" in chain.group(1), "Clock de scan diferente de clk na subida")
    for kind, port in (("in", "scan_in"), ("out", "scan_out"), ("enable", "scan_enable")):
        require(re.search(r"^\s*test_scan_" + kind + r": " + port + r"\s", preview, re.M),
                "Porta de scan diferente da prevista: " + port)
    config = (reports / "dft_configuration.rpt").read_text()
    require(re.search(r"^Scan Compression:\s+disable$", config, re.M),
            "Compressão de scan habilitada")
    protocol = (reports / "preview_protocol.spf").read_text()
    reset_values = re.findall(r'^\s*"reset_n"\s*=\s*([^;]+);', protocol, re.M)
    require(len(reset_values) == 5 and set(reset_values) == {"1"},
            "Reset síncrono precisa estar inativo no setup e na captura")

    drc = (reports / "pre_preview_drc.rpt").read_text()
    require(re.search(r"^\s*0 TOTAL VIOLATIONS\s*$", drc, re.M), "Violações no resumo do DRC")
    for metric in ("Non-Scan Elements", "Excluded Scan Elements", "Violated Scan Elements"):
        require(re.search(r"^\s*" + metric + r".*?:\s*0\s", drc, re.M),
                "DRC não confirma zero elementos para " + metric)
    require(re.search(r"Traced Scan Elements.*?:\s*115\s", drc),
            "DRC não confirmou os 115 elementos rastreados")
    details = (reports / "dft_violations_details.rpt").read_text()
    build_rules = Counter(re.findall(r"\(([A-Z]\d+)-\d+\)\s*$", details, re.M))
    require(build_rules == {"B7": 45, "B8": 4, "B10": 44, "B12": 230, "N20": 1},
            "Avisos detalhados divergentes dos avisos da base e dos tie-offs")
    undriven = re.findall(r"pin \( /kuidamos_pixel_frontend/(\S+) \)\. \(B12-\d+\)", details)
    require(Counter(undriven) == Counter(cell + "/" + pin for cell in expected for pin in ("SE", "SI")),
            "B12 em terminais diferentes dos SE/SI temporariamente liberados")

    ordered = reports / "planned_chain.tsv"
    with ordered.open("w") as output:
        output.write("position\tinstance\n")
        output.writelines("{}\t{}\n".format(i, cell) for i, cell in enumerate(cells, 1))
    print("Preview confirmado: 1 cadeia, 115 SDFFs únicos, 0 excluídos, 0 cadeias conectadas.")


if __name__ == "__main__":
    try:
        if len(sys.argv) == 3 and sys.argv[1] == "--reports-only":
            validate_reports(Path(sys.argv[2]))
        elif len(sys.argv) == 2:
            validate(Path(sys.argv[1]))
        else:
            raise ValueError("Uso: check_preview.py <run> ou --reports-only <reports>")
    except (IndexError, KeyError, OSError, ValueError) as error:
        sys.exit("Preview não validado: " + str(error))
