# Bring-Your-Own-Key AI Providers

**Status:** ready-for-agent

## Problem Statement

The Expense Consultant only works when the developer builds the app with a Gemini key in `.env`. Anyone else who installs the app gets "The Consultant is off" and no way to turn it on. A key baked into the app is also a shared secret that can be pulled out of the binary, and every chat runs on the developer's bill.

## Solution

In Settings, an "AI provider" row opens a screen listing five AI Providers: Google Gemini, OpenAI, Anthropic Claude, Groq and OpenRouter. The user pastes their own API key for one of them and taps Test. The app lists the provider's chat models (proving the key works) and preselects a cheap default; for OpenRouter the user types a model id instead. Save pings the chosen model with a one-token request and shows one of six plain outcomes. Keys stay on the phone in the OS secure store. The user can save a key per provider and pick which one is active, and the Consultant answers with the active one.

## User Stories

1. As a user, I want to pick an AI Provider from Gemini, OpenAI, Anthropic Claude, Groq and OpenRouter, so that I can use the account I already have.
2. As a user, I want to paste my API key and tap Test, so that I know straight away whether it works.
3. As a user, I want a clear outcome when I test: Connected, Key not accepted, No credit or rate-limited, Model not found, Can't reach provider, or Provider error, with the provider's own message underneath, so that I know what to fix.
4. As a user, I want to choose a model from the provider's chat models with a sensible cheap default preselected, so that I don't have to know model names.
5. As an OpenRouter user, I want to type the model id I want, so that I can use any of its models.
6. As a user, I want Save to check that the chosen model actually answers, so that I find out about missing credit before I start chatting.
7. As a user, I want to save a key even when I'm offline or the check fails, after confirming, so that a bad moment doesn't stop me setting up.
8. As a user, I want each saved key to show its status (Connected, Not verified, or the last failure), so that Settings tells me the truth.
9. As a user, I want the status to update when a chat succeeds or fails, so that a key saved offline becomes Connected once it works.
10. As a user, I want to save keys for several providers and choose which one is active, so that I can switch without re-pasting.
11. As a user, I want my key shown masked (••••a1b2) after saving and never in full, so that someone glancing at my phone can't read it.
12. As a user, I want to remove a provider's key, so that I can stop using it.
13. As a user, I want my keys kept only on this phone in its secure store, never synced, so that my paid key doesn't sit in the cloud.
14. As a user, I want my keys to stay when I switch accounts, so that I don't have to set them up again.
15. As a user, I want to be told that my Expense and Income summary goes to the provider under my own account when I chat, so that I know where my data goes.
16. As a user, I want switching provider mid-conversation to keep my chat, with a line saying which provider and model now answer, so that I don't lose context.
17. As a user with no key saved, I want the Consultant screen to point me to Settings, so that I know how to turn it on.
18. As a web user, I want to be told the Consultant is available in the mobile and desktop apps, so that I'm not asked to store a key in the browser.

## Implementation Decisions

- **BYOK only.** Remove `GEMINI_API_KEY` from `.env.example` and `AppConfig`. ADR 0009 records why.
- **New slice `lib/features/ai_provider/`** (ADR 0004) with one deep module, **`AiProviderStore`**. It saves and removes keys, sets the active provider, reports each provider's status and chosen model, tests a key (list models), pings and saves, and hands the consultant slice a ready `ConsultantClient` for the active provider. Chat outcomes flow back into the status.
- **Storage.** Keys go behind a `SecretStore` interface: `flutter_secure_storage` on the device, an in-memory fake in tests. Non-secret data (active provider, model per provider, status) is one JSON `TextPref` file (`ai_provider.json`, `lib/core/prefs/text_pref.dart`). No SQLite or Supabase change. `AccountService` doesn't touch keys.
- **Transport.** `package:http` for all providers, with one SSE line parser and one shared status-code-to-outcome mapping. Drop `google_generative_ai`.
- **Adapters** behind one `ProviderAdapter` interface (list models, ping, stream):
  - Gemini: `generativelanguage.googleapis.com/v1beta`, header `x-goog-api-key`. List keeps models whose `supportedGenerationMethods` include `generateContent`. Stream uses `:streamGenerateContent?alt=sse`.
  - OpenAI-compatible (OpenAI `api.openai.com/v1`, Groq `api.groq.com/openai/v1`, OpenRouter `openrouter.ai/api/v1`): Bearer auth, `/models`, `/chat/completions` with `stream: true`. Each provider filters to chat models (OpenAI: `gpt-*`/`o*` minus audio, realtime, image, transcribe, tts, search, instruct, `-pro` and deep-research, which can't use `/chat/completions`; Groq: minus whisper, guard and tts). A reasoning model that answers the one-token ping with "max_tokens or model output limit was reached" counts as passed: it proved the key, model and credit.
  - OpenRouter tests with `GET /key` (its `/models` is public), then checks that the typed id is in `/models`.
  - Anthropic: `api.anthropic.com/v1`, headers `x-api-key` and `anthropic-version: 2023-06-01`, `/models` and `/messages` streaming.
- **Outcomes**: 401/403 → Key not accepted; 402/429 → No credit or rate-limited; 404 or unknown model → Model not found; socket error or 15s timeout → Can't reach provider; anything else → Provider error. The raw provider message is kept for display.
- **Status**: Connected, Not verified (saved without a test, or the test couldn't reach the provider) or Failed with an outcome. Set by Test, Save and every chat call.
- **Settings**: an "AI provider" `MenuRow` (subtitle: provider, model, status) opens `/ai-provider`, which follows the Categories screen pattern. The row is hidden on web.
- **Consultant**: keeps `ConsultantClient` and `consultantSystemInstruction`. The empty state becomes "Connect an AI provider in Settings" with a button. Switching provider adds a marker line to the thread.

## Testing Decisions

- Adapters: `http`'s `MockClient` (a fake HTTP client, no mocking library) covering model filtering, SSE parsing, request shape and status-code mapping per provider.
- `AiProviderStore`: in-memory `SecretStore` and `TextPref`. Covers test then save, untested save, ping failure then save anyway, switching active, removing a key, a chat 401 flipping status, and a chat success setting Connected.
- Cubit tests with `bloc_test`. Widget tests for the Settings row, the provider screen and editor states, and the Consultant empty state.

## Out of Scope

- A built-in or shared key, or any server-side proxy.
- Syncing keys across devices.
- Web support for the Consultant.
- Local models (Ollama and similar) or providers beyond these five.
- Token or cost tracking.
