No linter, formatter, or automated test suite is configured in this repo.
Practical "done" bar for a change:
1. Code compiles — run `ant dist` (or trigger a NetBeans build) and confirm no javac errors, especially around the manually-vendored jars in `lib/` (see `mem:tech_stack`).
2. For backend (`LiteApiServlet`/`LiteService`) changes: manually trace the request against `docs/preview/09-code-backend.md` to confirm the case in `doGet`/`doPost` and any `canSetStatus` transition rules still hold — there is no test to catch a broken order-status transition.
3. For frontend changes: verify the JSP element `id`s referenced by the paired JS file still match (see `mem:frontend` debugging table) — a mismatch fails silently (blank UI, no console error).
4. If DB schema/seed changed in `LiteService.init()/seed()`, note that `CoffeeShopLite` DB persists across runs — a fresh schema/seed change won't take effect against an already-created DB without manually dropping it or bumping schema logic.
