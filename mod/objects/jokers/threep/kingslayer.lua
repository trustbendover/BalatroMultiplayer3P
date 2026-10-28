-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_kingslayer.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "kingslayer", path = "j_kingslayer.png", px = 71, py = 95 })

SMODS.Joker({
	key = "kingslayer",
	atlas = "kingslayer",
	rarity = 2,
	cost = 7,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { x_mult = 2 } },
	-- X(1 + min(1, 2 / rivals)): X2 with 1-2 rivals, X1.5 with 4, X1.29 with 7
	mp_include = function(self) return MP.J3P.available(2) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		local on = MP.GAME and MP.GAME.enemies and MP.J3P.opponent_leads(MP.J3P.my_lives(), nil, MP.GAME.koth) or false
		local x = MP.J3P.SCALE.kingslayer_x(math.max(1, MP.J3P.rival_count()))
		return { vars = { x, localize(on and "k_mp3p_active" or "k_mp3p_inactive") } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code and MP.is_pvp_boss()
			and MP.J3P.opponent_leads(MP.J3P.my_lives(), nil, MP.GAME.koth) then
			return { x_mult = MP.J3P.SCALE.kingslayer_x(math.max(1, MP.J3P.rival_count())) }
		end
	end,
})
