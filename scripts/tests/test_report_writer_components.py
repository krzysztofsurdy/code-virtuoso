import re
import unittest
from pathlib import Path

REFERENCES = Path(__file__).resolve().parents[2] / "skills/tools/report-writer/references"
ICON_CLASS = re.compile(r"^bi(-[\w-]+)?$")


def documented_classes():
    markdown = (REFERENCES / "components.md").read_text(encoding="utf-8")
    classes = set()
    for block in re.findall(r"```html\n(.*?)```", markdown, re.S):
        for attribute in re.findall(r'class="([^"]*)"', block):
            classes.update(attribute.split())
    return {name for name in classes if not ICON_CLASS.match(name)}


def styled_classes():
    template = (REFERENCES / "template.html").read_text(encoding="utf-8")
    css = " ".join(re.findall(r"<style>(.*?)</style>", template, re.S))
    return set(re.findall(r"\.([A-Za-z_][\w-]*)", css))


class ComponentsStyledTest(unittest.TestCase):
    def test_components_md_documents_classes(self):
        self.assertIn("card", documented_classes())

    def test_every_documented_class_has_a_selector_in_the_template(self):
        self.assertEqual(sorted(documented_classes() - styled_classes()), [])


if __name__ == "__main__":
    unittest.main()
