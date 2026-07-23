# -*- coding: utf-8 -*-
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:9999/The-Coffee-Shop-Management-System-main"
OUT = Path(r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\srs_screenshots")


def login(page, role, pin):
    page.goto(f"{BASE}/staff-login.jsp")
    page.wait_for_timeout(500)
    page.click(f".role-option[data-role='{role}']")
    page.fill("#pin", pin)
    page.click("#login-form button[type=submit]")
    page.wait_for_load_state("networkidle")
    page.wait_for_timeout(1000)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()

        ctx = browser.new_context(viewport={"width": 1440, "height": 900}, locale="en-US")
        ctx.add_init_script("localStorage.setItem('coffeshop_lang', 'en');")
        page = ctx.new_page()
        login(page, "cashier", "2222")
        page.keyboard.press("Escape")
        page.evaluate(
            """() => {
                const o = document.getElementById('split-overlay');
                const s = document.getElementById('split-sheet');
                if (o) o.remove();
                if (s) s.remove();
            }"""
        )
        page.wait_for_timeout(400)
        page.screenshot(path=str(OUT / "10-cashier-unpaid.png"), full_page=True)
        print("OK 10-cashier-unpaid")
        ctx.close()

        ctx = browser.new_context(viewport={"width": 1440, "height": 900}, locale="en-US")
        ctx.add_init_script("localStorage.setItem('coffeshop_lang', 'en');")
        page = ctx.new_page()
        login(page, "barista", "1111")
        if page.locator("#btn-view-order").count():
            page.locator("#btn-view-order").click()
            page.wait_for_timeout(800)
        # Pending
        pend = page.locator("button").filter(has_text="PENDING")
        if pend.count():
            pend.first.click()
            page.wait_for_timeout(700)
        page.screenshot(path=str(OUT / "06d-barista-status-update.png"), full_page=True)
        print("OK 06d status-update (pending)")
        # Ready tab shot as secondary reference stored
        ready = page.locator("button").filter(has_text="READY")
        if ready.count():
            ready.first.click()
            page.wait_for_timeout(700)
            page.screenshot(path=str(OUT / "06c-barista-ready.png"), full_page=True)
            print("OK 06c ready")
        # Cook by item
        if page.locator("#btn-view-item").count():
            page.locator("#btn-view-item").click()
            page.wait_for_timeout(1000)
        page.screenshot(path=str(OUT / "07-barista-item-prepare.png"), full_page=True)
        print("OK 07 item")
        ctx.close()
        browser.close()


if __name__ == "__main__":
    main()
