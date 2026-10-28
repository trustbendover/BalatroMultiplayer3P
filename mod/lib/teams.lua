-- Balatro High Stakes: Teams mode, client side (team state, teammate checks, HUD totals,
-- messages). The rules run on the servers (networking/teams_rules.lua, server/src/teams.ts).
-- GPL-3.0, based on Balatro Multiplayer.
MP.TEAMS = MP.TEAMS or {}
local T = MP.TEAMS

T.LETTERS = { "A", "B", "C", "D" }

function T.colour(letter)
	local C = (G and G.C) or {}
	return ({ A = C.BLUE, B = C.RED, C = C.GREEN, D = C.GOLD })[letter] or C.UI and C.UI.TEXT_LIGHT
end

function T.is_active()
	return MP.MODES ~= nil and MP.MODES.is_teams()
end

function T.state() return MP.GAME and MP.GAME.teams or nil end

--- Team letter of a player id: in a game from teamsUpdate, before it from the lobby preview.
function T.team_of(id)
	if id == nil then return nil end
	local st = T.state()
	if st and st.teams then
		for letter, t in pairs(st.teams) do
			for _, m in ipairs(t.members or {}) do
				if m.id == id then return letter end
			end
		end
	end
	for _, pl in ipairs((MP.LOBBY and MP.LOBBY.player_list) or {}) do
		if pl.id == id then return pl.team end
	end
	return nil
end

function T.my_team()
	local st = T.state()
	if st and st.team then return st.team end
	return T.team_of(MP.LOBBY and MP.LOBBY.my_id)
end

--- True when id plays in my team (never true outside Teams mode, never true for myself).
function T.is_teammate(id)
	if not T.is_active() or id == nil then return false end
	if MP.LOBBY and id == MP.LOBBY.my_id then return false end
	local mine = T.my_team()
	return mine ~= nil and T.team_of(id) == mine
end

--- "[A] Bob" in Teams mode, plain name otherwise.
function T.seat_label(seat)
	if not seat or not seat.username then return "" end
	if T.is_active() and seat.team then return "[" .. seat.team .. "] " .. seat.username end
	return seat.username
end

--- Score sums per team for the HUD: { {letter, score(insane int), lives, mine}, ... }
function T.totals()
	local st = T.state()
	if not st or not st.teams then return {} end
	local out = {}
	for _, letter in ipairs(T.LETTERS) do
		local t = st.teams[letter]
		if t then
			local sum = MP.INSANE_INT.empty()
			for _, m in ipairs(t.members or {}) do
				local sc
				if MP.LOBBY and m.id == MP.LOBBY.my_id then
					sc = MP.GAME.score
				else
					local e = MP.GAME.enemies and MP.GAME.enemies[m.id]
					sc = e and e.real_score
				end
				if sc then
					local ok, r = pcall(MP.INSANE_INT.add, sum, sc)
					if ok and r then sum = r end
				end
			end
			out[#out + 1] = { letter = letter, score = sum, lives = t.lives, mine = letter == st.team }
		end
	end
	return out
end

--- "Team A (you) 12,000 4L | Team B 9,000 3L"
function T.hud_text(hide)
	local parts = {}
	for _, t in ipairs(T.totals()) do
		local sc = hide and "???" or MP.INSANE_INT.to_string(t.score)
		local name = MP.MODES.L("k_teams_team", "Team #1#", { t.letter })
		if t.mine then name = name .. MP.MODES.L("k_teams_you_suffix", " (you)") end
		parts[#parts + 1] = string.format("%s %s %sL", name, sc, tostring(t.lives or "?"))
	end
	return table.concat(parts, " | ")
end

--- Pure: messages for a teamsUpdate (tested in tests/test_teams_client.lua)
function T.messages(p, prev)
	local out = {}
	if type(p) ~= "table" then return out end
	if p.lastLoser == "none" then
		out[#out + 1] = MP.MODES.L("k_teams_msg_tie", "Tie for lowest team - nobody loses a life")
	elseif p.lastLoser and p.lastLoser == p.team then
		out[#out + 1] = MP.MODES.L("k_teams_msg_we_lost", "Your team loses a life")
	elseif p.lastLoser then
		out[#out + 1] = MP.MODES.L("k_teams_msg_lost", "Team #1# loses a life", { p.lastLoser })
	end
	return out
end

function T.on_update(p)
	if type(p) ~= "table" then return end
	MP.GAME = MP.GAME or {}
	MP.GAME.teams = { you = p.you, team = p.team, teamSize = p.teamSize, teams = p.teams or {} }
	for i, msg in ipairs(T.messages(p)) do
		pcall(function()
			G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.6 + (i - 1) * 1.6, blocking = false, blockable = false,
				func = function()
					attention_text({ text = msg, scale = 0.7, hold = 2.5, major = G.play or G.ROOM_ATTACH, align = "cm",
						offset = { x = 0, y = -2.6 }, backdrop_colour = T.colour(p.lastLoser) or G.C.RED, silent = false })
					return true
				end }))
		end)
	end
	pcall(MP.THREEP.refresh_hud)
end

--- Host: random team order (teams_order option) -> server re-sends lobbyInfo with the preview.
function T.shuffle(n, rnd)
	rnd = rnd or math.random
	local list = {}
	for i = 1, n do list[i] = i end
	for i = n, 2, -1 do
		local j = rnd(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return table.concat(list, ",")
end

--- Next team size that fits n players (2 -> 3 -> 4 -> 2 ...), skipping sizes that do not fit.
function T.next_size(n, size)
	size = tonumber(size) or 2
	for _ = 1, 3 do
		size = size + 1
		if size > 4 then size = 2 end
		if n % size == 0 and n / size >= 2 then return size end
	end
	return 2
end

return T
