-- luajit tests/test_jokers_3p.lua (run from mod root): special multiplayer jokers, 2-8 players + Teams
MP = { LOBBY = { code = "ABCDE", config = { multiplayer_jokers = true }, player_count = 3 }, GAME = { lives = 3, enemies = {} }, UTILS = {} }
G = { STAGE = 1, STAGES = { RUN = 1 }, C = {}, jokers = {}, hand = { size = 8, change_size = function(self, n) self.size = self.size + n end } }
local dollars = 0
function ease_dollars(n) dollars = dollars + n end
function localize(k) return type(k) == "string" and k or "?" end
function card_eval_status_text() end
MP.UTILS.add_nemesis_info = function() end
local pvp = false
MP.is_pvp_boss = function() return pvp end
local defs = {}
SMODS = { Atlas = function() end, Joker = function(t) defs[t.key] = t end }
dofile("lib/modes.lua"); dofile("lib/teams.lua"); dofile("lib/jokers_3p.lua")
for _, k in ipairs({ "third_wheel", "vulture", "laughing_third", "kingslayer", "bounty_hunter", "middle_of_the_pack", "triumvirate" }) do
	dofile("objects/jokers/threep/" .. k .. ".lua")
end
local J = MP.J3P
local function ok(c, m) assert(c, m); print("ok: " .. m) end
local function deep(t) local r = {} for k, v in pairs(t) do r[k] = type(v) == "table" and deep(v) or v end return r end
local function card(key) local d = defs[key]; return { ability = { extra = deep(d.config.extra) }, area = G.jokers, def = d } end
local main = { cardarea = G.jokers, joker_main = true }
local function E(t) MP.GAME.enemies = t end

-- helpers
E({ b = { id = "b", lives = 4 }, c = { id = "c", lives = 2 } })
ok(J.count_ahead(3) == 1 and J.is_middle(3) and J.players_in(3) == 3, "count_ahead / middle / players_in")
ok(J.lives_leader(3) == "b" and J.opponent_leads(3) and not J.opponent_leads(5), "lives leader")
ok(J.lives_leader(4) == nil, "tied top = no leader")
ok(J.opponent_leads(5, nil, { kingId = "c", you = "a" }) and not J.opponent_leads(1, nil, { kingId = "a", you = "a" }), "KotH crown decides the leader")
E({ b = { id = "b", lives = 0, eliminated = true }, c = { id = "c", lives = 2 } })
ok(J.players_in(3) == 2 and not J.is_middle(3), "eliminated players don't count")

-- gating
local n = 0; for _, d in pairs(defs) do n = n + 1; assert(d.mp_include() == true, d.key) end
ok(n == 7, "7 jokers, all available in a 3-player MP lobby")
E({ b = { id = "b", lives = 3 } })
ok(not defs.vulture.mp_include() and not defs.laughing_third.mp_include() and not defs.middle_of_the_pack.mp_include(), "1v1: Vulture, Laughing Third, Middle of the Pack not offered")
ok(defs.third_wheel.mp_include() and defs.kingslayer.mp_include() and defs.bounty_hunter.mp_include() and defs.triumvirate.mp_include(), "1v1: the other four are offered")
MP.LOBBY.config.multiplayer_jokers = false; E({ b = { id = "b", lives = 3 }, c = { id = "c", lives = 3 } })
ok(not defs.vulture.mp_include(), "respects the multiplayer_jokers lobby option")
MP.LOBBY.config.multiplayer_jokers = true

-- Third Wheel
E({ b = { id = "b", lives = 4 }, c = { id = "c", lives = 5 } }); MP.GAME.lives = 3
local c = card("third_wheel")
ok(defs.third_wheel.calculate(nil, c, main).mult == 24, "Third Wheel: +12 per opponent ahead")
MP.GAME.lives = 5; ok(defs.third_wheel.calculate(nil, c, main) == nil, "Third Wheel: nothing when nobody is ahead")

-- Kingslayer / Triumvirate (PvP only)
MP.GAME.lives = 3; E({ b = { id = "b", lives = 4 }, c = { id = "c", lives = 2 } })
c = card("kingslayer")
ok(defs.kingslayer.calculate(nil, c, main) == nil, "Kingslayer: only in PvP blinds")
pvp = true
ok(defs.kingslayer.calculate(nil, c, main).x_mult == 2, "Kingslayer: X2 while an opponent leads")
MP.GAME.koth = { kingId = "a", you = "a" }
ok(defs.kingslayer.calculate(nil, c, main) == nil, "Kingslayer: off while you are King")
MP.GAME.koth = nil
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 2, "Triumvirate: X2 with three in (0.5 + 0.5 x 3)")
MP.GAME.enemies.c.eliminated = true
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 1.5, "Triumvirate: X1.5 with two left")
MP.GAME.enemies.c.eliminated = false; pvp = false

