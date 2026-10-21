# 03: Anthropic Claude

**What to build:** Anthropic Claude works end to end through an `AnthropicAdapter`. It uses `x-api-key` and `anthropic-version: 2023-06-01` headers, `/v1/models` and streaming `/v1/messages` (`content_block_delta` events), with the system prompt in the top-level `system` field.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `AnthropicAdapter`, list, ping and stream
- [ ] Default model preselected
- [ ] Adapter tests: request shape, SSE events, error mapping (including 529 overloaded → Provider error)
