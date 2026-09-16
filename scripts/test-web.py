#!/usr/bin/env python3
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile


with tempfile.TemporaryDirectory(prefix="dsh-web-test-") as home:
    env = {**os.environ, "HOME": home, "DSH_HOME": str(Path(home) / ".dsh")}
    process = subprocess.Popen(
        [sys.argv[1], "web", "--no-open", "--host", "127.0.0.1", "--port", "0"],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        start_new_session=True,
    )
    survived = False
    try:
        output, _ = process.communicate(timeout=15)
    except subprocess.TimeoutExpired:
        survived = True
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                output, _ = process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                output, _ = process.communicate()

    print(re.sub(r"token=[^\s]+", "token=<REDACTED>", output))
    # The URL is printed before HMR initializes, so readiness alone misses this crash.
    if not survived or "dsh web: http://127.0.0.1:" not in output:
        sys.exit("FAIL: web profile did not remain running after startup")
    print("PASS: web profile remained running for 15 seconds")
