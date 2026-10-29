# Activepieces: any public URL to clean Markdown (no API key)

[`url-to-markdown.flow.json`](url-to-markdown.flow.json) is one importable Activepieces flow built only from built-in pieces (Webhook, Data Mapper, HTTP, Router and Return Response). It turns a public page URL into clean Markdown that you can feed into your own next step. It needs no credential, no API key, no connection, and no custom piece, plugin or package.

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

The flow is `Webhook -> Input URL (Data Mapper) -> ReplyNodes Markdown (HTTP GET) -> Route response (Router)`. The Router sends a 2xx response to **Output: markdown + source_url** and every other outcome to a clearly named **Stop** branch.

To get a response back to the caller, append `/sync` to the Live URL. Only the Stop branches return a response in the export (the error status and a short JSON message). A successful run returns `204` with no body, so read the result from the Output step, or add your own **Return Response** step after it.

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

The HTTP step uses the piece's own **On Failure** option set to **Continue flow on 4xx errors**. With it, a 4xx response continues the flow so the Router can branch on the status. A 5xx response or a network error is retried by the piece, at most 3 attempts in total, and then fails the HTTP step.

| Response | What the flow does | What you do |
| --- | --- | --- |
| 400 `invalid_request` | Branch **400: invalid URL (stop)** returns 400 and stops. No retry. | Use a full public `https://` page URL. |
| 429 `anonymous_limit_reached` | Branch **429: daily keyless limit (stop, no retry)** returns 429 and stops. No retry loop. The message says the quota resets at the next UTC midnight and links the free account with 500 credits. | Wait for the reset, or [create a free account](https://platform.replynodes.com/sign-up). If you share an egress IP, other people's requests count against the same quota. |
| 451 | Branch **451: page excluded by publisher (stop)** returns 451 and stops. | Use a different page. |
| Any other 4xx | Branch **Other error (stop)** returns 502 and stops. | Open the run's HTTP step to see the status and body. |
| 5xx (including 502 `upstream_blocked` and 502 `upstream_unavailable`) | The HTTP piece makes up to 3 attempts, then the HTTP step fails and the run is marked **Failed**. The error body is visible on the failed step. | Try another page or try again later. |

Limitations of error handling in this flow, caused by what the built-in HTTP piece exposes:

- The piece does not read the `retryable` field, so it retries every 5xx, including 502 `upstream_blocked` and `upstream_unavailable` with `reason: empty_content`, which the contract says are not worth retrying. A blocked page therefore costs 3 requests. There is no delay between attempts.
- On the continue path the piece returns only the status and body, not the response headers. The flow therefore cannot show the exact `x-ratelimit-reset` value on a 429. It states the UTC-midnight reset instead.
- 5xx and 502 failures end the run as **Failed** instead of being routed to a branch.

## Evidence (2026-10-29)

Environment: Activepieces Community Edition **0.82.0**, self-hosted, official Docker image `activepieces/activepieces:latest` (digest `sha256:65ea85f5e7ea236416b342eef0d2dbade8da51247aaea495d191eb027095805a`), embedded PGLite database, in-memory queue, unsandboxed execution mode, local only. Built-in piece versions: Webhook 0.1.43, Data Mapper 0.3.21, HTTP 0.11.19. Details are in [`evidence/`](evidence/).

**Verified, real requests to the live service** ([`evidence/real-runs.json`](evidence/real-runs.json)). Each was run in a throwaway container that had no flows when it started, by importing the exported file through the web UI, publishing it, and posting to its webhook. That was the second UI import in that container (the first import there was deleted after a publish race). The file imported then had the same flow content as the committed one, without the `blogUrl` link:

- Site root `https://example.com/`: HTTP 200, title "Example Domain", `source_url` `https://example.com/`, and `markdown` reached the Output step.
- `https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview?utm_source=activepieces-demo`: HTTP 200, title "Overview of HTTP - HTTP | MDN", heading `# Overview of HTTP`, 20,409 characters of Markdown in the Output step. `source_url` was `https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview`.
- Query preservation: `https://httpbin.org/anything/docs/page?x=1&y=two` returned 200 and the fetched page echoed `args` `x=1, y=two`.
- A real 400: input `not-a-url` returned 400 `invalid_request` from the live service. The flow took the 400 branch and returned its own 400 JSON.
- Four of these runs were fired at the same moment. The root-URL run finished all its steps but its run record stayed `RUNNING`. A sequential re-run of the root URL ended `SUCCEEDED`.

**Simulated, not observed on the live service** ([`evidence/simulated-error-runs.json`](evidence/simulated-error-runs.json)). A copy of the export with only the base URL changed to a local mock server returned 429, 451, 403, two 502 variants, an always-503 and a 503, 503, 200 sequence. Results: 429, 451 and 403 were routed to their branches after one request each. Each 502 and the always-503 made 3 requests and then failed the HTTP step. The 503, 503, 200 sequence made 3 requests and produced output. The mock's error code names for 451 and 502 are illustrative. The live service was not made to return 429, 451, 502 or 5xx.

**Import.** The exported file was imported through the Activepieces web UI (**Import** dialog), and the flow appeared with all steps and branches and published ([`ui-rehearsal-*` screenshots](evidence/)). The final committed bytes (which add only the guide link in `blogUrl` after that UI import) were imported through the same `IMPORT_FLOW` operation the UI uses, validated, published, and the imported step tree was checked equal to the file. They were not re-imported through the UI dialog.

**Screen capture.** [`evidence/activepieces-ui-run-capture.mp4`](evidence/activepieces-ui-run-capture.mp4) is a real recording of the UI: the imported flow, its steps and branches, a run that succeeded, and the output of the 400 branch. It was edited: trimmed to start after sign-in, sped up 1.75x (about 82 seconds), and a rectangle was masked over a browser password-manager prompt (the grey box). It does not expand the HTTP step or the Markdown output, and a browser banner about a `--no-sandbox` flag is visible. The five `ui-rehearsal-*` screenshots are real captures from an earlier fresh container during rehearsal, not from the final take.

**Not verified:** Activepieces Cloud, versions other than 0.82.0, sandboxed execution mode, a live 429, 451 or 502, and whether the Activepieces community forum accepts this as a template (the description is 169 letters, inside the 50 to 250 range). No token comparison is made.

## Notes for fresh self-hosted installs

A new self-hosted instance downloads built-in piece metadata from the Activepieces registry in the background. Until that finishes (minutes on a slow link), importing or publishing a flow can fail with "piece not found" errors. Restarting the container once loads the metadata that has already arrived.
