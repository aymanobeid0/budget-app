# 01: Choose your Currency

**Status:** resolved
**Blocked by:** none

The Currency row in Settings opens a picker (MRU, USD, EUR, EGP, SAR). The choice is remembered across launches and every amount label in the app uses it: Home, Income, the Add sheet, Net card, Categories, Settings. The Expense Consultant's context and system prompt use the chosen Currency instead of telling Gemini to write "$25.00".

- [x] Picking a Currency in Settings updates every amount label immediately
- [x] The choice survives a restart; first launch shows MRU
- [x] Consultant prompt and spending context name the chosen Currency
- [x] `Money.currencyLabel` TODO(issue-06) is gone
