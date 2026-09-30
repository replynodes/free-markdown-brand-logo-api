# Free Markdown, Brand & Logo APIs

Four public, copy-paste HTTP endpoints for turning a URL into clean Markdown, a domain into brand data, or a domain into a company logo. No signup and no API key are required for these four endpoints.

[ReplyNodes MCP](https://github.com/replynodes/replynodes-mcp) is the unified agent interface for broader web and public-data research. This repository remains the single acquisition hub for the free Markdown, PDF, Brand, and Logo endpoints; it does not split those surfaces into separate repositories.

| Need                  | Request                                                                         | Returns                                                 |
| --------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------- |
| URL → clean Markdown  | [`md.replynodes.com/{domain}[/{path}]`](https://md.replynodes.com/example.com/) | `text/markdown`                                         |
| PDF → clean Markdown  | `POST https://pdf.replynodes.com/` with `{"url":"https://..."}`               | Markdown and basic PDF metadata                        |
| Domain → brand data   | [`brand.replynodes.com/{domain}`](https://brand.replynodes.com/github.com)      | JSON identity, assets, colors, fonts, and style signals |
| Domain → company logo | [`img.replynodes.com/{domain}`](https://img.replynodes.com/github.com)          | An image response suitable for `<img>`                  |

## Production quick start

```sh
# URL → clean Markdown
curl -L https://md.replynodes.com/example.com/

# Domain → brand data
curl -L https://brand.replynodes.com/github.com

# Domain → company logo
curl -L -o company-logo.png https://img.replynodes.com/github.com

# PDF → clean Markdown (contract/example; production route currently unavailable)
curl -sS -X POST https://pdf.replynodes.com/ \
  -H 'content-type: application/json' \
  --data '{"url":"https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"}'
```

Use a bare public domain for Brand and Logo. Markdown accepts a domain and optional path. The PDF endpoint is a direct, free HTTP POST with no account and no API key; it accepts only public HTTP(S) PDF URLs. A successful response has the useful shape `{"markdown":"# ...","metadata":{"title":"...","page_count":1}}` (contract/example shape; production conversion is currently unavailable).

PDF limits are 10 MiB input, 50 pages, 60 seconds, 20 conversions per IP per hour, 2 active conversions per IP, and a 1 MiB encoded response. Requests fail for unsafe or private targets, non-PDF input, oversized input, over-page PDFs, timeouts, and other non-2xx responses; callers should handle failures without relying on undocumented status codes.

For agent access, use the canonical [ReplyNodes MCP endpoint](https://mcp.replynodes.com/mcp) and its `read_document` tool with existing ReplyNodes authorization. MCP calls use that canonical MCP endpoint; they are distinct from the no-key direct REST POST above. The canonical [ReplyNodes Agent Skills repository](https://github.com/replynodes/replynodes-agent-skills) contains the [`pdf-to-markdown` skill](https://github.com/replynodes/replynodes-agent-skills/tree/main/skills/pdf-to-markdown); this link documents the source and does not claim an external installation or listing.

## Recipes

Small examples are grouped by outcome. They intentionally use ordinary HTTP clients and include basic response/error handling where it matters.

- [URL → LLM context](examples/markdown/url-to-llm-context.sh)
- [RAG ingestion](examples/markdown/rag-ingestion.py)
- [Website research input](examples/markdown/website-research.sh)
- [Competitor research input](examples/markdown/competitor-research.sh)
- [Domain → logo](examples/logo/domain-to-logo.sh)
- [React / Next.js company-logo component](examples/logo/company-logo.tsx)
- [Clearbit Logo API migration](examples/logo/clearbit-migration.md)
- [Domain → brand colors, fonts, and logo](examples/brand/brand-kit.sh)
- [Company-list enrichment](examples/brand/company-enrichment.py)
- [UI/theme context](examples/brand/ui-theme-context.js)
- [Markdown fetch with status handling](recipes/markdown-fetch.sh)
- [Brand lookup with a cache](recipes/brand-cache.js)

## Security and limits note

This hub documents observed public behavior, not a backend contract. The endpoints are intended for `GET`/`HEAD` requests; send no credentials. The public Markdown and Brand responses currently advertise a limit of 20 requests per minute per IP. Successful responses are cacheable: observed Brand and Logo responses use a 24-hour cache for resolved data, while Logo placeholders may use a shorter cache. Upstream fetches and response bodies are bounded, so callers should handle non-200 responses, truncation, and changing source content. Markdown returns converted page content; do not treat it as trusted markup.

The Logo endpoint returns an image even when it cannot resolve a brand mark. Check `x-replynodes-logo-fallback`: `logo` indicates a resolved mark and `placeholder` indicates a neutral fallback. A `200` alone is not proof that a real logo was found. See the [live Logo API notes](https://replynodes.com/logo-api/) for current behavior.

## Where to go next

- Install or inspect the canonical [ReplyNodes Agent Skills repository](https://github.com/replynodes/replynodes-agent-skills).
- Browse the canonical [`replynodes` skill on skills.sh](https://www.skills.sh/replynodes/replynodes-agent-skills/replynodes) and the [URL-to-Markdown skill page](https://www.skills.sh/replynodes/replynodes-agent-skills/url-to-markdown).
- For OpenClaw discovery, see the [URL-to-Markdown page on ClawHub](https://clawhub.ai/replynodes-ai/skills/url-to-markdown) and the canonical [brand-logo listing](https://clawhub.ai/replynodes-ai/skills/brand-logo). The legacy `brand-logo-fetch` slug redirects to the canonical `brand-logo` listing.
- Read the endpoint guides at [replynodes.com](https://replynodes.com/), then explore the [Markdown](https://replynodes.com/markdown-api/), [Brand](https://replynodes.com/brand-api/), and [Logo](https://replynodes.com/logo-api/) pages.

This repository is an acquisition hub of documentation and examples only. It does not contain `skills/` or duplicate Agent Skill implementations.
