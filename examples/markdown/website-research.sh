#!/usr/bin/env bash
set -euo pipefail

# Pipe the converted page to the research prompt/tool of your choice.
curl --fail --location --silent --show-error https://md.replynodes.com/replynodes.com/markdown-api/ > research-input.md
echo "Wrote Markdown research input to research-input.md" >&2
