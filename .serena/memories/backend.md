Full narrative walkthrough already exists at `docs/preview/09-code-backend.md` (Vietnamese) — read it for details; this memory only holds the load-bearing facts an agent needs before touching backend code.

- Reading order for backend: `web/WEB-INF/web.xml` -> `DBContext` -> `SecurityFilter` -> `LiteApiServlet` -> `LiteService` -> `JsonUtils`.
- `LiteApiServlet` dispatches purely on `req.getPathInfo()` via `switch` in `doGet`/`doPost` — e.g. `/api/orders` arrives as pathInfo `/orders`. No routing framework.
- `SecurityFilter` (`@WebFilter("/*")`) groups pages/APIs by role (admin/barista/cashier/runner/public) and enforces both page access and API access server-side (`isPublicApi`, `isAllowedApi`) — see `mem:conventions` for the two-layer access model.
- Order status transitions enforced in `LiteApiServlet.canSetStatus` — see `mem:conventions` for the exact state machine.
- `LiteService.init()` auto-creates schema (`Users, Tables, MenuItems, MenuItemSizes, Orders, OrderItems, CashEvents, StoreState, SystemLogs`) and seeds demo data (users, 2-floor tables w/ QR codes, sample menu, ~1yr of fake sales history, a few open demo orders) on first run — this only runs once per DB; re-seeding requires dropping `CoffeeShopLite`.
- Cup inventory: `cupCountForOrder` sums `OrderItems.quantity` for drink-category items only (not food) when an order moves `Preparing -> Ready`; insufficient `StoreState` cup count blocks the transition.
- QR generation: `zxing` `QRCodeWriter` produces a `BitMatrix` only — `LiteApiServlet.qrSvg()` manually walks the matrix to build an SVG string. To change QR visual styling, edit `qrSvg()`, not the DB.
- Dashboard revenue figures only count orders in `Paid`/`Cleared` status.
