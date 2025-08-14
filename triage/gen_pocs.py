#!/usr/bin/env python

import os
import sys
import hashlib
import shutil
import argparse

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crashing</title>
</head>

<body>
    <script>
        // REPLACE_ME
    </script>
</body>

</html>
"""


def main(crashes_dir="./triage/crashes", pocs_dir="./triage/pocs"):
    print(f"Reading crashes from {crashes_dir}")

    for file in os.listdir(crashes_dir):
        if any(
            [
                file.startswith("."),
                file.endswith(".txt"),
                file.endswith(".backtrace_one"),
                file.endswith(".backtrace_full"),
            ]
        ):
            continue

        print(f"Crash file {file}")

        m = hashlib.sha256()
        m.update(file.encode("utf-8"))

        crash_id = m.hexdigest()
        out_dir = os.path.join(pocs_dir, crash_id)
        os.makedirs(out_dir, exist_ok=True)

        crash_file_path = os.path.join(crashes_dir, file)
        print(f"Opening crash file {crash_file_path}")

        with open(crash_file_path, "r") as f:
            crash_script = f.read()

            poc_body = HTML_TEMPLATE.replace("// REPLACE_ME", crash_script)

            with open(os.path.join(pocs_dir, crash_id, "index.html"), "w") as g:
                g.write(poc_body)

        crash_poc_dir = os.path.join(crashes_dir, file)
        print(f"Saving poc in {crash_poc_dir}")

        shutil.copy(crash_poc_dir, out_dir)
        shutil.copy(crash_poc_dir + ".backtrace_full", out_dir)
        shutil.copy(crash_poc_dir + ".backtrace_one", out_dir)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        prog="scpg",
        description="Servo crash pocs generator",
    )
    parser.add_argument(
        "-i",
        "--crashes-dir",
        default="./triage/crashes",
        type=str,
        help="Where to look for crash files and their backtraces",
    )
    parser.add_argument(
        "-o",
        "--pocs-dir",
        default="./triage/pocs",
        type=str,
        help="Where to save the HTML poc files",
    )
    args = parser.parse_args()

    main(crashes_dir=args.crashes_dir, pocs_dir=args.pocs_dir)
