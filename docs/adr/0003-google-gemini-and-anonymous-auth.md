# Google Gemini AI Consultant and Anonymous-First Supabase Auth

We chose Google Gemini as the LLM provider for the AI Expense Consultant due to its analytical strength, rapid response times, and cost efficiency. For authentication, users start immediately in an anonymous guest session in Supabase with zero onboarding friction, retaining the ability to link an email or Google account later for multi-device sync.

Superseded in part by [ADR 0009](0009-bring-your-own-key-ai-providers.md): the Consultant no longer ships with a Gemini key; the user connects an AI Provider of their choice.
