-- Balatro Multiplayer 3P: helpers for the special 3-player jokers (objects/jokers/threep/).
-- GPL-3.0. Everything here only reads state the client already gets from the server
-- (enemyInfo lives/eliminated, own lives, King of the Hill state), so the jokers work the same
-- with the in-game Steam P2P host and the TS server, without extra networking.
MP.J3P = MP.J3P or {}
local J = MP.J3P

--- Opponents known this game (alive and eliminated), as a list.
function J.enemies(enemies)
	local list = {}
	for id, e in pairs(enemies or (MP.GAME and MP.GAME.enemies) or {}) do
		if type(e) == "table" and id ~= "legacy" then list[#list + 1] = e end
	end
	table.sort(list, function(a, b) return tostring(a.id) < tostring(b.id) end)
	return list
end

local function alive(e) return not e.eliminated and (tonumber(e.lives) or 0) > 0 end

--- Shop gate: multiplayer jokers on, and the match started with 3 players (2 opponents seen).
function J.available()
	if not (MP.LOBBY and MP.LOBBY.code and MP.LOBBY.config and MP.LOBBY.config.multiplayer_jokers) then return false end
	if MP.GAME and MP.GAME.enemies then return #J.enemies() >= 2 end
	return (MP.LOBBY.player_count or 0) >= 3
end

function J.my_lives() return tonumber(MP.GAME and MP.GAME.lives) or 0 end

--- Number of alive opponents with more lives than you.
function J.count_ahead(my, enemies)
	local n = 0
	for _, e in ipairs(J.enemies(enemies)) do if alive(e) and (tonumber(e.lives) or 0) > my then n = n + 1 end end
	return n
end

--- Players still in the match, including you (if you're alive).
function J.players_in(my, enemies)
	local n = my > 0 and 1 or 0
	for _, e in ipairs(J.enemies(enemies)) do if alive(e) then n = n + 1 end end
	return n
end

--- true when one alive opponent has more lives than you and another has fewer.
function J.is_middle(my, enemies)
	local more, fewer = false, false
	for _, e in ipairs(J.enemies(enemies)) do
		if alive(e) then
			local l = tonumber(e.lives) or 0
			if l > my then more = true elseif l < my then fewer = true end
		end
	end
	return more and fewer
end

--- Leader on lives: "me", an opponent id, or nil when the top is tied.
function J.lives_leader(my, enemies)
	local best, best_id, tied = my, "me", false
	for _, e in ipairs(J.enemies(enemies)) do
		if alive(e) then
			local l = tonumber(e.lives) or 0
			if l > best then best, best_id, tied = l, e.id, false elseif l == best then tied = true end
		end
	end
	if tied then return nil end
	return best_id
end

--- Is an opponent leading? In King of the Hill: someone else wears the crown.
function J.opponent_leads(my, enemies, koth)
	if koth and koth.kingId then return koth.kingId ~= koth.you end
	local l = J.lives_leader(my, enemies)
	return l ~= nil and l ~= "me"
end

--- Serializable snapshot (stored in card.ability so it survives save/load).
function J.snapshot(my, enemies, koth)
	local s = { lives = {}, elim = {}, my = my }
	for _, e in ipairs(J.enemies(enemies)) do
		s.lives[e.id] = tonumber(e.lives) or 0
		if e.eliminated then s.elim[e.id] = true end
	end
	local leader = J.lives_leader(my, enemies)
	if leader and leader ~= "me" then s.leader, s.leader_lives = leader, s.lives[leader] end
	if koth and koth.kingId and koth.kingId ~= koth.you then s.king = koth.kingId end
	return s
end

--- What happened between two snapshots: opponent life losses, new eliminations, leader fell.
function J.diff(prev, cur)
	local ev = { life_losses = 0, eliminations = 0, leader_fell = false }
	if not prev then return ev end
	for id, l in pairs(cur.lives) do
		local before = prev.lives[id]
		if before and l < before then ev.life_losses = ev.life_losses + (before - l) end
		if cur.elim[id] and not prev.elim[id] and before ~= nil then ev.eliminations = ev.eliminations + 1 end
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
