"""Resume relatórios reais do FC; conclusão da execução não implica DRC limpo."""
import pathlib
import re
import sys


def extract(text, pattern):
    matches = re.findall(pattern, text, re.MULTILINE)
    if len(matches) != 1:
        raise ValueError("Relatório ausente, truncado ou ambíguo: " + pattern)
    return int(matches[0])


def main(directory):
    root = pathlib.Path(directory)
    if (root / "execution.status").read_text().strip() != "COMPLETED":
        raise ValueError("O driver não concluiu a execução")
    if (root / "protected.before.sha256").read_bytes() != (root / "protected.after.sha256").read_bytes():
        raise ValueError("Arquivos protegidos foram modificados")
    rpt = root / "reports"
    drc = (rpt / "pre_dft_drc.rpt").read_text()
    details = (rpt / "dft_violations.rpt").read_text()
    structure = (rpt / "check_design.rpt").read_text()
    data = {
        "sequential_detected": extract(drc, r"Sequential Elements Detected\s*:\s*(\d+)"),
        "scan_eligible_traced": extract(drc, r"Traced Scan Elements \(Percent\)\s*:\s*(\d+)"),
        "excluded_scan_elements": extract(drc, r"^\s*Excluded Scan Elements\s*:\s*(\d+)"),
        "violated_scan_elements": extract(drc, r"^\s*Violated Scan Elements \(Excluded\)\s*:\s*(\d+)"),
        "scan_drc_violations": extract(drc, r"^\s*(\d+) TOTAL VIOLATIONS\s*$"),
        "all_reported_dft_violations": extract(details, r"Total Violations:\s*(\d+)"),
        "structural_errors": extract(structure, r"Total \d+ EMS messages : (\d+) errors,"),
        "structural_warnings": extract(structure, r"Total \d+ EMS messages : \d+ errors, (\d+) warnings,"),
    }
    # Evita reduzir avisos B/N à contagem de regras de scan do relatório resumido.
    rules = re.findall(r"^\s*(\d+) .+\(([A-Z]+\d+)\)\s*$", details, re.MULTILINE)
    if sum(int(count) for count, _ in rules) != data["all_reported_dft_violations"]:
        raise ValueError("Contagem detalhada de regras não confere com o total")
    if data["scan_eligible_traced"] > data["sequential_detected"]:
        raise ValueError("Contagem de elegíveis inconsistente")
    lines = ["EXECUÇÃO PRÉ-DFT CONCLUÍDA; NÃO É ACEITE GLOBAL DE M9."]
    lines.extend("{}={}".format(key, value) for key, value in data.items())
    lines.extend("rule_{}={}".format(rule, count) for count, rule in rules)
    lines.append("scan_replacement=NAO_EXECUTADO; scan_insertion=NAO_EXECUTADO; ATPG=NAO_EXECUTADO")
    text = "\n".join(lines) + "\n"
    (root / "summary.txt").write_text(text)
    print(text, end="")


if __name__ == "__main__":
    try:
        main(sys.argv[1])
    except (IndexError, OSError, ValueError) as error:
        sys.exit("Resumo não validado: " + str(error))
