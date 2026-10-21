# 03: Anthropic Claude

**What to build:** Anthropic Claude works end to end through an `AnthropicAdapter`. It uses `x-api-key` and `anthropic-version: 2023-06-01` headers, `/v1/models` and streaming `/v1/messages` (`content_block_delta` events), with the system prompt in the top-level `system` field.

**Blocked by:** 01

**Status:** resolved

- [x] `AnthropicAdapter`, list, ping and stream
- [x] Default model preselected
- [x] Adapter tests: request shape, SSE events, error mapping (including 529 overloaded → Provider error)

## Answer

`AnthropicAdapter` (`data/anthropic_adapter.dart`) sends `x-api-key` and `anthropic-version: 2023-06-01` to `api.anthropic.com/v1`. It lists `/models?limit=1000` without a filter, because every Anthropic model can chat. It pings `/messages` with `max_tokens: 1`, and streams `/messages` with the system prompt in the top-level `system` field and `max_tokens: 8192`, yielding each `content_block_delta` `text_delta` until `message_stop`. It reuses `providerRequest`/`providerStream`: the shared SSE parser already skips `event:` lines, so the adapter dispatches on each payload's `type`. A mid-stream `error` event fails the stream after the text so far, with its error type standing in for the status (`overloaded_error` → 529 → Provider error, `rate_limit_error` → 429 → No credit or rate-limited). A 400 whose message mentions "credit balance" maps to No credit, because that is how Anthropic reports an empty balance. `AiProviderKind.anthropic` ("Anthropic Claude", default `claude-haiku-5-5`, key URL `console.anthropic.com/settings/keys`) sits after `openAi`, and `main.dart` registers it.
