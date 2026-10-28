// Balatro High Stakes: who loses a life after a free-for-all PvP blind (2-8 players).
// Same rules as mod/networking/pvp_rules.lua. GPL-3.0, based on Balatro Multiplayer.
//  * Up to 5 players: the single lowest score loses a life (tie for lowest: nobody).
//  * 6-8 players: the bottom two. k = max(1, floor(n / 3)); a player loses when at most k
//    players (including himself) scored the same or less. Ties at the cut are spared.
export const loserCount = (n: number): number => Math.max(1, Math.floor(n / 3));

export function pvpLosers<S>(entries: { id: string; score: S }[], le: (a: S, b: S) => boolean): string[] {
	if (entries.length < 2) return [];
	const k = loserCount(entries.length);
	return entries.filter((p) => entries.filter((q) => le(q.score, p.score)).length <= k).map((p) => p.id);
}
