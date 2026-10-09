#!/usr/bin/env python3
"""Removes a temporary test hook from AppDelegate.swift.

A hook starts at a line holding `// TEMPORARY TEST HOOK` and ends at the line
holding `// END TEST HOOK`; both lines go with it. It refuses when either marker
is missing or there is more than one hook. On 6 October 2026 a hook was cut at
the first line after it that looked like its end, which also stood inside the
hook, and the broken file was pushed.
"""
import pathlib
import sys

path = pathlib.Path(__file__).resolve().parent.parent / "Sources/Pine/App/AppDelegate.swift"
lines = path.read_text().split("\n")
starts = [i for i, l in enumerate(lines) if "// TEMPORARY TEST HOOK" in l]
ends = [i for i, l in enumerate(lines) if "// END TEST HOOK" in l]
if not starts and not ends:
    print("no test hook")
    sys.exit(0)
if len(starts) != 1 or len(ends) != 1 or ends[0] < starts[0]:
    print(f"refusing: {len(starts)} start and {len(ends)} end markers")
    sys.exit(1)
del lines[starts[0]:ends[0] + 1]
# The hook went in with a blank line after it: take one away, so the file is
# as it was and a later hook can find the same lines again.
if 0 < starts[0] < len(lines) and lines[starts[0]] == "" and lines[starts[0] - 1] == "":
    del lines[starts[0]]
path.write_text("\n".join(lines))
print(f"removed lines {starts[0] + 1} to {ends[0] + 1}")
