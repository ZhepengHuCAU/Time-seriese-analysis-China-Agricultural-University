from html import escape
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "第1章_差分方程_教材式中文讲义.md"
OUT = ROOT / "导出文件" / "第1章_差分方程_教材式中文讲义.pdf"
FIGURE = ROOT / "图片" / "图1-1_假想时间序列" / "图1-1_假想时间序列.png"


def register_fonts():
    candidates = [
        Path(r"C:\Windows\Fonts\NotoSansSC-VF.ttf"),
        Path(r"C:\Windows\Fonts\msyh.ttc"),
        Path(r"C:\Windows\Fonts\simsun.ttc"),
    ]
    font_path = next((p for p in candidates if p.exists()), None)
    if font_path is None:
        raise FileNotFoundError("No suitable Chinese font found in C:\\Windows\\Fonts")
    pdfmetrics.registerFont(TTFont("CJK", str(font_path)))
    pdfmetrics.registerFont(TTFont("CJK-Bold", str(font_path)))
    return "CJK"


def make_styles(font_name):
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            "ChapterTitle",
            parent=styles["Title"],
            fontName=font_name,
            fontSize=22,
            leading=30,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#1f2933"),
            spaceAfter=22,
        )
    )
    styles.add(
        ParagraphStyle(
            "Heading2C",
            parent=styles["Heading2"],
            fontName=font_name,
            fontSize=15,
            leading=22,
            textColor=colors.HexColor("#17324d"),
            spaceBefore=16,
            spaceAfter=8,
            keepWithNext=True,
        )
    )
    styles.add(
        ParagraphStyle(
            "Heading3C",
            parent=styles["Heading3"],
            fontName=font_name,
            fontSize=12.5,
            leading=18,
            textColor=colors.HexColor("#243b53"),
            spaceBefore=13,
            spaceAfter=6,
            keepWithNext=True,
        )
    )
    styles.add(
        ParagraphStyle(
            "BodyC",
            parent=styles["BodyText"],
            fontName=font_name,
            fontSize=10.5,
            leading=18,
            firstLineIndent=21,
            alignment=TA_LEFT,
            spaceAfter=7,
        )
    )
    styles.add(
        ParagraphStyle(
            "CaptionC",
            parent=styles["BodyText"],
            fontName=font_name,
            fontSize=9.2,
            leading=14,
            alignment=TA_LEFT,
            textColor=colors.HexColor("#4b5563"),
            spaceAfter=10,
        )
    )
    styles.add(
        ParagraphStyle(
            "CodeC",
            parent=styles["Code"],
            fontName=font_name,
            fontSize=9.8,
            leading=16,
            leftIndent=18,
            rightIndent=8,
            borderWidth=0.4,
            borderColor=colors.HexColor("#d8dee6"),
            borderPadding=8,
            backColor=colors.HexColor("#f7f9fb"),
            spaceBefore=4,
            spaceAfter=10,
        )
    )
    styles.add(
        ParagraphStyle(
            "QuestionC",
            parent=styles["BodyText"],
            fontName=font_name,
            fontSize=10.5,
            leading=17,
            firstLineIndent=0,
            leftIndent=12,
            spaceAfter=5,
        )
    )
    return styles


SUBSCRIPT_MAP = {
    "₀": "0",
    "₁": "1",
    "₂": "2",
    "₃": "3",
    "₄": "4",
    "₅": "5",
    "₆": "6",
    "₇": "7",
    "₈": "8",
    "₉": "9",
    "ₜ": "t",
    "₊": "+",
    "₋": "-",
}


def normalize_math_glyphs(text):
    out = []
    in_subscript = False
    for ch in text:
        if ch in SUBSCRIPT_MAP:
            if not in_subscript:
                out.append("_")
                in_subscript = True
            out.append(SUBSCRIPT_MAP[ch])
        else:
            in_subscript = False
            if ch == "−":
                out.append("-")
            elif ch in {"—", "–"}:
                out.append("-")
            else:
                out.append(ch)
    return "".join(out)


