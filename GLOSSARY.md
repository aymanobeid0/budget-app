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
A dedicated conversational chat assistant, powered by the user's AI Provider, that queries and analyzes logged expenses to answer user questions, highlight patterns, and provide tailored financial advice on demand.
_Avoid_: Financial advisor, notification bot, budget enforcer

**AI Provider**:
The service and model the user connects with their own API key to power the Expense Consultant (Google Gemini, OpenAI, Anthropic Claude, Groq or OpenRouter). One is active at a time; its key stays on the device.
_Avoid_: LLM, vendor, backend, AI service

**Currency**:
The global monetary unit and symbol configured by the user (e.g., USD $, EUR €, EGP E£) applied across all logged expenses.
_Avoid_: Exchange rate, multi-currency conversion

**Income**:
Money the user received, recorded on the day it was paid, with an amount and an Income Source. The amount is always the user's own share as they typed it.
_Avoid_: Transaction, credit, earning, revenue, salary entry

**Income Source**:
A user-managed label for where money comes from (e.g., Salary, Freelance, Dental clinic). Removing a source hides it from pickers but keeps its past Income.
_Avoid_: Category, account, employer, income type

**Net**:
Income minus Expenses over the calendar month Home shows: the current month so far, or a whole past month.
_Avoid_: Balance, savings, profit
