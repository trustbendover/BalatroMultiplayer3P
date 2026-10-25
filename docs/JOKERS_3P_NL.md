# Speciale 3-speler jokers (BalatroMultiplayer3P 0.6.7, in ontwikkeling)

Onofficiële fork van Balatro Multiplayer (GPL, credits aan Virtualized en het Balatro Multiplayer-team).
Ontwerp en implementatie voor de fork: Trust Ben Dover.

## Doel

Zeven nieuwe Multiplayer-jokers die pas echt werken met **drie** spelers: ze kijken naar *beide*
tegenstanders, wie er aan kop gaat, wie in het midden zit en wie er uitgeschakeld wordt.
In King of the Hill kijken ze naar de kroon; in de andere modi naar de levens.

## Spelregels voor alle 3P-jokers

- Alleen in de winkel/boosters in een multiplayer-lobby met "Multiplayer jokers" aan, en pas als er
  **2 tegenstanders** in de match zitten (in een 1-tegen-1 of solo-run verschijnen ze niet).
- Ze lezen alleen informatie die al naar elke client gesynchroniseerd wordt (levens en
  uitschakelingen van tegenstanders, eigen levens, de King of the Hill-kroon). Daardoor is er geen
  servercode nodig en werken ze identiek via **Steam P2P** en de **TS-server**.
- Ze beïnvloeden tegenstanders nooit (geen griefing): ze belonen alleen jouw eigen run.
- Gebeurtenis-jokers (Gier, Lachende Derde, Premiejager) tellen alleen wat er gebeurt **nadat** je
  ze gekocht hebt; kaarten in de winkel tellen niet mee.

## De jokers

| Naam (EN / NL) | Zeldzaamheid | Prijs | Effect |
|---|---|---|---|
| Third Wheel / Derde Wiel | Common | $4 | +12 Mult voor elke tegenstander met meer levens dan jij (max +24). Catch-up voor wie achter staat. |
| Vulture / Gier | Common | $5 | Als een tegenstander uitgeschakeld wordt: $8 en +1 handgrootte (max +2, weg als je hem verkoopt). Niet Blueprint-compatibel. |
| Laughing Third / Lachende Derde | Uncommon | $7 | Krijgt X0.25 Mult erbij telkens als een tegenstander een leven verliest (ook als ze tegen elkaar verliezen). Start op X1. Niet perishable. |
| Kingslayer / Koningsdoder | Uncommon | $7 | X2 Mult in Aartsvijand/PvP-blinds zolang een tegenstander aan kop gaat (KotH: iemand anders is Koning; anders: een tegenstander heeft strikt de meeste levens). |
| Bounty Hunter / Premiejager | Uncommon | $6 | Als de koploper valt (tegenstander-Koning onttroond, of de tegenstander met de meeste levens verliest een leven): $4 en +3 Mult erbij (stapelt). Niet perishable. |
| Middle of the Pack / Middenmoot | Uncommon | $6 | X1.5 Mult als je precies in het midden zit op levens (één tegenstander meer, één minder), anders +10 Mult. |
| Triumvirate / Driemanschap | Rare | $8 | In Aartsvijand/PvP-blinds X1 Mult per speler die nog meedoet (X3 met z'n drieën, X2 als er één uit is). |

## Balans

- Common/Uncommon-waarden liggen in de buurt van vergelijkbare vanilla jokers (bv. +12 Mult per
  conditie ~ Jolly-niveau, X2 alleen in PvP ~ voorwaardelijke X-mult).
- Catch-up zit vooral in Derde Wiel en Koningsdoder (sterker als je achter staat); Middenmoot
  beloont de "veilige" middenpositie; Driemanschap is sterk maar alleen in PvP-blinds.
- Schaal-jokers groeien langzaam: in een normale match verliezen tegenstanders samen ~4-6 levens,
  dus Lachende Derde eindigt rond X2-X2.5.

## Techniek

- Gedeelde helpers: `mod/lib/jokers_3p.lua` (`MP.J3P`: wie staat voor, middenpositie, koploper,
  snapshot/diff voor gebeurtenissen, gating).
- Jokers: `mod/objects/jokers/threep/*.lua` (sleutels `j_mp_third_wheel`, `j_mp_vulture`,
  `j_mp_laughing_third`, `j_mp_kingslayer`, `j_mp_bounty_hunter`, `j_mp_middle_of_the_pack`,
  `j_mp_triumvirate`), geladen in `core.lua`.
- Teksten: `localization/en-us.lua` en `localization/nl.lua`.
- Tests: `mod/tests/test_jokers_3p.lua`.
- **Art = PLACEHOLDER**: eenvoudige pixelkaarten in het Balatro-kaartkader met "3P"-label,
  gegenereerd met `tools/make_placeholder_jokers.py` (`mod/assets/1x` en `2x`). Vervang de PNG's
  (71x95 / 142x190) door echte art wanneer die er is; de code hoeft niet te veranderen.
