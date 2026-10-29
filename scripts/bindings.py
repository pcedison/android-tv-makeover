#!/usr/bin/env python3
"""Show which other processes hold a binding to a package's services.

    TV_HOST=<ip> UPSTREAM=<cleanyourtv> scripts/bindings.py candeebug eum amazonalexa
    scripts/bindings.py --file services.txt candeebug          # from a saved `dumpsys activity services`

A package whose service is bound by the TV app, settings or the power manager is load-bearing:
give it its own batch and test harder, or keep it. Only running services show up, so an empty
answer means "not bound right now", not "safe".
"""
import os
import re
import subprocess
import sys


def dump_services() -> str:
    upstream = os.environ.get("UPSTREAM")
    if not upstream or not os.environ.get("TV_HOST"):
        sys.exit("set TV_HOST and UPSTREAM, or pass --file <saved dumpsys activity services>")
    py = os.path.join(upstream, "tools", "venv", "bin", "python")
    tv = os.path.join(upstream, "tools", "tv.py")
    return subprocess.run([py, tv, "dumpsys activity services"], capture_output=True,
                          text=True, check=True).stdout


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 2
    if argv[0] == "--file":
        with open(argv[1], errors="ignore") as fh:
            text = fh.read()
        targets = argv[2:]
    else:
        text = dump_services()
        targets = argv
    if not targets:
        sys.exit("name at least one package or package substring")

    found = False
    for block in re.split(r"\n  \* ServiceRecord\{", text)[1:]:
        head = block.split("\n", 1)[0]
        m = re.search(r"u0 (\S+)\}", head)
        if not m:
            continue
        comp = m.group(1)
        if not any(t in comp for t in targets):
            continue
        own = comp.split("/")[0]
        clients = sorted({c for c in re.findall(
            r"Client AppBindRecord\{\S+ ProcessRecord\{\S+ \d+:([^/]+)/", block)
            if c.split(":")[0] != own})
        found = True
        print(f"{comp}\n    bound by: {', '.join(clients) if clients else '-'}")
    if not found:
        print("no running service matched: " + ", ".join(targets))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
