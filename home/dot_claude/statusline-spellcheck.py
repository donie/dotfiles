#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyspellchecker"]
# ///
"""
Spell-check helper for the Claude Code statusline.
Usage: statusline-spellcheck.py <path-to-text-file>
Reads text from the given file path.
Outputs one "wrong > correction" line per typo found, or nothing if clean.
"""

import re
import sys
from pathlib import Path

from spellchecker import SpellChecker


def main() -> None:
    if len(sys.argv) < 2:
        return

    text = Path(sys.argv[1]).read_text(encoding="utf-8")
    spell = SpellChecker()

    # Tokenise: letters and apostrophes only, preserving order
    words = re.findall(r"[A-Za-z']+", text)

    # Skip: all-caps acronyms, very short words (≤2 chars), possessives
    candidates = [w for w in words if len(w) > 2 and not w.isupper() and not w.endswith("'s")]

    misspelled = spell.unknown(candidates)

    seen: set[str] = set()
    for word in candidates:
        lower = word.lower()
        if lower in misspelled and lower not in seen:
            seen.add(lower)
            correction = spell.correction(word)
            if correction and correction.lower() != lower:
                print(f"{word} > {correction}")


if __name__ == "__main__":
    main()
