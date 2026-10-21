# 01: Connect Your Own Gemini Key

**What to build:** The tracer bullet. Settings gets an "AI provider" row that opens a provider screen. There the user pastes a Google Gemini key, taps Test (list models, filtered to chat models, cheap default preselected), picks a model and Saves (one-token ping). The Consultant then answers with that key and model. The built-in `GEMINI_API_KEY` goes away, so with no key saved the Consultant points to Settings. Gemini is called over plain `http` with an SSE parser, and `google_generative_ai` is removed.

**Blocked by:** none

**Status:** resolved

- [x] `lib/features/ai_provider/` slice: `AiProviderKind`, `ConnectionOutcome` (6 outcomes), `ProviderStatus`, `ProviderAdapter`, `GeminiAdapter`, shared SSE parser and status-code mapping
- [x] `AiProviderStore` with `SecretStore` (secure storage on device, in-memory in tests) and a JSON `TextPref` for active provider, model and status
- [x] Settings "AI provider" row (hidden on web) → `/ai-provider` screen with key field, Test, model picker, Save, Remove key, masked key and privacy notice
- [x] Save allowed untested or after a failed ping, with a "Save anyway" confirmation; status shows Connected, Not verified or the failure
- [x] Consultant uses the store's client; empty state says "Connect an AI provider in Settings" (or the web message on web)
- [x] `GEMINI_API_KEY` removed from `AppConfig` and `.env.example`; `google_generative_ai` removed from `pubspec.yaml`
- [x] Tests: Gemini adapter with `MockClient` (seam agreed with the user; store, cubit and UI left untested for now), Consultant empty state updated

## Answer

New slice `lib/features/ai_provider/`. `AiProviderStore` (`data/ai_provider_store.dart`) is the deep module: keys in `SecretStore` (`DeviceSecretStore` over `flutter_secure_storage`), active provider, model and status in `ai_provider.json` via `FileTextPref`. Its `consultantClient` always answers with the active provider. `GeminiAdapter` talks to `generativelanguage.googleapis.com/v1beta` over `package:http`, with the shared `providerRequest`/`providerStream` helpers (`provider_http.dart`, 15s timeout, status → `ConnectionOutcome`) and the SSE parser (`sse.dart`) that later adapters reuse. Gemini's 400 `API_KEY_INVALID` maps to Key not accepted. Settings has an "AI provider" row (hidden on web) opening `/ai-provider`; the editor sheet runs Test (list models, which also updates a saved key's status) and Save (one-token ping, then "Save anyway" on failure). `GEMINI_API_KEY` and `google_generative_ai` are gone. Only the adapter is tested, at the seam agreed for this ticket.
