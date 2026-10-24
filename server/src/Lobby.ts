import type Client from "./Client.js";
import { InsaneInt } from "./InsaneInt.js";
import GameModes from "./GameMode.js";
import type {
	ActionLobbyInfo,
	ActionServerToClient,
	GameMode,
} from "./actions.js";

export const Lobbies = new Map<string, Lobby>();

const generateUniqueLobbyCode = (): string => {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	let result = "";
	for (let i = 0; i < 5; i++) {
		result += chars.charAt(Math.floor(Math.random() * chars.length));
	}
	return Lobbies.get(result) ? generateUniqueLobbyCode() : result;
};

export const MAX_PLAYERS = 3;

/** Legacy helper: returns the first *other* player (prefers alive ones). */
export const getEnemy = (client: Client): [Lobby | null, Client | null] => {
	const lobby = client.lobby
	if (!lobby) return [null, null]
	if (!lobby.players.some((p) => p.id === client.id)) return [lobby, null]
	const others = lobby.players.filter((p) => p.id !== client.id)
	return [lobby, others.find((p) => !p.eliminated) ?? others[0] ?? null]
}

/** All other players in the client's lobby (alive and eliminated). */
export const getOpponents = (client: Client, aliveOnly = false): Client[] => {
	const lobby = client.lobby
	if (!lobby) return []
	return lobby.players.filter((p) => p.id !== client.id && (!aliveOnly || !p.eliminated))
}

/** Relay an action from client to every other player in the lobby. */
export const sendToOpponents = (client: Client, action: ActionServerToClient & { playerId?: string }, aliveOnly = false) => {
	for (const p of getOpponents(client, aliveOnly)) p.sendAction(action)
}

/** How long to keep a disconnected player's slot reserved (ms) */
const RECONNECT_GRACE_PERIOD = 60000;

/** How long an in-game lobby survives with nobody connected (ms) */
const EMPTY_LOBBY_TTL = 10 * 60 * 1000;

/** Disconnected player whose seat is held until the game ends. The old Client
 *  object is kept as the state snapshot. */
interface DisconnectedSlot {
	reconnectToken: string;
	index: number;
	old: Client;
	since: number;
}

/** "Name~3" -> "name" (usernames carry a blind colour suffix) */
export const baseName = (u: string) => (u || "").split("~")[0].trim().toLowerCase();

class Lobby {
	code: string;
	/** Ordered player list; players[0] is the host. Max MAX_PLAYERS. */
	players: Client[] = [];
	get host(): Client | null { return this.players[0] ?? null }
	get guest(): Client | null { return this.players[1] ?? null }
	gameMode: GameMode;
	// biome-ignore lint/suspicious/noExplicitAny:
	options: { [key: string]: any };
	tcgBets: Map<string, number>;
    handyAllowMPExtension: Map<string, boolean>;
	firstReadyAt: number | null;
	/** Tracks disconnected players awaiting reconnection */
	disconnectedSlots: DisconnectedSlot[] = [];
	/** Whether a game is currently in progress */
	isInGame = false;
	/** Authoritative seed generated for the current game (null until startGame,
	 *  or for different-seeds games where each client uses its own). */
	seed: string | null = null;
	/** 3P: a blind has started and its PvP result hasn't been resolved yet */
	blindActive = false;
	/** 3P: increments for every started PvP blind */
	blindSeq = 0;
	/** 3P: deletes the lobby if nobody reconnects while it's empty mid-game */
	emptyTimer: ReturnType<typeof setTimeout> | null = null;

	// Attrition is the default game mode
	constructor(host: Client, gameMode: GameMode = "attrition") {
		do {
			this.code = generateUniqueLobbyCode();
		} while (Lobbies.get(this.code));
		Lobbies.set(this.code, this);

		this.players = [host];
		this.gameMode = gameMode;
		this.options = {};
		this.tcgBets = new Map();
        this.handyAllowMPExtension = new Map();
		this.firstReadyAt = null;

		host.setLobby(this);
		host.isReadyLobby = false;
		host.sendAction({
			action: "joinedLobby",
			code: this.code,
			type: this.gameMode,
			reconnectToken: host.reconnectToken,
		});
	}

	static get = (code: string) => {
		return Lobbies.get(code);
	};

