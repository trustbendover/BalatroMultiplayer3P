-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_third_wheel.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "third_wheel", path = "j_third_wheel.png", px = 71, py = 95 })

SMODS.Joker({
	key = "third_wheel",
	atlas = "third_wheel",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { mult_max = 24 } },
	-- +Mult x (share of rival groups with more lives than you); 1v1: +24 while behind
	mp_include = function(self) return MP.J3P.available(2) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local m = MP.GAME and MP.GAME.enemies and MP.J3P.third_wheel_mult(MP.J3P.my_lives()) or 0
		return { vars = { MP.J3P.SCALE.third_wheel_max, m } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code then
			local m = MP.J3P.third_wheel_mult(MP.J3P.my_lives())
			if m > 0 then return { mult = m } end
		end
	end,
})
