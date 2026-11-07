#!/usr/bin/env python3
"""
normalize_md_headings.py
Normalizes Markdown heading levels across Document 1A, 1B, 1C, 2A, 2B, 2T, and 3:
  - #     (H1): Document Title (first heading in file)
  - ##    (H2): Part I..VI, Executive Summary/Overview, Introduction, How to Read,
                Synthesis:, Coda:, Appendix, Navigation
  - ###   (H3): Single-digit or single-character sections (e.g. "1. ...", "A. ...", "Aspect 1:", "Folder 1:")
  - ####  (H4): Alphanumeric.Alphanumeric sections (e.g. "1.1 ...", "3.2B ..."), or top-level Appendix Tables ("Table A.1:")
  - ##### (H5): Two-dot sections (e.g. "2.2.1 ...", "3.4.7 ..."), sub-tables ("Table 3.2A:", "Table 5.1A:", "Table 4.1:"),
                and unnumbered 3rd-level subheadings inside a section ("Left Regime", "Why Traditional Cash Budgeting...")
"""

import re
import sys
from pathlib import Path

DOC_FILES = [
    "Document 1A.md",
    "Document 1B.md",
    "Document 1C.md",
    "Document 2A.md",
    "Document 2B.md",
    "Document 2T.md",
    "Document 3.md",
]

# Regex patterns on the stripped heading text (without leading #'s)
RE_TWO_DOT = re.compile(r"^[0-9A-Za-z]+\.[0-9A-Za-z]+\.[0-9A-Za-z]+\b")
RE_ONE_DOT = re.compile(r"^[0-9A-Za-z]+\.[0-9A-Za-z]+\b")
RE_SINGLE_CHAR_SEC = re.compile(r"^(?:[0-9]+|[A-Z])\.\s+")

# Major H2 divisions (Part I..VI, Executive Summary, Intro, Appendix, Coda, etc.)
RE_H2_MAJOR = re.compile(
    r"^(?:"
    r"Part\s+[IVX0-9]+\b|"
    r"Executive\s+(?:Summary|Overview)\b|"
    r"Introduction\b|"
    r"How\s+to\s+Read\b|"
    r"Synthesis\b|"
    r"Coda\b|"
    r"Appendix\s+[A-Z0-9]+\b|"
    r"Navigation\s+to\b"
    r")",
    re.IGNORECASE,
)

# H3 equivalents (Aspect 1..3, Folder 1..6, Why International History...)
RE_H3_SPECIAL = re.compile(
    r"^(?:"
    r"Aspect\s+[0-9]+\b|"
    r"Folder\s+[0-9]+\b|"
    r"Why\s+International\s+History\b"
    r")",
    re.IGNORECASE,
)

# Tables: "Table A.1" under Appendix -> H4; "Table 3.2A", "Table 5.1A", "Table 4.1", "Table 6A" -> H5
RE_TABLE_APPENDIX = re.compile(r"^Table\s+A\.[0-9]+\b", re.IGNORECASE)
RE_TABLE_SUB = re.compile(r"^Table\s+[0-9]+", re.IGNORECASE)


def classify_heading(text: str, is_first_h1: bool, current_parent_level: int) -> int:
    """Returns target hash count (1 to 5)."""
    clean = text.strip()
    # Strip leading bold markers if heading starts with **1.1 ...**
    clean_unbold = re.sub(r"^\*\*|\*\*$", "", clean).strip()

    if is_first_h1:
        return 1

    # 1. Two-dot section: e.g. 2.2.1, 3.4.7, 4.5.1 -> H5 (#####)
    if RE_TWO_DOT.match(clean_unbold):
        return 5

    # 2. One-dot section: e.g. 1.1, 3.2, 5.6 -> H4 (####)
    if RE_ONE_DOT.match(clean_unbold):
        return 4

    # 3. Major Part / Executive Summary / Intro / Appendix / Coda -> H2 (##)
    if RE_H2_MAJOR.match(clean_unbold):
        return 2

    # 4. Appendix Tables (Table A.1, A.2, A.3) -> H4 (####); Other Tables -> H5 (#####)
    if RE_TABLE_APPENDIX.match(clean_unbold):
        return 4
    if RE_TABLE_SUB.match(clean_unbold):
        return 5

    # 5. Single-digit or single-letter section: e.g. "1. ...", "A. ..."
    if RE_SINGLE_CHAR_SEC.match(clean_unbold):
        # If it's "A. Structural Rationale" inside a 2.2.2 two-dot section, make it H5!
        if re.match(r"^[A-D]\.\s+", clean_unbold) and current_parent_level >= 4:
            return 5
        return 3

    # 6. Special H3 sections (Aspect 1..3, Folder 1..6)
    if RE_H3_SPECIAL.match(clean_unbold):
        return 3

    # 7. Unnumbered subheadings (e.g. "Left Regime...", "Sweden and Finland...",
    #    "How the 12-Layer Attribution...", "The Retirement-Age U-Curve..."):
    #    Place 1 level below the current numbered parent section (bounded to H4 or H5).
    return min(5, max(4, current_parent_level + 1))


def process_file(filepath: Path, dry_run: bool = False) -> int:
    lines = filepath.read_text(encoding="utf-8").splitlines(keepends=True)
    new_lines = []
    in_code_block = False
    seen_first_heading = False
    current_parent_level = 3
    changes = 0

    for idx, line in enumerate(lines, start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~~"):
            in_code_block = not in_code_block
            new_lines.append(line)
            continue

        if in_code_block:
            new_lines.append(line)
            continue

        m = re.match(r"^(#{1,6})\s+(.*?)(\r?\n?)$", line)
        if not m:
            new_lines.append(line)
            continue

        old_hashes, title_text, newline_char = m.group(1), m.group(2), m.group(3)
        is_first = not seen_first_heading
        seen_first_heading = True

        target_level = classify_heading(title_text, is_first, current_parent_level)

        # Update current_parent_level when we hit a structural H2, H3, or H4
        clean_unbold = re.sub(r"^\*\*|\*\*$", "", title_text.strip()).strip()
        if target_level in (2, 3) or RE_ONE_DOT.match(clean_unbold) or RE_TWO_DOT.match(clean_unbold):
            current_parent_level = target_level

        new_hashes = "#" * target_level
        if new_hashes != old_hashes:
            changes += 1
            print(f"[{filepath.name}:{idx}] {old_hashes} -> {new_hashes} | {title_text[:72]}")
            new_lines.append(f"{new_hashes} {title_text}{newline_char}")
        else:
            new_lines.append(line)

    if changes > 0 and not dry_run:
        filepath.write_text("".join(new_lines), encoding="utf-8")

    return changes


def main():
    dry_run = "--dry-run" in sys.argv
    mode_str = "DRY RUN (no files modified)" if dry_run else "APPLYING CHANGES"
    print(f"=== Markdown Heading Normalizer ({mode_str}) ===")
    total_changes = 0
    for fname in DOC_FILES:
        p = Path(fname)
        if p.exists():
            c = process_file(p, dry_run=dry_run)
            total_changes += c
            print(f"  -> {fname}: {c} heading(s) updated.\n")
        else:
            print(f"  -> {fname}: [SKIPPED - file not found]\n")
    print(f"Total headings normalized: {total_changes}")


if __name__ == "__main__":
    main()