	/** Voluntary leave — no grace period */
	leave = (client: Client) => {
		const wasMember = this.players.some((p) => p.id === client.id);
		this.players = this.players.filter((p) => p.id !== client.id);
		client.setLobby(null);
		client.eliminated = false;
		if (!wasMember) return;
		this.handyAllowMPExtension.delete(client.id);

		if (this.players.length === 0) {
			this.destroy();
			return;
		}

		if (this.isInGame) {
			// A voluntary leaver mid-game is out; the game continues for the others.
			this.broadcastAction({ action: "playerLeft", playerId: client.id, username: client.username });
			this.checkGameOver();
			if (this.isInGame) {
				this.tryStartBlind();
				this.tryResolvePvP();
			}
		} else {
			this.broadcastAction({ action: "stopGame" });
			this.resetPlayers();
		}
		this.broadcastLobbyInfo();
	};

	destroy = () => {
		if (this.emptyTimer) clearTimeout(this.emptyTimer);
		this.emptyTimer = null;
		this.disconnectedSlots = [];
		Lobbies.delete(this.code);
	};

	/** Connection lost. Mid-game the seat is held until the game ends; the
	 *  player is skipped for PvP while away. */
	disconnect = (client: Client) => {
		const index = this.players.findIndex((p) => p.id === client.id);
		if (index === -1) return;

		if (!this.isInGame) {
			this.leave(client);
			return;
		}

		console.log(`Player ${client.id} (${client.username}) disconnected from lobby ${this.code}; holding seat until game ends`);
		this.disconnectedSlots.push({ reconnectToken: client.reconnectToken, index, old: client, since: Date.now() });
		this.players.splice(index, 1);
		client.setLobby(null);

		for (const p of this.players) {
			p.sendAction({ action: "enemyDisconnected", timeout: 0, playerId: client.id, held: true });
		}

		if (this.players.length === 0) {
			this.emptyTimer = setTimeout(() => {
				console.log(`Lobby ${this.code} empty for too long, deleting`);
				this.destroy();
			}, EMPTY_LOBBY_TTL);
			return;
		}
		// Don't let the others wait on someone who isn't there
		this.tryStartBlind();
		this.tryResolvePvP();
		this.broadcastLobbyInfo();
	};

	/** Seat a reconnecting client in a held slot, restoring their state. */
	reclaimSlot = (newClient: Client, slot: DisconnectedSlot) => {
		this.disconnectedSlots = this.disconnectedSlots.filter((s) => s !== slot);
		if (this.emptyTimer) { clearTimeout(this.emptyTimer); this.emptyTimer = null; }
		const o = slot.old;
		const fields = [
			"lives", "score", "handsLeft", "ante", "skips", "furthestBlind", "isReady", "firstReady",
			"isReadyLobby", "roundLivesBlocker", "timerLivesBlocker", "location", "eliminated", "pvpDone",
			"pvpTimerFailed", "playedThisBlind", "blindSeq", "inPvp", "sitOut", "modHash", "isCached",
		] as const;
		for (const f of fields) (newClient as any)[f] = (o as any)[f];
		if (!newClient.username || newClient.username === "Guest") newClient.username = o.username;

		this.players.splice(Math.min(slot.index, this.players.length), 0, newClient);
		newClient.setLobby(this);
		this.handyAllowMPExtension.set(newClient.id, false);

		// The PvP blind they were in finished while they were away: release them
		const missedBlind = newClient.inPvp && (!this.blindActive || newClient.blindSeq !== this.blindSeq);
		if (missedBlind) {
			newClient.inPvp = false;
			newClient.pvpDone = false;
			newClient.isReady = false;
		}

		newClient.sendAction({ action: "rejoinedLobby", code: this.code, type: this.gameMode, reconnectToken: newClient.reconnectToken });
		newClient.sendAction({ action: "lobbyOptions", gamemode: this.gameMode, ...this.options });
		this.sendResume(newClient, false);
		if (missedBlind) newClient.sendAction({ action: "endPvP", lost: false, loserIds: [] });

		for (const p of this.players) {
			if (p.id !== newClient.id) {
				p.sendAction({ action: "enemyReconnected", playerId: newClient.id });
				p.sendAction(this.enemyInfoFor(newClient, true));
			}
		}
		console.log(`Player ${newClient.username} rejoined lobby ${this.code} (lives=${newClient.lives}, ante=${newClient.ante})`);
		this.broadcastLobbyInfo();
	};

