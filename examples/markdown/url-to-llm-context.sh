#!/usr/bin/env bash
set -euo pipefail

url="${1:-https://example.com/}"
domain_path="${url#https://}"
domain_path="${domain_path#http://}"
curl --fail-with-body --location --silent --show-error "https://md.replynodes.com/${domain_path}"
