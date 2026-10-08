#!/bin/bash
# Validate Mermaid diagrams with the official Mermaid CLI (same parser GitHub uses).
#
# Usage:
#   validate.sh diagram.mmd [output.svg]   one diagram; prints an ASCII preview
#   validate.sh doc.md                     every ```mermaid block in a Markdown file
#
# Exit status: 0 = all valid, 1 = invalid diagram or bad usage.
# Never writes next to the input; renders go to a temp dir unless output.svg is given.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 diagram.mmd [output.svg] | $0 doc.md"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-}"

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT"
    exit 1
fi

TMP=$(mktemp -d /tmp/mermaid_validate.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# mermaid-cli >= 12 declares puppeteer as a peer dependency, which npx won't
# install on its own, so request both packages explicitly.
mmdc() {
    npx -y -p @mermaid-js/mermaid-cli -p puppeteer mmdc "$@"
}

# Print the parser's message without the JavaScript stack trace.
mmdc_quiet() {
    local log="$TMP/mmdc.log"
    if mmdc "$@" -q >"$log" 2>&1; then
        return 0
    fi
    grep -vE '^\s+at |Parser\.|mermaid-cli-intercept|^\s*$' "$log" | sed 's/^/    /'
    return 1
}

ascii_preview() {
    # Best effort: beautiful-mermaid only supports some diagram types.
    MERMAID_INPUT="$1" npx -y --package beautiful-mermaid node -e '
const fs = require("node:fs");
const path = require("node:path");
const binPath = process.env.PATH.split(":")[0];
const moduleRoot = path.dirname(binPath);
const { renderMermaidAscii } = require(path.join(moduleRoot, "beautiful-mermaid"));
const text = fs.readFileSync(process.env.MERMAID_INPUT, "utf8");
process.stdout.write(renderMermaidAscii(text));
process.stdout.write("\n");
' 2>/dev/null || echo "(no ASCII preview for this diagram type)"
}

case "$INPUT" in
*.md | *.markdown)
    # Split out each ```mermaid block, remembering where it starts.
    awk -v dir="$TMP" '
        /^[ \t]*```+[ \t]*mermaid[ \t]*$/ { n++; inblock = 1; print n, NR + 1 > (dir "/index"); next }
        inblock && /^[ \t]*```+[ \t]*$/ { inblock = 0; next }
        inblock { print > (dir "/block-" n ".mmd") }
    ' "$INPUT"
    if [ ! -s "$TMP/index" ]; then
        echo "No \`\`\`mermaid blocks found in $INPUT"
        exit 1
    fi
    total=$(wc -l <"$TMP/index" | tr -d ' ')
    echo "Validating $total Mermaid block(s) in $INPUT"

    # Fast path: one browser for the whole file.
    if mmdc -i "$INPUT" -o "$TMP/out.md" -q >/dev/null 2>&1; then
        echo "✓ All $total block(s) OK"
        exit 0
    fi

    # Something failed: check blocks one by one to say which.
    failed=0
    while read -r n line; do
        if [ ! -s "$TMP/block-$n.mmd" ]; then
            echo "✗ Block $n ($INPUT:$line): empty"
            failed=$((failed + 1))
        elif mmdc_quiet -i "$TMP/block-$n.mmd" -o "$TMP/block-$n.svg" >"$TMP/err" 2>&1; then
            echo "✓ Block $n ($INPUT:$line)"
        else
            rel=$(sed -nE 's/.*on line ([0-9]+).*/\1/p' "$TMP/err" | head -1)
            if [ -n "$rel" ]; then
                echo "✗ Block $n ($INPUT:$line), error at $INPUT:$((line + rel - 1)):"
            else
                echo "✗ Block $n ($INPUT:$line):"
            fi
            cat "$TMP/err"
            failed=$((failed + 1))
        fi
    done <"$TMP/index"
    echo "✗ $failed of $total block(s) invalid"
    exit 1
    ;;
*)
    echo "Validating: $INPUT"
    if mmdc_quiet -i "$INPUT" -o "${OUTPUT:-$TMP/out.svg}"; then
        echo "✓ Mermaid OK"
        echo ""
        echo "ASCII preview:"
        ascii_preview "$INPUT"
        [ -n "$OUTPUT" ] && echo "Rendered to: $OUTPUT"
        exit 0
    fi
    echo "✗ Mermaid validation failed"
    exit 1
    ;;
esac