	/** Tell a (re)joining client how to continue: seed, ante, lives, opponents. */
	sendResume = (client: Client, lateJoin: boolean) => {
		client.sendAction({
			action: "resumeGame",
			seed: this.seed ?? undefined,
			ante: Math.max(1, client.ante),
			lives: client.lives,
			lateJoin,
			eliminated: client.eliminated,
			blindActive: this.blindActive,
			inCurrentBlind: client.inPvp && this.blindActive && client.blindSeq === this.blindSeq,
		});
		client.sendAction({ action: "playerInfo", lives: client.lives });
		for (const o of this.players) if (o.id !== client.id) client.sendAction(this.enemyInfoFor(o, true));
		for (const s of this.disconnectedSlots) client.sendAction(this.enemyInfoFor(s.old, true));
	};

	/** Reconnect via token (automatic reconnect / restart with saved token). */
	rejoin = (newClient: Client, reconnectToken: string): boolean => {
		let slot = this.disconnectedSlots.find((s) => s.reconnectToken === reconnectToken);
		if (!slot) {
			// The server may not have noticed the old socket died yet: take it over
			const stale = this.players.find((p) => p.reconnectToken === reconnectToken && p.id !== newClient.id);
			if (stale && this.isInGame) {
				this.disconnect(stale);
				try { stale.closeConnection(); } catch {}
				slot = this.disconnectedSlots.find((s) => s.old === stale);
			}
		}
		if (!slot) return false;
		this.reclaimSlot(newClient, slot);
		return true;
	};

	join = (client: Client) => {
		if (this.isInGame) {
			const name = baseName(client.username);
			// 1) Rejoin by name (e.g. after a crash, without the saved token)
			const slot = this.disconnectedSlots.find((s) => baseName(s.old.username) === name);
			if (slot) {
				this.reclaimSlot(client, slot);
				return;
			}
			const stale = this.players.find((p) => baseName(p.username) === name && p.id !== client.id);
			if (stale) {
				this.disconnect(stale);
				try { stale.closeConnection(); } catch {}
				const s2 = this.disconnectedSlots.find((s) => s.old === stale);
				if (s2) { this.reclaimSlot(client, s2); return; }
			}
			// 2) Late join if there's a free seat
			if (this.players.length + this.disconnectedSlots.length < MAX_PLAYERS) {
				this.lateJoin(client);
				return;
			}
			client.sendAction({ action: "error", message: "Lobby is full." });
			return;
		}
		if (this.players.length >= MAX_PLAYERS) {
			client.sendAction({ action: "error", message: "Lobby is full or does not exist." });
			return;
		}
		this.players.push(client);
		client.eliminated = false;
		client.setLobby(this);
		client.isReadyLobby = false;
		this.handyAllowMPExtension.set(client.id, false);
		client.sendAction({ action: "joinedLobby", code: this.code, type: this.gameMode, reconnectToken: client.reconnectToken });
		client.sendAction({ action: "lobbyOptions", gamemode: this.gameMode, ...this.options });
		this.broadcastLobbyInfo();
	};

	/**
	 * Late join rule: the newcomer starts a fresh run on the lobby seed at the
	 * lowest ante any alive player is on, with the lowest life total among
	 * alive players (min 1). They sit out a PvP blind that's already running.
	 */
	lateJoin = (client: Client) => {
		const aliveConnected = this.alivePlayers();
		const aliveAway = this.awayAlive().map((s) => s.old);
		const all = [...aliveConnected, ...aliveAway];
		client.lives = Math.max(1, Math.min(...all.map((p) => p.lives)));
		client.ante = Math.max(1, Math.min(...(aliveConnected.length ? aliveConnected : all).map((p) => p.ante || 1)));
		client.eliminated = false;
		client.isReady = false;
		client.firstReady = false;
		client.score = new InsaneInt(0, 0, 0);
		client.handsLeft = 4;
		client.skips = 0;
		client.inPvp = false;
		client.pvpDone = false;
		client.sitOut = this.blindActive;
		client.resetBlocker();
		this.players.push(client);
		client.setLobby(this);
		client.isReadyLobby = true;
		this.handyAllowMPExtension.set(client.id, false);
		client.sendAction({ action: "joinedLobby", code: this.code, type: this.gameMode, reconnectToken: client.reconnectToken });
		client.sendAction({ action: "lobbyOptions", gamemode: this.gameMode, ...this.options });
		this.sendResume(client, true);
		for (const p of this.players) {
			if (p.id !== client.id) {
				p.sendAction({ action: "playerJoined", playerId: client.id, username: client.username });
				p.sendAction(this.enemyInfoFor(client, true));
			}
		}
		console.log(`Late join: ${client.username} joined ${this.code} at ante ${client.ante} with ${client.lives} lives`);
		this.broadcastLobbyInfo();
	};

