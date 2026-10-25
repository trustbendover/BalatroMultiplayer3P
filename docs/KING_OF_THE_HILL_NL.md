# King of the Hill / Bounty – spelmodus voor 3 spelers

*Status: in ontwikkeling voor 0.6.7~3P (feature branch `feature/king-of-the-hill`, nog niet uitgebracht).*

## Het idee in één zin
Wie de PvP wint wordt **Koning** en krijgt een **premie** op zijn hoofd die elke ronde groeit;
de andere twee proberen hem te onttronen om die premie op te strijken – en wie de heuvel
**4 PvP's op rij** vasthoudt, wint meteen.

## Basis (zoals Attrition)
- 3 spelers, standaard **3 levens**.
- Elke boss blind (vanaf de PvP-startronde) is een **Nemesis/PvP-blind** met z'n drieën.
- De **laagste score verliest een leven** (gelijkspel voor de laagste plek = niemand).
- Laatste speler over wint ook gewoon.

## De kroon
| Situatie na een PvP | Wat er gebeurt |
| --- | --- |
| Nog geen Koning | De (enige) hoogste score wordt Koning. |
| Koning heeft weer de hoogste score | Hij blijft Koning, **reeks +1**. Premie = reeks. |
| Iemand anders heeft de hoogste score | Die **onttroont** de Koning: krijgt **$4 × premie** en de kroon (reeks 1). Bij premie **3 of meer** ook **+1 leven** (max. het startaantal). |
| Koning scoort het **laagst** | **Kroonschild:** hij verliest de **kroon in plaats van een leven**. |
| Gelijkspel om de hoogste plek | Kroon blijft waar hij is (reeks telt niet door); verloor de Koning ook nog (laagste), dan is de kroon vrij. |

**Winnen:** reeks van **4** (instelbaar 2–10 via `koth_hold_target`) = "Hold the Hill" → direct gewonnen.
Of als laatste overblijven.

## Waarom zo (balans)
- **2-tegen-1-frustratie:** iedereen jaagt op de Koning, maar het **kroonschild** zorgt dat hij daar
  geen levens door verliest – alleen zijn kroon. Hij blijft dus in het spel.
- **Geen runaway leader:** de Koning moet elke ronde de **hoogste** zijn tegen twee rivalen; één
  misser en hij is de kroon kwijt. Hoe langer hij blijft, hoe **groter de premie** voor wie hem
  verslaat (geld, en vanaf premie 3 een extra leven) – de achterblijver krijgt zo een inhaalkans.
- **Duidelijk einde:** 4 keer op rij de beste = winst; potjes duren niet eindeloos.
- **Simpel:** geen nieuwe kaarten of jokers; alleen kroon, premie en reeks.

## Randgevallen
- **Nog 2 spelers over** (iemand uitgeschakeld of weg): dezelfde regels.
- **Koning valt weg / verbinding kwijt:** kroon vervalt; volgende hoogste score wordt Koning.
  Komt hij terug met rejoin vóór de volgende PvP, dan houdt hij zijn kroon.
- **PvP-timer verlopen:** die speler verliest gewoon een leven (schild geldt alleen voor de laagste score).

## In het spel
- Lobby → *Create Lobby* → spelmodus **King of the Hill** (bij Battle, naast Attrition/Showdown).
- Bovenaan het scherm: `Koning: Bob | Premie 2 | Heuvel 2/4`.
- In de PvP-HUD staat `[K]` voor de naam van de Koning.
- Meldingen: "Premie gepakt! +$8", "Kroonschild…", "Jij bent de Koning!", "… hield de heuvel vast en wint!".

## Techniek
- Regels: `mod/networking/koth_rules.lua` (Steam P2P-host in het spel) en `server/src/koth.ts` (TS-server);
  beide getest met dezelfde testgevallen `mod/tests/koth_vectors.json`.
- Server stuurt na elke PvP `kothUpdate` (gepersonaliseerd met `you`); de client (`mod/lib/koth.lua`)
  toont de badge, meldingen en betaalt de premie uit (`ease_dollars`). Extra leven komt via `playerInfo`.
- Spelmodus-definitie: `mod/gamemodes/koth.lua`.
