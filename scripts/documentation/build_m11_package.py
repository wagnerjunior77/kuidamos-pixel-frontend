"""Monte a entrega local M11 a partir dos arquivos existentes, sem executar EDA."""

import argparse
import hashlib
import re
import shutil
import subprocess
from html import escape
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.parse import quote, unquote, urlsplit

from markdown_it import MarkdownIt


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs/m11"
SOURCE = DOCS / "relatorio_tecnico_final.md"
GITHUB = "https://github.com/wagnerjunior77/kuidamos-pixel-frontend/blob"
PDF_NAME = "KUIDAMOS_6C_relatorio_tecnico.pdf"
CHAPTER_PAGES = (3, 3, 4, 4, 5, 5, 9, 9, 10, 12, 13, 13, 14, 14)
DOCUMENTS = (
    "manual_reproducao.md",
    "matriz_rastreabilidade.md",
    "resumo_resultados.md",
    "checklist_revisao.md",
)


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("photo-run", "floorplan", "placement", "cts", "routing"):
        parser.add_argument(f"--{name}", required=True, type=Path, help="diretório da execução")
    parser.add_argument("--output", required=True, type=Path, help="novo diretório dentro de outputs/m11")
    parser.add_argument("--chrome", default="google-chrome", help="executável do Chrome ou Chromium")
    parser.add_argument("--reference", default="docs/m11-final-documentation", help="referência GitHub dos links")
    return parser.parse_args()


def assets(args):
    return {
        "arquitetura.svg": DOCS / "figuras/arquitetura.svg",
        "threshold_sintetico.png": ROOT / "docs/imagens/m1/05_threshold.png",
        "comparativo_estagios.png": args.photo_run / "comparativo_estagios.png",
        "comparativo_bit_a_bit_crop.png": args.photo_run / "comparativo_bit_a_bit_crop.png",
        "detalhe_placa_rtl.png": args.photo_run / "detalhe_placa_rtl.png",
        "comparativo_thresholds_x1.png": args.photo_run / "comparativo_thresholds_x1.png",
        "comparativo_thresholds_x2.png": args.photo_run / "comparativo_thresholds_x2.png",
        "dft.svg": DOCS / "figuras/dft.svg",
        "floorplan.svg": args.floorplan / "floorplan.svg",
        "placement.svg": args.placement / "placement.svg",
        "cts_tree.svg": args.cts / "cts_tree.svg",
        "signals_layout.svg": args.routing / "signals_layout.svg",
    }


def resolve_links(markdown, source, reference, package=None):
    def replace(match):
        prefix, url = match.groups()
        target = urlsplit(url)
        if target.scheme or not target.path:
            return match.group()
        path = (source.parent / unquote(target.path)).resolve()
        relative = path.relative_to(ROOT).as_posix()
        if not path.exists():
            raise FileNotFoundError(path)
        if package and prefix.startswith("!"):
            name = "threshold_sintetico.png" if relative == "docs/imagens/m1/05_threshold.png" else path.name
            url = (package / "figuras" / name).as_uri()
        elif not package and path.parent == DOCS and path.name in DOCUMENTS:
            url = path.name
        else:
            url = f"{GITHUB}/{quote(reference)}/{quote(relative)}"
        if target.fragment:
            url += "#" + quote(unquote(target.fragment))
        return f"{prefix}{url})"

    return re.sub(r"(!?\[[^\]\n]+\]\()([^\s)]+)\)", replace, markdown)


def figure(package, filename, caption, css=""):
    url = (package / "figuras" / filename).as_uri()
    return (
        f'<figure class="{css}"><img src="{url}" alt="{escape(caption, quote=True)}">'
        f"<figcaption>{escape(caption)}</figcaption></figure>"
    )


def report_chapters():
    parts = re.split(r"^## (.+)$", SOURCE.read_text(), flags=re.MULTILINE)
    chapters = dict(zip(parts[1::2], parts[2::2]))
    titles = list(chapters)
    if len(titles) != len(CHAPTER_PAGES) or titles[-1] != "Referências":
        raise ValueError("Esperados 13 capítulos e uma seção de referências")
    return chapters


def validate_pdf(path):
    contents = subprocess.check_output(["pdftotext", "-layout", str(path), "-"], text=True)
    pages = contents.rstrip("\f\n").split("\f")
    if len(pages) != max(CHAPTER_PAGES) or "file://" in contents:
        raise ValueError("A paginação mudou ou há uma referência local exposta no texto")
    for title, page in zip(report_chapters(), CHAPTER_PAGES):
        if title not in pages[page - 1]:
            raise ValueError(f"O sumário aponta para a página errada em {title}")