def page_header_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFont("CJK", 8.5)
    canvas.setFillColor(colors.HexColor("#6b7280"))
    canvas.drawString(2.1 * cm, height - 1.28 * cm, "经济时间序列")
    canvas.drawRightString(width - 2.1 * cm, height - 1.28 * cm, "第 1 章  差分方程")
    canvas.setStrokeColor(colors.HexColor("#d9dee7"))
    canvas.setLineWidth(0.4)
    canvas.line(2.1 * cm, height - 1.45 * cm, width - 2.1 * cm, height - 1.45 * cm)
    canvas.drawCentredString(width / 2, 1.25 * cm, str(doc.page))
    canvas.restoreState()


def flush_paragraph(story, para_lines, styles):
    if not para_lines:
        return
    text = " ".join(line.strip() for line in para_lines).strip()
    if not text:
        para_lines.clear()
        return
    text = normalize_math_glyphs(text)
    text = escape(text)
    text = text.replace("**", "")
    style = styles["BodyC"]
    if text.startswith("图 1.1") or text.startswith("**图 1.1"):
        style = styles["CaptionC"]
    story.append(Paragraph(text, style))
    para_lines.clear()


def build_story(markdown, styles):
    story = []
    lines = markdown.splitlines()
    para_lines = []
    i = 0
    in_questions = False
    while i < len(lines):
        raw = lines[i]
        line = raw.rstrip()
        stripped = line.strip()

        if not stripped:
            flush_paragraph(story, para_lines, styles)
            i += 1
            continue

        if stripped == "---":
            flush_paragraph(story, para_lines, styles)
            story.append(Spacer(1, 8))
            i += 1
            continue

        if stripped.startswith("!["):
            flush_paragraph(story, para_lines, styles)
            if FIGURE.exists():
                img = Image(str(FIGURE))
                max_width = A4[0] - 4.4 * cm
                ratio = max_width / img.imageWidth
                img.drawWidth = max_width
                img.drawHeight = img.imageHeight * ratio
                story.append(Spacer(1, 6))
                story.append(img)
                story.append(Spacer(1, 8))
            i += 1
            continue

        if stripped.startswith("# "):
            flush_paragraph(story, para_lines, styles)
            story.append(Paragraph(escape(stripped[2:].strip()), styles["ChapterTitle"]))
            i += 1
            continue

        if stripped.startswith("## "):
            flush_paragraph(story, para_lines, styles)
            heading = stripped[3:].strip()
            if heading == "本章小结":
                story.append(PageBreak())
            if heading == "思考题":
                in_questions = True
            story.append(Paragraph(escape(heading), styles["Heading2C"]))
            i += 1
            continue

        if stripped.startswith("### "):
            flush_paragraph(story, para_lines, styles)
            story.append(Paragraph(escape(stripped[4:].strip()), styles["Heading3C"]))
            i += 1
            continue

        if raw.startswith("    "):
            flush_paragraph(story, para_lines, styles)
            code_lines = []
            while i < len(lines) and (lines[i].startswith("    ") or not lines[i].strip()):
                if lines[i].strip():
                    code_lines.append(normalize_math_glyphs(lines[i][4:]))
                else:
                    code_lines.append("")
                i += 1
            story.append(Preformatted("\n".join(code_lines), styles["CodeC"]))
            continue

        if in_questions and stripped[:2] in {f"{n}." for n in range(1, 10)}:
            flush_paragraph(story, para_lines, styles)
            story.append(Paragraph(escape(normalize_math_glyphs(stripped)), styles["QuestionC"]))
            i += 1
            continue

        para_lines.append(line)
        i += 1

    flush_paragraph(story, para_lines, styles)
    return story


def main():
    font_name = register_fonts()
    styles = make_styles(font_name)
    markdown = SOURCE.read_text(encoding="utf-8")
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        rightMargin=2.1 * cm,
        leftMargin=2.1 * cm,
        topMargin=2.0 * cm,
        bottomMargin=1.9 * cm,
        title="Enders Chapter 1 教材式中文讲义",
        author="Codex",
    )
    story = build_story(markdown, styles)
    doc.build(story, onFirstPage=page_header_footer, onLaterPages=page_header_footer)
    print("PDF created")


if __name__ == "__main__":
    main()
