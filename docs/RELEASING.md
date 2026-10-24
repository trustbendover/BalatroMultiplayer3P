# Releasing

Releases are built by GitHub Actions (`.github/workflows/release.yml`) whenever a tag `v*` is pushed.
The workflow runs the Lua and server tests, builds the zips with `tools/build_release.py` and publishes
a GitHub Release with three assets:

- `BalatroMultiplayer3P-vX.Y.Z-Installer.zip` — what players download (the in-game updater uses this)
- `BalatroMultiplayer3P-vX.Y.Z-source.zip` — corresponding source (GPL-3.0)
- `SHA256SUMS-vX.Y.Z.txt` — checked by the updater before installing

## Steps

1. Bump the version everywhere (all must match):
   - `mod/Multiplayer.json` → `"version": "X.Y.Z~3P"`
   - `mod/networking/p2p_server.lua` → `Core.SERVER_VERSION = "X.Y.Z-MULTIPLAYER3P"`
   - `server/src/actionHandlers.ts` → `serverVersion`, and `server/package.json` (+ `npm install` for the lock file)
   - version strings in `mod/tests/test_steam_p2p.lua` and `server/test/*.mjs`
   - `version.json` (`version` and `tag`) — fallback for the update check
   - installer texts in `installer/README.txt` / `LEES_MIJ.txt`
2. Add a section to `mod/CHANGELOG.md`.
3. Run the tests locally (see README) and optionally `python3 tools/build_release.py` to check the zips.
4. Commit, then tag and push:
   ```
   git commit -am "vX.Y.Z"
   git tag vX.Y.Z
   git push origin main vX.Y.Z
   ```
5. Watch *Actions*; the Release appears under *Releases* and becomes `latest`.
   Every installed copy (0.6.6 or newer) shows "Update available" on its next start.

The workflow fails if the tag doesn't match `mod/Multiplayer.json` or if a zip contains `.env`,
logs, `node_modules` or other forbidden content.

## Manual release (without Actions)

```
python3 tools/build_release.py --out dist-release
gh release create vX.Y.Z dist-release/* --title "vX.Y.Z~3P" --notes-file notes.md
```

## Notes

- Lovely 0.10.0 and Steamodded 1.0.0~BETA-1620a are downloaded by the build script from their
  official releases and verified against pinned SHA256 hashes (see `VENDOR` in `tools/build_release.py`).
- Never commit `.env`, logs, `server/data/` or anything with personal data.
