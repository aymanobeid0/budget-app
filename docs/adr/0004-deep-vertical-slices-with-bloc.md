# Deep Vertical Feature Slices with Bloc State Management

We decided to structure the Flutter codebase into deep vertical feature slices (`features/expenses/`, `features/categories/`, `features/consultant/`) rather than horizontal Clean Architecture layers. Each feature colocates its UI widgets, models, and deep module interface (`ExpenseLedger`, `CategoryStore`, `ExpenseConsultant`). Bloc/Cubit connects UI to deep modules, cross-feature dependencies are injected directly at module constructors, and `core/` is kept strictly lean (theme, clients, routing).
