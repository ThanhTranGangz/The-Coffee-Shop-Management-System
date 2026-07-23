# -*- coding: utf-8 -*-
"""Re-capture SRS screenshots that were wrong or incomplete."""
import sys
import traceback
from pathlib import Path

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:9999/The-Coffee-Shop-Management-System-main"
OUT = Path(r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\srs_screenshots")
OUT.mkdir(parents=True, exist_ok=True)

PINS = {"barista": "1111", "cashier": "2222", "runner": "3333"}
DESKTOP = {"width": 1440, "height": 900}
MOBILE = {"width": 414, "height": 896}


def note(msg):
    print(msg.encode("ascii", "replace").decode("ascii"))


def api(p, tab):
    return p.request.new_context(extra_http_headers={"X-Tab-Session": tab})


def jget(ctx, path):
    r = ctx.get(BASE + "/api" + path)
    assert r.ok, f"GET {path}: {r.status} {r.text()[:200]}"
    return r.json()


def jpost(ctx, path, body):
    r = ctx.post(BASE + "/api" + path, data=body)
    assert r.ok, f"POST {path}: {r.status} {r.text()[:200]}"
    return r.json()


def login_api(ctx, role):
    jpost(ctx, "/auth/login", {"username": role, "password": PINS[role]})


def admin_api(ctx):
    jpost(ctx, "/auth/admin-pin", {"pin": "8888"})


def ui_login(page, role):
    page.goto(f"{BASE}/staff-login.jsp")
    page.wait_for_timeout(500)
    page.click(f".role-option[data-role='{role}']")
    page.fill("#pin", PINS[role])
    page.click("#login-form button[type=submit]")
    page.wait_for_load_state("networkidle")
    page.wait_for_timeout(800)


def shot(page, name, full=False):
    page.wait_for_timeout(700)
    page.screenshot(path=str(OUT / name), full_page=full)
    note(f"OK {name}")


def first_table_code(p):
    ctx = api(p, "tables")
    tables = [t for t in jget(ctx, "/tables") if t.get("active")]
    ctx.dispose()
    return tables[0]["code"], tables


def ensure_served_order(p, code):
    """Create a multi-item Served order for split/payment shots."""
    pub = api(p, "pub")
    menu = [m for m in jget(pub, "/menu") if m.get("active")]
    pub.dispose()
    g = api(p, "guest-seed")
    g.get(f"{BASE}/api/tables/by-code?code={code}")

    def item(i, qty=1):
        m = menu[i % len(menu)]
        size = (m.get("sizes") or [{}])[0].get("sizeName", "") if m.get("sizes") else ""
        return {"menuItemId": m["id"], "size": size or "", "quantity": qty}

    order = jpost(g, "/orders", {
        "tableName": "", "tableCode": code, "customerPhone": "",
        "note": "SRS capture", "items": [item(0, 2), item(1, 2), item(2, 1)],
    })
    g.dispose()
    bar = api(p, "bar")
    login_api(bar, "barista")
    jpost(bar, "/orders/status", {"id": order["id"], "status": "Preparing"})
    jpost(bar, "/orders/status", {"id": order["id"], "status": "Ready"})
    bar.dispose()
    run = api(p, "run")
    login_api(run, "runner")
    jpost(run, "/orders/status", {"id": order["id"], "status": "Served"})
    run.dispose()
    return order


def capture_guest(browser, code):
    ctx = browser.new_context(viewport=MOBILE, locale="vi-VN")
    page = ctx.new_page()
    try:
        page.goto(f"{BASE}/menu.jsp?tableCode={code}")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)
        shot(page, "02-menu-customer.png")

        # Fill cart through page globals (openSheet/addToCart/renderCart)
        page.evaluate(
            """() => {
                if (typeof menuItems === 'undefined' || !menuItems.length) return false;
                const act = menuItems.filter(m => m.active);
                cart = [];
                const a = act[0], b = act[1] || act[0];
                cart.push({menuItemId: a.id, size: (a.sizes||[])[0]?.sizeName||'', quantity: 1, note: 'Ít đá'});
                cart.push({menuItemId: b.id, size: (b.sizes||[])[0]?.sizeName||'', quantity: 2, note: ''});
                if (typeof renderCart === 'function') renderCart();
                return true;
            }"""
        )
        page.wait_for_timeout(500)
        cart_sec = page.locator("#cart-list, #cart, .cart-panel").first
        if cart_sec.count():
            cart_sec.scroll_into_view_if_needed()
        else:
            page.evaluate("document.getElementById('cart-list')?.scrollIntoView()")
            page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
        page.wait_for_timeout(500)
        shot(page, "03-menu-cart.png")
        # Also capture product sheet for reference if needed
        page.evaluate("typeof openSheet === 'function' && menuItems[0] && openSheet(menuItems[0].id)")
        page.wait_for_timeout(500)
        shot(page, "03b-product-sheet.png")
        page.keyboard.press("Escape")
        page.wait_for_timeout(300)
        # Checkout area
        page.locator("#submit-order, button").filter(has_text="XÁC NHẬN").first.scroll_into_view_if_needed()
        page.wait_for_timeout(300)
        shot(page, "03c-menu-checkout.png")

        # Place order for status page
        page.evaluate(
            """async (code) => {
                const menu = await (await api('/menu')).json();
                const act = menu.filter(m => m.active);
                await api('/orders', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        tableName: '', tableCode: code, customerPhone: '',
                        note: 'Ít đá', items: [
                            {menuItemId: act[0].id, size: (act[0].sizes||[])[0]?.sizeName || '', quantity: 1},
                            {menuItemId: act[1].id, size: '', quantity: 1}
                        ]
                    })
                });
            }""",
            code,
        )
        page.goto(f"{BASE}/order-status.jsp?tableCode={code}")
        page.wait_for_load_state("networkidle")
        shot(page, "04-order-status.png")
    except Exception:
        traceback.print_exc()
    finally:
        ctx.close()


