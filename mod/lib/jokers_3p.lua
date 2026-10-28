-- Balatro High Stakes: helpers for the special multiplayer jokers (objects/jokers/threep/,
-- folder name kept from the 3P fork). GPL-3.0, based on Balatro Multiplayer.
-- Everything here only reads state the client already gets from the server (enemyInfo
-- lives/eliminated, own lives, King of the Hill / Teams state), so the jokers work the same
-- with the in-game Steam P2P host and the TS server, without extra networking.
--
-- 2-8 players: every joker scales with the number of rivals (opponents that are not your
-- teammate) and has a cap; jokers that need "another opponent" are not offered in a 1v1.
-- In Teams mode a whole rival team counts as one "group" (it shares its lives).
MP.J3P = MP.J3P or {}
local J = MP.J3P

local function is_teammate(id)
	return MP.TEAMS ~= nil and MP.TEAMS.is_teammate ~= nil and MP.TEAMS.is_teammate(id) or false
end

--- Rivals known this game (alive and eliminated, teammates excluded), as a list.
function J.enemies(enemies)
	local list = {}
	for id, e in pairs(enemies or (MP.GAME and MP.GAME.enemies) or {}) do
		if type(e) == "table" and id ~= "legacy" and not is_teammate(e.id or id) then list[#list + 1] = e end
	end
	table.sort(list, function(a, b) return tostring(a.id) < tostring(b.id) end)
	return list
end

local function alive(e) return not e.eliminated and (tonumber(e.lives) or 0) > 0 end

--- Group of a rival: their team letter in Teams mode, otherwise the player itself.
function J.group_of(e)
	local t = MP.TEAMS and MP.TEAMS.team_of and MP.TEAMS.is_active and MP.TEAMS.is_active() and MP.TEAMS.team_of(e.id)
	return t and ("team:" .. t) or tostring(e.id)
end

--- Rival groups: { [group] = { lives = max lives of alive members, alive = bool, ids = {...} } }
function J.groups(enemies)
	local g = {}
	for _, e in ipairs(J.enemies(enemies)) do
		local k = J.group_of(e)
		local x = g[k] or { lives = 0, alive = false, ids = {} }
		g[k] = x
		x.ids[#x.ids + 1] = e.id
		if alive(e) then
			x.alive = true
			x.lives = math.max(x.lives, tonumber(e.lives) or 0)
		end
	end
	return g
end

--- Number of rivals this game (alive and eliminated): the joker scaling base.
function J.rival_count(enemies) return #J.enemies(enemies) end

--- Number of rival groups (teams in Teams mode).
function J.group_count(enemies)
	local n = 0
	for _ in pairs(J.groups(enemies)) do n = n + 1 end
	return n
end

--- Players in this match (you + every opponent seen, teammates included).
function J.player_count()
	if MP.GAME and MP.GAME.enemies and next(MP.GAME.enemies) then
		local n = 1
		for id, e in pairs(MP.GAME.enemies) do if type(e) == "table" and id ~= "legacy" then n = n + 1 end end
		return n
	end
	return tonumber(MP.LOBBY and MP.LOBBY.player_count) or 0
end

--- Shop gate: multiplayer jokers on, and at least min_players in the match (default 2).
--- min_groups: rival groups needed (Teams: rival teams; FFA: rivals). Default 1.
function J.available(min_players, min_groups)
	if not (MP.LOBBY and MP.LOBBY.code and MP.LOBBY.config and MP.LOBBY.config.multiplayer_jokers) then return false end
	min_players = min_players or 2
	if J.player_count() < min_players then return false end
	if min_groups and min_groups > 1 then
		if MP.GAME and MP.GAME.enemies and next(MP.GAME.enemies) then
			return J.group_count() >= min_groups
		end
		-- before the first enemyInfo: Teams lobby preview
		if MP.TEAMS and MP.TEAMS.is_active and MP.TEAMS.is_active() then
			local teams = {}
			for _, pl in ipairs(MP.LOBBY.player_list or {}) do if pl.team then teams[pl.team] = true end end
			local n = 0
			for _ in pairs(teams) do n = n + 1 end
			return n - 1 >= min_groups
		end
		return J.player_count() - 1 >= min_groups
	end
	return true
end

function J.my_lives() return tonumber(MP.GAME and MP.GAME.lives) or 0 end

--- Number of alive rival groups with more lives than you.
function J.count_ahead(my, enemies)
	local n = 0
	for _, g in pairs(J.groups(enemies)) do if g.alive and g.lives > my then n = n + 1 end end
	return n
end

--- Number of alive rival groups.
function J.groups_alive(enemies)
	local n = 0
	for _, g in pairs(J.groups(enemies)) do if g.alive then n = n + 1 end end
	return n
end

--- Players still in the match, including you (if you're alive) and your teammates.
function J.players_in(my, enemies)
	local n = my > 0 and 1 or 0
	for id, e in pairs(enemies or (MP.GAME and MP.GAME.enemies) or {}) do
		if type(e) == "table" and id ~= "legacy" and alive(e) then n = n + 1 end
	end
	return n
end

--- true when at least one alive rival group has more lives than you and another has fewer
--- ("middle ranks", any player count).
function J.is_middle(my, enemies)
	local more, fewer = false, false
	for _, g in pairs(J.groups(enemies)) do
		if g.alive then
			if g.lives > my then more = true elseif g.lives < my then fewer = true end
		end
	end
	return more and fewer
end

--- Leader on lives: "me", a rival group, or nil when the top is tied.
function J.lives_leader(my, enemies)
	local best, best_id, tied = my, "me", false
	for k, g in pairs(J.groups(enemies)) do
		if g.alive then
			if g.lives > best then best, best_id, tied = g.lives, k, false elseif g.lives == best then tied = true end
		end
	end
	if tied then return nil end
	return best_id
end

--- Is an opponent ahead of you? In King of the Hill: someone else wears the crown; otherwise a
--- rival has more lives than you (with up to 7 rivals a tie at the top is common, so a strict
--- single leader is not required).
function J.opponent_leads(my, enemies, koth)
	if koth and koth.kingId then return koth.kingId ~= koth.you end
	return J.count_ahead(my, enemies) > 0
end

-- ===== scaling (pure; r = rivals in the match, at least 1) =====
local function r2(x) return math.floor(x * 100 + 0.5) / 100 end
J.SCALE = {
	third_wheel_max = 24, -- +Mult when every alive rival group has more lives than you
	vulture_money = function(r) return math.max(3, math.floor(16 / math.max(1, r))) end,
	vulture_max_hands = 2,
	laughing_gain = function(r) return math.max(0.05, math.floor(50 / math.max(2, r)) / 100) end,
	laughing_cap = 3,
	kingslayer_x = function(r) return r2(1 + math.min(1, 2 / math.max(1, r))) end,
	bounty_money = function(r) return math.max(2, math.floor(8 / math.max(2, r))) end,
	bounty_mult = function(r) return math.max(1, math.floor(6 / math.max(2, r))) end,
	bounty_cap = 24,
	triumvirate_x = function(n_in) return math.min(3, 0.5 + 0.5 * math.max(0, n_in)) end,
}

--- Third Wheel: +Mult share of the max for the share of alive rival groups ahead of you.
function J.third_wheel_mult(my, enemies)
	local alive_g = J.groups_alive(enemies)
	if alive_g < 1 then return 0 end
	return math.floor(J.SCALE.third_wheel_max * J.count_ahead(my, enemies) / alive_g + 0.5)
end

--- Serializable snapshot (stored in card.ability so it survives save/load).
function J.snapshot(my, enemies, koth)
	local s = { lives = {}, elim = {}, my = my }
	for k, g in pairs(J.groups(enemies)) do
		s.lives[k] = g.alive and g.lives or 0
		if not g.alive then s.elim[k] = true end
	end
	local leader = J.lives_leader(my, enemies)
	if leader and leader ~= "me" then s.leader, s.leader_lives = leader, s.lives[leader] end
	if koth and koth.kingId and koth.kingId ~= koth.you then s.king = koth.kingId end
	return s
end

--- What happened between two snapshots: rival life losses, new eliminations, leader fell.
--- A rival team counts once (it shares its lives).
function J.diff(prev, cur)
	local ev = { life_losses = 0, eliminations = 0, leader_fell = false }
	if not prev then return ev end
	for id, l in pairs(cur.lives) do
		local before = prev.lives[id]
		local newly_out = cur.elim[id] and not prev.elim[id] and before ~= nil
		-- a rival who leaves / times out with lives left counts as one lost life, not all of them
		if before and l < before then ev.life_losses = ev.life_losses + (newly_out and 1 or (before - l)) end
		if newly_out then ev.eliminations = ev.eliminations + 1 end
	end
	if prev.king then
		-- King of the Hill: the opponent King lost the crown
		if cur.king ~= prev.king then ev.leader_fell = true end
	elseif prev.leader then
		local now = cur.lives[prev.leader]
		if now and now < (prev.leader_lives or 0) then ev.leader_fell = true end
	end
	return ev
end

--- Per-card event tracking: returns the diff since the card last looked (nil on first look).
function J.poll(card)
	if not (MP.LOBBY and MP.LOBBY.code and MP.GAME and MP.GAME.enemies) then return nil end
	local cur = J.snapshot(J.my_lives(), MP.GAME.enemies, MP.GAME.koth)
	local prev = card.ability.extra.snap
	card.ability.extra.snap = cur
	if not prev then return nil end
	return J.diff(prev, cur)
end

function J.say(card, text, colour)
	pcall(card_eval_status_text, card, "extra", nil, nil, nil, { message = text, colour = colour or G.C.MONEY })
end

return J
