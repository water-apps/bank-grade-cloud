"""Generate quarterly access reviews from the platform (Chapter 6).

    python3 tools/access_review/access_review.py --quarter 2026-Q3 --as-of 2026-10-01

Reads who can hold which role in which production account, through which
group, and when they last used it, then writes one review per account in the
Appendix C format. Access unused for 90 days or more is marked for removal,
so the owner starts from a suggestion instead of a blank sheet.
"""
import argparse
import datetime as dt
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STALE_DAYS = 90


def suggestion(last_used, as_of):
    if last_used is None:
        return "Remove (never used)"
    age = (as_of - dt.date.fromisoformat(last_used)).days
    return f"Remove (unused {age} days)" if age >= STALE_DAYS else "Keep"


def build_reviews(data, quarter, as_of, out):
    out = Path(out) / quarter
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for account, meta in sorted(data["accounts"].items()):
        rows = [a for a in data["assignments"] if a["account"] == account]
        lines = [
            f"# Access review: {account}, {quarter}",
            f"Generated: {as_of.isoformat()}, by tools/access_review",
            f"Owner: {meta['owner']}",
            "",
            "| Person | Role | Granted through | Last used | Suggested | Decision | Reason |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
        for a in sorted(rows, key=lambda r: r["person"]):
            lines.append(f"| {a['person']} | {a['role']} | {a['group']} | {a['last_used'] or 'never'} | "
                         f"{suggestion(a['last_used'], as_of)} | Keep / Remove | |")
        lines += ["", "Removals completed: <date>, change <reference>",
                  "Signed off by owner: <name>, <date>", ""]
        path = out / f"{account}.md"
        path.write_text("\n".join(lines))
        written.append(path)
    return written


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--quarter", required=True)
    p.add_argument("--as-of", required=True, type=dt.date.fromisoformat)
    p.add_argument("--input", default=str(ROOT / "samples" / "identity" / "assignments.json"))
    p.add_argument("--out", default=str(ROOT / "reviews"))
    args = p.parse_args(argv)
    data = json.loads(Path(args.input).read_text())
    for path in build_reviews(data, args.quarter, args.as_of, args.out):
        print(f"Wrote {path}")


if __name__ == "__main__":
    sys.exit(main())
