// Balatro Multiplayer 3P: "King of the Hill / Bounty" rules. Same rules as
// mod/networking/koth_rules.lua (in-game Steam P2P host); both are checked against
// test/koth_vectors.json. GPL-3.0. Designed for 3 players (works with 2 left).
//
// Per PvP blind (normal attrition: the single lowest score loses a life):
//  * The single highest score becomes King (or stays King: +1 streak). Bounty = King's streak.
//  * Beating the King claims the bounty: $ (bountyMoney x bounty), +1 life (max starting
//    lives) when bounty >= lifeBounty.
//  * Crown shield: a King with the single lowest score loses the crown instead of a life.
//  * Hold the Hill: a King whose streak reaches holdTarget wins. Last one standing also wins.

export type KothConfig = { holdTarget: number; bountyMoney: number; lifeBounty: number; startingLives: number };
export type KothState = { kingId: string | null; streak: number };
export type KothEntry<S> = { id: string; name: string; score: S };
export type KothEvent = {
	holdTarget: number;
	reward: number;
	lifeBonus: boolean;
	kingId: string | null;
	kingName?: string;
	streak: number;
	bounty: number;
	shieldedId?: string;
	prevKingId?: string;
	prevKingName?: string;
	claimedBy?: string;
	claimedName?: string;
	claimedBounty?: number;
	crowned?: boolean;
	winnerId?: string;
	snapshot?: boolean;
};

export const KOTH_DEFAULTS: KothConfig = { holdTarget: 4, bountyMoney: 4, lifeBounty: 3, startingLives: 3 };

// biome-ignore lint/suspicious/noExplicitAny: lobby options are loosely typed
export const kothConfig = (options: { [k: string]: any } = {}): KothConfig => {
	const c = { ...KOTH_DEFAULTS };
	const h = Number(options.koth_hold_target);
	if (Number.isFinite(h) && h >= 2 && h <= 10) c.holdTarget = Math.floor(h);
	const m = Number(options.koth_bounty_money);
	if (options.koth_bounty_money !== undefined && Number.isFinite(m) && m >= 0 && m <= 50) c.bountyMoney = Math.floor(m);
	const s = Number(options.starting_lives);
	if (Number.isFinite(s) && s >= 1) c.startingLives = Math.floor(s);
	return c;
};

export const newKothState = (): KothState => ({ kingId: null, streak: 0 });

export function resolveKoth<S>(
	st: KothState,
	entries: KothEntry<S>[],
	roundLoserId: string | null,
	gt: (a: S, b: S) => boolean,
	eq: (a: S, b: S) => boolean,
	cfg: KothConfig = KOTH_DEFAULTS,
): KothEvent {
	const ev: KothEvent = { holdTarget: cfg.holdTarget, reward: 0, lifeBonus: false, kingId: null, streak: 0, bounty: 0 };
	const king = entries.find((e) => e.id === st.kingId);
	if (st.kingId && !king) { st.kingId = null; st.streak = 0; }

	let top: KothEntry<S> | undefined;
	let tied = 0;
	for (const e of entries) {
		if (!top || gt(e.score, top.score)) { top = e; tied = 1; }
		else if (eq(e.score, top.score)) tied++;
	}
	if (tied !== 1) top = undefined;

	const kingLowest = !!king && roundLoserId === king.id;
	if (kingLowest && king) ev.shieldedId = king.id;

	if (king && top === king) {
		st.streak++;
	} else if (top) {
		if (king) {
			const bounty = Math.max(1, st.streak);
			ev.prevKingId = king.id; ev.prevKingName = king.name;
			ev.claimedBy = top.id; ev.claimedName = top.name; ev.claimedBounty = bounty;
			ev.reward = cfg.bountyMoney * bounty;
			ev.lifeBonus = bounty >= cfg.lifeBounty;
		} else {
			ev.crowned = true;
		}
		st.kingId = top.id; st.streak = 1;
	} else if (kingLowest && king) {
		ev.prevKingId = king.id; ev.prevKingName = king.name;
		st.kingId = null; st.streak = 0;
	}

	ev.kingId = st.kingId; ev.streak = st.streak; ev.bounty = st.streak;
	const k = entries.find((e) => e.id === st.kingId);
	if (k) ev.kingName = k.name;
	if (st.kingId && entries.length >= 2 && st.streak >= cfg.holdTarget) ev.winnerId = st.kingId;
	return ev;
}

export const kothSnapshot = (st: KothState, names: Map<string, string>, cfg: KothConfig = KOTH_DEFAULTS): KothEvent => ({
	kingId: st.kingId,
	...(st.kingId && names.get(st.kingId) ? { kingName: names.get(st.kingId) } : {}),
	streak: st.streak,
	bounty: st.streak,
	holdTarget: cfg.holdTarget,
	reward: 0,
	lifeBonus: false,
	snapshot: true,
});
