# -*- coding: utf-8 -*-
"""Capture all SRS screenshots with English UI (localStorage lang=en)."""
import traceback
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:9999/The-Coffee-Shop-Management-System-main"
OUT = Path(r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\srs_screenshots")
OUT.mkdir(parents=True, exist_ok=True)
PINS = {"barista": "1111", "cashier": "2222", "runner": "3333"}
DESKTOP = {"width": 1440, "height": 900}
MOBILE = {"width": 414, "height": 896}


def note(m):
    print(m.encode("ascii", "replace").decode("ascii"))


def en_context(browser, viewport):
    ctx = browser.new_context(viewport=viewport, locale="en-US")
    ctx.add_init_script("localStorage.setItem('coffeshop_lang', 'en');")
    return ctx


def api(p, tab):
    return p.request.new_context(extra_http_headers={"X-Tab-Session": tab})


def jget(ctx, path):
    r = ctx.get(BASE + "/api" + path)
    assert r.ok, r.text()[:200]
    return r.json()


def jpost(ctx, path, body):
    r = ctx.post(BASE + "/api" + path, data=body)
    assert r.ok, f"{path} {r.status} {r.text()[:200]}"
    return r.json()


def login_api(ctx, role):
    jpost(ctx, "/auth/login", {"username": role, "password": PINS[role]})


def ui_login(page, role):
    page.goto(f"{BASE}/staff-login.jsp")
    page.wait_for_timeout(500)
    page.click(f".role-option[data-role='{role}']")
    page.fill("#pin", PINS[role])
    page.click("#login-form button[type=submit]")
    page.wait_for_load_state("networkidle")
    page.wait_for_timeout(800)


def shot(page, name, full=False):
    page.wait_for_timeout(600)
    page.screenshot(path=str(OUT / name), full_page=full)
    note("OK " + name)


def seed(p):
    pub = api(p, "pub")
    tables = [t for t in jget(pub, "/tables") if t.get("active")]
    menu = [m for m in jget(pub, "/menu") if m.get("active")]
    pub.dispose()
    code = tables[min(3, len(tables) - 1)]["code"]

    def item(i, qty=1):
        m = menu[i % len(menu)]
        size = (m.get("sizes") or [{}])[0].get("sizeName", "") if m.get("sizes") else ""
        return {"menuItemId": m["id"], "size": size or "", "quantity": qty}

    g = api(p, "g")
    g.get(f"{BASE}/api/tables/by-code?code={code}")
    order = jpost(g, "/orders", {
        "tableName": "", "tableCode": code, "customerPhone": "",
        "note": "EN capture", "items": [item(0, 2), item(1, 2), item(2, 1)],
    })
    g.dispose()
    bar = api(p, "b"); login_api(bar, "barista")
    jpost(bar, "/orders/status", {"id": order["id"], "status": "Preparing"})
    jpost(bar, "/orders/status", {"id": order["id"], "status": "Ready"})
    bar.dispose()
    run = api(p, "r"); login_api(run, "runner")
    jpost(run, "/orders/status", {"id": order["id"], "status": "Served"})
    run.dispose()
    return tables[-1]["code"], tables


def main():
    with sync_playwright() as p:
        guest_code, tables = seed(p)
        browser = p.chromium.launch()

        # Guest
        ctx = en_context(browser, MOBILE)
        page = ctx.new_page()
        page.goto(f"{BASE}/menu.jsp?tableCode={guest_code}")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)
        shot(page, "02-menu-customer.png")
        page.evaluate("""() => {
            if (typeof menuItems === 'undefined' || !menuItems.length) return;
            const act = menuItems.filter(m => m.active);
            cart = [
              {menuItemId: act[0].id, size: (act[0].sizes||[])[0]?.sizeName||'', quantity: 1, note: 'Less ice'},
              {menuItemId: act[1].id, size: (act[1].sizes||[])[0]?.sizeName||'', quantity: 2, note: ''}
            ];
            if (typeof renderCart === 'function') renderCart();
        }""")
        page.wait_for_timeout(500)
        page.evaluate("document.getElementById('cart-list')?.scrollIntoView()")
        page.wait_for_timeout(400)
        shot(page, "03-menu-cart.png")
        page.evaluate("""async (code) => {
            const menu = await (await api('/menu')).json();
            const act = menu.filter(m => m.active);
            await api('/orders', {method:'POST', headers:{'Content-Type':'application/json'},
              body: JSON.stringify({tableName:'', tableCode:code, customerPhone:'', note:'Less ice',
                items:[{menuItemId:act[0].id, size:(act[0].sizes||[])[0]?.sizeName||'', quantity:1}]})});
        }""", guest_code)
        page.goto(f"{BASE}/order-status.jsp?tableCode={guest_code}")
        page.wait_for_load_state("networkidle")
        shot(page, "04-order-status.png")
        ctx.close()

        # Barista
        ctx = en_context(browser, DESKTOP)
        page = ctx.new_page()
        ui_login(page, "barista")
        shot(page, "06-barista-board.png", full=True)
        if page.locator("#btn-view-item").count():
            page.locator("#btn-view-item").click()
            page.wait_for_timeout(1000)
        shot(page, "07-barista-item-prepare.png", full=True)
        ctx.close()

        # Runner
        ctx = en_context(browser, DESKTOP)
        page = ctx.new_page()
        ui_login(page, "runner")
        shot(page, "08-runner-station.png", full=True)
        tab = page.evaluate("tabSessionId()")
        page.goto(f"{BASE}/table-transfer.jsp?tabSession={tab}")
        page.wait_for_load_state("networkidle")
        shot(page, "09-table-transfer.png", full=True)
        ctx.close()

        # Cashier
        ctx = en_context(browser, DESKTOP)
        page = ctx.new_page()
        ui_login(page, "cashier")
        shot(page, "10-cashier-unpaid.png", full=True)
        if page.locator("button.split-btn").count():
            page.locator("button.split-btn").first.click()
            page.wait_for_timeout(700)
            shot(page, "11-cashier-split.png")
            page.keyboard.press("Escape")
        tab = page.evaluate("tabSessionId()")
        page.goto(f"{BASE}/counter-order.jsp?tabSession={tab}")
        page.wait_for_load_state("networkidle")
        shot(page, "12-counter-order.png", full=True)
        ctx.close()

        # Admin
        ctx = en_context(browser, DESKTOP)
        page = ctx.new_page()
        page.goto(f"{BASE}/dashboard.jsp")
        page.wait_for_timeout(600)
        shot(page, "13-admin-pin-gate.png")
        page.fill("#admin-pin-input", "8888")
        page.click("#admin-pin-form button[type=submit]")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1200)
        btn = page.locator("button").filter(has_text="WEEK")
        if btn.count() == 0:
            btn = page.locator("button").filter(has_text="TUẦN")
        if btn.count():
            btn.first.click()
            page.wait_for_timeout(800)
        shot(page, "14-admin-dashboard.png", full=True)
        page.locator("text=/Revenue|BIẾN ĐỘNG|Doanh thu/i").first.scroll_into_view_if_needed()
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
            page.wait_for_timeout(1100)
            shot(page, name, full=(name != "20-system-logs.png"))
            if url == "system-logs.jsp":
                page.screenshot(path=str(OUT / name), full_page=False)
                note("OK " + name + " viewport")
            if url == "admin-staff.jsp":
                try:
                    page.fill("#payrollMonth", "2026-07")
                    page.evaluate("typeof fetchPayroll==='function' && fetchPayroll()")
                    page.wait_for_timeout(900)
                    page.locator("#payroll-section").scroll_into_view_if_needed()
                    page.locator("#payroll-section").screenshot(path=str(OUT / "18-admin-payroll.png"))
                    note("OK 18-admin-payroll.png")
                    # also full staff board at top
                    page.evaluate("window.scrollTo(0,0)")
                    page.wait_for_timeout(400)
                    shot(page, "17-admin-staff.png", full=True)
                except Exception as e:
                    note("payroll fail " + str(e))
        page.goto(f"{BASE}/staff-login.jsp")
        page.wait_for_timeout(700)
        shot(page, "05-staff-login.png")
        page.goto(f"{BASE}/index.html")
        page.wait_for_timeout(700)
        shot(page, "01-landing.png")
        ctx.close()
        browser.close()
    note("done EN captures")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
