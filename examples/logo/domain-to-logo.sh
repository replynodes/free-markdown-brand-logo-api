#!/usr/bin/env bash
set -euo pipefail

domain="${1:-github.com}"
curl --fail --location --silent --show-error --output "${domain}.png" "https://img.replynodes.com/${domain}"
echo "Saved ${domain}.png; inspect x-replynodes-logo-fallback when the distinction matters." >&2
