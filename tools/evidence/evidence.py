"""Build the evidence pack for one control and one period (Chapter 15).

    python3 tools/evidence/evidence.py --control DATA-01 --period 2026-Q3

Reads the control register, finds what the collectors gathered for each
assertion, and writes:

    evidence/<period>/<control>/
        summary.md       one page for a person: control, assertions, results, exceptions
        items/*.json     one evidence item per assertion, in the format from Chapter 15
        raw/*.json       the collected data each item summarises, hashed
        exceptions.md    approved exemptions in force during the period

The collectors themselves are environment-specific. The samples/ folder holds
example collector output so the generator can be run and tested anywhere.
"""
import argparse
import datetime as dt
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]

GOOD = {"compliant"}
OK_WITH_EXCEPTIONS = {"compliant_with_exceptions"}


def parse_period(period):
    """'2026-Q3' -> (date(2026, 7, 1), date(2026, 9, 30))."""
    m = re.fullmatch(r"(\d{4})-Q([1-4])", period)
    if not m:
        raise ValueError(f"period must look like 2026-Q3, got {period!r}")
    year, q = int(m.group(1)), int(m.group(2))
    start = dt.date(year, 3 * q - 2, 1)
    end = dt.date(year + (q == 4), (3 * q) % 12 + 1, 1) - dt.timedelta(days=1)
    return start, end


def as_date(v):
    return v if isinstance(v, dt.date) else dt.date.fromisoformat(str(v))


def source_filename(source):
    return source.replace(":", "__").replace("/", "_") + ".json"


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load_register(path=ROOT / "controls" / "register.yaml"):
    return {c["id"]: c for c in yaml.safe_load(Path(path).read_text())}


def load_exceptions(path=ROOT / "controls" / "exceptions.yaml"):
    p = Path(path)
    if not p.exists():
        return []
    return yaml.safe_load(p.read_text()) or []


def active_exceptions(exceptions, control_id, start, end):
    out = []
    for e in exceptions:
        if not str(e["control"]).startswith(control_id + "."):
            continue
        if as_date(e["approved"]) <= end and as_date(e["expires"]) >= start:
            out.append(e)
    return out


def build_pack(control_id, period, collected=ROOT / "samples" / "collected", out=ROOT / "evidence",
               register=None, exceptions=None):
    register = register if register is not None else load_register()
    exceptions = exceptions if exceptions is not None else load_exceptions()
    if control_id not in register:
        raise KeyError(f"{control_id} is not in the control register")
    control = register[control_id]
    start, end = parse_period(period)

    pack = Path(out) / period / control_id
    if pack.exists():
        shutil.rmtree(pack)
    (pack / "items").mkdir(parents=True)
    (pack / "raw").mkdir()

    items = []
    for a in control["assertions"]:
        raw_src = Path(collected) / period / source_filename(a["source"])
        item = {
            "control": a["id"],
            "period": f"{start.isoformat()}/{end.isoformat()}",
            "source": a["source"],
        }
        if raw_src.exists():
            raw = json.loads(raw_src.read_text())
            raw_dst = pack / "raw" / raw_src.name
            shutil.copyfile(raw_src, raw_dst)
            item.update({
                "collected_at": raw["collected_at"],
                "collector": raw["collector"],
                "result": raw["result"],
                "scope": raw.get("scope", {}),
                "raw": str(raw_dst.relative_to(pack)),
                "sha256": sha256(raw_dst),
            })
        else:
            item.update({"result": "missing", "note": "No collected evidence found for this period"})
        (pack / "items" / f"{a['id']}.json").write_text(json.dumps(item, indent=2) + "\n")
        items.append((a, item))

    in_force = active_exceptions(exceptions, control_id, start, end)
    results = {i["result"] for _, i in items}
    if results <= GOOD:
        verdict = "Held throughout the period."
    elif results <= GOOD | OK_WITH_EXCEPTIONS and in_force:
        verdict = "Held throughout the period, with the approved exceptions listed below."
    else:
        verdict = "Not fully evidenced. See the assertions marked for attention."

    lines = [
        f"# {control_id}: evidence for {period}",
        "",
        f"**Control:** {control['statement']}",
        f"**Supports:** {', '.join(control['supports'])}",
        f"**Owner:** {control['owner']}",
        f"**Period:** {start.isoformat()} to {end.isoformat()}",
        "",
        f"**Result:** {verdict}",
        "",
        "| Assertion | What it checks | Result | Evidence |",
        "| --- | --- | --- | --- |",
    ]
    for a, i in items:
        flag = "" if i["result"] in GOOD | OK_WITH_EXCEPTIONS else " (attention)"
        ev = f"items/{a['id']}.json" if i["result"] != "missing" else "none collected"
        lines.append(f"| {a['id']} | {a['text']} | {i['result']}{flag} | {ev} |")
    lines += ["", f"Exceptions in force: {len(in_force)} (see exceptions.md)", ""]
    (pack / "summary.md").write_text("\n".join(lines))

    ex = [f"# Exceptions in force for {control_id}, {period}", ""]
    if not in_force:
        ex.append("None.")
    for e in in_force:
        ex += [
            f"## {e['control']}: {e['resource']}",
            f"- Reason: {e['reason']}",
            f"- Compensating controls: {e['compensating']}",
            f"- Approved by: {e['approved_by']} on {as_date(e['approved']).isoformat()} ({e['risk_reference']})",
            f"- Implemented as: {e['implemented_as']}",
            f"- Expires: {as_date(e['expires']).isoformat()}",
            "",
        ]
    (pack / "exceptions.md").write_text("\n".join(ex) + "\n")
    return pack, verdict


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--control", required=True)
    p.add_argument("--period", required=True)
    p.add_argument("--collected", default=str(ROOT / "samples" / "collected"))
    p.add_argument("--out", default=str(ROOT / "evidence"))
    args = p.parse_args(argv)
    pack, verdict = build_pack(args.control, args.period, args.collected, args.out)
    print(f"Wrote {pack}/")
    for f in ("summary.md", "items/*.json", "exceptions.md"):
        print(f"  {f}")
    print(verdict)


if __name__ == "__main__":
    sys.exit(main())
