#!/usr/bin/env python3
"""Prove network ADB is closed while the device is online.

    scripts/port_check.py <ip> --closed 5555,<debug-port> --alive 6466 [--wait 240]

Waits up to --wait seconds for one --alive port to accept a connection (the device is up), then
requires every --closed port to answer "connection refused". A timeout or "host down" on a closed
port proves nothing (the device may be off or elsewhere), so it fails the check.
Exit 0 = proven closed, 1 = an ADB port is open or unproven, 2 = device never came online.
Pick an alive port that this device really serves: 6466 (Android TV remote service), 8009 (Cast)
or 1925/1926 (Philips JointSpace), checked while ADB was still on.
"""
import argparse
import socket
import sys
import time


def probe(host, port, timeout=3.0):
    s = socket.socket()
    s.settimeout(timeout)
    try:
        s.connect((host, port))
        return "OPEN"
    except ConnectionRefusedError:
        return "REFUSED"
    except socket.timeout:
        return "TIMEOUT"
    except OSError as e:
        return f"UNREACHABLE ({e.strerror or e})"
    finally:
        s.close()


def ports(text):
    return [int(p) for p in text.split(",") if p.strip()]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("host")
    ap.add_argument("--closed", required=True, help="comma-separated ADB ports that must refuse")
    ap.add_argument("--alive", required=True, help="comma-separated ports, one of which must be open")
    ap.add_argument("--wait", type=int, default=240)
    a = ap.parse_args()

    alive = ports(a.alive)
    t0 = time.time()
    up = None
    while time.time() - t0 <= a.wait:
        for p in alive:
            if probe(a.host, p) == "OPEN":
                up = p
                break
        if up:
            break
        time.sleep(5)
    if not up:
        print(f"device not reachable on {alive} within {a.wait}s: cannot prove anything")
        return 2
    print(f"online: port {up} open after {int(time.time() - t0)}s")

    ok = True
    for p in ports(a.closed):
        r = probe(a.host, p)
        print(f"{p}: {r}")
        ok &= r == "REFUSED"
    print("ADB closed: proven" if ok else "ADB closed: NOT proven")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
