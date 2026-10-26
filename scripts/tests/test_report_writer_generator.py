import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

GENERATOR = (
    Path(__file__).resolve().parents[2]
    / "skills/tools/report-writer/references/data-explorer-generator.py"
)


class GeneratorTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.config = self.tmp / "config.json"
        self.config.write_text(json.dumps({"title": "T"}), encoding="utf-8")
        self.out = self.tmp / "report.html"

    def generate(self, csv_text):
        source = self.tmp / "data.csv"
        source.write_text(csv_text, encoding="utf-8")
        return subprocess.run(
            [sys.executable, str(GENERATOR), "--csv", str(source), "--out", str(self.out), "--config", str(self.config)],
            capture_output=True,
            text=True,
        )

    def embedded(self, script_id):
        page = self.out.read_text(encoding="utf-8")
        match = re.search(rf'<script id="{script_id}" type="application/json">(.*?)</script>', page, re.S)
        self.assertIsNotNone(match)
        return json.loads(match.group(1))

    def test_cell_with_closing_script_tag_stays_inside_the_data_block(self):
        result = self.generate('name,note\nx,"</script><b>a & b</b>"\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.embedded("data-records"), [{"name": "x", "note": "</script><b>a & b</b>"}])

    def test_short_row_is_padded_with_empty_cells(self):
        result = self.generate("a,b,c\n1,2,3\n4\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.embedded("data-records")[1], {"a": "4", "b": "", "c": ""})

    def test_row_with_more_cells_than_header_fails_with_line_number(self):
        result = self.generate("a,b\n1,2\n3,4,5\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("line 3", result.stderr)
        self.assertFalse(self.out.exists())


if __name__ == "__main__":
    unittest.main()
