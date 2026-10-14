# 04: Supabase Cloud Sync & Anonymous Auth Slice

**What to build:** Seamless cloud synchronization with the local Supabase Docker instance. Automatically authenticates the user as an anonymous guest on first launch, mirrors local SQLite expense and category entries to the Docker Supabase PostgreSQL tables, and handles background synchronization when network connectivity changes.

**Blocked by:** 03: Expense Logging & Instant Add Slice

**Status:** resolved

- [x] App signs in anonymously via Supabase Auth on the local Docker container without blocking user interaction
- [x] New and updated local expenses sync to the local Supabase Docker container
- [x] Offline writes queue in SQLite and sync automatically upon network reconnection
- [x] Remote data is protected by user-scoped Row-Level Security (RLS) policies in PostgreSQL

