# Activepieces: any public URL to clean Markdown (no API key)

[`url-to-markdown.flow.json`](url-to-markdown.flow.json) is one importable Activepieces flow built only from built-in pieces (Webhook, Data Mapper, HTTP, Delay, Router and Return Response). It turns a public page URL into clean Markdown that you can feed into your own next step. It needs no credential, no API key, no connection, and no custom piece, plugin or package.

This is a community example. It is not an official Activepieces template, a marketplace listing, or a verified integration.

## Use it

1. In Activepieces open **Automations**, choose **Import**, and select `url-to-markdown.flow.json`.
2. Open the flow and select **Publish**.
3. Copy the **Live URL** from the Webhook trigger and send it a URL:

   ```sh
   curl -X POST "<LIVE_URL>" \
     -H 'content-type: application/json' \
     -d '{"url":"https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=demo"}'
   ```

4. Open **Runs**, select the run, and select the **Output: markdown + source_url** step. Its output has `markdown` and `source_url`. Add your own steps after it.

The flow is `Webhook -> Input URL (Data Mapper) -> ReplyNodes Markdown (HTTP GET) -> Route attempt 1 (Router)`. The Router sends a 2xx response to **Output: markdown + source_url**, a 400, 429 or 451 to a named **Stop** branch, a retryable 5xx to a short **Wait** and a second HTTP attempt (then a third), and everything else to a **Stop: other error** branch.

To get a response back to the caller, append `/sync` to the Live URL. Only the Stop branches return a response in the export (the error status and a JSON body). A successful run returns `204` with no body, after the sync wait of up to about 30 seconds, so read the result from the Output step, or add your own **Return Response** step after it.

## The request

`GET https://md.replynodes.com/{full page URL}` with `Accept: application/json`. For example `https://md.replynodes.com/https://example.com/docs/page?x=1`. The complete URL goes after the host: do not split it into domain and path and do not URL-encode it. The path and query string are preserved. The Markdown is in `data.markdown` of the `{data, meta}` response. `source_url` is `data.url`, which is the page after redirects and may omit your query string (the MDN example below does).

The flow sends no `Authorization` header and no other custom header, and it stores no secret.

## Limits

- Keyless use is limited to **100 requests per day**, one page per request.
- The quota is keyed by the client IP bucket and UTC day. Everyone behind the same egress IP (an office, a VPN, a shared Activepieces host) shares the same 100 per day.
- This keyless endpoint is not documented to render JavaScript or get past bot challenges, and this example does not claim either.
- The webhook trigger has no authentication (`authType: none`). Anyone who has its Live URL can trigger runs and spend your IP bucket's quota, so keep the URL private.
- Treat the returned Markdown as untrusted content.

## Errors

The HTTP step uses the piece's **On Failure** option set to **Continue flow on all errors** (`continue_all`), so a 4xx or 5xx response continues the flow with `status` and `body` and a Router chooses the branch. Retries are built from the same built-in pieces: at most **3 HTTP attempts**, with a 2-second Delay piece before attempts 2 and 3.

The live service's error body is `{"error":{"code","message","request_id","retryable","reason"?}}`. This was observed on a real 400. The retry gate reads `error.retryable` (not a top-level `retryable`). A retry happens only when the status is 500 to 599 **and** `error.retryable` is `true`. A missing or `false` `retryable` is never retried.

