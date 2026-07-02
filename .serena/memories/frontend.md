Full walkthrough already exists at `docs/preview/10-code-frontend.md` (Vietnamese, includes a JSP<->JS<->API mapping table for all 13 pages and a symptom->file debugging table) — read it for details; this memory holds only the load-bearing facts.

- Structure: JSP files (`web/*.jsp`) hold only static layout + element `id`s; all logic lives in one paired JS file per page under `web/assets/js/page-*.js`. Example: `menu.jsp` <-> `page-menu.js`.
- `web/assets/js/i18n.js` is the shared file for every page: translation dict + `t(key)`, the `api(path, options)` fetch wrapper (prefixes `/api`, sends `credentials: 'same-origin'` for session cookies), `money()`/`statusText()` formatters, role-based nav rendering, logout flow, toast/modal helpers.
- No framework/bundler — rendering is `element.innerHTML = \`...\`` template strings; always escape untrusted data via `escapeHtml`/`escapeAttr`/`escapeJs` (defined per-page-JS-file) when interpolating.
- Language toggle re-renders dynamic content by calling `window.renderPage()` (each page must define this) — changing only static HTML text does not update JS-rendered content.
- Staff "hold to confirm" UX pattern: status-changing actions (order status advance, table clear) require a 0.5s press-and-hold (`beginHold()` + `setTimeout`) before firing the POST — intentional anti-mis-tap design for phone use in a busy shop; don't "simplify" this to a plain click without checking with the user.
- Cashier logout has a side effect: before `/api/auth/logout`, it fetches `/api/cash/status`, prompts for counted cash, and POSTs `/api/cash/count` — only after that does the actual logout call fire.
- Guest-facing order status timeline collapses `Paid`/`Cleared` display down to "Served" — guests never see post-payment internal states.
