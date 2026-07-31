# -*- coding: utf-8 -*-
"""Capture barista cook-by-order / cook-by-item screens for SRS update."""
import time
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:9999/The-Coffee-Shop-Management-System-main"
OUT = Path(r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Project\The-Coffee-Shop-Management-System\_srs_shots")
OUT.mkdir(parents=True, exist_ok=True)

def shot(page, name):
    path = OUT / f"{name}.png"
    # Capture main content viewport (not endless full_page scroll noise)
    page.screenshot(path=str(path), full_page=True)
    print(f"saved {path.name} ({path.stat().st_size} bytes)")
    return path

def click_tab(page, en, vi=None):
    # tabs: button.mobile-tab with .tab-label
    for text in ([en] + ([vi] if vi else [])):
        loc = page.locator("button.mobile-tab").filter(has_text=text)
        if loc.count() > 0:
            loc.first.click()
            page.wait_for_timeout(900)
            return True
    return False

def ensure_english(page):
    body = page.inner_text("body")
    if any(x in body for x in ["Chờ xử lý", "Đang pha", "Nấu theo", "Sẵn sàng"]):
        btn = page.locator("#lang-toggle")
        if btn.count():
            btn.click()
            page.wait_for_timeout(700)

def hold_card(page, locator, ms=700):
    box = locator.bounding_box()
    if not box:
        return False
    x = box["x"] + box["width"] / 2
    y = box["y"] + min(40, box["height"] / 2)
    page.mouse.move(x, y)
    page.mouse.down()
    page.wait_for_timeout(ms)
    page.mouse.up()
    page.wait_for_timeout(900)
    return True

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(viewport={"width": 1440, "height": 960}, locale="en-US")
    page = context.new_page()

    page.goto(f"{BASE}/staff-login.jsp", wait_until="networkidle")
    page.wait_for_selector(".role-option[data-role='barista'], #pin", timeout=20000)
    role = page.locator(".role-option[data-role='barista']")
    if role.count():
        role.first.click()
        page.wait_for_timeout(300)
    page.fill("#pin", "1111")
    # submit if form button exists
    submit = page.locator("button[type='submit'], button.login-btn, form button")
    if submit.count():
        submit.first.click()
    page.wait_for_url("**/staff-orders.jsp**", timeout=15000)
    page.wait_for_selector("#orders-board", timeout=20000)
    page.wait_for_timeout(1200)
    ensure_english(page)
    page.wait_for_timeout(500)

    # 1) Pending — toggle must be hidden
    click_tab(page, "Pending", "Chờ")
    page.wait_for_timeout(500)
    toggle_html = page.locator("#view-toggle-group").inner_html().strip()
    print("Pending toggle empty?", toggle_html == "")
    shot(page, "01_pending_no_toggle")

    # Ensure Preparing has at least one order
    click_tab(page, "Preparing", "Đang")
    prep_cards = page.locator("article.order-card")
    print("Preparing cards:", prep_cards.count())
    if prep_cards.count() == 0:
        click_tab(page, "Pending", "Chờ")
        cards = page.locator("article.order-card.hold-card")
        print("Pending hold cards:", cards.count())
        moved = 0
        for i in range(min(2, cards.count())):
            if hold_card(page, cards.nth(i)):
                moved += 1
                print("moved pending card", i)
                # after move, board refreshes to same tab with fewer cards
                page.wait_for_timeout(400)
                cards = page.locator("article.order-card.hold-card")
        click_tab(page, "Preparing", "Đang")
        print("Preparing after move:", page.locator("article.order-card").count())

    # 2) Preparing + Cook by Order
    click_tab(page, "Preparing", "Đang")
    page.wait_for_selector("#btn-view-order, #btn-view-item", timeout=8000)
    page.locator("#btn-view-order").click()
    page.wait_for_timeout(800)
    print("Order mode active class:", page.locator("#btn-view-order").get_attribute("class"))
    shot(page, "02_preparing_cook_by_order")

    # 3) Preparing + Cook by Item
    page.locator("#btn-view-item").click()
    page.wait_for_timeout(1000)
    print("Item mode active class:", page.locator("#btn-view-item").get_attribute("class"))
    # Prefer a multi-item preparing order if possible for nicer shot
    shot(page, "03_preparing_cook_by_item")

    # 4) Ready — toggle hidden
    click_tab(page, "Ready", "Sẵn")
    page.wait_for_timeout(600)
    toggle_html = page.locator("#view-toggle-group").inner_html().strip()
    print("Ready toggle empty?", toggle_html == "")
    shot(page, "04_ready_no_toggle")

    browser.close()
    print("DONE")
