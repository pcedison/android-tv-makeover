# android-tv-makeover

A [Claude Code](https://claude.com/claude-code) skill that debloats an Android TV or Google TV device over
ADB, swaps its home screen for a clean Apple TV style launcher built from source, verifies every step on
the real device, and closes network ADB when it is done. Every change is designed to be reversible
(packages are disabled, never uninstalled).

[繁體中文說明在下方](#繁體中文)

It is a workflow layer on top of the open-source **[cleanyourtv](https://github.com/Gathin23/cleanyourtv)**
project (MIT), which provides the ADB client, the safety-checked disable/restore tools, per-device example
lists and the launcher source. The skill clones cleanyourtv at run time; nothing from it is bundled here.
This project is not affiliated with cleanyourtv.

## What it does

1. Connects over Wi-Fi ADB (classic port 5555, or Wireless debugging pairing on Google TV 12+), without
   scanning networks you don't own.
2. Backs up the package list, settings, getprop and display state, and writes a restore script **before**
   the first change.
3. Classifies packages (telemetry, vendor ads, preloaded apps, streaming apps, must-keep), checks which
   ones are load-bearing via service bindings and same-board examples, and asks you what to keep.
4. Disables in small batches (`pm disable-user`, never uninstall), verifying Home, Settings, an app and,
   on TVs, the sources drawer, Live TV and HDMI after each batch, plus an idle log check for retry loops.
5. Builds and installs the launcher, sets your dock, remaps remote buttons the stock launcher used to
   handle, optionally applies a wallpaper theme, and has you test the physical remote.
6. Reboots and checks nothing came back, then hands you a README, `restore.sh` and `install.sh` per device.
7. Has you switch debugging off and proves port 5555 and the Wireless debugging ports refuse connections.

## Tested on

| Device | Android | Notes |
|---|---|---|
| Philips 70PUH8217/96 (TP Vision, board PH1M_EA_9970A, MediaTek MT5895) | Android TV 11, RTT2.211108.001 | 32 packages disabled, launcher with Live TV + HDMI inputs |
| Chromecast with Google TV 4K (`sabrina`) | Google TV 14, UTTC.250917.004 | 16 packages + stock home, YouTube key remapped, wallpaper theme |

Other Android TV / Google TV devices should work wherever cleanyourtv works; check its `examples/` for
your board. Samsung Tizen, LG webOS, Roku, Apple TV and cast-only Chromecasts cannot be done this way.

## Requirements

- An AI agent that runs on your computer, loads Agent Skills and can run shell commands, on macOS or
  Linux (see [Install](#install)).
- The TV/stick on the same network as your computer, Developer options available.
- Python 3; `adb` (Android platform-tools) for Wireless debugging pairing.
- For the launcher: JDK 17 and Android SDK platform 34 + build-tools 34 (about 0.9 GB; the skill asks
  before downloading anything and before accepting the Android SDK licence).

## Install

The skill talks to your TV over your home network, so it needs an AI agent that runs **on your own
computer** and can run shell commands. The web and mobile chat apps (ChatGPT, Claude.ai, Grok and the
like) run in the cloud and cannot reach your TV, even where they accept uploaded skills.

The skill uses the open [Agent Skills](https://agentskills.io) format (a folder with a `SKILL.md`), so
any agent that supports that format can load it. It has only been tested with Claude Code.

| Agent | Status | Install |
|---|---|---|
| Claude Code (terminal, or the Code tab in the Claude desktop app) | Tested on both devices above | `git clone https://github.com/pcedison/android-tv-makeover.git ~/.claude/skills/android-tv-makeover` |
| OpenAI Codex (CLI, IDE extension, ChatGPT desktop app) | Should work, not tested | `git clone https://github.com/pcedison/android-tv-makeover.git ~/.agents/skills/android-tv-makeover` |
| Gemini CLI, GitHub Copilot in VS Code, Cursor and other Agent Skills clients | Should work, not tested | `npx skills add pcedison/android-tv-makeover -g` (the [skills](https://github.com/vercel-labs/skills) installer by Vercel) |

For any other agent, put the folder wherever it loads Agent Skills from. With only a chat app, you can
paste `SKILL.md` into the chat and run each command yourself, but it is slow and easy to get wrong.

Then describe the job to your agent. No special command is needed; it picks the skill from what you
ask, for example:

> Clean up my Philips Android TV and give it an Apple TV style home screen. It's on 192.168.1.50.

> Set up the break-room Chromecast with Google TV at the office the same way as my home TV. Nobody casts to it.

Expect three or four rounds of questions (apps you use, voice/casting/updates, dock apps and order,
ad-blocking DNS) and a few steps in front of the TV (enable debugging, accept the prompt, press remote
buttons, re-join Wi-Fi on Google TV).

## Layout

```
SKILL.md                     workflow and ground rules (what the agent reads first)
references/                  connection, Google TV sticks, TV sets, launcher, gotchas
scripts/                     backup, batch cutting, verification, service bindings, idle-loop and port checks
templates/                   per-device TASK_STATE, debloat list, restore.sh, install.sh, README
evals/                       test prompts used to check the skill
```

## Safety

Packages are disabled, never uninstalled; Android core packages and what the TV needs to work are never
touched; factory packages are never launched; Wi-Fi passwords and accounts are entered by you on the
device, never by the agent; network ADB is closed and verified at the end. You are responsible for the
devices you run this on; use it only on devices you own or are allowed to change.

**No warranty.** This is provided as is (see [LICENSE](LICENSE)) and you use it at your own risk.
Disabling system packages can still break a feature in a way no check catches. The per-device
`restore.sh` undoes the changes; a factory reset is the last resort.

## Credits and licence

- [cleanyourtv](https://github.com/Gathin23/cleanyourtv) by Gathin, MIT: tools, examples and launcher.
- This skill: MIT, see [LICENSE](LICENSE).
- Philips, Android TV, Google TV, Chromecast, Apple TV and the other product names here are trademarks
  of their respective owners. They are used only to describe compatible devices and styles; this
  project is not affiliated with or endorsed by any of them.

---

## 繁體中文

這是一個 [Claude Code](https://claude.com/claude-code) 的 skill。它能透過 ADB 幫 Android TV 或 Google TV 裝置移除預載程式（debloat），把主畫面換成從原始碼編譯、仿 Apple TV 風格的簡潔主畫面。每一步都在實機上驗證，完成後關閉網路 ADB。所有改動都設計成可以還原（只停用、不解除安裝）。

它建立在開源專案 **[cleanyourtv](https://github.com/Gathin23/cleanyourtv)**（MIT 授權）之上。ADB 工具、有安全檢查的停用與還原腳本、各機型的實測清單，以及主畫面的原始碼都來自 cleanyourtv。這個 skill 會在執行時才去 clone 它，本身不附帶它的程式碼。本專案與 cleanyourtv 沒有隸屬關係。

### 它會做什麼

1. 透過 Wi-Fi 連上 ADB：一般是 5555 埠，Google TV 12 以上用「無線偵錯」配對碼。不是你管的網路，它不會掃描。
2. 備份套件清單、系統設定與顯示設定，並在**第一次改動之前**寫好還原腳本。
3. 把套件分類成遙測、廠商廣告、預載 app、串流 app、必須保留。用服務綁定關係和同主機板的實測紀錄，判斷哪些是電視運作需要的。要保留哪些，它會先問你。
4. 小批次停用（只停用、不解除安裝）。每批停完都會實測主畫面、設定、app；如果是電視，還會測訊號源選單、看電視和 HDMI，並檢查閒置時有沒有程式在無限重試。
5. 編譯並安裝新主畫面，依你的選擇設定 Dock，把原廠主畫面負責的遙控器按鍵對應回來，可以選擇加上桌布主題，最後請你用實體遙控器測試。
6. 重開機確認沒有東西被救回來。每台裝置都會留下 README、`restore.sh`、`install.sh`。
7. 請你關閉偵錯，並實際證明 5555 埠和無線偵錯的埠都已拒絕連線。

### 實測過的裝置

- Philips 70PUH8217/96（Android TV 11）：停用 32 個套件，新主畫面支援看電視與 HDMI 切換。
- Chromecast with Google TV 4K（Google TV 14）：停用 16 個套件和原廠主畫面，YouTube 鍵重新對應，換上桌布主題。

只要 cleanyourtv 支援的 Android TV／Google TV 都應該可以用，可以先查它的 `examples/` 有沒有你的主機板。Samsung（Tizen）、LG（webOS）、Roku、Apple TV，以及只能投放的舊款 Chromecast 不適用。

### 安裝與使用

這個 skill 要從你的電腦透過家裡網路連到電視，所以必須搭配**裝在你自己電腦上**、能執行終端機指令的 AI 工具。ChatGPT、Claude.ai、Grok 這類網頁或手機 App 是在雲端執行，連不到你家的電視；就算它們能上傳 skill 也一樣用不了。

它使用開放的 [Agent Skills](https://agentskills.io) 格式（一個含 `SKILL.md` 的資料夾），所以支援這個格式的 AI 工具都能載入。目前只有 Claude Code 實測過。

| AI 工具 | 狀態 | 安裝方式 |
|---|---|---|
| Claude Code（終端機版，或 Claude 桌面 App 的 Code 分頁） | 上面兩台裝置都實測過 | `git clone https://github.com/pcedison/android-tv-makeover.git ~/.claude/skills/android-tv-makeover` |
| OpenAI Codex（CLI、IDE 擴充、ChatGPT 桌面 App） | 照標準應該能用，未實測 | `git clone https://github.com/pcedison/android-tv-makeover.git ~/.agents/skills/android-tv-makeover` |
| Gemini CLI、VS Code 的 GitHub Copilot、Cursor 等支援 Agent Skills 的工具 | 照標準應該能用，未實測 | `npx skills add pcedison/android-tv-makeover -g`（Vercel 的 [skills](https://github.com/vercel-labs/skills) 安裝工具） |

其他 AI 工具，把資料夾放到它讀取 Agent Skills 的位置即可。如果只有聊天 App，也可以把 `SKILL.md` 貼進對話、自己一行一行跑指令，但很慢，也容易出錯。

裝好後直接跟 AI 描述你要做的事，不需要特別的指令，它會從描述判斷要用這個 skill。例如：「幫我清理家裡的 Philips Android TV，換成 Apple TV 風格的主畫面，IP 是 192.168.1.50」。

過程中大約會有三到四輪問題，包括你用哪些 app、語音／投放／更新要不要留、Dock 放哪些 app、要不要開擋廣告 DNS。也有幾個步驟需要你在電視前操作：開啟偵錯、按允許、按遙控器測試；如果是 Google TV，還要重新連一次 Wi-Fi。

### 安全原則

- 只停用、不解除安裝，不碰 Android 核心套件和電視運作需要的元件，也不啟動任何工廠模式程式。
- Wi-Fi 密碼和帳號由你在裝置上自己輸入。
- 結束時會關閉網路 ADB，並實際驗證連接埠已經關上。
- 請只在你擁有、或有權調整的裝置上使用。
- **不提供任何保證**（見 [LICENSE](LICENSE)），使用風險自負。停用系統套件仍可能讓某些功能出問題，而且不一定檢查得出來。每台裝置的 `restore.sh` 可以還原這些改動，最後手段是恢復原廠設定。
- Philips、Android TV、Google TV、Chromecast、Apple TV 等名稱是各自擁有者的商標，這裡只用來描述相容的裝置與風格；本專案與它們沒有隸屬關係，也未獲其認可。
