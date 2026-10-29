# Getting ADB up

Pick the path by what the device offers. In every case, tell the user before a prompt will appear on
the TV ("Allow USB debugging?"): they must be in front of it to accept, and the prompt times out.

## Find the device

- **Home network**: ARP table, hostname, or passive mDNS browsing is fine:
  `dns-sd -B _androidtvremote2._tcp`, `_googlecast._tcp`, `_adb._tcp`, `_adb-tls-connect._tcp`;
  resolve a name with `dns-sd -L <instance> <type> local.` and `dns-sd -G v4 <host>.local.`
  The `_androidtvremote2` instance name is often the model number.
- **Office, school, hotel or any network you don't run**: do not scan or browse. Ask the user for the IP
  shown under Settings > Network, or under Developer options > Wireless debugging.
- Before anything else, check the Mac/PC can reach it at all (a single TCP connect to the port the user
  gave). Enterprise Wi-Fi often isolates clients; if so, nothing below will work from that network.

## Path A - classic network ADB on 5555 (most Android TV 9-11 sets)

User: Settings > Device Preferences > About > press OK on "Build" 7 times; then Developer options >
USB debugging on (and "Network debugging"/"ADB over network" if the set shows it).

```
adb connect <ip>:5555
adb devices -l              # "unauthorized" means: the prompt is on the TV now
```
Ask the user to tick "Always allow from this computer" and accept. If the prompt timed out,
`adb disconnect; adb kill-server; adb connect <ip>:5555` shows it again.

`cleanyourtv/tools/tv.py` (pure-Python `adb-shell`) reuses `~/.android/adbkey` when it exists, so after
the stock adb was accepted it usually works without a second prompt. On some boards it shows its own
prompt once.

## Path B - Wireless debugging pairing (Google TV 12+, Chromecast with Google TV, Google TV Streamer)

Port 5555 is closed until you pair once.

User: Settings > System > About > press OK on "Android TV OS build" 7 times; Developer options > USB
debugging on, Wireless debugging on. On the Wireless debugging screen: note "IP address & port" (the
connect port), then "Pair device with pairing code" shows a 6-digit code and a *different* pairing port.
The code only works while that dialog stays open.

```
adb pair <ip>:<pairing-port> <code>      # "protocol fault" usually means you used the connect port
adb connect <ip>:<connect-port>
adb -s <ip>:<connect-port> tcpip 5555    # tv.py and upstream tools use 5555
adb connect <ip>:5555
```
If the user only gives you one port, `adb mdns services` lists both `_adb-tls-pairing` and
`_adb-tls-connect` for that device (filter the output to its IP).

What to expect afterwards:
- 5555 closes again at every reboot, and Wireless debugging switches itself off at every reboot and
  whenever Wi-Fi drops. The pairing survives: switch Wireless debugging on, `adb connect` the new
  connect port, `adb tcpip 5555` again.
- The IP can change after a reboot or Wi-Fi re-join (DHCP). Read it from the Wireless debugging screen.
- On Ethernet, some sticks flip Wireless debugging straight back off: pair on Wi-Fi.

## macOS quirks

- `adb` says "No route to host" while the port is open: macOS Local Network privacy is blocking the adb
  binary. Use `tv.py` (Python) instead of debugging it. If `tv.py --push` hangs on large files, upstream's
  `tools/b64push.py` sends base64 chunks and checks md5.
- A sandboxed agent that cannot reach the LAN at all: ask the user to run `tools/relay.py <tv ip>` in a
  terminal and use `TV_HOST=127.0.0.1 TV_PORT=15555`.
- Don't trust `nc` on macOS for port checks; Local Network privacy can block it too. Use
  `scripts/port_check.py`.

## USB ports and USB Ethernet

Some boxes cut power to their USB port while USB debugging is on, so a USB drive, speaker or USB
Ethernet adapter on that port can drop. Ask what is plugged in, and separately whether the network
comes over a USB Ethernet adapter. On such a set check `dumpsys usb | grep host_connected` and
`dumpsys connectivity | grep -o 'Transports: [A-Z]*'` before changing anything, finish in one sitting,
and prefer Wireless debugging if the device has it.

## When `pm install` or sideloading is refused

Some China-market sets answer every sideload with `INSTALL_FAILED_VERIFICATION_FAILURE`, or refuse any
package that declares HOME without the vendor signature. Do the debloat half, say plainly the launcher
half is impossible on that set, and stop retrying. Below upstream `minSdk` (26) the launcher can't be
installed either; don't lower `minSdk` or hand over an APK built elsewhere.
