# Personal Expense Tracker

A streamlined, friction-free personal expense tracking application with an interactive AI chat consultant.

## Language

**Expense**:
A recorded monetary outflow containing an amount, date, and category.
_Avoid_: Transaction, debit, transfer, bill, recurring expense

**Category**:
A customizable classification label used to group expenses (e.g., Food, Transport, Utilities), with support for user-created custom categories.
_Avoid_: Budget, cap, envelope, limit

**Expense Ledger**:
The deep module interface responsible for logging, deleting, caching, and streaming expenses.
_Avoid_: Expense repository, expense service, expense DAO

**Expense Consultant**:
A dedicated conversational chat assistant powered by Google Gemini that queries and analyzes logged expenses to answer user questions, highlight patterns, and provide tailored financial advice on demand.
_Avoid_: Financial advisor, notification bot, budget enforcer

**Currency**:
The global monetary unit and symbol configured by the user (e.g., USD $, EUR €, EGP E£) applied across all logged expenses.
_Avoid_: Exchange rate, multi-currency conversion
