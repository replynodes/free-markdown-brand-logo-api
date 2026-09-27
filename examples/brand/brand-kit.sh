#!/usr/bin/env bash
set -euo pipefail

domain="${1:-github.com}"
curl --fail --location --silent --show-error -H 'Accept: application/json' "https://brand.replynodes.com/${domain}"

# The JSON shape is the live contract; inspect its identity, logos, colors, and fonts fields.