def render_report(package, reference):
    engine = MarkdownIt().enable("table")
    validate_link = engine.validateLink
    figure_uri = (package / "figuras").as_uri() + "/"
    engine.validateLink = lambda url: url.startswith(figure_uri) or validate_link(url)
    chapters = report_chapters()
    titles = list(chapters)

    def chapter(number):
        title = titles[number - 1]
        contents = resolve_links(chapters[title], SOURCE, reference, package)
        html = engine.render(contents).replace("<p><em>Figura ", '<p class="image-caption"><em>Figura ')
        return f'<h2 id="cap-{number}">{escape(title)}</h2>' + html

    def gallery(title):
        return f'<p class="kicker section-label">{title}</p>'

    def image(name, caption, css=""):
        return figure(package, name, caption, css)

    toc = "".join(
        f'<li><a href="#cap-{number}"><span>{escape(title)}</span><strong>{page}</strong></a></li>'
        for number, (title, page) in enumerate(zip(titles, CHAPTER_PAGES), 1)
    )
    sections = [
        ("cover", """
        <div class="band"></div>
        <p class="kicker">CIExpert · Projeto KUIDAMOS · Grupo 6C</p>
        <h1>Front-end de<br>pré-processamento<br>de pixels</h1>
        <p class="subtitle">Relatório técnico de especificação, verificação e implementação digital</p>
        <div class="authors">
          <p><strong>Wagner Cutrim Rabelo Junior</strong><br>DFT</p>
          <p><strong>Thiago Fernandes Carvalho de Souza</strong><br>RTL e síntese</p>
        </div>
        <p class="date"><strong>Versão 0.2 para revisão humana</strong><br>25 de novembro de 2026</p>
        """),
        ("", f"""
        <h2>Resumo</h2>
        <p>O Grupo 6C implementou um IP em streaming para conversão RGB888 em grayscale,
        crop, redução nearest-neighbor e threshold com bypass. O Golden Model e o scoreboard
        em SystemVerilog orientaram a verificação. A regressão RTL registrou 15 de 15 cenários
        aprovados. O circuito mapeado em SAED32 RVT recebeu uma cadeia de 115 células de scan.
        A implementação física roteou as 1.486 redes requeridas. Em análise funcional a 100 MHz,
        as piores folgas registradas foram +1,8647 ns de setup no canto slow e +0,0639 ns de
        hold no canto fast. A potência estimada com atividade simulada e RC extraído foi
        358,3551 µW no cenário slow. Uma demonstração com fotografia comparou 937.248
        pixels em seis configurações RTL, sem divergências. O relatório delimita a validação
        acadêmica e as verificações pendentes.</p>
        <p><strong>Palavras-chave.</strong> Pré-processamento de pixels, verificação RTL,
        Golden Model, scan, implementação física.</p>
        <h2>Sumário</h2><ol class="toc">{toc}</ol>
        """),
        ("", chapter(1) + chapter(2)),
        ("", chapter(3) + chapter(4)),
        ("rtl", chapter(5) + chapter(6)),
        ("", gallery("Capítulo 6 · Demonstração") + "<h2>Do RGB ao crop e ao resize</h2>" + image(
            "comparativo_estagios.png",
            "Figura 3 — Entrada RGB com as regiões marcadas e saídas capturadas no RTL. "
            "O crop (1,1) mantém 376 × 264 amostras em grayscale. O resize (2,2) reduz a região a 188 × 132.",
            "stage native",
        )),
        ("", gallery("Capítulo 6 · Demonstração") + "<h2>Concordância bit a bit e preservação de detalhes</h2>" + image(
            "comparativo_bit_a_bit_crop.png",
            "Figura 4 — Referência Golden Model, captura RTL e mapa de diferenças do crop. "
            "O mapa preto representa zero diferenças em 99.264 pixels.",
            "native",
        ) + image(
            "detalhe_placa_rtl.png",
            "Figura 5 — Quatro saídas capturadas do RTL para a mesma região da placa. "
            "A área tem 88 × 40 amostras no fator (1,1) e 44 × 20 no fator (2,2). "
            "O zoom por replicação deixa a perda de resolução visível.",
            "detail native",
        )),
        ("", gallery("Capítulo 6 · Demonstração") + "<h2>Efeito do limiar</h2>" + image(
            "comparativo_thresholds_x1.png",
            "Figura 6a — Fator (1,1). Grayscale, T=96 e T=128 vêm do RTL. "
            "T=64, T=160 e T=192 vêm do Golden Model.",
            "native",
        ) + image(
            "comparativo_thresholds_x2.png",
            "Figura 6b — Fator (2,2). Grayscale e T=96 vêm do RTL. Os demais limiares vêm do Golden Model. "
            "A perda de amostras já ocorre no resize e se mantém após a binarização.",
            "native",
        )),
        ("", chapter(7) + chapter(8)),
        ("", chapter(9) + '<div class="physical">' + image(
            "floorplan.svg", "Figura 8 — Floorplan inicial exportado, com os limites do die e do core e as 52 rows."
        ) + image(
            "placement.svg", "Figura 9 — Placement aceito após a correção da rede PG em M1."
        ) + "</div>"),
        ("", gallery("Capítulo 9 · Implementação física") + "<h2>Árvore de clock e layout roteado</h2>"
         + "<p>As duas visualizações foram geradas a partir de objetos e geometrias dos checkpoints "
           "da implementação. O manifesto local registra os arquivos-fonte.</p>"
         + '<div class="physical">' + image(
            "cts_tree.svg", "Figura 10 — Posições dos buffers e sinks de CTS. As conexões desenhadas "
            "representam a topologia da árvore."
        ) + image(
            "signals_layout.svg", "Figura 11 — Segmentos de sinal, clock e alimentação obtidos do DEF "
            "da execução que produziu o checkpoint final."
        ) + "</div>"),
        ("metrics", chapter(10)),
        ("", chapter(11) + chapter(12)),
        ("", chapter(13) + chapter(14)),
    ]
    body = "\n".join(f'<section class="sheet {css}">{content}</section>' for css, content in sections)
    css = Path(__file__).with_name("m11_print.css").read_text()
    return (
        '<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">'
        f"<title>KUIDAMOS 6C — Relatório técnico</title><style>{css}</style></head><body>{body}</body></html>"
    )


