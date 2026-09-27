#!/usr/bin/env bash
set -euo pipefail

url="https://md.replynodes.com/github.com/"
status=$(curl --location --silent --show-error --output /tmp/replynodes-page.md --write-out '%{http_code}' "$url")
case "$status" in
  2*) cat /tmp/replynodes-page.md ;;
  *) echo "Markdown request failed with HTTP $status" >&2; exit 1 ;;
esac
