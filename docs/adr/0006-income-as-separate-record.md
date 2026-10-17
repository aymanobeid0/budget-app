# Income as a Separate Record, Not Signed Transactions

We added Income as its own record (amount, paid-on date, Income Source) rather than letting Expenses carry negative or signed amounts. This keeps the Expense model from ADR 0002 untouched and avoids drifting into the transaction/double-entry model ADR 0001 rejected. Income is grouped by Income Sources, not expense Categories, and every amount is typed by the user on the day it was paid: there is no recurring automation, no fixed/dynamic distinction, and no percentage calculation, so the "no recurring" stance of ADR 0002 still holds.
