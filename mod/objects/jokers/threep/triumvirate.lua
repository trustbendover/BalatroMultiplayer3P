-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_triumvirate.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "triumvirate", path = "j_triumvirate.png", px = 71, py = 95 })

SMODS.Joker({
	key = "triumvirate",
	atlas = "triumvirate",
	rarity = 3,
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { } },
	-- X(0.5 + 0.5 per player still in), capped at X3: X1.5 in a 1v1, X3 from 5 players
	mp_include = function(self) return MP.J3P.available(2) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local n = MP.GAME and MP.GAME.enemies and MP.J3P.players_in(MP.J3P.my_lives()) or 0
		return { vars = { MP.J3P.SCALE.triumvirate_x(math.max(n, 1)) } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code and MP.is_pvp_boss() then
			local n = MP.J3P.players_in(MP.J3P.my_lives())
			if n >= 2 then return { x_mult = MP.J3P.SCALE.triumvirate_x(n) } end
		end
	end,
})
