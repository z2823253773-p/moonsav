"""The actual acceptance entry must identify its execution environment honestly."""
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import unittest


class VerifyContextTest(unittest.TestCase):
    def test_entry_records_actual_platform_and_ci_run_instead_of_mac_only_text(self):
        root = Path(__file__).resolve().parents[1]
        env = dict(os.environ, GITHUB_ACTIONS="true", RUNNER_OS="synthetic-runner",
                   GITHUB_SERVER_URL="https://github.com", GITHUB_REPOSITORY="example/ci-proof",
                   GITHUB_RUN_ID="123")
        env.pop("_", None)
        with tempfile.TemporaryDirectory(prefix="moonsav-context-") as output:
            result = subprocess.run([sys.executable, "tools/verify.py", "--case", "AC01",
                                     "--output", output], cwd=root, env=env,
                                    capture_output=True, text=True, timeout=90)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            report = json.loads((Path(output) / "summary.json").read_text())
            context = report.get("execution_context", {})
            self.assertTrue(context.get("github_actions"), "CI execution was reported as unrun")
            self.assertEqual(context["system"], platform.system())
            self.assertEqual(context["machine"], platform.machine())
            self.assertEqual(context["runner_os"], "synthetic-runner")
            self.assertEqual(context["run_url"], "https://github.com/example/ci-proof/actions/runs/123")
            self.assertIn(platform.system(), report["acceptance_scope"])
            self.assertEqual(report["remote_ci"], "this_job_executed")


if __name__ == "__main__":
    unittest.main()
