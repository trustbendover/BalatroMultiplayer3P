-- luajit tests/test_three_player.lua (run from mod root)
MP = { LOBBY = { config = {}, player_count = 3 }, GAME = { enemy = {} }, UTILS = {} }
function MP.UTILS.string_split(s, sep) local t = {} for x in (s .. sep):gmatch("(.-)" .. sep) do t[#t + 1] = x end return t end
function number_format(n) return tostring(n) end
MP.is_pvp_boss = function() return true end
G = { GAME = { current_round = { hands_played = 1 } } }
dofile("lib/insane_int.lua"); dofile("lib/three_player.lua")
local I = MP.INSANE_INT
MP.GAME.enemies = {
  a = { id = "a", username = "Bob", real_score = I.from_string("100"), lives = 2, hands = 1 },
  b = { id = "b", username = "Carol", real_score = I.from_string("250"), lives = 1, hands = 2 },
}
assert(MP.THREEP.is_3p())
assert(MP.THREEP.pick_focus().id == "b", "highest score is focus")
MP.GAME.enemies.b.eliminated = true
assert(MP.THREEP.pick_focus().id == "a", "eliminated never focus")
MP.THREEP.refresh_hud()
assert(MP.GAME.enemy.hud_title == "Bob 100 (1h) 2L | Carol X", MP.GAME.enemy.hud_title)
MP.LOBBY.config.hide_score_until_played = true; G.GAME.current_round.hands_played = 0
MP.THREEP.refresh_hud(); assert(MP.GAME.enemy.hud_title:find("???", 1, true))
MP.LOBBY.guest = {}
assert(MP.THREEP.lobby_player("guest").config.Mods and MP.LOBBY.guest.config == nil, "no mutation")
-- 0.6.5: Game Over nemesis (never "ERROR")
function sendInfoMessage() end
MP.LOBBY.names_by_id = {}
MP.GAME.enemies = {
  a = { id = "a", username = "Bob", real_score = I.from_string("100"), lives = 2 },
  b = { id = "b", username = "Carol", real_score = I.from_string("900"), lives = 1 },
  c = { id = "c", username = "Dave", real_score = I.from_string("50"), lives = 0, eliminated = true },
}
MP.GAME.elim_order = { "c" }
assert(MP.THREEP.pick_nemesis(false).id == "a", "lost: most lives wins nemesis")
MP.GAME.enemies.b.lives = 2
assert(MP.THREEP.pick_nemesis(false).id == "b", "lost: tie on lives -> higher score")
MP.GAME.enemies.a.eliminated = true; MP.GAME.enemies.b.eliminated = true; MP.GAME.elim_order = { "c", "a", "b" }
assert(MP.THREEP.pick_nemesis(true).id == "b", "won: last eliminated is nemesis")
assert(MP.THREEP.pick_nemesis(false).id == "b", "nobody alive: last eliminated")
MP.GAME.enemies = {}; MP.GAME.elim_order = nil; MP.LOBBY.host = nil; MP.LOBBY.guest = nil; MP.GAME.enemy = {}
assert(MP.THREEP.pick_nemesis(true) == nil)
assert(MP.THREEP.nemesis_name(nil) == "Opponent", "no enemy -> Opponent, not ERROR")
MP.GAME.enemies = { x = { id = "x", username = "?", lives = 1 } }; MP.LOBBY.names_by_id = { x = "Eve" }
MP.THREEP.set_game_end_nemesis(false)
assert(MP.GAME.nemesis_id == "x" and MP.GAME.nemesis_name == "Eve", tostring(MP.GAME.nemesis_name))
MP.GAME.enemies = { legacy = { id = "legacy", username = "?", lives = 1 } }; MP.LOBBY.names_by_id = {}
MP.LOBBY.is_host = true; MP.LOBBY.guest = { username = "Guesty" }
MP.THREEP.set_game_end_nemesis(true)
assert(MP.GAME.nemesis_id == nil and MP.GAME.nemesis_name == "Guesty", "2P fallback to guest name")
print("PASS test_three_player")
