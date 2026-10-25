-- luajit tests/test_jokers_3p.lua (run from mod root): special 3-player jokers
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
dofile("lib/jokers_3p.lua")
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
ok(not defs.triumvirate.mp_include(), "not in the shop with only 1 opponent")
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
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 3, "Triumvirate: X3 with all three in")
MP.GAME.enemies.c.eliminated = true
ok(defs.triumvirate.calculate(nil, card("triumvirate"), main).x_mult == 2, "Triumvirate: X2 with two left")
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
print("PASS test_jokers_3p")