-- Middle of the Pack
c = card("middle_of_the_pack")
ok(defs.middle_of_the_pack.calculate(nil, c, main).x_mult == 1.5, "Middle of the Pack: X1.5 in the middle")
MP.GAME.lives = 5; ok(defs.middle_of_the_pack.calculate(nil, c, main).mult == 10, "Middle of the Pack: +10 Mult otherwise")

-- event jokers: Vulture, Laughing Third, Bounty Hunter
MP.GAME.lives = 3; E({ b = { id = "b", lives = 4 }, c = { id = "c", lives = 1 } })
local v, l, h = card("vulture"), card("laughing_third"), card("bounty_hunter")
for _, x in ipairs({ v, l, h }) do x.def.add_to_deck(nil, x, false) end
for _, x in ipairs({ v, l, h }) do x.def.update(nil, x, 0) end
ok(dollars == 0 and l.ability.extra.x_mult == 1, "no events right after buying")
MP.GAME.enemies.b.lives = 3 -- leader b loses a life
for _, x in ipairs({ v, l, h }) do x.def.update(nil, x, 0) end
ok(l.ability.extra.x_mult == 1.25, "Laughing Third: +X0.25 per opponent life lost")
ok(h.ability.extra.mult == 3 and dollars == 4, "Bounty Hunter: leader fell -> $4 and +3 Mult")
MP.GAME.enemies.c.lives = 0; MP.GAME.enemies.c.eliminated = true
for _, x in ipairs({ v, l, h }) do x.def.update(nil, x, 0) end
ok(dollars == 12 and G.hand.size == 9 and v.ability.extra.hands == 1, "Vulture: elimination -> $8 and +1 hand size")
ok(l.ability.extra.x_mult == 1.5, "Laughing Third counts the eliminating life too")
ok(defs.laughing_third.calculate(nil, l, main).x_mult == 1.5 and defs.bounty_hunter.calculate(nil, h, main).mult == 3, "scaled jokers score")
v.def.remove_from_deck(nil, v, false)
ok(G.hand.size == 8, "Vulture: hand size returned when sold")
-- KotH: opponent King dethroned (e.g. by you) counts as the leader falling
E({ b = { id = "b", lives = 3 }, c = { id = "c", lives = 3 } }); MP.GAME.koth = { kingId = "b", you = "a" }
h.def.update(nil, h, 0)
MP.GAME.koth = { kingId = "a", you = "a" }
h.def.update(nil, h, 0)
ok(h.ability.extra.mult == 6 and dollars == 16, "Bounty Hunter: King dethroned in KotH")
-- shop copies never react
local s = card("laughing_third"); s.area = {}; MP.GAME.enemies.b.lives = 1
s.def.update(nil, s, 0); ok(s.ability.extra.snap == nil, "cards in the shop don't track")
-- loc_vars never crash
for k, d in pairs(defs) do assert(d.loc_vars(d, {}, card(k)).vars, k) end
ok(true, "loc_vars for all jokers")

-- ===== scaling tables =====
local S = J.SCALE
ok(S.vulture_money(2) == 8 and S.vulture_money(4) == 4 and S.vulture_money(7) == 3, "Vulture $: 8 / 4 / 3 for 2 / 4 / 7 rivals")
ok(S.laughing_gain(2) == 0.25 and S.laughing_gain(4) == 0.12 and S.laughing_gain(7) == 0.07, "Laughing Third gain: 0.25 / 0.12 / 0.07")
ok(S.kingslayer_x(1) == 2 and S.kingslayer_x(2) == 2 and S.kingslayer_x(4) == 1.5 and S.kingslayer_x(7) == 1.29, "Kingslayer: X2 / X2 / X1.5 / X1.29")
ok(S.bounty_money(1) == 4 and S.bounty_money(7) == 2 and S.bounty_mult(2) == 3 and S.bounty_mult(7) == 1, "Bounty Hunter scaling")
ok(S.triumvirate_x(2) == 1.5 and S.triumvirate_x(4) == 2.5 and S.triumvirate_x(8) == 3, "Triumvirate: X1.5 / X2.5 / capped X3")

-- ===== 1v1 =====
pvp = true; MP.GAME.koth = nil; MP.GAME.lives = 2
E({ b = { id = "b", lives = 4 } })
ok(defs.third_wheel.calculate(nil, card("third_wheel"), main).mult == 24, "1v1 Third Wheel: +24 while behind")
ok(defs.kingslayer.calculate(nil, card("kingslayer"), main).x_mult == 2, "1v1 Kingslayer: X2 while behind")
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 1.5, "1v1 Triumvirate: X1.5")
MP.GAME.lives = 4; ok(defs.third_wheel.calculate(nil, card("third_wheel"), main) == nil and defs.kingslayer.calculate(nil, card("kingslayer"), main) == nil, "1v1: tied lives -> off")

