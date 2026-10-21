# 05: Several Keys, Switching, and Live Status

**What to build:** Each provider keeps its own key, and the provider screen lets the user Set active. Switching mid-conversation keeps the chat and adds "Now answering with <Provider> · <model>". Real chat calls update the active key's status: a reply sets Connected, and a 401/402/429 sets the matching failure, which the Consultant also shows with a link to Settings.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Set active per provider; Settings row subtitle follows it
- [ ] Switch marker line in the chat thread
- [ ] Chat outcomes written back to status
- [ ] Store and Consultant tests for switching and status changes
