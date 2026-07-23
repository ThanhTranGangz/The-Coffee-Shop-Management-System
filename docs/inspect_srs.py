# -*- coding: utf-8 -*-
"""Dump the structural map of the SRS docx: body elements in order."""
import sys
from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph

SRC = r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\Group2_1.SRS Document.docx"
OUT = r"d:\STUDY\Tai_lieu\FPT_University\Semester\Summer_2026\SWP391\Documents\srs_structure.txt"


def iter_block_items(parent):
    from docx.oxml.ns import qn
    for child in parent.element.body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def main():
    doc = Document(SRC)
    lines = []
    for i, block in enumerate(iter_block_items(doc)):
        if isinstance(block, Paragraph):
            style = block.style.name if block.style else "?"
            text = block.text.strip()
            has_img = "IMG" if block._p.xpath(".//w:drawing") else ""
            if text or has_img:
                lines.append(f"[{i}] P style={style} {has_img} | {text[:150]}")
        else:
            rows = len(block.rows)
            cols = len(block.columns)
            first = " | ".join(c.text.strip()[:40] for c in block.rows[0].cells) if rows else ""
            second = " | ".join(c.text.strip()[:40] for c in block.rows[1].cells) if rows > 1 else ""
            lines.append(f"[{i}] TABLE {rows}x{cols} | R0: {first} || R1: {second}")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"{len(lines)} blocks -> {OUT}")


if __name__ == "__main__":
    main()
