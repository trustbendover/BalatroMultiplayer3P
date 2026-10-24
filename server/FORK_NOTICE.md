# Balatro Multiplayer 3P (fork)

This is a modified version of [Balatro Multiplayer](https://github.com/Balatro-Multiplayer/BalatroMultiplayer)
by Virtualized and contributors, licensed under GPL-3.0 (see LICENSE.md, unchanged).
Modified 2026-10 to support 3-player Attrition lobbies. It requires the matching
3P server fork (based on https://github.com/Balatro-Multiplayer/BalatroMultiplayerAPI-Server, GPL-3.0).

Server changes: src/Lobby.ts (player list, max 3, N-player PvP resolution), src/Client.ts, src/actionHandlers.ts, src/actions.ts, test/threePlayer.test.mjs.

3P fork by Trust Ben Dover. Unofficial; not affiliated with LocalThunk, Playstack, or the Balatro Multiplayer team.
