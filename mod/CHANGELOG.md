# Changelog

## Ranked Update 0.4.0

### Standard Ranked

#### Jokers

- **To Do List** — Reworked. Now pays $5 (up from $4). Target poker hand is chosen from all hands, not just discovered ones.
- **Golden Ticket** — Reverted payout nerf, now earns $4 (up from $3)
- **Speedrun** — Out of rotation.
- **Ouija** and **Ectoplasm** — Now cost $4 (bug fix).

#### Consumables

- **Justice** — Back in rotation.

#### Economy & Enhancements

- **Gold Card** (Enhancement) — Payout increased from $3 to $4.
- **Comeback Gold** — Now awarded on any life loss again, not just PvP boss losses. Payout amounts ($4, or $2 on higher stakes) are unchanged.

### Quality of Life

- **Balanced Sticker** — Now shows a tooltip explaining what was changed on the card it's attached to.
- **Hotkeys — Menu Shortcuts** — Hold Tab in the menu to see context-sensitive shortcuts. Main menu: **C** creates a lobby, **V** joins from clipboard. In a lobby: **C** copies the code, **L** leaves, **D** picks deck. Disconnected: **R** reconnects.
- **Timer and score preview rework** - TODO
- **Match Replays (Practice Mode)** — Practice against a ghost opponent replayed from a past match. Drop a Lovely log (`.log`) or exported `.json` into the `replays/` folder and it shows up in the replay picker. Accessed via Practice → Ruleset → Replay Picker. Flip perspective to play as either side.

### Legacy Ranked

#### Jokers

- **Hanging Chad** — Reworked. Retriggers first 2 cards instead of first card twice.

## Ranked Update 0.3.0

### Jokers

- **Seltzer** — Lasts 8 hands instead of 10.
- **Turtle Bean** — Grants +4 hand size instead of +5.
- **Golden Ticket** — Earns $3 instead of $4. No longer requires Gold cards in deck. Now Uncommon rarity.
- **Speedrun** — Can now activate for both players if the second player joins within 30 seconds.

### Consumables

- **Ouija** — Destroys 3 cards instead of converting all cards to a single suit and reducing hand size.
- **Judgment** — Now draws from its own queue (vanilla behavior) on Orange Stake and above. Still uses the shop queue on lower stakes.

## 0.6.6~3P (Trust Ben Dover)
- Auto-update: after the main menu loads the mod checks (in the background, 15 s timeout, silent
  when offline) https://api.github.com/repos/trustbendover/BalatroMultiplayer3P/releases/latest,
  falling back to version.json in the repo. When a newer release exists an
  "Update available: vX" button appears top-left in the main menu; clicking it starts the updater.
  Turn the check off with update_check=false in .env.
- New updater (updater/update.ps1 + Update.bat, installed with the mod and in the Installer zip):
  downloads the Installer zip of the latest release, verifies its SHA256 against the SHA256SUMS
  asset, waits until Balatro is closed and runs the installer in update mode (keeps .env).
- The project now lives at https://github.com/trustbendover/BalatroMultiplayer3P; releases are
  built by GitHub Actions on every v* tag.

## 0.6.5~3P (Trust Ben Dover)
- Game Over: "Your Nemesis" no longer shows ERROR in 3-player games. The nemesis is the strongest
  opponent still in (most lives, then score) when you lose, or the runner-up (last one eliminated)
  when you win; falls back to any known opponent / "Opponent" (also after a disconnect).
- Game Over: "Enemy Jokers", the nemesis deck and stats now come from that nemesis. Requests and
  replies carry a targetId so only that player answers (TS server and in-game P2P host); empty or
  wrong-player replies no longer overwrite the jokers.
- Ko-fi button now points to https://ko-fi.com/trustbendover ("Support us on Ko-fi"). Original
  BalatroMultiplayer credits stay in FORK_NOTICE.md / CREDITS (GPL-3.0).

## 0.6.4~3P (Trust Ben Dover)
- Fix: accepting a Steam invite started Balatro but did not join the lobby. Balatro never calls
  luasteam's runCallbacks(), so Steam callbacks were never dispatched; the mod now pumps them each frame.
- Launch from invite: reads +connect_lobby from the full process command line, waits for the main menu, retries JoinLobby.
- Host accepts SteamNetworkingMessages session requests (callback 1251).
- "Join From Clipboard" accepts a Steam lobby id / steam://joinlobby link; "Join Steam invite again" button.
- Much more "MULTIPLAYER-P2P" logging (invite:, launch command line, callback pump, JoinLobby results).
