import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPTS))

try:
    import tomllib
except ImportError:  # Python below 3.11
    tomllib = None

spec = importlib.util.spec_from_file_location("build_codex_agents", SCRIPTS / "build-codex-agents.py")
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)

READ_ONLY = """---
name: scout
description: Scans code. Delegate when you need a "quick" look at C:\\paths.
tools: Read, Grep, Glob, Bash
---

# Scout

Read `${CLAUDE_PLUGIN_ROOT}/roles/scout/guide.md` first.
Backslash \\n and quote ' stay as written.
"""

WRITER = """---
name: writer
description: Writes things. Use when asked.
tools: Read, Edit, Write, Bash
---

# Writer

Do the work.
"""

MEMORY_WRITER = """---
name: planner
description: Plans and records decisions. Use when asked.
tools: Read, Grep, Glob, Bash
memory: project
---

# Planner

Write the decision record.
"""

TRIPLE = """---
name: tricky
description: Has triple quotes.
tools: Read
---

Body with ''' inside and a trailing quote'
"""


def parse(text):
    return tomllib.loads(text)


@unittest.skipIf(tomllib is None, "tomllib needs Python 3.11+")
class RenderTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.agents = self.tmp / "agents"
        self.agents.mkdir()

    def write(self, name, text):
        path = self.agents / f"{name}.md"
        path.write_text(text, encoding="utf-8")
        return path

    def test_required_fields_and_no_model(self):
        data = parse(build.render_agent(self.write("scout", READ_ONLY)))
        self.assertEqual(data["name"], "scout")
        self.assertIn('"quick"', data["description"])
        self.assertIn("C:\\paths", data["description"])
        self.assertNotIn("model", data)
        self.assertEqual(set(data), {"name", "description", "developer_instructions"})

    def test_header_comment(self):
        text = build.render_agent(self.write("scout", READ_ONLY))
        self.assertTrue(text.startswith("# generated from agents/scout.md, do not edit\n"))

    def test_read_only_agent_gets_no_modify_sentence(self):
        data = parse(build.render_agent(self.write("scout", READ_ONLY)))
        self.assertTrue(data["developer_instructions"].startswith("Do not modify files."))

    def test_writer_agent_has_no_sentence(self):
        data = parse(build.render_agent(self.write("writer", WRITER)))
        self.assertNotIn("Do not modify files.", data["developer_instructions"])

    def test_memory_agent_is_write_capable_so_no_sentence(self):
        data = parse(build.render_agent(self.write("planner", MEMORY_WRITER)))
        self.assertNotIn("Do not modify files.", data["developer_instructions"])

    def test_plugin_root_rewritten_with_home_note(self):
        body = parse(build.render_agent(self.write("scout", READ_ONLY)))["developer_instructions"]
        self.assertNotIn("CLAUDE_PLUGIN_ROOT", body)
        self.assertIn("${CODE_VIRTUOSO_HOME}/roles/scout/guide.md", body)
        self.assertIn("~/.codex/code-virtuoso", body.split("# Scout")[0])

    def test_no_home_note_without_references(self):
        body = parse(build.render_agent(self.write("writer", WRITER)))["developer_instructions"]
        self.assertNotIn("CODE_VIRTUOSO_HOME", body)

    def test_body_preserved_with_literal_string(self):
        text = build.render_agent(self.write("scout", READ_ONLY))
        self.assertIn("'''", text)
        body = parse(text)["developer_instructions"]
        self.assertIn("Backslash \\n and quote ' stay as written.", body)
        self.assertNotIn("name: scout", body)

    def test_triple_quote_falls_back_to_basic_string(self):
        text = build.render_agent(self.write("tricky", TRIPLE))
        body = parse(text)["developer_instructions"]
        self.assertIn("Body with ''' inside and a trailing quote'", body)

    def test_missing_frontmatter_raises(self):
        path = self.write("bad", "no frontmatter\n")
        with self.assertRaises(ValueError):
            build.render_agent(path)


@unittest.skipIf(tomllib is None, "tomllib needs Python 3.11+")
class BuildAndCheckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.agents = self.tmp / "agents"
        self.out = self.tmp / "codex" / "agents"
        self.agents.mkdir()
        (self.agents / "scout.md").write_text(READ_ONLY, encoding="utf-8")
        (self.agents / "writer.md").write_text(WRITER, encoding="utf-8")

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPTS / "build-codex-agents.py"),
             "--agents-dir", str(self.agents), "--out-dir", str(self.out), *args],
            capture_output=True, text=True,
        )

    def test_build_writes_one_toml_per_agent(self):
        result = self.run_cli()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted(p.name for p in self.out.glob("*.toml")), ["scout.toml", "writer.toml"])
        for path in self.out.glob("*.toml"):
            tomllib.loads(path.read_text(encoding="utf-8"))

    def test_check_passes_when_current(self):
        self.run_cli()
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_check_fails_when_missing(self):
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("scout.toml", result.stdout)

    def test_check_fails_when_agent_changed(self):
        self.run_cli()
        (self.agents / "writer.md").write_text(WRITER + "More.\n", encoding="utf-8")
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("writer.toml", result.stdout)

    def test_check_fails_on_stale_file(self):
        self.run_cli()
        (self.out / "gone.toml").write_text("name = 'gone'\n", encoding="utf-8")
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("gone.toml", result.stdout)

    def test_build_removes_stale_file(self):
        self.run_cli()
        (self.out / "gone.toml").write_text("name = 'gone'\n", encoding="utf-8")
        self.run_cli()
        self.assertFalse((self.out / "gone.toml").exists())

    def test_check_does_not_write(self):
        self.run_cli("--check")
        self.assertFalse(self.out.exists())


if __name__ == "__main__":
    unittest.main()
