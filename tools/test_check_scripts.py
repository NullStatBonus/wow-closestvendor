"""The check scripts must pass on a good copy of the addon and fail, with a clear message, on each kind of damage."""
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VANILLA = "ClosestVendor/ClosestVendor_Vanilla.toc"
CAMELOT = "ClosestVendor/ClosestVendor_Camelot.toc"


class Checks(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.dir, True)
        shutil.copytree(os.path.join(ROOT, "ClosestVendor"), os.path.join(self.dir, "ClosestVendor"))
        shutil.copy(os.path.join(ROOT, "CHANGELOG.md"), self.dir)

    def run_script(self, name, *args):
        r = subprocess.run(["sh", os.path.join(ROOT, "tools", name), *args], cwd=self.dir,
                           capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr

    def path(self, rel):
        return os.path.join(self.dir, rel)

    def edit(self, rel, old, new):
        with open(self.path(rel)) as f:
            text = f.read()
        self.assertIn(old, text)
        with open(self.path(rel), "w") as f:
            f.write(text.replace(old, new, 1))

    def test_good_copy_passes_every_check(self):
        for toc in (VANILLA, CAMELOT):
            self.assertEqual(self.run_script("check-toc.sh", toc)[0], 0, toc)
        self.assertEqual(self.run_script("check-tocs-match.sh")[0], 0)
        self.assertEqual(self.run_script("check-version.sh")[0], 0)

    def test_toc_listing_a_missing_file_fails(self):
        self.edit(CAMELOT, "Core.lua\n", "Core.lua\nNotThere.lua\n")
        code, out = self.run_script("check-toc.sh", CAMELOT)
        self.assertNotEqual(code, 0)
        self.assertIn("MISSING  NotThere.lua", out)

    def test_lua_file_missing_from_the_toc_fails(self):
        with open(self.path("ClosestVendor/Forgotten.lua"), "w") as f:
            f.write("-- nobody lists me\n")
        code, out = self.run_script("check-toc.sh", CAMELOT)
        self.assertNotEqual(code, 0)
        self.assertIn("UNLISTED Forgotten.lua", out)

    def test_the_example_locale_may_stay_unlisted(self):
        code, out = self.run_script("check-toc.sh", CAMELOT)
        self.assertEqual(code, 0)
        self.assertNotIn("Example.lua", out)

    def test_toc_without_an_interface_line_fails(self):
        self.edit(VANILLA, "## Interface: 11509\n", "")
        code, out = self.run_script("check-toc.sh", VANILLA)
        self.assertNotEqual(code, 0)
        self.assertIn("MISSING  ## Interface line", out)

    def test_tocs_listing_different_files_fail(self):
        self.edit(VANILLA, "Log.lua\n", "")
        code, out = self.run_script("check-tocs-match.sh")
        self.assertNotEqual(code, 0)
        self.assertIn("DIFFERS  ClosestVendor_Vanilla.toc", out)

    def test_tocs_may_differ_in_their_header(self):
        # Interface numbers differ by design.
        code, _ = self.run_script("check-tocs-match.sh")
        self.assertEqual(code, 0)

    def test_tocs_with_different_versions_fail(self):
        self.edit(VANILLA, "## Version: 0.1.0", "## Version: 0.1.1")
        code, out = self.run_script("check-version.sh")
        self.assertNotEqual(code, 0)
        self.assertIn("VERSION", out)

    def test_tag_must_equal_the_version(self):
        self.assertEqual(self.run_script("check-version.sh", "v0.1.0")[0], 0)
        self.assertEqual(self.run_script("check-version.sh", "0.1.0")[0], 0)
        code, out = self.run_script("check-version.sh", "v0.2.0")
        self.assertNotEqual(code, 0)
        self.assertIn("TAG", out)

    def test_changelog_must_have_the_version(self):
        self.edit("CHANGELOG.md", "## 0.1.0", "## 0.0.9")
        code, out = self.run_script("check-version.sh")
        self.assertNotEqual(code, 0)
        self.assertIn("CHANGELOG", out)

    def test_missing_changelog_fails(self):
        os.remove(self.path("CHANGELOG.md"))
        self.assertNotEqual(self.run_script("check-version.sh")[0], 0)


if __name__ == "__main__":
    unittest.main()
