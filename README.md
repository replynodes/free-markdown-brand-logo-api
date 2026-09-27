# Free Markdown, Brand & Logo APIs

Three public, copy-paste HTTP endpoints for turning a URL into clean Markdown, a domain into brand data, or a domain into a company logo. No signup and no API key are required for these three endpoints.

| Need                  | Request                                                                         | Returns                                                 |
| --------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------- |
| URL → clean Markdown  | [`md.replynodes.com/{domain}[/{path}]`](https://md.replynodes.com/example.com/) | `text/markdown`                                         |
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
```

Use a bare public domain for Brand and Logo. Markdown accepts a domain and optional path. The endpoint pages have the authoritative request shapes and live examples: [Markdown API](https://replynodes.com/markdown-api/), [Brand API](https://replynodes.com/brand-api/), and [Logo API](https://replynodes.com/logo-api/).

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
- For OpenClaw discovery, see the [URL-to-Markdown page on ClawHub](https://clawhub.ai/skills/url-to-markdown) and [Brand page on ClawHub](https://clawhub.ai/skills/brand).
- Read the endpoint guides at [replynodes.com](https://replynodes.com/), then explore the [Markdown](https://replynodes.com/markdown-api/), [Brand](https://replynodes.com/brand-api/), and [Logo](https://replynodes.com/logo-api/) pages.

This repository is an acquisition hub of documentation and examples only. It does not contain `skills/` or duplicate Agent Skill implementations.
