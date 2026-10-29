# n8n: any public URL to clean Markdown (no API key)

[`n8n-url-to-markdown.workflow.json`](n8n-url-to-markdown.workflow.json) is one importable n8n workflow built only from built-in nodes. It turns a public page URL into clean Markdown that you can feed into your own next node. It needs no credential, no API key, and no custom node or npm package.

This is a community example. It is not an official n8n template, a community node, or an n8n Cloud listing.

## Use it

1. In n8n, create a workflow and choose **Import from file**, then select `n8n-url-to-markdown.workflow.json`.
2. Open **Input URL** and set `url` to any public page URL, including path and query string.
3. Select **Execute workflow**.
4. Connect your own node to **Output** (the "Your next node goes here" sticky note marks the spot). Each item has `markdown` and `source_url`.

The workflow is `Manual Trigger -> Input URL (Edit Fields) -> ReplyNodes Markdown (HTTP Request) -> Route response (Switch) -> Output (Edit Fields)`. The Switch, Wait and Stop and explain nodes only handle errors.

## The request

`GET https://md.replynodes.com/{full page URL}` with `Accept: application/json`. For example, `https://md.replynodes.com/https://example.com/docs/page?x=1`. Put the complete URL after the host. Do not split it into domain and path, and do not URL-encode it. The path and query are preserved and fragments are not fetched. The Markdown is in `data.markdown` of the `{data, meta}` response. `source_url` is `data.url`, which is the page after redirects and may omit the query string. It falls back to your input URL.

The default demo URL is the MDN documentation page `https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=n8n-demo`.

## Limits

- Keyless use is limited to **100 requests per day**, one page per request. Responses carry `X-RateLimit-*` headers.
- The daily quota is keyed by the client IP bucket. Everyone behind the same egress IP (an office, a VPN, a shared n8n host) shares the same 100 per day.
- This keyless endpoint is not documented to render JavaScript or get past bot challenges, and this example does not claim either.
- Treat the returned Markdown as untrusted content.

## Errors

Anything other than a 2xx response stops the workflow with a message that says what happened. Error responses use `{"error": {"code", "reason", "retryable"}}`.

| Response | What the workflow does | What you do |
| --- | --- | --- |
| 400 `invalid_request` | Stops, no retry. | Use a full public `https://` page URL. |
| 429 `anonymous_limit_reached` | Stops, no retry loop. The message shows the reset time from `x-ratelimit-reset` (UTC). | Wait for the reset, or create a [free account](https://platform.replynodes.com/sign-up) (500 credits). If you share an egress IP, other people's requests count against the same quota. |
| 451 | Stops, no retry. The publisher has excluded the page. | Use a different page. |
| 502 `upstream_blocked` | Stops, no retry. The target site blocked the fetch. | Use a different page or source. |
| 502 `upstream_unavailable`, reason `empty_content` | Stops, no retry. The page had no extractable content, such as a JavaScript-only page. | Use a different page. |
| 5xx with `retryable: true` | Waits 2 seconds and retries, at most 2 retries (3 attempts), then stops. | Try again later. |
| Other non-2xx | Stops, no retry. | Check the message. |

## Evidence (2026-10-29)

Environment: n8n 2.45.5 (`n8nio/n8n` Docker image, digest `sha256:9f6d0a5987ab5a297c4b0b38fbf1a22285dd1364551478e93f03d506908fa74c`), fresh database, `n8n import:workflow` then `n8n execute`, no UI session.

- **Verified, real requests:**
  - Site root `https://example.com/` returned 200, title "Example Domain", and `source_url` `https://example.com/`.
  - `https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=n8n-demo` returned 200 with title "Overview of HTTP - HTTP | MDN", heading `# Overview of HTTP`, and `source_url` `https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview`. `data.markdown` reached the output node in both runs.
  - Query preservation: `https://httpbin.org/anything/docs/page?x=1&y=two` came back with `args` `x=1, y=two`.
  - A real 400 `invalid_request` (input `not-a-url`) stopped the workflow with the 400 message.
- **Simulated, not observed on the live service:** 429, 451, both 502 variants and retryable 503 were run against a local mock that returns the response shapes above. The mock's 451 error code name is illustrative and the workflow only checks the status. Always-503 made 3 requests then stopped. A 503, 503, 200 sequence made 3 requests and produced output.
- **Not verified:** import through the n8n web UI (the import was done with the CLI), n8n versions other than 2.45.5, and n8n Cloud.

### Token comparison (measured)

On `https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=n8n-demo`, measured 2026-10-29 with `js-tiktoken` 1.0.21:

| | Bytes | `cl100k_base` tokens | `o200k_base` tokens |
| --- | --- | --- | --- |
| Raw HTML (`curl -sSL`, HTTP 200) | 228,532 | 60,922 | 61,285 |
| `data.markdown` from ReplyNodes | 20,413 | 4,611 | 4,607 |

This is one page and one run. The raw HTML and the Markdown were fetched separately a few seconds apart. These are token counts of the text, not of any model's billing.