def assemble(package, args):
    figures = package / "figuras"
    figures.mkdir(parents=True)
    sources = assets(args)
    for name, source in sources.items():
        shutil.copy2(source, figures / name)
    for name in DOCUMENTS:
        source = DOCS / name
        (package / name).write_text(resolve_links(source.read_text(), source, args.reference))
    with TemporaryDirectory(prefix="kuidamos-print-") as temp:
        temp = Path(temp)
        layout = temp / "relatorio.html"
        layout.write_text(render_report(package, args.reference))
        subprocess.run(
            [
                args.chrome, "--headless", "--disable-dev-shm-usage",
                "--no-pdf-header-footer", f"--user-data-dir={temp / 'profile'}",
                f"--print-to-pdf={package / PDF_NAME}", layout.as_uri(),
            ],
            check=True,
        )
    if not (package / PDF_NAME).read_bytes().startswith(b"%PDF-"):
        raise ValueError("O navegador não gerou um PDF válido")
    validate_pdf(package / PDF_NAME)
    files = [f"- [{name}]({name})" for name in (PDF_NAME, *DOCUMENTS)]
    figure_sources = [
        f"- [figuras/{name}](figuras/{name}) · origem `{source.resolve().relative_to(ROOT)}`"
        for name, source in sources.items()
    ]
    (package / "inventario.md").write_text("\n".join([
        "# KUIDAMOS 6C — inventário do pacote local M11",
        "",
        "PDF com fotografia e visualizações físicas para revisão local.",
        "As figuras da fotografia dependem de confirmação de autoria e licença para divulgação.",
        "Os caminhos das origens são relativos à raiz do repositório.",
        "",
        "## Documentos", "", *files, "",
        "## Figuras", "", *figure_sources, "",
        "## Integridade", "",
        "A partir desta pasta, execute `sha256sum -c SHA256SUMS`.",
        "O manifesto cobre o PDF, os documentos, o inventário e as figuras.", "",
    ]))
    checksums = []
    for path in sorted(package.rglob("*")):
        if path.is_file():
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            checksums.append(f"{digest}  {path.relative_to(package).as_posix()}\n")
    (package / "SHA256SUMS").write_text("".join(checksums))


def main():
    args = arguments()
    output = args.output.resolve()
    output.relative_to(ROOT / "outputs/m11")
    if output.exists():
        raise FileExistsError(f"Use um diretório novo: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(prefix=".m11-package-", dir=output.parent) as temp:
        package = Path(temp) / "entrega"
        assemble(package, args)
        package.rename(output)
    print(output / PDF_NAME)


if __name__ == "__main__":
    main()
