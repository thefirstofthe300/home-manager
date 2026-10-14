#!/usr/bin/env python3
"""Triage code comments and markdown docs for wordiness, AI-sounding prose, and hard-to-read formatting.

Usage: scan.py [--base REF] [PATH ...]

With no PATH, scans lines added on the current branch relative to the merge-base with
REF (default: origin/HEAD, falling back to main/master). With PATHs, scans those files
or directories whole. Output is a list of candidates for a human or model to judge,
not verdicts.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

LINE_COMMENT = {
    "#": {".py", ".sh", ".bash", ".zsh", ".yaml", ".yml", ".nix", ".tf", ".rb", ".toml", ".mk", ".dockerfile"},
    "//": {".go", ".js", ".jsx", ".ts", ".tsx", ".java", ".c", ".h", ".cc", ".cpp", ".rs", ".kt", ".swift", ".tfvars"},
    "--": {".sql", ".lua", ".hs"},
}
EXT_TO_PREFIX = {ext: p for p, exts in LINE_COMMENT.items() for ext in exts}
DIRECTIVE = re.compile(r"nolint|eslint-|type:\s*ignore|shellcheck|\+kubebuilder|\+k8s|noqa|pragma|SPDX|Copyright|#!|go:generate|go:build|prettier-ignore", re.I)
NARRATION = re.compile(r"\b(added|now|no longer|previously|used to|fixed|refactor(ed)?|updated? to|changed|new)\b|per (the )?(ticket|pr|review)", re.I)
TICKET = re.compile(r"\b[A-Z]{2,}-\d+\b")
TODO = re.compile(r"\b(TODO|FIXME|XXX)\b(?!\s*[(\[]|.*[A-Z]{2,}-\d+)")
BANNER = re.compile(r"^[\W_]{0,3}\s*([-=#*~_]{4,}|[-=#*~_]{2,}.*[-=#*~_]{2,})\s*$")
CODE_LIKE = re.compile(r"[;{}]\s*$|^\s*(if|for|while|return|func|def|import|var|let|const)\b.*[({:]\s*$|\w+\([^)]*\)\s*$")
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿]")
BOLD = re.compile(r"\*\*[^*\n]+\*\*|__[^_\n]+__")
BULLET = re.compile(r"^(\s*)([-*+]|\d+\.)\s+")
CALLOUT = re.compile(r"^>\s*\*\*(Note|Warning|Tip|Important)", re.I)
QUOTED = re.compile(r"`[^`]*`|\"[^\"]*\"")  # quoted examples are not the author's own prose
EM_DASH = re.compile("\u2014|(?<=\\w) -- (?=\\w)")
CHATBOT = re.compile(r"great question|i hope this helps|certainly!|absolutely!|let'?s (dive|explore|take a look|break)|as of my last|feel free to reach out", re.I)
# High-signal subset of references/ai-patterns.md; judge in context, the full catalog is there.
AI_WORDS = re.compile(r"\b(delve|tapestry|leverag(e|es|ing)|utiliz(e|es|ing)|robust|seamless(ly)?|game-chang(er|ing)|holistic(ally)?|pivotal|meticulous(ly)?|cutting-edge|testament to|in order to|serves as|boasts|moreover|furthermore|it'?s worth noting|it is important to note)\b", re.I)


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=False).stdout


def base_ref(explicit):
    for ref in ([explicit] if explicit else []) + ["origin/HEAD", "origin/main", "origin/master", "main", "master"]:
        if run("git", "rev-parse", "--verify", "--quiet", ref).strip():
            return run("git", "merge-base", "HEAD", ref).strip()
    sys.exit("could not find a base ref; pass --base REF or explicit paths")


def added_lines(base):
    """Map path -> {line_number: text} for lines added since base, including untracked files."""
    out, current, lineno = {}, None, 0
    for raw in run("git", "diff", "-U0", base).splitlines():
        if raw.startswith("+++ b/"):
            current, out[current] = raw[6:], {}
        elif raw.startswith("@@"):
            lineno = int(re.search(r"\+(\d+)", raw).group(1)) - 1
        elif current and raw.startswith("+") and not raw.startswith("+++"):
            lineno += 1
            out[current][lineno] = raw[1:]
    for path in run("git", "ls-files", "--others", "--exclude-standard").split("\n"):
        if path:
            out[path] = dict(enumerate(Path(path).read_text(errors="ignore").splitlines(), 1))
    return out


def whole_files(paths):
    out = {}
    for p in map(Path, paths):
        for f in ([p] if p.is_file() else p.rglob("*")):
            if f.is_file() and ".git" not in f.parts:
                out[str(f)] = dict(enumerate(f.read_text(errors="ignore").splitlines(), 1))
    return out


def scan_prose(path, prose, report):
    """prose: {line_number: text} of sentences meant for readers (comment bodies, markdown text)."""
    dashes = [n for n, t in prose.items() if EM_DASH.search(t)]
    if dashes:
        report.append((path, dashes[0], f"em dash ({len(dashes)} lines); rules allow none", prose[dashes[0]]))
    plain = {n: QUOTED.sub("", t) for n, t in prose.items()}
    words = [(n, m.group(0).lower()) for n, t in plain.items() for m in AI_WORDS.finditer(t)]
    if words:
        uniq = ", ".join(sorted({w for _, w in words}))
        report.append((path, words[0][0], f"AI-pattern words ({len(words)}x): {uniq}", prose[words[0][0]]))
    for n, t in plain.items():
        if CHATBOT.search(t):
            report.append((path, n, "chatbot phrasing", prose[n]))


def scan_code(path, lines, prefix, report):
    comments = {n: t.strip() for n, t in lines.items() if t.strip().startswith(prefix)}
    blocks, run_start, prev = [], None, None
    for n in sorted(comments):
        if prev is None or n != prev + 1:
            run_start = n
            blocks.append([n, n])
        else:
            blocks[-1][1] = n
        prev = n
    for n, text in comments.items():
        if DIRECTIVE.search(text):
            continue
        body = text[len(prefix):].strip()
        if NARRATION.search(body):
            report.append((path, n, "narrates change?", text))
        if TICKET.search(body):
            report.append((path, n, "ticket ref (ok only if explaining a quirk)", text))
        if TODO.search(body):
            report.append((path, n, "TODO without owner/ticket", text))
        if BANNER.match(body):
            report.append((path, n, "banner/divider", text))
        if CODE_LIKE.search(body):
            report.append((path, n, "commented-out code?", text))
    for start, end in blocks:
        if end - start + 1 > 3 and not DIRECTIVE.search(comments[start]):
            report.append((path, start, f"{end - start + 1}-line comment block (ceiling is 3)", comments[start]))
    scan_prose(path, {n: t[len(prefix):].strip() for n, t in comments.items() if not DIRECTIVE.search(t)}, report)
    nonblank = sum(1 for t in lines.values() if t.strip())
    return len(comments), nonblank


def scan_markdown(path, lines, report):
    nums = sorted(lines)
    text = [lines[n] for n in nums]
    body = [t for t in text if t.strip()]
    heads = [n for n in nums if re.match(r"^#{1,6}\s", lines[n])]
    bold = sum(len(BOLD.findall(t)) for t in text)
    nested = [n for n in nums if (m := BULLET.match(lines[n])) and len(m.group(1)) >= 2]
    tables = [n for n in nums if re.match(r"^\s*\|.*\|\s*$", lines[n])]
    emoji = [n for n in nums if EMOJI.search(lines[n])]
    fm_end = 0
    if lines.get(1, "").strip() == "---":
        fm_end = next((n for n in nums if n > 1 and lines[n].strip() == "---"), 0)
    rules = [n for n in nums if re.match(r"^\s*([-*_])\1{2,}\s*$", lines[n]) and n > fm_end]
    callouts = [n for n in nums if CALLOUT.match(lines[n])]
    if len(body) < 25 and len(heads) >= 3:
        report.append((path, heads[0], f"{len(heads)} headings in {len(body)} lines", lines[heads[0]]))
    if len(heads) > 1 and len(body) / len(heads) < 8:
        report.append((path, heads[0], f"heading every {len(body) // len(heads)} lines on average", lines[heads[0]]))
    if bold > 3:
        report.append((path, nums[0], f"{bold} bold spans", ""))
    for label, hits in (("nested bullets", nested), ("emoji", emoji), ("horizontal rule", rules), ("callout blockquote", callouts)):
        if hits:
            report.append((path, hits[0], f"{label} ({len(hits)}x)", lines[hits[0]]))
    if tables:
        report.append((path, tables[0], f"table ({len(tables)} lines); needs 3+ columns and 3+ rows to justify", lines[tables[0]]))
    prose, fenced = {}, False
    for n in nums:
        if lines[n].lstrip().startswith("```"):
            fenced = not fenced
        elif not fenced and lines[n].strip():
            prose[n] = lines[n]
    scan_prose(path, prose, report)
    return len(body)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base")
    ap.add_argument("paths", nargs="*")
    args = ap.parse_args()
    files = whole_files(args.paths) if args.paths else added_lines(base_ref(args.base))
    report, summary = [], []
    for path, lines in sorted(files.items()):
        ext = Path(path).suffix.lower()
        if Path(path).name == "Dockerfile":
            ext = ".dockerfile"
        if ext in (".md", ".markdown"):
            n = scan_markdown(path, lines, report)
            summary.append(f"{path}: markdown, {n} non-blank lines" + (" (all added)" if not args.paths else ""))
        elif ext in EXT_TO_PREFIX:
            c, total = scan_code(path, lines, EXT_TO_PREFIX[ext], report)
            if total:
                summary.append(f"{path}: {c}/{total} lines are comments ({100 * c // total}%)")
    print("== Per-file summary ==")
    print("\n".join(summary) or "(no code or markdown files in scope)")
    print("\n== Candidates ==")
    for path, n, why, text in report:
        print(f"{path}:{n}: {why}" + (f"\n    {text.strip()[:120]}" if text.strip() else ""))
    if not report:
        print("(none)")


if __name__ == "__main__":
    main()
