# TASK_STATE - <device name>

Started: <date>. Re-read this file first after any context summary. Other devices live in sibling folders.

## Facts
- Device: <model> (<ro.product.device>, board, build). Network: <Wi-Fi/Ethernet/USB Ethernet>. USB: <...>.
- Use: <family room / meeting room / break room>. Owner OK to change it: <yes / who>.
- Connection: <IP>, <5555 | Wireless debugging pair/connect ports>. Upstream commit: <sha>.
- Reference example(s): <cleanyourtv examples/...>.

## User answers
- Keep: <apps / features>.  Disable: <...>.  Dock: <apps in order>.  Private DNS: <yes/no, router?>.

## Acceptance criteria (observed behaviour, not "the command said Success")
1. backup/ complete and non-empty; restore.sh written before the first disable and tested on one package.
2. Every disabled package is in lists/debloat.txt; none is core or must-keep.
3. After each batch: Home, Settings, an app (and on a TV: sources drawer, Live TV, HDMI) work; no new crashes.
4. Launcher is Home (mFocusedApp after HOME), D-pad behaves, real remote buttons pressed by the user work.
5. Reboot: disabled list unchanged (re-enablers noted), Home/keys/Wi-Fi/DNS still right.
6. README, restore.sh, install.sh delivered; install.sh ran once end to end.
7. ADB closed: debugging off, authorisations revoked, reboot, port_check.py proves the ADB ports refuse.

## Progress
- [ ] Workspace + upstream clone
- [ ] Connect
- [ ] Backup
- [ ] Preferences
- [ ] Batches
- [ ] Launcher
- [ ] Reboot check
- [ ] Deliverables
- [ ] Close ADB
