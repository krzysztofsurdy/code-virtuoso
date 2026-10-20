import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPTS))

import validate_common as vc


class PlainScalarProblemTest(unittest.TestCase):
    def test_plain_value_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem("Reviews code. Use when merging."))

    def test_colon_inside_word_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem("see http://example.com and a:b"))

    def test_hash_without_leading_space_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem("issue#12 and C#"))

    def test_colon_space_is_an_error(self):
        self.assertIn("quote", vc.plain_scalar_problem("Scrum fundamentals: roles and events"))

    def test_trailing_colon_is_an_error(self):
        self.assertIsNotNone(vc.plain_scalar_problem("Steps for the release:"))

    def test_space_hash_is_an_error(self):
        self.assertIsNotNone(vc.plain_scalar_problem("Use for tickets #12 and more"))

    def test_double_quoted_value_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem('"Scrum fundamentals: roles"'))

    def test_single_quoted_value_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem("'Scrum fundamentals: roles'"))

    def test_indicator_characters_at_start_are_errors(self):
        for first in "[]{}&*!%@`":
            with self.subTest(first=first):
                self.assertIsNotNone(vc.plain_scalar_problem(f"{first}value"))

    def test_block_scalar_indicator_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem(">-"))
        self.assertIsNone(vc.plain_scalar_problem("|"))

    def test_empty_value_is_fine(self):
        self.assertIsNone(vc.plain_scalar_problem(""))


class FrontmatterYamlProblemsTest(unittest.TestCase):
    def problems(self, body):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "SKILL.md"
            path.write_text(body, encoding="utf-8")
            return vc.frontmatter_yaml_problems(path)

    def test_valid_frontmatter_has_no_problems(self):
        body = '---\nname: x\ndescription: "A: b"\ntools: Read, Grep\nskills:\n  - a: b is not checked\n---\n\nBody: text # here\n'
        self.assertEqual(self.problems(body), [])

    def test_unquoted_colon_is_reported_with_key_and_line(self):
        problems = self.problems("---\nname: x\ndescription: Scrum: roles\n---\n")
        self.assertEqual(len(problems), 1)
        self.assertIn("'description'", problems[0])
        self.assertIn("line 3", problems[0])

    def test_indented_continuation_lines_are_ignored(self):
        body = "---\nname: x\ndescription: >\n  Folded text: with colon\n---\n"
        self.assertEqual(self.problems(body), [])

    def test_body_after_frontmatter_is_ignored(self):
        self.assertEqual(self.problems("---\nname: x\n---\nkey: a: b\n"), [])

    def test_missing_frontmatter_has_no_problems(self):
        self.assertEqual(self.problems("# Title\n"), [])


if __name__ == "__main__":
    unittest.main()
