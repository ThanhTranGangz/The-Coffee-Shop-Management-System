Project: "Coffee Shop Management System — Lite". Java Servlet/JSP web app (no Maven, no framework, no npm). NetBeans/Ant project, deployed as WAR to Tomcat.

## Active system vs legacy dead code
Only ONE servlet is wired in `web/WEB-INF/web.xml`: `LiteApiServlet` mapped to `/api/*`. `SecurityFilter` (`@WebFilter("/*")`) also runs on every request via annotation (not web.xml). These two plus `LiteService` (business logic singleton) are the entire live backend.

Everything under `src/java/dao/*`, `src/java/model/*` (old set: InventoryDAO, MemberDAO, MenuDAO, OrderDAO, ShiftDAO, StaffDAO, TableDAO, VoucherDAO, Expense, HistoricalReport, Ingredient, Member, Voucher, etc.), plus `AuthServlet`, `BrewApiServlet`, `BrewStateService`, `BrewWebSocketEndpoint/Handler` are **dead legacy code** from an earlier, more elaborate version of this app. They are not referenced by web.xml, not annotated with `@WebServlet`, and nothing in `web/` calls them. Do not spend time reading/fixing them unless explicitly asked to revive that functionality — the live app is the "Lite" one.

## Request flow (live system)
Browser JSP -> page-specific JS (`fetch` via `api()` helper in `i18n.js`) -> `LiteApiServlet` (`doGet`/`doPost`, dispatches on `req.getPathInfo()`) -> `LiteService` (singleton, all business logic + raw JDBC) -> SQL Server (`CoffeeShopLite` DB, auto-created on first connection by `DBContext`).

## Deep references
- `mem:backend` — LiteApiServlet/LiteService/SecurityFilter/DBContext internals, order status state machine, transactions/locking.
- `mem:frontend` — JSP/JS pairing, i18n, per-page JS responsibilities, debugging-by-symptom table.
- `mem:tech_stack`, `mem:suggested_commands`, `mem:task_completion`, `mem:conventions`.

## Pre-existing docs (read these before re-deriving — they are current and detailed)
- `README.md` — scope, demo accounts, DB defaults.
- `docs/preview/README.md` — Vietnamese overview: architecture, roles, order lifecycle, DB tables, demo walkthrough.
- `docs/preview/09-code-backend.md`, `10-code-frontend.md`, `11-code-workflows.md` — line-by-line backend/frontend/workflow explanations, written for the live "Lite" system only.
- `docs/preview/01..08` — per-role feature walkthroughs (admin, guest, barista, waiter, cashier, table transfer, counter order, QR).
- `HUONG_DAN_TRUY_CAP.md` — access/demo instructions, but paths inside are **stale/Mac-specific** (`/Users/mtsmvp/...`, `brew services ...`); this repo is being worked on from Windows now — treat those paths as historical, not current.

Order status state machine, DB schema, role/PIN table, and full API surface are documented in `mem:backend` and the docs above — do not re-derive from scratch each session.
