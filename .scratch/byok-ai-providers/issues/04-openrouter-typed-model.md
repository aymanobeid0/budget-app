# 04: OpenRouter with a Typed Model Id

**What to build:** OpenRouter works end to end. The editor shows a model id text field instead of a picker. Test checks the key with `GET /key`, then checks that the typed id is in the public `/models` list (Model not found otherwise). Chat reuses `OpenAiCompatibleAdapter`.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] OpenRouter entry, model id field with a suggested default
- [ ] Key check and model lookup
- [ ] Tests: valid key with unknown model → Model not found