-- ===== 8 players (7 rivals) =====
local eight = {}
for i = 1, 7 do eight["p" .. i] = { id = "p" .. i, lives = i <= 3 and 4 or 1 } end
E(eight); MP.GAME.lives = 2
for _, d in pairs(defs) do assert(d.mp_include(), d.key .. " offered with 8 players") end
ok(true, "8 players: all 7 jokers offered")
ok(defs.third_wheel.calculate(nil, card("third_wheel"), main).mult == 10, "8p Third Wheel: 3 of 7 ahead -> +10")
ok(defs.kingslayer.calculate(nil, card("kingslayer"), main).x_mult == 1.29, "8p Kingslayer: X1.29")
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 3, "8p Triumvirate: capped X3")
ok(defs.middle_of_the_pack.calculate(nil, card("middle_of_the_pack"), main).x_mult == 1.5, "8p Middle of the Pack: middle ranks")
local lt, vu, bh = card("laughing_third"), card("vulture"), card("bounty_hunter")
dollars = 0
for _, x in ipairs({ lt, vu, bh }) do x.def.add_to_deck(nil, x, false); x.def.update(nil, x, 0) end
for i = 4, 7 do eight["p" .. i].lives = 0; eight["p" .. i].eliminated = true end
for _, x in ipairs({ lt, vu, bh }) do x.def.update(nil, x, 0) end
ok(lt.ability.extra.x_mult == 1.28, "8p Laughing Third: 4 lives lost x 0.07 = X1.28 (" .. lt.ability.extra.x_mult .. ")")
ok(dollars == 12 and vu.ability.extra.hands == 2, "8p Vulture: 4 eliminations -> 4 x $3, hand size capped at +2")
lt.ability.extra.x_mult = 2.99; eight.p1.lives = 1
lt.def.update(nil, lt, 0)
ok(lt.ability.extra.x_mult == 3, "Laughing Third capped at X3")
bh.ability.extra.mult = 23; bh.ability.extra.snap = nil; bh.def.update(nil, bh, 0)
eight.p2.lives = 4; eight.p3.lives = 4; eight.p1.lives = 5; bh.def.update(nil, bh, 0); eight.p1.lives = 3; bh.def.update(nil, bh, 0)
ok(bh.ability.extra.mult == 24, "Bounty Hunter capped at +24")
vu.def.remove_from_deck(nil, vu, false)

-- ===== Teams (teammates are not rivals; a team counts once) =====
MP.LOBBY.config.gamemode = "gamemode_mp_teams"; MP.LOBBY.my_id = "me"
MP.GAME.teams = { you = "me", team = "A", teams = {
	A = { lives = 2, members = { { id = "me" }, { id = "a2" } } },
	B = { lives = 4, members = { { id = "b1" }, { id = "b2" } } } } }
E({ a2 = { id = "a2", lives = 2 }, b1 = { id = "b1", lives = 4 }, b2 = { id = "b2", lives = 4 } }); MP.GAME.lives = 2
ok(J.rival_count() == 2 and J.group_count() == 1, "2v2: 2 rivals in 1 rival team, teammate excluded")
ok(not defs.middle_of_the_pack.mp_include(), "2v2: Middle of the Pack not offered (only one rival team)")
ok(defs.vulture.mp_include() and defs.laughing_third.mp_include(), "2v2: Vulture / Laughing Third offered (4 players)")
ok(defs.third_wheel.calculate(nil, card("third_wheel"), main).mult == 24, "2v2 Third Wheel: the rival team is ahead -> +24")
local lt2 = card("laughing_third"); lt2.def.add_to_deck(nil, lt2, false); lt2.def.update(nil, lt2, 0)
MP.GAME.enemies.b1.lives = 3; MP.GAME.enemies.b2.lives = 3
MP.GAME.enemies.a2.lives = 1 -- teammate losing a life never counts
lt2.def.update(nil, lt2, 0)
ok(lt2.ability.extra.x_mult == 1.25, "2v2 Laughing Third: a rival team life counts once (X1.25)")
MP.GAME.teams.teams.C = { lives = 1, members = { { id = "c1" }, { id = "c2" } } }
MP.GAME.enemies.c1 = { id = "c1", lives = 1 }; MP.GAME.enemies.c2 = { id = "c2", lives = 1 }
ok(defs.middle_of_the_pack.mp_include() and defs.middle_of_the_pack.calculate(nil, card("middle_of_the_pack"), main).x_mult == 1.5, "2v2v2: Middle of the Pack between team B and team C")
MP.LOBBY.config.gamemode = "gamemode_mp_attrition"; MP.GAME.teams = nil; pvp = false
print("PASS test_jokers_3p")
