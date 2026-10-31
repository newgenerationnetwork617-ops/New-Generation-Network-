#!/usr/bin/env python3
"""Download CCEL's public-domain Spurgeon text and prepare NGN morning readings."""
from __future__ import annotations
import json, re, urllib.request
from datetime import date, timedelta
from pathlib import Path
from xml.etree import ElementTree as ET

SOURCE_URL = "https://www.ccel.org/ccel/spurgeon/morneve.xml"
OUT_DIR = Path("data/devotionals/spurgeon-morning")
ENTITY_MAP = {"mdash":"—","ndash":"–","lsquo":"‘","rsquo":"’","ldquo":"“","rdquo":"”","nbsp":" ","hellip":"…","emdash":"—","copy":"©","reg":"®","trade":"™","deg":"°","para":"¶","sect":"§","dagger":"†","Dagger":"‡","bull":"•","prime":"′","Prime":"″"}
ID_RE = re.compile(r"^d(\d{2})(\d{2})(am|pm)$")
MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"]

def text_of(node):
    parts = [node.text or ""]
    for child in node:
        parts.append(text_of(child))
        parts.append(child.tail or "")
    return "".join(parts)

def clean(value):
    return re.sub(r"\s+", " ", value or "").strip()

def is_navigation_paragraph(node):
    children = list(node)
    if (node.text or "").strip() or not children:
        return False
    return all(child.tag == "a" and not (child.tail or "").strip() for child in children)

def collect_blocks(node):
    blocks = []
    for child in node:
        tag = child.tag
        if tag in {"h2","h3","h4","h5","sync","a"}:
            continue
        if tag == "p":
            if not is_navigation_paragraph(child):
                value = clean(text_of(child))
                if value:
                    blocks.append((child.get("class",""), value))
        elif tag == "verse":
            lines = [clean(text_of(line)) for line in child]
            value = "\n".join(line for line in lines if line)
            if value:
                blocks.append(("verse", value))
        elif tag in {"div3","div4","div5"}:
            blocks.extend(collect_blocks(child))
    return blocks

def parse_source(raw):
    try:
        source = raw.decode("utf-8")
    except UnicodeDecodeError:
        source = raw.decode("cp1252", errors="replace")
    source = re.sub(r"<!DOCTYPE\s[^[>]*(?:\[[^\]]*\])?>", "", source, flags=re.S)
    def replace_entity(match):
        return ENTITY_MAP.get(match.group(1), match.group(0))
    source = re.sub(r"&([A-Za-z][A-Za-z0-9]*);", replace_entity, source)
    root = ET.fromstring(source)
    readings = {}
    for div in root.iter("div2"):
        match = ID_RE.match(div.get("id",""))
        if not match:
            continue
        month, day, period = int(match.group(1)), int(match.group(2)), match.group(3)
        if period != "am":
            continue
        reference = None
        for heading in div:
            if heading.tag == "h3" and "scrip" in heading.get("class","").lower():
                ref = heading.find(".//scripRef")
                if ref is not None:
                    reference = clean(text_of(ref))
                break
        blocks = collect_blocks(div)
        theme = next((value for cls,value in blocks if "passage" in cls.lower()), None)
        message = "\n\n".join(value for cls,value in blocks if "passage" not in cls.lower()).strip()
        if not message or not reference:
            raise ValueError(f"Incomplete morning entry d{month:02d}{day:02d}am")
        readings[(month,day)] = {"reference":reference,"theme":theme,"message":message}
    if len(readings) not in (365,366):
        raise ValueError(f"Expected 365 or 366 morning entries; parsed {len(readings)}")
    return readings

def main():
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent":"NGN devotional importer/1.0"})
    with urllib.request.urlopen(request, timeout=90) as response:
        readings = parse_source(response.read())
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    current, end = date(2026,11,1), date(2027,12,31)
    grouped, total = {}, 0
    while current <= end:
        source = readings.get((current.month,current.day))
        if source is None:
            raise ValueError(f"No source reading for {current.isoformat()}")
        month_name = MONTHS[current.month-1]
        row = {
            "title": f"Morning Devotional — {month_name} {current.day}",
            "theme": source["theme"],
            "bible_reference": source["reference"],
            "message": source["message"],
            "life_application": None,
            "prayer": None,
            "memory_verse": None,
            "published_at": current.isoformat() + "T00:00:00+01:00",
            "source_author": "C. H. Spurgeon",
            "source_title": "Morning and Evening: Daily Readings",
            "source_url": SOURCE_URL
        }
        grouped.setdefault(current.strftime("%Y-%m"), []).append(row)
        total += 1
        current += timedelta(days=1)
    for month_key, rows in grouped.items():
        payload = {
            "source":"C. H. Spurgeon, Morning and Evening: Daily Readings",
            "archive":"Christian Classics Ethereal Library (CCEL)",
            "source_url":SOURCE_URL,
            "rights_note":"CCEL source page marks this work Public Domain — Copy Freely.",
            "period":"morning readings only",
            "count":len(rows),
            "entries":rows
        }
        (OUT_DIR / f"{month_key}.json").write_text(json.dumps(payload,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    readme = """# NGN — Spurgeon Morning Devotionals

Prepared for NEW GENERATION NETWORK from C. H. Spurgeon's *Morning and Evening: Daily Readings*.

- Author: Charles Haddon Spurgeon
- Source archive: Christian Classics Ethereal Library (CCEL)
- Source URL: https://www.ccel.org/ccel/spurgeon/morneve.xml
- CCEL's work page marks the text **Public Domain — Copy Freely**.
- Selection: morning readings only.
- Scheduled range: 1 November 2026 through 31 December 2027.
- The annual morning reading is assigned to its corresponding calendar date in 2026/2027.
- life_application, prayer, and memory_verse are left empty rather than inventing content not separately supplied by the source.

The source author is Spurgeon; CCEL is the digital archive, not the author.
"""
    (OUT_DIR / "README.md").write_text(readme,encoding="utf-8")
    print(f"Prepared {total} dated morning readings in {len(grouped)} monthly files.")

if __name__ == "__main__":
    main()
