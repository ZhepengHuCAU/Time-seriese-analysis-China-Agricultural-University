from pathlib import Path
import re

root = Path(r"C:\Users\zhepeng\OneDrive\CAU\学校\经济时间序列")
src = root / "草稿" / "第1章_差分方程_详细中文讲义_旧稿.md"
dst = root / "草稿" / "第1章_差分方程_详细中文讲义_普通公式旧稿.md"
text = src.read_text(encoding="utf-8")

# The only piecewise formula in this chapter is clearer as a sentence in plain Markdown.
piecewise = r'''\lambda_t=
\begin{cases}
0, & c_t-c_{t-1}\geq0,\\
1, & c_t-c_{t-1}<0。
\end{cases}'''
text = text.replace(piecewise, "λₜ = 0（当 cₜ − cₜ₋₁ ≥ 0）；λₜ = 1（当 cₜ − cₜ₋₁ < 0）。")

# Remove display and inline math delimiters first.
text = text.replace("$$", "").replace("$", "")

# Remove equation tags, then handle common compound mathematical commands.
text = re.sub(r"\\tag\{[^}]*\}", "", text)
text = re.sub(r"\\boxed\{([^{}]*)\}", r"\1", text)
text = re.sub(r"\\text\{([^{}]*)\}", r"\1", text)
text = re.sub(r"\\frac\{([^{}]*)\}\{([^{}]*)\}", r"\1/\2", text)
text = text.replace(r"\left|", "|").replace(r"\right|", "|")
text = text.replace(r"\mathcal I_t", "信息集 Iₜ")

replacements = {
    r"\alpha": "α", r"\beta": "β", r"\varepsilon": "ε", r"\lambda": "λ",
    r"\Delta": "Δ", r"\pi": "π", r"\rho": "ρ", r"\theta": "θ",
    r"\sum": "Σ", r"\sin": "sin", r"\cos": "cos", r"\infty": "∞",
    r"\rightarrow": "→", r"\ldots": "…", r"\cdots": "…",
    r"\mid": "|", r"\geq": "≥", r"\leq": "≤", r"\neq": "≠",
    r"\pm": "±", r"\times": "×", r"\quad": "  ", r"\qquad": "    ",
}
for old, new in replacements.items():
    text = text.replace(old, new)
text = text.replace(r"\gamma", "\u03b3").replace(r"\delta", "\u03b4")

# Make common time-series sub/superscripts readable without a math renderer.
token_map = {
    "_{t+1}": "ₜ₊₁", "_{t+2}": "ₜ₊₂", "_{t-1}": "ₜ₋₁", "_{t-2}": "ₜ₋₂",
    "_{t-k}": "ₜ₋ₖ", "_{t-j}": "ₜ₋ⱼ", "_{t+h}": "ₜ₊ₕ", "_{c,t-1}": "c,ₜ₋₁",
    "_{ct}": "cₜ", "_{it}": "iₜ", "_{s,t+2}": "s,ₜ₊₂", "_{f,t+1}": "f,ₜ₊₁",
    "_t": "ₜ", "_0": "₀", "_1": "₁", "_2": "₂",
    "^{t-1}": "ᵗ⁻¹", "^{t-2}": "ᵗ⁻²", "^{∞}": "∞", "^{T}": "ᵀ",
    "^t": "ᵗ", "^2": "²", "^h": "ʰ", "^j": "ʲ", "^*": "*",
}
for old, new in token_map.items():
    text = text.replace(old, new)
text = (text.replace("_3", "\u2083").replace("_4", "\u2084").replace("_5", "\u2085")
            .replace("_j", "\u2c7c").replace("_k", "\u2096").replace("_h", "\u2095")
            .replace("^3", "\u00b3").replace("^k", "\u1d4f").replace("^d", "\u1d48")
            .replace("^s", "\u02e2"))

# Remaining braces only grouped LaTeX-style terms; remove them for plain text.
text = text.replace("{", "").replace("}", "")
text = text.replace("\\", "")
text = re.sub(r"underbrace([^_\n]+)_([^\n]+)", r"\1（\2）", text)
text = (text.replace("y\u209c_t=1\u1d40", "y\u209c（t = 1，…，T）")
            .replace("\u03a3\u2c7c=0\u1d57\u207b\u00b9", "\u03a3（j = 0 至 t−1）")
            .replace("\u03a3\u2c7c=0\u221e", "\u03a3（j = 0 至 ∞）")
            .replace("r\u2081,2", "r\u2081、r\u2082")
            .replace("Q\u209c\u1d48", "Q\u1d48\u209c").replace("Q\u209c\u02e2", "Q\u02e2\u209c")
            .replace("y\u209c^(p)", "y\u209c（p）")
            .replace("L^ky\u209c", "L\u1d4fy\u209c")
            .replace("(1-bL)^-1", "(1 − bL)\u207b\u00b9")
            .replace("y\u209c+5", "y\u209c\u208a\u2085"))

# Keep display equations visually distinct in ordinary Markdown.
text = re.sub(r"\n\n\s*\n", "\n\n", text)
dst.write_text(text, encoding="utf-8")
print("Plain Markdown handout created.")
