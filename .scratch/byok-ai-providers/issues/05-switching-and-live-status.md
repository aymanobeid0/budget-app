# 05: Several Keys, Switching, and Live Status

**What to build:** Each provider keeps its own key, and the provider screen lets the user Set active. Switching mid-conversation keeps the chat and adds "Now answering with <Provider> · <model>". Real chat calls update the active key's status: a reply sets Connected, and a 401/402/429 sets the matching failure, which the Consultant also shows with a link to Settings.

**Blocked by:** 01

**Status:** resolved

- [x] Set active per provider; Settings row subtitle follows it
- [x] Switch marker line in the chat thread
- [x] Chat outcomes written back to status
- [x] Store and Consultant tests for switching and status changes

## Answer

`AiProviderStore.setActive` switches the provider the Consultant answers with; every saved key stays. The editor sheet shows Set active for a saved provider that isn't active, and the Settings row follows the active one. The store's `consultantClient` writes each chat's outcome back to that provider's status: the first reply chunk sets Connected, and a refusal (401/403, 402/429, 404, other errors) sets the matching failure. Can't reach provider leaves the status alone, since being offline says nothing about the key. The store publishes every change on `changes`, and `AiProviderCubit` listens to it, so Settings updates while open. `ConsultantClient.answeredBy` ("Google Gemini · gemini-2.5-flash") lets `ConsultantCubit` add a marker `ChatMessage` (`isMarker`, never sent to the provider) reading "Now answering with <Provider> · <model>" when the provider changed since the last message. A chat failure shows the outcome and the provider's message in the error banner, with a Settings link to `/ai-provider`. Tests: `ai_provider_store_test.dart` (the spec's list, with `FakeProviderAdapter`), `ai_provider_cubit_test.dart`, `ai_provider_screen_test.dart` (Set active), and new Consultant cubit and widget cases.
