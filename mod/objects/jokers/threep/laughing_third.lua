-- Balatro Multiplayer 3P: special 3-player joker (see docs/JOKERS_3P_NL.md). GPL-3.0.
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
	mp_include = function(self) return MP.J3P.available() end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.gain, card.ability.extra.x_mult } }
	end,
	add_to_deck = function(self, card, from_debuff)
		if not from_debuff then MP.J3P.poll(card) end
	end,
	update = function(self, card, dt)
		if G.STAGE ~= G.STAGES.RUN or card.area ~= G.jokers or card.debuff then return end
		local ev = MP.J3P.poll(card)
		if ev and ev.life_losses > 0 then
			card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.gain * ev.life_losses
			MP.J3P.say(card, localize("k_upgrade_ex"), G.C.MULT)
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.x_mult > 1 then
			return { x_mult = card.ability.extra.x_mult }
		end
	end,
})
