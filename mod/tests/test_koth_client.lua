-- luajit tests/test_koth_client.lua (run from mod root): KotH client texts/messages + HUD marker
MP = { LOBBY = { config = { gamemode = "gamemode_mp_koth" }, names_by_id = { b = "Bob", c = "Carol" }, player_count = 3 }, GAME = { enemy = {} }, UTILS = {} }
function localize() return "ERROR" end -- force English fallbacks
function MP.UTILS.string_split(s, sep) local t = {} for x in (s .. sep):gmatch("(.-)" .. sep) do t[#t + 1] = x end return t end
function number_format(n) return tostring(n) end
local dollars = 0
function ease_dollars(n) dollars = dollars + n end
G = {} -- no UI in tests: badge/messages are pcall'd
dofile("lib/insane_int.lua"); dofile("lib/three_player.lua"); dofile("lib/koth.lua")
local K = MP.KOTH
local function ok(c, m) assert(c, m); print("ok: " .. m) end

ok(K.is_active(), "gamemode detected")
K.on_update({ you = "a", kingId = nil, streak = 0, bounty = 0, holdTarget = 4, snapshot = true })
ok(MP.GAME.koth_text == "No King yet - top score takes the crown", "no king text")
K.on_update({ you = "a", kingId = "b", kingName = "Bob", streak = 2, bounty = 2, holdTarget = 4, reward = 0 })
ok(MP.GAME.koth_text == "King: Bob  |  Bounty 2  |  Hill 2/4", MP.GAME.koth_text)
ok(K.name_prefix("b") == "[K] " and K.name_prefix("c") == "", "crown marker for the King")
MP.GAME.enemies = { b = { id = "b", username = "Bob", real_score = MP.INSANE_INT.from_string("10"), lives = 3, hands = 4 },
	c = { id = "c", username = "Carol", real_score = MP.INSANE_INT.from_string("5"), lives = 2, hands = 4 } }
MP.is_pvp_boss = function() return false end
MP.THREEP.refresh_hud()
ok(MP.GAME.enemy.hud_title:find("[K] Bob", 1, true) == 1, "HUD shows [K] before the King: " .. MP.GAME.enemy.hud_title)

local m = K.messages({ you = "a", claimedBy = "a", reward = 12, lifeBonus = true, prevKingId = "b", prevKingName = "Bob", kingId = "a" })
ok(m[1] == "Bounty claimed! +$12" and m[2] == "+1 life from the bounty!", "claim messages")
K.on_update({ you = "a", claimedBy = "a", reward = 12, kingId = "a", streak = 1, bounty = 1, holdTarget = 4 })
ok(dollars == 12, "bounty paid out with ease_dollars")
ok(MP.GAME.koth_text == "King: You  |  Bounty 1  |  Hill 1/4", "you are king text")
K.on_update({ you = "b", claimedBy = "a", reward = 4, kingId = "a", streak = 1, bounty = 1, holdTarget = 4 })
ok(dollars == 12, "only the claimer gets paid")
m = K.messages({ you = "b", shieldedId = "b", claimedBy = "c", claimedName = "Carol", prevKingName = "Bob", reward = 8, kingId = "c" })
ok(m[1] == "Carol dethroned Bob (+$8)" and m[2] == "Crown shield: you lose the crown, not a life", "shield + dethrone messages")
m = K.messages({ you = "a", crowned = true, kingId = "a" })
ok(m[1] == "You are the King! Both rivals are after you", "crowned message")
m = K.messages({ you = "a", winnerId = "b", kingName = "Bob" })
ok(m[1] == "Bob held the hill and wins!", "hill win message")
m = K.messages({ you = "b", prevKingId = "b", kingId = nil })
ok(m[1] == "You lost the crown", "vacant crown message")
ok(#K.messages({ snapshot = true, you = "a", kingId = "a" }) == 0, "snapshot shows no popups")
K.on_update("garbage"); ok(true, "bad payload ignored")
print("PASS test_koth_client")
