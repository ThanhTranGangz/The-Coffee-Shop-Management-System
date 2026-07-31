from docx import Document
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph
from docx.table import Table
import zipfile, os, shutil

path = r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Group2_1.SRS Document.docx"
out = r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Project\The-Coffee-Shop-Management-System\_srs_media"
os.makedirs(out, exist_ok=True)

# Extract all media
with zipfile.ZipFile(path) as z:
    for n in z.namelist():
        if n.startswith('word/media/'):
            z.extract(n, out)
            print('extracted', n, z.getinfo(n).file_size)

doc = Document(path)

# Map rId -> image for paragraphs that have drawings near barista section
# Find image relationships in document part
print('\n=== Rel map ===')
for rel in doc.part.rels.values():
    if 'image' in rel.reltype:
        print(rel.rId, rel.target_ref)

# Walk paragraphs around section 3.3 and print which image rIds
print('\n=== Paragraphs 270-340 with image rIds ===')
paras = list(doc.paragraphs)
for i, p in enumerate(paras):
    if i < 250 or i > 340:
        continue
    drawings = p._element.xpath('.//*[local-name()="blip"]')
    rids = []
    for blip in drawings:
        rid = blip.get(qn('r:embed')) or blip.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed')
        if rid:
            rids.append(rid)
    text = p.text.strip()[:120]
    if text or rids:
        print(f'[{i}] rids={rids} text={text}')
