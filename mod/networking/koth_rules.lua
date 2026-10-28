-- Balatro High Stakes: "King of the Hill / Bounty" rules (pure Lua, no LOVE/Balatro deps).
-- Used by the in-game Steam P2P host (networking/p2p_server.lua). The TypeScript server has the
-- same rules in server/src/koth.ts; both are checked against tests/koth_vectors.json.
-- GPL-3.0. 2 to 8 players; the defaults scale with the number of players at the start.
--
-- Rules per PvP blind (normal attrition: the single lowest score loses a life):
--  * The single highest score becomes King (or stays King: +1 streak). Bounty = King's streak.
--  * Beating the King (someone else has the single highest score) claims the bounty:
--    $ (bounty_money x bounty), and +1 life (max starting lives) when bounty >= life_bounty.
--  * Crown shield: if the King has the single lowest score, he loses the crown instead of a life.
--  * Hold the Hill: a King whose streak reaches hold_target wins the match. Last one standing also wins.
--  * Scaling (players at the start): hold target 5 (2 players), 4 (3-4), 3 (5-8): the crown is
--    harder to keep with more rivals. Life bounty at bounty 3 (2-4 players), 2 (5-8).
--    With 6-8 players two players can lose a life per PvP; a King among them is shielded.
local K = {}

K.DEFAULTS = { hold_target = 4, bounty_money = 4, life_bounty = 3, starting_lives = 3 }

--- Defaults for this many players (nil = 3, the original tuning).
function K.scaled(players)
	local n = tonumber(players) or 3
	local c = {}
	for k, v in pairs(K.DEFAULTS) do c[k] = v end
	if n <= 2 then c.hold_target = 5 elseif n >= 5 then c.hold_target = 3 end
	if n >= 5 then c.life_bounty = 2 end
	return c
end

function K.config(options, players)
	options = options or {}
	local c = K.scaled(players)
	local h = tonumber(options.koth_hold_target)
	if h and h >= 2 and h <= 10 then c.hold_target = math.floor(h) end
	local m = tonumber(options.koth_bounty_money)
	if m and m >= 0 and m <= 50 then c.bounty_money = math.floor(m) end
	local s = tonumber(options.starting_lives)
	if s and s >= 1 then c.starting_lives = math.floor(s) end
	return c
end

function K.new_state() return { kingId = nil, streak = 0 } end

--- entries: list of { id, name, score } for everyone who played this PvP.
--- gt(a, b) / eq(a, b) compare scores. roundLosers: id (or list of ids) losing a life this PvP.
--- Mutates st and returns an event table (sent to clients as action "kothUpdate").
function K.resolve(st, entries, roundLosers, gt, eq, cfg)
	cfg = cfg or K.config()
	local losing = {}
	if type(roundLosers) == "table" then
		for _, id in ipairs(roundLosers) do losing[id] = true end
	elseif roundLosers ~= nil then
		losing[roundLosers] = true
	end
	local ev = { holdTarget = cfg.hold_target, reward = 0, lifeBonus = false }
	local king
	for _, e in ipairs(entries) do if e.id == st.kingId then king = e end end
	if st.kingId and not king then st.kingId, st.streak = nil, 0 end -- King left / was eliminated / is away

	local top, tied = nil, 0
	for _, e in ipairs(entries) do
		if top == nil or gt(e.score, top.score) then top, tied = e, 1
		elseif eq(e.score, top.score) then tied = tied + 1 end
	end
	if tied ~= 1 then top = nil end

	local king_lowest = king ~= nil and losing[king.id] == true
	if king_lowest then ev.shieldedId = king.id end

	if king and top == king then
		st.streak = st.streak + 1
	elseif top then
		if king then
			local bounty = math.max(1, st.streak)
			ev.prevKingId, ev.prevKingName = king.id, king.name
			ev.claimedBy, ev.claimedName, ev.claimedBounty = top.id, top.name, bounty
			ev.reward = cfg.bounty_money * bounty
			ev.lifeBonus = bounty >= cfg.life_bounty
		else
			ev.crowned = true
		end
		st.kingId, st.streak = top.id, 1
	elseif king_lowest then
		ev.prevKingId, ev.prevKingName = king.id, king.name
		st.kingId, st.streak = nil, 0
	end

	ev.kingId, ev.streak, ev.bounty = st.kingId, st.streak, st.streak
	for _, e in ipairs(entries) do if e.id == st.kingId then ev.kingName = e.name end end
	if st.kingId and #entries >= 2 and st.streak >= cfg.hold_target then ev.winnerId = st.kingId end
	return ev
end

--- Snapshot for (re)joining players.
function K.snapshot(st, names, cfg)
	return { kingId = st.kingId, kingName = st.kingId and names[st.kingId] or nil, streak = st.streak,
		bounty = st.streak, holdTarget = (cfg or K.config()).hold_target, reward = 0, lifeBonus = false, snapshot = true }
end

return K
