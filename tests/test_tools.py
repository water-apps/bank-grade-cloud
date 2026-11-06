"""Run: python3 -m unittest discover -s tests -v"""
import datetime as dt
import hashlib
import json
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "evidence"))
sys.path.insert(0, str(ROOT / "tools" / "access_review"))

import access_review  # noqa: E402
import evidence  # noqa: E402

APPENDIX_A = ["ACC-01", "ACC-02", "DATA-01", "NET-01", "NET-02", "IAM-01", "IAM-02", "IAM-03",
              "KEY-01", "SEC-01", "CERT-01", "K8S-01", "K8S-02", "CHG-01", "LOG-01", "MON-01",
              "BCK-01", "BCK-02", "SUP-01", "COST-01"]


class RegisterTest(unittest.TestCase):
    def setUp(self):
        self.reg = evidence.load_register()

    def test_matches_appendix_a(self):
        self.assertEqual(list(self.reg), APPENDIX_A)

    def test_every_control_has_assertions_and_owner(self):
        for cid, c in self.reg.items():
            self.assertTrue(c["assertions"], cid)
            self.assertTrue(c["owner"], cid)
            for a in c["assertions"]:
                self.assertTrue(a["id"].startswith(cid + "."), a["id"])
                for layer in ("prevent", "detect", "test", "source"):
                    self.assertIn(layer, a, a["id"])

    def test_referenced_repo_files_exist(self):
        for c in self.reg.values():
            for a in c["assertions"]:
                for layer in ("prevent", "test"):
                    v = a[layer]
                    if re.search(r"\.(tf|rego|json|yaml|py)$", v):
                        self.assertTrue((ROOT / v).exists(), f"{a['id']} {layer}: {v}")


class PeriodTest(unittest.TestCase):
    def test_quarters(self):
        self.assertEqual(evidence.parse_period("2026-Q1"), (dt.date(2026, 1, 1), dt.date(2026, 3, 31)))
        self.assertEqual(evidence.parse_period("2026-Q3"), (dt.date(2026, 7, 1), dt.date(2026, 9, 30)))
        self.assertEqual(evidence.parse_period("2026-Q4"), (dt.date(2026, 10, 1), dt.date(2026, 12, 31)))

    def test_bad_period(self):
        with self.assertRaises(ValueError):
            evidence.parse_period("2026-09")


class EvidencePackTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_data01_pack_held_with_exception(self):
        pack, verdict = evidence.build_pack("DATA-01", "2026-Q3", out=self.tmp)
        self.assertIn("approved exceptions", verdict)
        for name in ("summary.md", "exceptions.md", "items/DATA-01.1.json", "items/DATA-01.2.json", "items/DATA-01.3.json"):
            self.assertTrue((pack / name).exists(), name)
        item = json.loads((pack / "items/DATA-01.1.json").read_text())
        self.assertEqual(item["period"], "2026-07-01/2026-09-30")
        self.assertEqual(item["result"], "compliant")
        self.assertEqual(item["scope"]["accounts_checked"], 214)
        raw = pack / item["raw"]
        self.assertEqual(item["sha256"], hashlib.sha256(raw.read_bytes()).hexdigest())
        self.assertIn("marketing-public-images", (pack / "exceptions.md").read_text())

    def test_tampered_raw_no_longer_matches(self):
        pack, _ = evidence.build_pack("DATA-01", "2026-Q3", out=self.tmp)
        item = json.loads((pack / "items/DATA-01.1.json").read_text())
        raw = pack / item["raw"]
        raw.write_text(raw.read_text().replace('"non_compliant": 0', '"non_compliant": 5', 1))
        self.assertNotEqual(item["sha256"], evidence.sha256(raw))

    def test_missing_evidence_is_flagged(self):
        pack, verdict = evidence.build_pack("NET-01", "2026-Q3", out=self.tmp)
        self.assertTrue(verdict.startswith("Not fully evidenced"))
        self.assertEqual(json.loads((pack / "items/NET-01.1.json").read_text())["result"], "missing")
        self.assertIn("none collected", (pack / "summary.md").read_text())

    def test_partial_restore_testing_needs_attention(self):
        pack, verdict = evidence.build_pack("BCK-02", "2026-Q3", out=self.tmp)
        self.assertTrue(verdict.startswith("Not fully evidenced"))
        self.assertIn("partial (attention)", (pack / "summary.md").read_text())

    def test_expired_exception_is_not_in_force(self):
        ex = [{"control": "DATA-01.3", "approved": "2025-01-01", "expires": "2025-12-31"}]
        self.assertEqual(evidence.active_exceptions(ex, "DATA-01", dt.date(2026, 7, 1), dt.date(2026, 9, 30)), [])

    def test_unknown_control(self):
        with self.assertRaises(KeyError):
            evidence.build_pack("NOPE-01", "2026-Q3", out=self.tmp)


class AccessReviewTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.data = json.loads((ROOT / "samples/identity/assignments.json").read_text())

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_one_review_per_account(self):
        paths = access_review.build_reviews(self.data, "2026-Q3", dt.date(2026, 10, 1), self.tmp)
        self.assertEqual(sorted(p.name for p in paths), ["claims-prod.md", "payments-prod.md"])

    def test_stale_and_never_used_marked_for_removal(self):
        access_review.build_reviews(self.data, "2026-Q3", dt.date(2026, 10, 1), self.tmp)
        text = (self.tmp / "2026-Q3" / "payments-prod.md").read_text()
        self.assertRegex(text, r"r\.patel .*Remove \(unused 143 days\)")
        self.assertRegex(text, r"m\.lee .*Remove \(never used\)")
        self.assertRegex(text, r"j\.smith .*\| Keep \|")
        self.assertNotIn("t.brown", text)


if __name__ == "__main__":
    unittest.main()