def capture_barista(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        ui_login(page, "barista")
        page.wait_for_timeout(1000)
        shot(page, "06-barista-board.png", full=True)
        # Switch to cook-by-item mode
        by_item = page.locator("#btn-view-item")
        if by_item.count() == 0:
            by_item = page.locator("button").filter(has_text="NẤU THEO MÓN")
        if by_item.count():
            by_item.first.click()
            page.wait_for_timeout(1200)
            shot(page, "07-barista-item-prepare.png", full=True)
        else:
            page.locator(".order-card").first.click()
            page.wait_for_timeout(600)
            shot(page, "07-barista-item-prepare.png")
    except Exception:
        traceback.print_exc()
    finally:
        ctx.close()


def capture_cashier(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        ui_login(page, "cashier")
        page.wait_for_timeout(1200)
        shot(page, "10-cashier-unpaid.png", full=True)
        # Split dialog
        if page.locator("button.split-btn").count():
            page.locator("button.split-btn").first.click()
            page.wait_for_timeout(700)
            shot(page, "11-cashier-split.png")
            page.keyboard.press("Escape")
            page.wait_for_timeout(400)
        # Counter order
        tab = page.evaluate("tabSessionId()")
        page.goto(f"{BASE}/counter-order.jsp?tabSession={tab}")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)
        shot(page, "12-counter-order.png", full=True)
    except Exception:
        traceback.print_exc()
    finally:
        ctx.close()


def capture_runner(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        ui_login(page, "runner")
        page.wait_for_timeout(1200)
        shot(page, "08-runner-station.png", full=True)
        tab = page.evaluate("tabSessionId()")
        page.goto(f"{BASE}/table-transfer.jsp?tabSession={tab}")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)
        shot(page, "09-table-transfer.png", full=True)
    except Exception:
        traceback.print_exc()
    finally:
        ctx.close()


def capture_admin(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        page.goto(f"{BASE}/dashboard.jsp")
        page.wait_for_timeout(700)
        shot(page, "13-admin-pin-gate.png")
        page.fill("#admin-pin-input", "8888")
        page.click("#admin-pin-form button[type=submit]")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1500)
        # Switch revenue to week/month so chart has data if any
        for label in ["TUẦN", "THÁNG", "TẤT CẢ"]:
            btn = page.locator("button").filter(has_text=label)
            if btn.count():
                btn.first.click()
                page.wait_for_timeout(800)
                break
        shot(page, "14-admin-dashboard.png", full=True)
        # Reports = same dashboard, crop/focus by scrolling to revenue
        page.locator("text=BIẾN ĐỘNG DOANH THU").first.scroll_into_view_if_needed()
        page.wait_for_timeout(400)
        shot(page, "14b-admin-reports.png")
        tab = page.evaluate("tabSessionId()")
        for url, name in [
            ("admin-menu.jsp", "15-admin-menu.png"),
            ("admin-tables.jsp", "16-admin-tables.png"),
            ("admin-staff.jsp", "17-admin-staff.png"),
            ("inventory.jsp", "19-admin-inventory.png"),
            ("system-logs.jsp", "20-system-logs.png"),
        ]:
            page.goto(f"{BASE}/{url}?tabSession={tab}")
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1200)
            shot(page, name, full=True)
            if url == "admin-staff.jsp":
                try:
                    page.fill("#payrollMonth", "2026-07")
                    page.evaluate("typeof fetchPayroll === 'function' && fetchPayroll()")
                    page.wait_for_timeout(1000)
                    page.locator("#payroll-section").scroll_into_view_if_needed()
                    page.wait_for_timeout(400)
                    page.locator("#payroll-section").screenshot(path=str(OUT / "18-admin-payroll.png"))
                    note("OK 18-admin-payroll.png")
                except Exception as e:
                    note(f"FAIL payroll {e}")
        # Staff login
        page.goto(f"{BASE}/staff-login.jsp")
        page.wait_for_timeout(700)
        shot(page, "05-staff-login.png")
        page.goto(f"{BASE}/index.html")
        page.wait_for_timeout(700)
        shot(page, "01-landing.png")
    except Exception:
        traceback.print_exc()
    finally:
        ctx.close()


def main():
    with sync_playwright() as p:
        code, tables = first_table_code(p)
        # use a quieter table for guest (last ones often free)
        guest_code = tables[-1]["code"] if len(tables) > 1 else code
        try:
            ensure_served_order(p, tables[min(3, len(tables)-1)]["code"])
            note("seeded served order")
        except Exception as e:
            note(f"seed warn: {e}")
        browser = p.chromium.launch()
        capture_guest(browser, guest_code)
        capture_barista(browser)
        capture_runner(browser)
        capture_cashier(browser)
        capture_admin(browser)
        browser.close()
    note(f"done -> {OUT}")


if __name__ == "__main__":
    main()