	broadcastAction = (action: ActionServerToClient) => {
		for (const p of this.players) p.sendAction(action);
	};

	broadcastLobbyInfo = () => {
		const host = this.host;
		if (!host) return;

		const players = this.players.map((p, i) => ({
			id: p.id,
			username: p.username,
			hash: p.modHash,
			cached: p.isCached,
			ready: p.isReadyLobby,
			isHost: i === 0,
			lives: p.lives,
			eliminated: p.eliminated,
		}));

		for (const p of this.players) {
			const others = this.players.filter((o) => o.id !== p.id);
			// Legacy fields: "guest" = first opponent from the receiver's view
			// (for the host) so old UI code keeps working.
			const action: ActionLobbyInfo = {
				action: "lobbyInfo",
				host: host.username,
				hostHash: host.modHash,
				isHost: p.id === host.id,
				hostCached: host.isCached,
				players,
				you: p.id,
				maxPlayers: MAX_PLAYERS,
				away: this.disconnectedSlots.map((sl) => ({ id: sl.old.id, username: sl.old.username, lives: sl.old.lives })),
				inGame: this.isInGame,
			};
			const legacyGuest = this.guest;
			if (legacyGuest) {
				action.guest = legacyGuest.username;
				action.guestHash = legacyGuest.modHash;
				action.guestCached = legacyGuest.isCached;
				action.guestReady = others.every((o) => o.id === host.id || o.isReadyLobby);
			}
			p.sendAction(action);
		}

        this.broadcastAction({
            action: "handyMPExtensionLobbyEnabled",
            enabled: Array.from(this.handyAllowMPExtension.values()).every(Boolean)
        })
	};

	setPlayersLives = (lives: number) => {
		for (const p of this.players) {
			p.lives = lives;
			p.eliminated = false;
		}

		this.broadcastAction({ action: "playerInfo", lives });
	};

	// Deprecated
	sendGameInfo = (client: Client) => {
		if (!this.players.includes(client)) {
			return client.sendAction({
				action: "error",
				message: "Client not in Lobby",
			});
		}

		client.sendAction({
			action: "gameInfo",
			...GameModes[this.gameMode].getBlindFromAnte(client.ante, this.options),
		});
	};

	setOptions = (options: { [key: string]: string }) => {
		for (const key of Object.keys(options)) {
			if (options[key] === "true" || options[key] === "false") {
				this.options[key] = options[key] === "true";
			} else {
				this.options[key] = options[key];
			}
		}
		for (const p of this.players.slice(1)) p.sendAction({ action: "lobbyOptions", gamemode: this.gameMode, ...options });
	};

	resetPlayers = () => {
		this.isInGame = false;
		for (const p of this.players) {
			p.isReady = false;
			p.firstReady = false;
			p.resetBlocker();
			p.setLocation("Blind Select");
			p.furthestBlind = 0;
			p.skips = 0;
			p.score = new InsaneInt(0, 0, 0);
			p.handsLeft = 4;
			p.pvpDone = false;
			p.pvpTimerFailed = false;
			p.playedThisBlind = false;
			p.inPvp = false;
			p.sitOut = false;
			p.ante = 1;
		}
		this.tcgBets.clear();
		this.firstReadyAt = null;
		this.blindActive = false;
		this.disconnectedSlots = [];
	};

	/** Held seats of players who are away but still alive. */
	awayAlive = () => this.disconnectedSlots.filter((s) => !s.old.eliminated && s.old.lives > 0);

	/** Players taking part in the current PvP blind (connected, alive, not sitting out). */
	participants = (): Client[] => this.alivePlayers().filter((p) => !p.sitOut);

	/** Players still in the game (not eliminated). */
	alivePlayers = (): Client[] => this.players.filter((p) => !p.eliminated);

