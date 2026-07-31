from docx import Document
from docx.document import Document as DocumentClass
from docx.oxml.ns import qn
from docx.table import Table, _Cell
from docx.text.paragraph import Paragraph
import os
import zipfile

path = r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Group2_1.SRS Document.docx"
doc = Document(path)

keywords = [
    'nấu', 'theo đơn', 'theo món', 'cook', 'kitchen', 'Staff Order',
    'chuẩn bị', 'bar', 'barista', 'pha', 'staff-orders', 'HÌNH', 'Hình',
    'Figure', 'screenshot', 'màn hình', 'UC', 'use case'
]

print("=== Matching paragraphs ===")
for i, p in enumerate(doc.paragraphs):
    t = p.text.strip()
    if not t:
        continue
    low = t.lower()
    if any(k.lower() in low for k in keywords):
        print(f"[{i}] {t[:300]}")

print("\n=== Images ===")
with zipfile.ZipFile(path) as z:
    images = [n for n in z.namelist() if n.startswith('word/media/')]
    for n in images:
        info = z.getinfo(n)
        print(f"{n} size={info.file_size}")

# Walk body in order to find paragraphs near images
print("\n=== Body order: text + drawing markers ===")
body = doc.element.body
idx = 0
for child in body.iterchildren():
    if child.tag == qn('w:p'):
        p = Paragraph(child, doc)
        text = p.text.strip()
        has_drawing = bool(child.xpath('.//*[local-name()="drawing" or local-name()="pict"]'))
        if text or has_drawing:
            marker = " [IMG]" if has_drawing else ""
            if text or has_drawing:
                show = text[:180] if text else "(image only)"
                # filter for relevance or nearby images
                if has_drawing or any(k.lower() in show.lower() for k in keywords):
                    print(f"P{idx}{marker}: {show}")
        idx += 1
    elif child.tag == qn('w:tbl'):
        print(f"T{idx}: <table>")
        idx += 1
