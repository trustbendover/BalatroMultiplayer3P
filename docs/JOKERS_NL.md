# Speciale multiplayer-jokers (Balatro High Stakes 0.6.7, in ontwikkeling)

Onofficiële fork van Balatro Multiplayer (GPL, credits aan Virtualized en het Balatro Multiplayer-team).
Ontwerp en implementatie voor de fork: Trust Ben Dover. (Vroeger "3-speler jokers"; vanaf 0.6.7
herwerkt voor 2 tot 8 spelers.)

## Doel

Zeven Multiplayer-jokers die kijken naar je tegenstanders: wie er aan kop gaat, wie in het midden
zit en wie er uitgeschakeld wordt. In King of the Hill kijken ze naar de kroon; in de andere modi
naar de levens. Alles schaalt mee met het aantal **rivalen** (tegenstanders die niet in jouw team
zitten) en heeft een maximum, zodat ze met 2 en met 8 spelers eerlijk blijven.

## Spelregels voor alle jokers

- Alleen in de winkel/boosters in een multiplayer-lobby met "Multiplayer jokers" aan.
- **Rivalen:** in Teams tellen je teamgenoten nooit mee. Een rivaliserend team telt als één
  "groep" (het team deelt zijn levens), dus een teamleven telt één keer.
- **1v1:** Gier, Lachende Derde en Middenmoot verschijnen niet (met één tegenstander is de enige
  uitschakeling meteen het einde, en er is geen "midden"). De andere vier wel.
- **Middenmoot** heeft minstens 2 rivaliserende groepen nodig: in FFA vanaf 3 spelers, in Teams
  alleen bij 3 of meer teams (2v2v2, 2v2v2v2).
- Ze lezen alleen informatie die al naar elke client gesynchroniseerd wordt (levens en
  uitschakelingen van tegenstanders, eigen levens, de kroon, de teams). Geen servercode nodig:
  ze werken identiek via **Steam P2P** en de **TS-server**.
- Ze beïnvloeden tegenstanders nooit (geen griefing): ze belonen alleen jouw eigen run.
- Gebeurtenis-jokers (Gier, Lachende Derde, Premiejager) tellen alleen wat er gebeurt **nadat** je
  ze gekocht hebt; kaarten in de winkel tellen niet mee.

## De jokers (r = aantal rivalen in de match)

| Naam (EN / NL) | Zeldzaamheid | Prijs | Effect | 1v1 | 3 spelers | 8 spelers |
|---|---|---|---|---|---|---|
| Third Wheel / Derde Wiel | Common | $4 | Tot +24 Mult: +24 × (aandeel levende rivaliserende groepen met meer levens dan jij). | +24 als je achter staat | +12 per rivaal voor (zoals vroeger) | +3 à +4 per rivaal voor |
| Vulture / Gier | Common | $5 | Per uitschakeling: $ = 16/r (min $3) en +1 handgrootte (max +2, weg bij verkopen). | niet in de winkel | $8 | $3 |
| Laughing Third / Lachende Derde | Uncommon | $7 | Per verloren leven van een rivaal: +X(0.5/r) Mult, max X3. Start op X1. | niet in de winkel | +X0.25 | +X0.07 |
| Kingslayer / Koningsdoder | Uncommon | $7 | X(1 + min(1, 2/r)) in PvP-blinds zolang een rivaal voor staat (KotH: iemand anders is Koning; anders: een rivaal heeft meer levens dan jij). | X2 | X2 | X1.29 |
| Bounty Hunter / Premiejager | Uncommon | $6 | Als de koploper valt: $ = 8/r (min $2, in 1v1 $4) en +Mult = 6/r (min +1, in 1v1 +3), Mult max +24. | $4, +3 | $4, +3 | $2, +1 |
| Middle of the Pack / Middenmoot | Uncommon | $6 | X1.5 Mult in de "middenmoot" (minstens één rivaal meer en één minder levens dan jij), anders +10 Mult. | niet in de winkel | zoals vroeger | middelste plaatsen |
| Triumvirate / Driemanschap | Rare | $8 | In PvP-blinds X(0.5 + 0.5 per speler die nog meedoet), max X3. | X1.5 | X2 | X3 (vanaf 5 spelers) |

## Waarom zo (balans)

- Met meer spelers gebeurt er per ronde meer (meer levens verloren, meer uitschakelingen), dus de
  beloning **per gebeurtenis** gaat omlaag (delen door r) en elke groeiende joker heeft een **plafond**
  (Lachende Derde X3, Premiejager +24, Gier +2 handgrootte).
- Driemanschap was X3 met z'n drieën (te sterk voor een Rare in PvP); nu X2 met drie, X1.5 in een
  duel en maximaal X3 in grote lobbies.
- Koningsdoder: met 8 spelers staat bijna altijd iemand voor je, dus het effect is kleiner (X1.29).
- Derde Wiel gebruikt een aandeel, zodat het maximum altijd +24 blijft (ook met 7 tegenstanders).
- Middenmoot "precies in het midden" bestaat alleen met 3 spelers; nu telt elke middenpositie.
- De oude 3-speler-waarden blijven exact gelijk bij 3 spelers (behalve Driemanschap).

## Techniek

- Gedeelde helpers: `mod/lib/jokers_3p.lua` (`MP.J3P`: rivalen en groepen, wie staat voor, middenpositie,
  koploper, snapshot/diff voor gebeurtenissen, gating per joker, schaaltabel `MP.J3P.SCALE`).
- Jokers: `mod/objects/jokers/threep/*.lua` (sleutels `j_mp_third_wheel`, `j_mp_vulture`,
  `j_mp_laughing_third`, `j_mp_kingslayer`, `j_mp_bounty_hunter`, `j_mp_middle_of_the_pack`,
  `j_mp_triumvirate`), geladen in `core.lua`.
- Teksten: `localization/en-us.lua` en `localization/nl.lua`.
- Tests: `mod/tests/test_jokers_3p.lua` (3 spelers, 1v1, 8 spelers, 2v2 en 2v2v2).
- **Art**: eigen pixel-art in Balatro-stijl (witte kaart met JOKER-letters, donkere omlijning,
  beperkt palet), pixel voor pixel getekend op 71x95 en 2x vergroot (nearest-neighbour) naar
  142x190. Gegenereerd met `tools/joker_art_3p/j3p_cards.py` (`mod/assets/1x` en `2x`).
  Er zit geen originele Balatro-art in de repo.

## Kaartontwerpen

- Premiejager: een "gezocht"-poster met een gekroonde nar en een stapel gouden munten.
- Derde Wiel: twee narren met een hartje erboven, een sippe derde nar ervoor.
- Gier: een gier met narrenmuts op een tak, met een gouden munt in de klauwen.
- Lachende Derde: twee boze narren die vechten (ster ertussen), een derde nar die erom lacht.
- Koningsdoder: een nar met een zwaard, de gevallen kroon ligt ervoor.
- Middenmoot: een nar op het middelste (zilveren) podium tussen goud en brons.
- Driemanschap: drie gekroonde narren.