	/** Snapshot of one player's public state for enemyInfo. */
	enemyInfoFor = (p: Client, withScore: boolean) => ({
		action: "enemyInfo" as const,
		playerId: p.id,
		username: p.username,
		handsLeft: p.handsLeft,
		score: withScore ? p.score.toString() : null,
		...(withScore ? {} : { noScore: true as const }),
		skips: p.skips,
		lives: p.lives,
		eliminated: p.eliminated,
	});

	/** Mark players with 0 lives eliminated; end the game if <=1 remains. */
	checkGameOver = (): boolean => {
		if (!this.isInGame) return true;
		for (const p of this.players) {
			if (!p.eliminated && p.lives <= 0) {
				p.eliminated = true;
				p.sendAction({ action: "loseGame" });
				for (const o of this.players) {
					if (o.id !== p.id) o.sendAction({ action: "playerEliminated", playerId: p.id, username: p.username });
				}
			}
		}
		const alive = this.alivePlayers();
		// Away players with lives left still count: their seat is held
		if (alive.length + this.awayAlive().length <= 1) {
			alive[0]?.sendAction({ action: "winGame" });
			this.isInGame = false;
			this.blindActive = false;
			this.disconnectedSlots = [];
			return true;
		}
		return false;
	};

	/** If every alive player is ready for the blind, start it. */
	tryStartBlind = () => {
		if (!this.isInGame || this.blindActive) return false;
		const alive = this.alivePlayers();
		if (alive.length === 0 || !alive.every((p) => p.isReady)) return false;
		this.blindSeq++;
		for (const p of alive) {
			p.sitOut = false;
			p.inPvp = true;
			p.blindSeq = this.blindSeq;
			p.isReady = false;
			p.score = new InsaneInt(0, 0, 0);
			p.handsLeft = 4;
			p.playedThisBlind = false;
			p.pvpDone = false;
			p.resetBlocker();
		}
		const first = alive.find((p) => p.firstReady);
		const firstPlayer = first ? (first.id === this.host?.id ? "host" : "guest") : undefined;
		this.firstReadyAt = null;
		this.blindActive = true;
		this.broadcastAction({ action: "startBlind", firstPlayer, firstPlayerId: first?.id });
		return true;
	};

	/**
	 * 3P PvP resolution: once every alive player is out of hands (or failed the
	 * PvP timer), the single lowest score loses a life. A tie for lowest costs
	 * nobody a life. Players at 0 lives are eliminated; last one standing wins.
	 */
	tryResolvePvP = () => {
		if (!this.isInGame || !this.blindActive) return;
		// Away / sitting-out players are skipped, so nobody waits forever
		const alive = this.participants();
		if (alive.length === 0) return;
		if (!alive.every((p) => p.pvpDone || p.handsLeft < 1)) return;
		this.blindActive = false;
		for (const p of this.players) p.inPvp = false;
		if (alive.length === 1) {
			// Opponents are away: nobody loses a life this blind
			const p = alive[0];
			p.firstReady = false;
			p.pvpDone = false;
			p.pvpTimerFailed = false;
			p.sendAction({ action: "endPvP", lost: false, loserIds: [], opponentsAway: true });
			return;
		}

		const timerLosers = alive.filter((p) => p.pvpTimerFailed);
		let roundLosers: Client[] = [];
		if (timerLosers.length === 0) {
			let lowest = alive[0];
			for (const p of alive) if (p.score.lessThan(lowest.score)) lowest = p;
			const tied = alive.filter((p) => p.score.equalTo(lowest.score));
			if (tied.length === 1) roundLosers = [lowest];
		}
		for (const p of roundLosers) p.loseLife("round");

		for (const p of alive) {
			p.firstReady = false;
			p.pvpDone = false;
			p.pvpTimerFailed = false;
		}
		// Send final scores of everyone to everyone
		for (const p of alive) {
			for (const o of this.players) if (o.id !== p.id) p.sendAction(this.enemyInfoFor(o, true));
		}
		if (this.checkGameOver()) return;
		// sit-out players (mid-blind late joiners) were not in this PvP: no endPvP for them
		for (const p of alive) {
			p.sendAction({
				action: "endPvP",
				lost: roundLosers.includes(p) || timerLosers.includes(p),
				...(timerLosers.length ? { pvpTimerLost: true } : {}),
				loserIds: [...roundLosers, ...timerLosers].map((l) => l.id),
			});
		}
	};
}

export default Lobby;
