-- Balatro High Stakes: King of the Hill client side (state, HUD badge, messages, bounty payout).
-- GPL-3.0. The rules themselves run on the server (networking/koth_rules.lua / server/src/koth.ts).
MP.KOTH = MP.KOTH or {}
local K = MP.KOTH

local function L(key, fallback, vars)
	local ok, s = pcall(localize, vars and { type = "variable", key = key, vars = vars } or key)
	if ok and type(s) == "string" and s ~= "ERROR" and s ~= key then return s end
	if vars then
		for i, v in ipairs(vars) do fallback = fallback:gsub("#" .. i .. "#", tostring(v)) end
	end
	return fallback
end

function K.is_active()
	local g = MP.LOBBY ~= nil and MP.LOBBY.config ~= nil and MP.LOBBY.config.gamemode
	return g == "gamemode_mp_koth" or g == "koth"
end

function K.state() return MP.GAME and MP.GAME.koth or nil end

function K.king_name(st)
	st = st or K.state()
	if not st or not st.kingId then return nil end
	if st.kingId == st.you then return L("k_koth_you", "You") end
	return (MP.LOBBY.names_by_id and MP.LOBBY.names_by_id[st.kingId]) or st.kingName or "?"
end

--- One-line status, e.g. "King: Bob  |  Bounty 2  |  Hill 2/4"
function K.status_text(st)
	st = st or K.state()
	if not st then return "" end
	if not st.kingId then return L("k_koth_no_king", "No King yet - top score takes the crown") end
	return L("k_koth_status", "King: #1#  |  Bounty #2#  |  Hill #3#/#4#",
		{ K.king_name(st), st.bounty or 0, st.streak or 0, st.holdTarget or 4 })
end

--- Pure: which messages to show for an update (tested in tests/test_koth_client.lua)
function K.messages(p)
	local out = {}
	if p.snapshot then return out end
	local me = p.you
	if p.winnerId then
		out[#out + 1] = p.winnerId == me and L("k_koth_msg_you_hill", "You held the hill! Victory!")
			or L("k_koth_msg_hill", "#1# held the hill and wins!", { p.kingName or "?" })
	end
	if p.claimedBy == me then
		out[#out + 1] = L("k_koth_msg_claimed", "Bounty claimed! +$#1#", { p.reward or 0 })
		if p.lifeBonus then out[#out + 1] = L("k_koth_msg_life", "+1 life from the bounty!") end
	elseif p.claimedBy then
		out[#out + 1] = L("k_koth_msg_other_claimed", "#1# dethroned #2# (+$#3#)", { p.claimedName or "?", p.prevKingName or "?", p.reward or 0 })
	end
	if p.shieldedId == me then out[#out + 1] = L("k_koth_msg_shield", "Crown shield: you lose the crown, not a life") end
	if p.crowned and p.kingId == me then out[#out + 1] = L("k_koth_msg_crowned", "You are the King! Everyone is after you") end
	if p.prevKingId == me and not p.claimedBy and not p.kingId then out[#out + 1] = L("k_koth_msg_lost", "You lost the crown") end
	return out
end

function K.on_update(p)
	if type(p) ~= "table" then return end
	MP.GAME = MP.GAME or {}
	MP.GAME.koth = {
		you = p.you, kingId = p.kingId, kingName = p.kingName, streak = tonumber(p.streak) or 0,
		bounty = tonumber(p.bounty) or 0, holdTarget = tonumber(p.holdTarget) or 4,
	}
	MP.GAME.koth_text = K.status_text(MP.GAME.koth)
	if p.claimedBy and p.claimedBy == p.you and (tonumber(p.reward) or 0) > 0 then
		pcall(ease_dollars, tonumber(p.reward))
	end
	for i, msg in ipairs(K.messages(p)) do
		pcall(function()
			G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.6 + (i - 1) * 1.6, blocking = false, blockable = false,
				func = function()
					attention_text({ text = msg, scale = 0.7, hold = 2.5, major = G.play or G.ROOM_ATTACH, align = "cm",
						offset = { x = 0, y = -2.6 }, backdrop_colour = G.C.GOLD, silent = false })
					return true
				end }))
		end)
	end
	pcall(MP.THREEP.refresh_hud)
	K.ensure_badge(10)
end

--- The first update arrives while the run is still loading: retry until we're in the run.
function K.ensure_badge(tries)
	local ok = pcall(K.show_badge)
	if ok and G.MP3P_KOTH_UI and not G.MP3P_KOTH_UI.REMOVED then return end
	if (tries or 0) <= 0 then return end
	pcall(function()
		G.E_MANAGER:add_event(Event({ trigger = "after", delay = 1, blocking = false, blockable = false, timer = "REAL",
			func = function() K.ensure_badge(tries - 1); return true end }))
	end)
end

--- Small always-visible badge at the top of the screen during a KotH run.
function K.show_badge()
	if not K.is_active() or not G.STAGES or G.STAGE ~= G.STAGES.RUN or not G.ROOM_ATTACH then return end
	if G.MP3P_KOTH_UI and not G.MP3P_KOTH_UI.REMOVED then return end
	G.MP3P_KOTH_UI = UIBox({
		definition = { n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = {
			{ n = G.UIT.R, config = { align = "cm", padding = 0.06, r = 0.1, colour = G.C.UI.TRANSPARENT_DARK }, nodes = {
				{ n = G.UIT.T, config = { ref_table = MP.GAME, ref_value = "koth_text", scale = 0.32, colour = G.C.GOLD, shadow = true } },
			} },
		} },
		config = { align = "tm", bond = "Weak", offset = { x = 0, y = 0.05 }, major = G.ROOM_ATTACH },
	})
end

--- Prefix for an opponent's name in the 3P HUD ("[K] Bob")
function K.name_prefix(id)
	local st = K.state()
	if st and st.kingId and st.kingId == id then return "[K] " end
	return ""
end

return K
