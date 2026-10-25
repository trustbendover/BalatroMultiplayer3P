-- Balatro Multiplayer 3P: special 3-player joker (see docs/JOKERS_3P_NL.md). GPL-3.0.
-- Art: original Balatro-style pixel art (assets/*/j_vulture.png), drawn by tools/joker_art_3p/j3p_cards.py
SMODS.Atlas({ key = "vulture", path = "j_vulture.png", px = 71, py = 95 })

SMODS.Joker({
	key = "vulture",
	atlas = "vulture",
	rarity = 1,
	cost = 5,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { money = 8, hands = 0, max_hands = 2 } },
	mp_include = function(self) return MP.J3P.available() end,
	mp_credits = { idea = { "Trust Ben Dover" }, art = { "Trust Ben Dover" }, code = { "Trust Ben Dover" } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.money, card.ability.extra.max_hands, card.ability.extra.hands } }
	end,
	add_to_deck = function(self, card, from_debuff)
		if not from_debuff then MP.J3P.poll(card) end -- only eliminations after buying count
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and card.ability.extra.hands > 0 and G.hand then
			G.hand:change_size(-card.ability.extra.hands)
			card.ability.extra.hands = 0
		end
	end,
	update = function(self, card, dt)
		if G.STAGE ~= G.STAGES.RUN or card.area ~= G.jokers or card.debuff then return end
		local ev = MP.J3P.poll(card)
		if not ev or ev.eliminations < 1 then return end
		for _ = 1, ev.eliminations do
			ease_dollars(card.ability.extra.money)
			if card.ability.extra.hands < card.ability.extra.max_hands and G.hand then
				card.ability.extra.hands = card.ability.extra.hands + 1
				G.hand:change_size(1)
			end
		end
		MP.J3P.say(card, localize("$") .. card.ability.extra.money, G.C.MONEY)
	end,
})
