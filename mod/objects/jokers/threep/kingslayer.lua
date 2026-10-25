-- Balatro Multiplayer 3P: special 3-player joker (see docs/JOKERS_3P_NL.md). GPL-3.0.
-- Art: PLACEHOLDER sprite (assets/*/j_kingslayer.png) until real art is made.
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
	mp_include = function(self) return MP.J3P.available() end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "placeholder" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		local on = MP.GAME and MP.GAME.enemies and MP.J3P.opponent_leads(MP.J3P.my_lives(), nil, MP.GAME.koth) or false
		return { vars = { card.ability.extra.x_mult, localize(on and "k_mp3p_active" or "k_mp3p_inactive") } }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and MP.LOBBY.code and MP.is_pvp_boss()
			and MP.J3P.opponent_leads(MP.J3P.my_lives(), nil, MP.GAME.koth) then
			return { x_mult = card.ability.extra.x_mult }
		end
	end,
})