| Response | What the flow does | What you do |
| --- | --- | --- |
| 400 `invalid_request` | Branch **400: invalid URL (stop)** returns 400 and stops. No retry. | Use a full public `https://` page URL. |
| 429 `anonymous_limit_reached` | Branch **429: daily keyless limit (stop, no retry)** returns 429 and stops, on any attempt. No retry. The message says the quota resets at 00:00 UTC and links the free account with 500 credits. | Wait for 00:00 UTC, or [create a free account](https://platform.replynodes.com/sign-up). If you share an egress IP, other people's requests count against the same quota. |
| 451 | Branch **451: page excluded by publisher (stop)** returns 451 and stops. | Use a different page. |
| 502 `upstream_blocked`, 502 `upstream_unavailable` with `reason: empty_content` (`retryable: false`) | **Stop: other error** returns the upstream status and body. No retry, 1 request. | Use a different page. |
| 5xx with `retryable: true` | Waits 2 seconds and retries, up to 3 attempts in total. If one succeeds the Markdown reaches the Output step. After the third failure the status and body are returned by **Stop: attempts exhausted or other error**. | Try again later. |
| Any other status, or a 5xx without `retryable: true` | **Stop: other error** returns the upstream status and body. No retry. | Open the run's HTTP step. |

Limitations:

- On the continue path the HTTP piece returns the status and body only, not the response headers. The flow cannot show the exact `x-ratelimit-reset` value on a 429, so it states the reset as 00:00 UTC.
- The run itself ends **Succeeded** even when a Stop branch returned an error to the caller, because the error was handled. Read the status from the webhook response (`/sync`) or from the Router branch in the run.
- Attempts 2 and 3 repeat the HTTP, Router and Stop steps, so the flow is long. The step names say which attempt each belongs to.

## Evidence (2026-10-29)

Environment: Activepieces Community Edition **0.82.0**, **self-hosted**, official Docker image `activepieces/activepieces:latest` (digest `sha256:65ea85f5e7ea236416b342eef0d2dbade8da51247aaea495d191eb027095805a`), embedded PGLite database, in-memory queue, unsandboxed execution mode, local only. Built-in pieces: Webhook 0.1.43, Data Mapper 0.3.21, HTTP 0.11.19, Delay 0.3.34. Details are in [`evidence/`](evidence/).

**Clean import (verified, web UI).** A brand-new container with no flows. The committed `url-to-markdown.flow.json` was imported with the **Import** dialog, imported with all steps and named branches ([`ui-1-import-dialog.png`](evidence/ui-1-import-dialog.png), [`ui-2-flow-imported.png`](evidence/ui-2-flow-imported.png)), and published with the UI **Publish** button.

**REAL runs against the live service** ([`evidence/real-runs.json`](evidence/real-runs.json)), run sequentially in that instance:

- Site root `https://example.com/`: HTTP 200, title "Example Domain", `source_url` `https://example.com/`, 156 characters of non-empty Markdown in the Output step.
- Path and query `https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=activepieces-demo`: HTTP 200, title "Overview of HTTP - HTTP | MDN", 20,409 characters of Markdown in the Output step. The HTTP step requested `https://md.replynodes.com/https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=activepieces-demo`, so path and query are preserved. `source_url` was `https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview` (the page after redirects, without the query).
- Query preservation: `https://httpbin.org/anything/docs/page?x=1&y=two` was requested as `https://md.replynodes.com/https://httpbin.org/anything/docs/page?x=1&y=two`. The returned Markdown echoes `args` `x=1, y=two`.
- A real 400: input `not-a-url` returned 400 `invalid_request` with `retryable: false`. The flow took the 400 branch, made one request, and returned its own 400.

**SIMULATED (mock), not observed on the live service** ([`evidence/simulated-error-runs.json`](evidence/simulated-error-runs.json)). The same export, imported into the same instance with only the base URL changed to a local mock (a diff confirmed nothing else differs), run once per case:

| Mock case | Requests | Result |
| --- | --- | --- |
| 400 | 1 | 400 branch |
| 429 | 1 | 429 branch, UTC-midnight guidance, no retry |
| 451 | 1 | 451 branch |
| 502 `upstream_blocked`, `retryable: false` | 1 | pass-through, no retry |
| 502 `upstream_unavailable`, `reason: empty_content`, `retryable: false` | 1 | pass-through, no retry |
| 503 `retryable: true`, then 200 | 2 | Output step |
| 503 `retryable: true` twice, then 200 | 3 | Output step |
| 503 `retryable: true` every time | 3 | 503 returned after exhausting 3 attempts |
| 502 `retryable: true` every time | 3 | 502 returned after exhausting 3 attempts |
| 503 with no `retryable` field | 1 | pass-through, no retry |
| 503 `retryable: true`, then 429 | 2 | 429 branch, no further retry |
| 403 | 1 | pass-through |

Every mock request carried `Accept: application/json` and no `Authorization` header. The mock's error code names for 451 and 5xx are illustrative. The live service was not made to return 429, 451, 502 or 5xx.

**Screen capture.** [`evidence/activepieces-ui-run-capture.mp4`](evidence/activepieces-ui-run-capture.mp4) is an unedited recording of the web UI on that instance: a webhook run of the path-and-query URL above, the run opened from **Runs**, and the Output step with `markdown` and `source_url` ([`ui-3-run-output-step.png`](evidence/ui-3-run-output-step.png) is a frame from the same take). It is a plain screen recording of the browser; it was not trimmed, sped up or masked, and the browser window shows a local `127.0.0.1` address.

**Not verified:** Activepieces Cloud, versions other than 0.82.0, sandboxed execution mode, a live 429, 451, 502 or 5xx, and whether the Activepieces community forum accepts this as a template (the description is 169 letters, inside the 50 to 250 range). No token comparison is made.

## Notes for fresh self-hosted installs

A new self-hosted instance downloads built-in piece metadata from the Activepieces registry in the background. Until that finishes (minutes on a slow link), importing or publishing a flow can fail with "piece not found" errors. Restarting the container once loads the metadata that has already arrived.
