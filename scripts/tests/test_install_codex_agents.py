import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "install-codex-agents.sh"


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.repo = self.tmp / "repo"
        self.home = self.tmp / "home"
        self.cwd = self.tmp / "project"
        for d in (self.repo / "scripts", self.home, self.cwd):
            d.mkdir(parents=True)
        shutil.copy(SCRIPT, self.repo / "scripts" / SCRIPT.name)
        self.write(self.repo / "codex/agents/scout.toml", "name = 'scout'\n")
        self.write(self.repo / "codex/agents/writer.toml", "name = 'writer'\n")
        self.write(self.repo / "roles/architect/adr.md", "adr v1\n")
        self.write(self.repo / "roles/README.md", "roles readme\n")
        self.write(self.repo / "skills/knowledge/refactoring/references/long-method.md", "lm\n")
        self.write(self.repo / "skills/knowledge/other/references/unused.md", "unused\n")
        self.write(
            self.repo / "agents/refactor-scout.md",
            "Read `skills/knowledge/refactoring/references/<technique>.md` on demand.\n",
        )
        self.cv_home = self.home / ".codex" / "code-virtuoso"

    def write(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def run_script(self, *args, extra_env=None):
        env = {**os.environ, "HOME": str(self.home)}
        env.pop("CODE_VIRTUOSO_HOME", None)
        env.update(extra_env or {})
        return subprocess.run(
            ["bash", str(self.repo / "scripts" / SCRIPT.name), *args],
            capture_output=True, text=True, env=env, cwd=self.cwd,
        )

    def test_user_install_copies_agents_roles_and_references(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / ".codex/agents/scout.toml").read_text(), "name = 'scout'\n")
        self.assertTrue((self.home / ".codex/agents/writer.toml").exists())
        self.assertEqual((self.cv_home / "roles/architect/adr.md").read_text(), "adr v1\n")
        self.assertTrue((self.cv_home / "skills/knowledge/refactoring/references/long-method.md").exists())
        self.assertFalse((self.cv_home / "skills/knowledge/other").exists())
        self.assertIn("scout.toml", result.stdout)
        self.assertIn("installed", result.stdout)

    def test_project_flag_installs_agents_into_project(self):
        result = self.run_script("--project")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.cwd / ".codex/agents/scout.toml").exists())
        self.assertFalse((self.home / ".codex/agents/scout.toml").exists())
        self.assertTrue((self.cv_home / "roles/architect/adr.md").exists())

    def test_code_virtuoso_home_override(self):
        custom = self.tmp / "custom"
        result = self.run_script(extra_env={"CODE_VIRTUOSO_HOME": str(custom)})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((custom / "roles/architect/adr.md").exists())
        self.assertFalse(self.cv_home.exists())

    def test_rerun_is_idempotent(self):
        self.run_script()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unchanged", result.stdout)
        self.assertNotIn("installed", result.stdout)

    def test_upgrade_updates_untouched_files(self):
        self.run_script()
        self.write(self.repo / "roles/architect/adr.md", "adr v2\n")
        result = self.run_script()
        self.assertEqual((self.cv_home / "roles/architect/adr.md").read_text(), "adr v2\n")
        self.assertIn("updated", result.stdout)

    def test_locally_modified_file_is_kept(self):
        self.run_script()
        mine = self.home / ".codex/agents/scout.toml"
        mine.write_text("name = 'mine'\n")
        self.write(self.repo / "codex/agents/scout.toml", "name = 'scout2'\n")
        result = self.run_script()
        self.assertEqual(mine.read_text(), "name = 'mine'\n")
        self.assertIn("skipped", result.stdout)
        self.assertIn("--force", result.stdout)

    def test_existing_unmanaged_file_is_kept(self):
        mine = self.home / ".codex/agents/scout.toml"
        self.write(mine, "name = 'user-made'\n")
        result = self.run_script()
        self.assertEqual(mine.read_text(), "name = 'user-made'\n")
        self.assertIn("skipped", result.stdout)

    def test_force_overwrites_modified_file(self):
        self.run_script()
        mine = self.home / ".codex/agents/scout.toml"
        mine.write_text("name = 'mine'\n")
        result = self.run_script("--force")
        self.assertEqual(mine.read_text(), "name = 'scout'\n")
        self.assertIn("overwritten", result.stdout)

    def test_force_then_normal_run_is_unchanged(self):
        self.run_script()
        (self.home / ".codex/agents/scout.toml").write_text("x\n")
        self.run_script("--force")
        result = self.run_script()
        self.assertNotIn("skipped", result.stdout)

    def test_spaces_in_paths(self):
        spaced = self.tmp / "my home"
        spaced.mkdir()
        self.home = spaced
        self.cv_home = spaced / ".codex" / "code-virtuoso"
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((spaced / ".codex/agents/scout.toml").exists())
        result = self.run_script()
        self.assertIn("unchanged", result.stdout)

    def test_unknown_flag_fails(self):
        result = self.run_script("--bogus")
        self.assertNotEqual(result.returncode, 0)

    def test_missing_generated_agents_fails(self):
        shutil.rmtree(self.repo / "codex")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("build-codex-agents.py", result.stderr)


if __name__ == "__main__":
    unittest.main()
