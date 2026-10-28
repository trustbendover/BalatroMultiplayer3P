-- Balatro High Stakes: who loses a life after a free-for-all PvP blind (Attrition, Showdown,
-- King of the Hill) for 2 to 8 players. Pure Lua; server/src/pvpRules.ts is the TS copy.
-- GPL-3.0, based on Balatro Multiplayer.
--
--  * Up to 5 players in the blind: the single lowest score loses a life (a tie for lowest: nobody).
--  * 6 to 8 players: the bottom two lose a life, so big lobbies don't drag on forever.
--    General rule: k = max(1, floor(players / 3)); a player loses when at most k players
--    (including himself) scored the same or less. Ties at the cut are spared.
local R = {}

function R.loser_count(n) return math.max(1, math.floor((tonumber(n) or 0) / 3)) end

--- entries: list of { id, score }. le(a, b) = a <= b. Returns the list of losing ids.
function R.losers(entries, le)
	local k = R.loser_count(#entries)
	local out = {}
	if #entries < 2 then return out end
	for _, p in ipairs(entries) do
		local n = 0
		for _, q in ipairs(entries) do if le(q.score, p.score) then n = n + 1 end end
		if n <= k then out[#out + 1] = p.id end
	end
	return out
end

return R
