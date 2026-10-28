-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_middle_of_the_pack.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "middle_of_the_pack", path = "j_middle_of_the_pack.png", px = 71, py = 95 })

SMODS.Joker({
	key = "middle_of_the_pack",
	atlas = "middle_of_the_pack",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { x_mult = 1.5, mult = 10 } },
	-- needs 2+ rival groups (3+ players; Teams: 3+ teams) - in a 1v1 or 2-team game there is no middle
	mp_include = function(self) return MP.J3P.available(3, 2) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local mid = MP.GAME and MP.GAME.enemies and MP.J3P.is_middle(MP.J3P.my_lives()) or false
		return { vars = { card.ability.extra.x_mult, card.ability.extra.mult, localize(mid and "k_mp3p_active" or "k_mp3p_inactive") } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code then
			if MP.J3P.is_middle(MP.J3P.my_lives()) then return { x_mult = card.ability.extra.x_mult } end
			return { mult = card.ability.extra.mult }
		end
	end,
})
