-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_laughing_third.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "laughing_third", path = "j_laughing_third.png", px = 71, py = 95 })

SMODS.Joker({
	key = "laughing_third",
	atlas = "laughing_third",
	rarity = 2,
	cost = 7,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	config = { extra = { gain = 0.25, x_mult = 1 } },
	-- not in a 1v1; gain = X0.5 / rivals per rival life lost, capped at X3
	mp_include = function(self) return MP.J3P.available(3) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local gain = MP.J3P.SCALE.laughing_gain(MP.J3P.rival_count())
		return { vars = { gain, card.ability.extra.x_mult, MP.J3P.SCALE.laughing_cap } }
	end,
	add_to_deck = function(self, card, from_debuff)
		if not from_debuff then MP.J3P.poll(card) end
	end,
	update = function(self, card, dt)
		if G.STAGE ~= G.STAGES.RUN or card.area ~= G.jokers or card.debuff then return end
		local ev = MP.J3P.poll(card)
		if ev and ev.life_losses > 0 and card.ability.extra.x_mult < MP.J3P.SCALE.laughing_cap then
			local gain = MP.J3P.SCALE.laughing_gain(MP.J3P.rival_count())
			card.ability.extra.gain = gain
			card.ability.extra.x_mult = math.min(MP.J3P.SCALE.laughing_cap,
				math.floor((card.ability.extra.x_mult + gain * ev.life_losses) * 100 + 0.5) / 100)
			MP.J3P.say(card, localize("k_upgrade_ex"), G.C.MULT)
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.x_mult > 1 then
			return { x_mult = card.ability.extra.x_mult }
		end
	end,
})
