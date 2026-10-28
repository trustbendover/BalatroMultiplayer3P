# Teams (2v2, 3v3, 4v4, 2v2v2, 2v2v2v2) – Balatro High Stakes 0.6.7

*Status: in ontwikkeling voor 0.6.7~3P, nog niet uitgebracht. Onofficiële fork van Balatro Multiplayer
(GPL-3.0, credits aan Virtualized en het Balatro Multiplayer-team). Ontwerp en code: Trust Ben Dover.*

## In één zin
Spelers vormen gelijke teams; per PvP-blind telt de **som** van de scores van het team, en het team
met de laagste som verliest één **gedeeld teamleven**. Het laatste team dat overblijft wint.

## Teams en spelersaantal
| Spelers | Mogelijke indelingen (`teams_size`) |
| --- | --- |
| 4 | 2v2 |
| 6 | 2v2v2 (grootte 2) of 3v3 (grootte 3) |
| 8 | 2v2v2v2 (grootte 2) of 4v4 (grootte 4) |

- Minder dan 4, of een oneven aantal (5, 7): de host kan niet starten; de lobby zegt waarom
  ("Teams heeft 4, 6 of 8 spelers nodig").
- Past de gekozen grootte niet (bv. 3 bij 8 spelers), dan valt het terug op teams van 2.
- **Wie bij wie zit:** de stoelen in lobbyvolgorde (of de door de host gehusselde volgorde,
  optie `teams_order`, bv. `3,1,2,4`) worden in stukken geknipt: team A, B, C, D.
- **In de lobby (host):** knoppen **Teams husselen** (willekeurige volgorde) en **Teamgrootte: N**
  (wisselt tussen de groottes die passen). Iedereen ziet de letter voor de naam: `[A] Bob`.

## Spelregels
- Blinds zoals Attrition: elke boss blind is een Aartsvijand/PvP-blind. Standaard **4 teamlevens**
  (instelbaar in de lobby-opties).
- **Teamscore = som** van de scores van de teamgenoten (grote scores met "e" worden correct
  vergeleken, ook voorbij 1e308).
- Het team met de **enige laagste** som verliest één leven; **gelijk laagste = niemand** verliest.
- **Gedeelde levens:** verliest het team een leven, dan verliezen alle teamleden er één (iedereen
  ziet dezelfde teamlevens). Een team op 0 levens is uit; het laatste team wint (`winGame` voor
  het hele team).
- PvP-timer verlopen of ronde gefaald: kost het **hele team** één leven.
- **Aartsvijand-effecten** (zoals asteroïden, sabotage-kaarten) raken alleen de **andere teams**,
  nooit je teamgenoot. Skip-informatie gaat naar iedereen.
- **Weg / disconnect:** de plek blijft vast; tot de teamgenoot terug is telt het team als
  (gemiddelde van de aanwezige leden × teamgrootte), zodat een disconnect nooit automatisch verlies is.
  Rejoin met dezelfde code en naam: je komt terug in je eigen team.
- **Geen late join** in Teams (de teams liggen vast bij de start).

## In het spel
- Lobby: *Create Lobby* → spelmodus **Teams** (bij Battle).
- PvP-HUD: eerst de teamstanden (`Team A (jij) 12.000 4L | Team B 9.000 3L`), daarna de rivalen;
  je teamgenoot staat er met een `+` voor.
- Meldingen na elke PvP: "Jouw team verliest een leven", "Team B verliest een leven",
  "Gelijk laagste team - niemand verliest een leven".
- Game Over: de "nemesis" is altijd een rivaal, nooit je teamgenoot.
- Jokers: teamgenoten tellen niet als tegenstander; een rivaliserend team telt één keer
  (zie `docs/JOKERS_NL.md`).

## Waarom zo (balans)
- **Som** is simpel en beloont beide spelers: een sterke speler kan een zwakkere dragen, maar elke
  punt telt. (Alternatieven als "beste van het team" of "slechtste van het team" maken één speler
  overbodig of straffen te hard.)
- **Gedeelde levens** houden het team samen: niemand ligt er als eerste uit terwijl zijn teamgenoot
  doorspeelt.
- **Gemiddelde bij disconnect** voorkomt dat een crash het team de wedstrijd kost.

## Techniek
- Regels (puur Lua / TS, zelfde gedrag): `mod/networking/teams_rules.lua` (Steam P2P-host in het spel)
  en `server/src/teams.ts` (TS-server), getest met dezelfde vectoren `mod/tests/teams_vectors.json`
  (`mod/tests/test_teams.lua` en `server/test/multiPlayer.test.mjs`).
- Servers sturen `teamsUpdate` { you, team, teamSize, teams: { A: { members, lives } … }, lastLoser }
  en `endPvP` met `loserTeam`; `lobbyInfo` bevat per speler de team-preview.
- Client: `mod/lib/teams.lua` (`MP.TEAMS`), spelmodus `mod/gamemodes/teams.lua`,
  limieten per modus `mod/lib/modes.lua` (`MP.MODES`).
