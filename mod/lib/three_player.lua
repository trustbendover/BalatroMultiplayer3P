-- Balatro Multiplayer 3P fork: helpers for 3-player lobbies.
-- GPL-3.0, based on Balatro-Multiplayer/BalatroMultiplayer.
MP.THREEP = MP.THREEP or {}

--- True when the current lobby has more than 2 players.
function MP.THREEP.is_3p()
	return MP.LOBBY ~= nil and (MP.LOBBY.player_count or 0) > 2
end

--- The alive opponent with the highest score this blind (ties: more lives).
function MP.THREEP.pick_focus()
	local best = nil
	for _, e in pairs((MP.GAME and MP.GAME.enemies) or {}) do
		if not e.eliminated then
			if
				best == nil
				or MP.INSANE_INT.greater_than(e.real_score, best.real_score)
				or (MP.INSANE_INT.equal(e.real_score, best.real_score) and (e.lives or 0) > (best.lives or 0))
			then
				best = e
			end
		end
	end
	return best
end

--- Sorted list of opponents for display (alive first, then by name).
function MP.THREEP.sorted_enemies()
	local list = {}
	for _, e in pairs((MP.GAME and MP.GAME.enemies) or {}) do
		list[#list + 1] = e
	end
	table.sort(list, function(a, b)
		if (a.eliminated and true or false) ~= (b.eliminated and true or false) then return not a.eliminated end
		return tostring(a.username) < tostring(b.username)
	end)
	return list
end

--- Rebuild the text shown in the PvP blind HUD and lobby info, e.g.
--- "Bob 1,200 (3h) 2L | Carol ??? (4h) 3L"
function MP.THREEP.refresh_hud()
	if not MP.GAME or not MP.GAME.enemy then return end
	local parts = {}
	local hide = MP.LOBBY.config.hide_score_until_played
		and MP.is_pvp_boss
		and MP.is_pvp_boss()
		and G.GAME
		and G.GAME.current_round
		and G.GAME.current_round.hands_played == 0
	for _, e in ipairs(MP.THREEP.sorted_enemies()) do
		if e.eliminated then
			parts[#parts + 1] = tostring(e.username) .. " X"
		else
			local sc = hide and "???" or MP.INSANE_INT.to_string(e.real_score or MP.INSANE_INT.empty())
			parts[#parts + 1] = string.format("%s %s (%sh) %sL%s", tostring(e.username), sc, tostring(e.hands or "?"), tostring(e.lives or "?"), e.away and " (away)" or "")
		end
	end
	if #parts == 0 then
		MP.GAME.enemy.hud_title = MP.GAME.enemy.username or ""
	else
		MP.GAME.enemy.hud_title = table.concat(parts, " | ")
	end
	MP.GAME.enemy.opponents_text = MP.GAME.enemy.hud_title
end

--- Lobby seat table by role ("host" | "guest" | "third"); never nil.
function MP.THREEP.lobby_player(role)
	local t = (role == "host" and MP.LOBBY.host) or (role == "guest" and MP.LOBBY.guest) or (role == "third" and MP.LOBBY.third)
	t = t or {}
	if t.config and t.config.Mods then return t end
	return { username = t.username, hash = t.hash, config = { Mods = {} } }
end

--- 3P game-over "nemesis": who to show on the Game Over screen (name + jokers + deck).
--- Lost: the strongest opponent still in the game (most lives, then highest score).
--- Won: the last opponent eliminated (the runner-up). Falls back to any known opponent.
function MP.THREEP.pick_nemesis(won)
	local enemies = (MP.GAME and MP.GAME.enemies) or {}
	local function alive(e) return not e.eliminated and (e.lives == nil or e.lives > 0) end
	local function stronger(a, b)
		if b == nil then return true end
		if (a.lives or 0) ~= (b.lives or 0) then return (a.lives or 0) > (b.lives or 0) end
		local ok, gt = pcall(MP.INSANE_INT.greater_than, a.real_score or MP.INSANE_INT.empty(), b.real_score or MP.INSANE_INT.empty())
		return ok and gt
	end
	if won then
		local order = (MP.GAME and MP.GAME.elim_order) or {}
		for i = #order, 1, -1 do
			if enemies[order[i]] then return enemies[order[i]] end
		end
	end
	local best, any = nil, nil
	for _, e in pairs(enemies) do
		any = any or e
		if alive(e) and stronger(e, best) then best = e end
	end
	if best then return best end
	-- nobody alive (or all away): last eliminated, then anyone
	local order = (MP.GAME and MP.GAME.elim_order) or {}
	if order[#order] and enemies[order[#order]] then return enemies[order[#order]] end
	return any
end

--- Display name for the Game Over nemesis; never "ERROR".
function MP.THREEP.nemesis_name(e)
	local name = e and ((MP.LOBBY.names_by_id and e.id and MP.LOBBY.names_by_id[e.id]) or e.username)
	if name and name ~= "" and name ~= "?" then return name end
	local other = (MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host) or {}
	if other.username and other.username ~= "" then return other.username end
	if MP.GAME and MP.GAME.enemy and MP.GAME.enemy.username and MP.GAME.enemy.username ~= "" then
		return MP.GAME.enemy.username
	end
	return "Opponent"
end

--- Choose the nemesis for this game end and remember its id for targeted requests.
function MP.THREEP.set_game_end_nemesis(won)
	local e = MP.THREEP.pick_nemesis(won)
	MP.GAME.nemesis_id = (e and e.id ~= "legacy") and e.id or nil
	MP.GAME.nemesis_name = MP.THREEP.nemesis_name(e)
	sendInfoMessage("Game over nemesis: " .. tostring(MP.GAME.nemesis_name) .. " (" .. tostring(MP.GAME.nemesis_id) .. ")", "MULTIPLAYER")
	return e
end
