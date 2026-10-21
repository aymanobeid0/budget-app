# 02: OpenAI and Groq

**What to build:** OpenAI and Groq show up on the provider screen and work end to end: test, model list, save with ping, chat. Both go through one `OpenAiCompatibleAdapter` with a base URL and a per-provider chat-model filter (OpenAI: `gpt-*`/`o*` minus audio, realtime, image, transcribe, tts and search; Groq: minus whisper and guard).

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `OpenAiCompatibleAdapter` for `/models` and streaming `/chat/completions`, Bearer auth
- [ ] OpenAI and Groq entries with default models
- [ ] Adapter tests: filtering, SSE `data: [DONE]`, error mapping
