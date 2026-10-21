# 01: Connect Your Own Gemini Key

**What to build:** The tracer bullet. Settings gets an "AI provider" row that opens a provider screen. There the user pastes a Google Gemini key, taps Test (list models, filtered to chat models, cheap default preselected), picks a model and Saves (one-token ping). The Consultant then answers with that key and model. The built-in `GEMINI_API_KEY` goes away, so with no key saved the Consultant points to Settings. Gemini is called over plain `http` with an SSE parser, and `google_generative_ai` is removed.

**Blocked by:** none

**Status:** ready-for-agent

- [ ] `lib/features/ai_provider/` slice: `AiProviderKind`, `ConnectionOutcome` (6 outcomes), `ProviderStatus`, `ProviderAdapter`, `GeminiAdapter`, shared SSE parser and status-code mapping
- [ ] `AiProviderStore` with `SecretStore` (secure storage on device, in-memory in tests) and a JSON `TextPref` for active provider, model and status
- [ ] Settings "AI provider" row (hidden on web) → `/ai-provider` screen with key field, Test, model picker, Save, Remove key, masked key and privacy notice
- [ ] Save allowed untested or after a failed ping, with a "Save anyway" confirmation; status shows Connected, Not verified or the failure
- [ ] Consultant uses the store's client; empty state says "Connect an AI provider in Settings" (or the web message on web)
- [ ] `GEMINI_API_KEY` removed from `AppConfig` and `.env.example`; `google_generative_ai` removed from `pubspec.yaml`
- [ ] Tests: Gemini adapter with `MockClient`, store, cubit, Settings row, editor, Consultant empty state
