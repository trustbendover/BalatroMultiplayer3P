-- Balatro High Stakes: special multiplayer joker for 2-8 players (see docs/JOKERS_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_bounty_hunter.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "bounty_hunter", path = "j_bounty_hunter.png", px = 71, py = 95 })

SMODS.Joker({
	key = "bounty_hunter",
	atlas = "bounty_hunter",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	config = { extra = { money = 4, mult_gain = 3, mult = 0 } },
	-- $ and Mult per fallen leader scale down with more rivals; Mult capped at +24
	mp_include = function(self) return MP.J3P.available(2) end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		local r = MP.J3P.rival_count()
		return { vars = { MP.J3P.SCALE.bounty_money(r), MP.J3P.SCALE.bounty_mult(r), card.ability.extra.mult, MP.J3P.SCALE.bounty_cap } }
	end,
	add_to_deck = function(self, card, from_debuff)
		if not from_debuff then MP.J3P.poll(card) end
	end,
	update = function(self, card, dt)
		if G.STAGE ~= G.STAGES.RUN or card.area ~= G.jokers or card.debuff then return end
		local ev = MP.J3P.poll(card)
		if ev and ev.leader_fell then
			local r = MP.J3P.rival_count()
			ease_dollars(MP.J3P.SCALE.bounty_money(r))
			card.ability.extra.mult = math.min(MP.J3P.SCALE.bounty_cap, card.ability.extra.mult + MP.J3P.SCALE.bounty_mult(r))
			MP.J3P.say(card, localize("k_upgrade_ex"), G.C.MONEY)
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.mult > 0 then
			return { mult = card.ability.extra.mult }
		end
	end,
})
