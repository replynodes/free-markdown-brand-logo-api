#!/usr/bin/env bash
set -euo pipefail

for domain in competitor-a.example competitor-b.example; do
  printf '\n# %s\n\n' "$domain"
  curl --fail --location --silent --show-error "https://md.replynodes.com/${domain}/"
done
