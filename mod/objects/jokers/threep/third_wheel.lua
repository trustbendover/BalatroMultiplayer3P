-- Balatro Multiplayer 3P: special 3-player joker (see docs/JOKERS_3P_NL.md). GPL-3.0.
-- Art: PLACEHOLDER sprite (assets/*/j_third_wheel.png) until real art is made.
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
	config = { extra = { mult_per = 12 } },
	mp_include = function(self) return MP.J3P.available() end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "placeholder" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local n = MP.GAME and MP.GAME.enemies and MP.J3P.count_ahead(MP.J3P.my_lives()) or 0
		return { vars = { card.ability.extra.mult_per, n * card.ability.extra.mult_per } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code then
			local n = MP.J3P.count_ahead(MP.J3P.my_lives())
			if n > 0 then return { mult = n * card.ability.extra.mult_per } end
		end
	end,
})
