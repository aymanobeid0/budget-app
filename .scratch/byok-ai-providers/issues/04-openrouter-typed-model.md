# 04: OpenRouter with a Typed Model Id

**What to build:** OpenRouter works end to end. The editor shows a model id text field instead of a picker. Test checks the key with `GET /key`, then checks that the typed id is in the public `/models` list (Model not found otherwise). Chat reuses `OpenAiCompatibleAdapter`.

**Blocked by:** 02

**Status:** resolved

- [x] OpenRouter entry, model id field with a suggested default
- [x] Key check and model lookup
- [x] Tests: valid key with unknown model → Model not found

## Answer

`OpenRouterAdapter` (in `data/open_ai_compatible_adapter.dart`) extends `OpenAiCompatibleAdapter` with base URL `openrouter.ai/api/v1`, so ping and streaming chat are reused unchanged. Its `listModels` first calls `GET /key`, because the public `/models` proves nothing about the key. Its `testModel` then looks the typed id up in `/models` and throws Model not found, naming the id, when it is missing. `ProviderAdapter` is unchanged: a new `TypedModelAdapter` interface beside it adds `testModel`, so the other adapters need nothing new. `AiProviderKind.openRouter` (suggested model `openai/gpt-4.1-mini`, key at `openrouter.ai/keys`) answers `typesModel`, which makes the editor show a "Model id" text field instead of the picker and makes Test call `AiProviderStore.testModel`. That records a saved key's status the way `listModels` does. Test and Save stay disabled while the model id is empty. `main.dart` registers the adapter.
