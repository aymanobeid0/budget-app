# 02: OpenAI and Groq

**What to build:** OpenAI and Groq show up on the provider screen and work end to end: test, model list, save with ping, chat. Both go through one `OpenAiCompatibleAdapter` with a base URL and a per-provider chat-model filter (OpenAI: `gpt-*`/`o*` minus audio, realtime, image, transcribe, tts and search; Groq: minus whisper and guard).

**Blocked by:** 01

**Status:** resolved

- [x] `OpenAiCompatibleAdapter` for `/models` and streaming `/chat/completions`, Bearer auth
- [x] OpenAI and Groq entries with default models
- [x] Adapter tests: filtering, SSE `data: [DONE]`, error mapping

## Answer

`OpenAiCompatibleAdapter` (`data/open_ai_compatible_adapter.dart`) has two named constructors, `.openAi` (`api.openai.com/v1`) and `.groq` (`api.groq.com/openai/v1`). Each one carries its base URL and its chat-model filter. It lists `/models`, pings with `max_completion_tokens: 1`, and streams `/chat/completions` until `data: [DONE]`, reusing the shared `providerRequest`/`providerStream` helpers. An error code of `model_not_found` or `model_decommissioned` maps to Model not found, because Groq answers a retired model with 400. `AiProviderKind` gains `openAi` (default `gpt-4.1-mini`) and `groq` (default `llama-3.1-8b-instant`), and `main.dart` registers both. The provider screen and editor were already generic, so nothing changed in the UI. The filters also drop `instruct`, `-pro`, `deep-research` (OpenAI) and `tts` (Groq), which can't chat over `/chat/completions`. A reasoning model that reports running out of its one ping token still passes the Save check (spec amended).
