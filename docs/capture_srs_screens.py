# -*- coding: utf-8 -*-
"""Capture SRS screenshots from the running CoffeeShop Lite app.

Seeds demo orders/shifts through the HTTP API, then walks every role screen
with Playwright and saves PNGs for embedding into the revised SRS document.
"""
import sys
import time
import traceback
from pathlib import Path

from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:9999/The-Coffee-Shop-Management-System-main"
OUT = Path(r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\srs_screenshots")
OUT.mkdir(parents=True, exist_ok=True)

PINS = {"barista": "1111", "cashier": "2222", "runner": "3333"}
DESKTOP = {"width": 1440, "height": 900}
MOBILE = {"width": 414, "height": 896}

results = []


def note(name, ok, extra=""):
    results.append((name, ok, extra))
    line = ("OK   " if ok else "FAIL ") + name + ("  " + extra if extra else "")
    print(line.encode("ascii", "replace").decode("ascii"))


def api_ctx(p, tab):
    return p.request.new_context(extra_http_headers={"X-Tab-Session": tab})


def login(ctx, role):
    r = ctx.post(BASE + "/api/auth/login", data={"username": role, "password": PINS[role]})
    assert r.ok, f"login {role}: {r.status} {r.text()}"
    return ctx


def admin_login(ctx):
    r = ctx.post(BASE + "/api/auth/admin-pin", data={"pin": "8888"})
    assert r.ok, f"admin pin: {r.status} {r.text()}"
    return ctx


def jget(ctx, path):
    r = ctx.get(BASE + "/api" + path)
    assert r.ok, f"GET {path}: {r.status} {r.text()}"
    return r.json()


def jpost(ctx, path, body):
    r = ctx.post(BASE + "/api" + path, data=body)
    if not r.ok:
        raise RuntimeError(f"POST {path}: {r.status} {r.text()}")
    return r.json()


def guest_order(p, tab, table_code, items, note_text=""):
    ctx = api_ctx(p, tab)
    ctx.get(f"{BASE}/api/tables/by-code?code={table_code}")
    order = jpost(ctx, "/orders", {
        "tableName": "", "tableCode": table_code, "customerPhone": "",
        "note": note_text, "items": items,
    })
    ctx.dispose()
    return order


def set_status(ctx, order_id, status):
    return jpost(ctx, "/orders/status", {"id": order_id, "status": status})


def seed_data(p):
    """Create orders in every workflow state plus staff/shift/payroll data."""
    pub = api_ctx(p, "seed-pub")
    tables = [t for t in jget(pub, "/tables") if t.get("active")]
    menu = [m for m in jget(pub, "/menu") if m.get("active")]
    pub.dispose()
    assert len(tables) >= 5 and len(menu) >= 3

    def item(i, qty=1):
        m = menu[i % len(menu)]
        size = (m.get("sizes") or [{}])[0].get("sizeName", "") if m.get("sizes") else ""
        return {"menuItemId": m["id"], "size": size, "quantity": qty}

    codes = [t["code"] for t in tables]
    bar = login(api_ctx(p, "seed-bar"), "barista")
    run = login(api_ctx(p, "seed-run"), "runner")

    orders = {}
    o = guest_order(p, "g1", codes[0], [item(0, 2), item(1, 1)], "It duong")
    orders["pending"] = o
    o = guest_order(p, "g2", codes[1], [item(2, 1), item(3, 2)])
    set_status(bar, o["id"], "Preparing")
    orders["preparing"] = o
    o = guest_order(p, "g3", codes[2], [item(4, 1), item(5, 1)])
    set_status(bar, o["id"], "Preparing")
    set_status(bar, o["id"], "Ready")
    orders["ready"] = o
    o = guest_order(p, "g4", codes[3], [item(0, 2), item(2, 2), item(4, 1)], "Khach doan")
    set_status(bar, o["id"], "Preparing")
    set_status(bar, o["id"], "Ready")
    set_status(run, o["id"], "Served")
    orders["served_split"] = o
    o = guest_order(p, "g5", codes[4], [item(1, 1), item(3, 1)])
    set_status(bar, o["id"], "Preparing")
    set_status(bar, o["id"], "Ready")
    set_status(run, o["id"], "Served")
    orders["served_pay"] = o
    bar.dispose()
    run.dispose()

    adm = admin_login(api_ctx(p, "seed-adm"))
    staff = jget(adm, "/staff")
    if len(staff) < 3:
        for name, role, pin in [
            ("Nguyen Van An", "Barista", "1111"),
            ("Tran Thi Bich", "Cashier", "2222"),
            ("Le Van Cuong", "Waiter", "3333"),
            ("Pham Thi Dao", "Barista", "4444"),
        ]:
            jpost(adm, "/staff/save", {
                "id": 0, "name": name, "role": role, "pin": pin, "shift": "",
                "active": True, "username": name.split()[-1].lower(),
                "password": pin, "status": "Đang làm", "overtime": False,
            })
        staff = jget(adm, "/staff")
    shifts = jget(adm, "/shifts")
    if len(shifts) < 5:
        shift_defs = [("Ca Sáng", "06:00 - 12:00"), ("Ca Chiều", "12:00 - 18:00"), ("Ca Tối", "18:00 - 23:00")]
        days = ["2026-07-1%d" % d for d in range(3, 9)]
        k = 0
        for day in days:
            for si, (sname, hours) in enumerate(shift_defs):
                s = staff[(k + si) % len(staff)]
                try:
                    jpost(adm, "/shifts", {
                        "id": "", "staffId": s["id"], "staffName": s["name"],
                        "date": day, "shiftName": sname, "hours": hours,
                        "status": "Đã làm", "notes": "", "assignedRole": s.get("role", ""),
                    })
                except RuntimeError as e:
                    if "SHIFT_OVERLAP" not in str(e):
                        raise
            k += 1
    adm.dispose()
    return orders, codes


def shot(page, name, full=False):
    page.wait_for_timeout(900)
    page.screenshot(path=str(OUT / name), full_page=full)
    note(name, True)


def ui_login(page, role):
    page.goto(f"{BASE}/staff-login.jsp")
    page.wait_for_timeout(600)
    page.click(f".role-option[data-role='{role}']")
    page.fill("#pin", PINS[role])
    page.click("#login-form button[type=submit]")
    page.wait_for_load_state("networkidle")


def capture_guest(browser, code):
    ctx = browser.new_context(viewport=MOBILE, locale="vi-VN")
    page = ctx.new_page()
    try:
        page.goto(f"{BASE}/index.html")
        shot(page, "01-landing.png")
        page.goto(f"{BASE}/menu.jsp?tableCode={code}")
        page.wait_for_load_state("networkidle")
        shot(page, "02-menu-customer.png")
        # add two items to cart through the UI
        try:
            buttons = page.locator(".menu-grid button, .product-card button, button.add-btn, .menu-item button")
            n = min(2, buttons.count())
            for i in range(n):
                buttons.nth(i).click()
                page.wait_for_timeout(400)
        except Exception:
            pass
        page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
        shot(page, "03-menu-cart.png")
        # place an order inside this browser session so order-status shows it
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
                            {menuItemId: act[1].id, size: '', quantity: 2}
                        ]
                    })
                });
            }""",
            code,
        )
        page.goto(f"{BASE}/order-status.jsp?tableCode={code}")
        page.wait_for_load_state("networkidle")
        shot(page, "04-order-status.png")
    except Exception as e:
        note("guest flow", False, str(e))
        traceback.print_exc()
    finally:
        ctx.close()


def capture_barista(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        page.goto(f"{BASE}/staff-login.jsp")
        page.wait_for_timeout(700)
        shot(page, "05-staff-login.png")
        ui_login(page, "barista")
        page.wait_for_timeout(1200)
        shot(page, "06-barista-board.png", full=True)
        # open first order detail to show per-item prepare buttons if present
        try:
            card = page.locator(".order-card").first
            card.click()
            page.wait_for_timeout(600)
            shot(page, "07-barista-item-prepare.png")
        except Exception as e:
            note("07-barista-item-prepare.png", False, str(e))
    except Exception as e:
        note("barista flow", False, str(e))
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
        shot(page, "09-table-transfer.png")
    except Exception as e:
        note("runner flow", False, str(e))
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
        try:
            page.locator("button.split-btn").first.click()
            page.wait_for_timeout(700)
            shot(page, "11-cashier-split.png")
            page.keyboard.press("Escape")
            overlay = page.locator("#split-overlay")
            if overlay.count() and overlay.first.is_visible():
                overlay.first.click(position={"x": 5, "y": 5})
            page.wait_for_timeout(400)
        except Exception as e:
            note("11-cashier-split.png", False, str(e))
        tab = page.evaluate("tabSessionId()")
        page.goto(f"{BASE}/counter-order.jsp?tabSession={tab}")
        page.wait_for_load_state("networkidle")
        shot(page, "12-counter-order.png")
    except Exception as e:
        note("cashier flow", False, str(e))
        traceback.print_exc()
    finally:
        ctx.close()


def capture_admin(browser):
    ctx = browser.new_context(viewport=DESKTOP, locale="vi-VN")
    page = ctx.new_page()
    try:
        page.goto(f"{BASE}/dashboard.jsp")
        page.wait_for_timeout(800)
        shot(page, "13-admin-pin-gate.png")
        page.fill("#admin-pin-input", "8888")
        page.click("#admin-pin-form button[type=submit]")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1500)
        shot(page, "14-admin-dashboard.png", full=True)
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
                # payroll is a section on the same page; select month and scroll
                try:
                    page.fill("#payrollMonth", "2026-07")
                    page.evaluate("typeof fetchPayroll === 'function' && fetchPayroll()")
                    page.wait_for_timeout(1200)
                    page.locator("#payroll-section").scroll_into_view_if_needed()
                    page.wait_for_timeout(500)
                    page.locator("#payroll-section").screenshot(path=str(OUT / "18-admin-payroll.png"))
                    note("18-admin-payroll.png", True)
                except Exception as e:
                    note("18-admin-payroll.png", False, str(e))
    except Exception as e:
        note("admin flow", False, str(e))
        traceback.print_exc()
    finally:
        ctx.close()


def main():
    with sync_playwright() as p:
        try:
            orders, codes = seed_data(p)
            note("seed", True, f"orders={ {k: v.get('orderNumber') for k, v in orders.items()} }")
        except Exception as e:
            note("seed", False, str(e))
            traceback.print_exc()
            codes = None
        browser = p.chromium.launch()
        if codes is None:
            pub = api_ctx(p, "fallback")
            codes = [t["code"] for t in jget(pub, "/tables") if t.get("active")]
            pub.dispose()
        capture_guest(browser, codes[5] if len(codes) > 5 else codes[0])
        capture_barista(browser)
        capture_runner(browser)
        capture_cashier(browser)
        capture_admin(browser)
        browser.close()
    fails = [r for r in results if not r[1]]
    print(f"\nDone: {len(results) - len(fails)} ok, {len(fails)} failed -> {OUT}")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
