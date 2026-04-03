# Court of Chaos Content Review and Match Strategy

This review is based on the live content and combat rules in:

- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/card_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/relic_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/potion_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/match_state.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/tennis_score.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/rally_state.gd`

## 1. How matches are actually won

The most important thing to understand is that matches are won on tennis scoring, not by grinding the enemy's displayed Condition to zero.

### Point win condition

You win a point when one of these happens:

1. You push rally pressure to the point target.
2. The enemy commits a forced error.

The default rally pressure target is:

- Regular: `42 + 8 per act after Act 1`
- Elite: regular target `+10`
- Boss: regular target `+18`
- Novice gets `-10` off that target

That means opening act targets are roughly:

- Regular: `42`
- Elite: `52`
- Boss: `60`
- Novice regular: `34`

### Tennis scoring

- Regular fight: `1 standard game`
- Elite: `1 no-ad game`
- Boss: `best of 3 games`

Point scoring is normal tennis:

- `Love -> 15 -> 30 -> 40 -> Game`
- Standard games use `Deuce` and `Ad`
- Elite no-ad games go straight from `40-40` to a deciding point

### What Condition actually does

Player Condition is your attrition resource.

- When the enemy wins a point, you lose Condition.
- The amount scales by act and encounter type.
- Heavy racquet setups can increase that loss on missed points.

Enemy Condition is currently not the real primary victory axis. In practice:

- rally pressure wins points
- points win games
- games win matches

### Guard matters more than it first appears

Pressure is applied through Guard first. If your shot generates 12 pressure and the enemy has 12 Guard, the rally does not move.

That means:

- medium-pressure cards are bad into a full Guard wall
- open-court, momentum, power spikes, and correct pattern bonuses matter a lot
- defensive setup cards are not passive; they buy time and deny enemy pressure

## 2. Turn structure and the 5-slot hand

Your hand is not a free-form STS hand anymore. It is a tactical rail with fixed roles:

1. `INITIAL`
2. `SHOT`
3. `ENHANCER`
4. `MODIFIER`
5. `SPECIAL`

### Slot meaning

- `INITIAL`: serve or return opener
- `SHOT`: your main rally strike
- `ENHANCER`: guard, draw, footwork, tempo, recovery, training
- `MODIFIER`: spin shape, placement, strings, racquet tuning
- `SPECIAL`: signatures, power plays, recovery spikes, boss debuffs

### Best way to think about a turn

A strong turn usually looks like this:

1. Solve the point context first.
   - If you are serving, use a serve.
   - If you are returning, use a return.
2. Use enhancer/modifier cards to set the geometry.
   - guard
   - draw
   - open court
   - spin
   - equipment setup
3. Cash out with the right shot for the current court state.

### Common mistake

The biggest mistake is playing your high-value shot into the wrong state:

- volley from baseline
- drop shot into a net player
- down-the-line before crosscourt or open-court setup
- smash without a high ball
- return card outside an actual return point

## 3. Shot logic and optimal usage

These are the important live tactical rules from `match_state.gd`.

| Pattern | Pressure rule | Accuracy rule | Best use |
| --- | --- | --- | --- |
| Serve | `+4` on point open | `+8%` on proper serve, `-20%` otherwise | Use only on your serve point and preferably as the opening strike |
| Return | `+6` on real return point, `-2` otherwise | `+8%` on proper return point, penalty otherwise | Almost always play a real return when receiving |
| Crosscourt | `+2` | `+5%` | Safe setup shot, best line-builder |
| Down The Line | `+6` after open court or prior crosscourt, `-1` otherwise | `-7%`, partly recovered after setup | Use as a finisher, not as a blind opener |
| Drop Shot | `+6` vs baseline, `-4` vs net | `+6%` vs baseline, `-6%` vs net | Punish deep defenders |
| Volley | `+5` when forward or ball is at net, `-3` from baseline | `+6%` when forward, `-8%` from baseline | Finish after approach or when already forward |
| Lob | `+6` vs forward opponent, `+1` otherwise | `+6%` vs forward or net ball | Beat net rushers, reset pressure |
| Slice | `+4` vs forward opponent | `+4%` on low ball | Great versus net pressure or awkward court states |
| Smash | `+10` on high ball or after lob, `-6` otherwise | `+8%` on high ball, `-12%` otherwise | Hold until the ball is actually there |

### Core patterns that win matches

#### Pattern 1: Crosscourt into line break

Sequence:

- `Crosscourt Rally`
- `Crosscourt Rally` or `Deep Return`
- `Down The Line` or `Backhand Redirect`

Why it works:

- crosscourt is safe
- it improves line-change conversion
- open-court pressure gets cashed in properly

#### Pattern 2: Serve plus one

Sequence:

- `Kick Serve` or `Steady Serve`
- `Flat Cannon`, `Return Rip`, `Net Rush`, or `Approach Shot`

Why it works:

- serve cards are strongest at point start
- `Power` specifically gets extra first-strike and plus-one benefits
- serve-and-volley classes can convert this into free net pressure

#### Pattern 3: Return stabilize into redirect

Sequence:

- `Block Return` or `Deep Return`
- `Split Step` or `Recover Breath`
- `Backhand Counter Return`, `Down The Line`, or `Inside-Out Forehand`

Why it works:

- return points are dangerous
- you get large bonuses for using actual return cards correctly
- stabilizing first prevents losing ugly short points

#### Pattern 4: Bring them in, then punish

Sequence:

- `Drop Shot` against baseline target
- follow with `Basic Volley`, `Net Rush`, or a sharp angle

Why it works:

- drop shot is best against deep defenders
- it changes geometry, not just damage

#### Pattern 5: Beat the net

Sequence:

- enemy comes forward
- answer with `Lob`, `Lobbed Return`, `Down The Line`, or `Slice Drag`

Why it works:

- many net enemies explicitly have `lob_weak` or `down_the_line_weak`
- lobs also create `HighBall` states and force repositioning

## 4. Match-winning principles

### A. Respect serve and return context

Use serve cards on serve points and return cards on return points. The game heavily rewards that and punishes cheating the context.

### B. Build, then cash

Think of `Crosscourt`, `Deep Return`, `Split Step`, and strings as setup.

Think of `Down The Line`, `Inside-Out Forehand`, `Flat Cannon`, and `Overhead Smash` as cash-out.

### C. Protect Condition, not just the rally

Losing points hurts your run, not just the match. Good players do not only ask, "Can I win this point?" They also ask, "If I lose this point, how much Condition do I burn?"

### D. Read enemy keywords

Enemy weaknesses and resistances matter. Examples:

- `return_weak`: return packages become premium
- `net_weak` or `volley_weak`: approach and volley lines get stronger
- `lob_weak`: punish forward movement with lobs
- `slice_resist`: do not autopilot slice into that enemy
- `power_weak`: cash out with power lines

### E. Use equipment early enough to matter

Strings and frame cards are match-long tuners. Playing them too late leaves value on the table.

Good default timing:

- turn 1 if the matchup is stable
- turn 2 if you need to survive first

## 5. Optimal strategy by class

### Novice

Plan:

- open safe
- use the free first skill each turn
- favor `Split Step`, `Recover Breath`, and `Endurance Training`
- win through low-risk crosscourt and redirect patterns

### Pusher

Plan:

- Guard first
- let passive pressure stack
- use long points to drain the opponent

### Slicer

Plan:

- make the court ugly
- abuse low balls, forward opponents, and geometry changes
- use `Drop Shot`, `Slice Drag`, `Chip Return`, and `Lob Escape`

### Power

Plan:

- serve-plus-one
- return-plus-one
- short points
- heavy use of power windows and equipment spikes

### All-Arounder

Plan:

- alternate tags
- keep drawing off variety
- transition between baseline and net based on enemy weakness

### Baseliner

Plan:

- crosscourt and topspin first
- then finish with forehand or line change
- this class wants sequence discipline more than raw tempo

### Serve and Volley

Plan:

- serve or return
- approach
- free or boosted net follow-up
- if you stay on the baseline too long, you waste your passive

### Master

Plan:

- retain key cards
- save line-breakers and recovery for the right point state
- reward patience and sequencing

### Alcaraz

Plan:

- chain footwork into signatures
- vary patterns aggressively
- use pace plus touch, not only pace

## 6. Card review

Verdict key:

- `Keep`: healthy and important
- `Watch`: playable but should be monitored
- `Buff`: underpowered or too narrow
- `Nerf Watch`: likely above curve or too efficient
- `Fix`: text, role, or implementation issue

### Initial contact cards

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Steady Serve | 1 | Reliable point opener on serve | Keep |
| Kick Serve | 1 | Better tempo serve, good for serve-plus-one | Keep |
| Ace Hunter | 2 | Big serve finisher, best in aggressive serve decks | Watch |
| Block Return | 0 | Safe return stabilizer, ideal into serve monsters | Keep |
| Deep Return | 1 | Best default return, opens court and can grant Focus | Keep |
| Chip Return | 1 | Low skid return, especially good into serve/net lines | Keep |
| Return Rip | 1 | Aggressive return cash-out | Keep |
| Short-Hop Pickup | 0 | Emergency stabilizer on return points | Keep |
| Lobbed Return | 1 | Niche anti-net return | Watch |
| Backhand Counter Return | 1 | Sharp redirect return, strong with setup | Keep |

### Shot and rally cards

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Crosscourt Rally | 1 | Best generic setup shot | Keep |
| Basic Volley | 1 | Cheap net conversion and Guard | Keep |
| Topspin Drive | 1 | Baseliner backbone, spin setup | Keep |
| Slice Drag | 1 | Great versus forward opponents | Keep |
| Flat Cannon | 2 | Pure power cash-out | Keep |
| Drop Shot | 1 | Punishes deep defenders | Keep |
| Approach Shot | 1 | Net bridge that turns on volley packages | Keep |
| Net Rush | 1 | Strong net payoff after approach or serve | Keep |
| Passing Bullet | 1 | Guard punish, but too narrow outside that | Buff |
| Lob Escape | 1 | Very solid anti-pressure reset and anti-net tool | Keep |
| Inside-Out Forehand | 1 | Premier forehand finisher once spin or setup exists | Keep |
| Backhand Redirect | 1 | Stable redirect cash-out | Keep |
| Down The Line | 1 | Real finisher, should not be spammed blind | Keep |
| Overhead Smash | 2 | Correct payoff for high ball states | Keep |
| Relentless Return | 1 | Attrition pattern, good in pusher shells | Keep |
| Highlight Reel | 2 | High-value tempo signature, probably a little pushed | Nerf Watch |

### Skills, recovery, and tech

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Recover Breath | 1 | Core survival card, very important in boss runs | Keep |
| Split Step | 1 | Guard + draw is universally good | Keep |
| Moonball Reset | 1 | Useful in attrition decks, a bit clunky outside them | Watch |
| Second Wind | 1 | Good emergency sustain, exhaust keeps it honest | Keep |
| Endurance Training | 1 | Long-fight scaling, good for majors and bosses | Keep |
| Masterclass | 1 | Retain/focus engine card | Keep |
| Elastic Chase | 0 | Smooth combo starter for Alcaraz-style turns | Keep |

### String modifier cards

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Polyester Bed | 1 | Best spin/rpm string | Keep |
| Natural Gut Lacing | 1 | Best comfort/control sustain string | Keep |
| Multifilament Touch | 1 | Best soft-hands volley/control string | Keep |
| Synthetic Gut Setup | 1 | Flexible middle-ground string | Keep |
| Hybrid String Job | 1 | Whole-court aggressive string, very broadly useful | Nerf Watch |
| Kevlar Coil | 1 | Guard plus heavy power tuning | Keep |

### Racquet modifier cards

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Lead Tape (12 O'Clock) | 1 | Serve/power spike at Condition risk | Keep |
| Lead Tape (3 and 9) | 1 | Stable control/net frame tune | Keep |
| Pro Stock Frame | 1 | Big power ceiling, biggest Condition tax | Keep |
| Head-Light Control Frame | 1 | Excellent control frame for touch/redirect decks | Keep |
| Extra-Long Leverage Build | 1 | Serve-first heavy frame | Keep |
| Counterweighted Handle | 1 | Balanced transition frame | Keep |

### Boss debuffs

| Card | Cost | Use | Review |
| --- | --- | --- | --- |
| Crowd Noise | 99 | Boss slot clogger, fatigue tax | Keep |
| Late Whistle | 99 | Boss slot clogger, pressure tax | Keep |
| Tight Strings | 99 | Boss slot clogger, fatigue plus open-court tax | Keep |

## 7. Relic review

### Common

| Relic | Use | Review |
| --- | --- | --- |
| Lead Tape | Good generic power bump | Watch because name overlaps with racquet cards |
| Dampener | Excellent safety relic | Keep |
| Polyester Strings | Great spin support | Keep |
| Fresh Grips | Strong opener relic | Keep |
| Wristband | Clean sustain relic | Keep |
| Compression Sleeve | Quietly very strong in long fights | Keep |
| New Balls | Serve consistency relic | Keep |
| Court Shoes | Strong footwork support | Keep |
| Overgrip | Great opening tempo relic | Keep |
| Practice Cones | Reward quality booster | Keep |
| Serve Scout Notes | Core return-support relic | Keep |

### Uncommon

| Relic | Use | Review |
| --- | --- | --- |
| Hawk-Eye Token | Intended accuracy reroll | Fix: currently looks placeholder with empty effect payload |
| String Saver | Nice slice-support relic | Keep |
| Headband | Good general combo relic | Keep |
| Split-Step Timer | Strong opener/read relic | Keep |
| Return Coach | Very strong return package payoff | Keep |
| Training Ladder | Rest synergy relic | Fix: description is stale because card upgrades now exist |
| Clay Specialist | Surface-specific spin payoff | Keep |
| Grass Specialist | Big net spike on grass-style lines | Nerf Watch |
| Small Sweet Spot | Interesting tradeoff relic | Watch |
| Big Sweet Spot | Premium universal consistency relic | Nerf Watch |
| Rally Counter | Good long-point relic | Keep |

### Rare

| Relic | Use | Review |
| --- | --- | --- |
| Champion's Towel | Excellent boss sustain relic | Keep |
| Titanium Frame | Strong anti-low-ball power answer | Keep |
| Smart Targeting | Signature/line-breaker support | Watch: text may under-explain actual effect |
| Serve Clock | Very strong serve deck engine | Nerf Watch |
| Chip-Charge Playbook | Great return-to-net bridge | Keep |
| Net Cord Charm | Intended second-chance touch relic | Fix: looks placeholder with empty effect payload |
| Mental Coach | Good deuce stabilizer | Keep |
| Physio Kit | Great tournament sustain relic | Keep |
| Lucky Coin Toss | Extremely strong tempo relic | Nerf Watch |

### Boss

| Relic | Use | Review |
| --- | --- | --- |
| Signature Racquet | Clean signature finisher relic | Keep |
| Trophy of the Tour | Reward scaling boss relic | Keep |

## 8. Potion review

| Potion | Price | Use | Review |
| --- | --- | --- | --- |
| Stamina Gel | 14 | Best pure boss stamina reset | Keep |
| Spin Serum | 18 | Great for topspin/slice decks and clay fights | Keep |
| Focus Salts | 17 | Best generic precision/clutch potion | Keep |
| Clutch Draught | 24 | Big boss-fight potion for power/signature decks | Keep |

## 9. Shortlist of redundant, weak, overloaded, or unclear pieces

### Redundant or confusing

1. `Lead Tape` relic and `Lead Tape` racquet cards are easy to confuse.
2. `Polyester Strings` relic and `Polyester Bed` string card overlap heavily in theme.
3. The boss debuffs are good structurally, but `Crowd Noise` and `Late Whistle` are close together in feel.

### Weak or narrow

1. `Passing Bullet`
   - Only really sings into Guard-heavy targets.
   - Could use better secondary utility or a slightly bigger default floor.
2. `Lobbed Return`
   - Correct tennis logic, but matchup-specific enough to be dead more often than `Deep Return`.
3. `Moonball Reset`
   - Fine in pusher attrition shells, low excitement elsewhere.

### Overloaded or pushed

1. `Hybrid String Job`
   - Broad enough that it often feels like the default best string.
2. `Highlight Reel`
   - Damage, open court, and draw in one package is a lot.
3. `Big Sweet Spot`
   - A universal `+10% accuracy` relic is extremely generically powerful.
4. `Serve Clock`
   - Cost reduction on serve cards is a major ceiling raiser in serve shells.
5. `Lucky Coin Toss`
   - Serving first and getting opener stamina is a huge tempo package.

### Needs implementation or cleanup

1. `Hawk-Eye Token`
   - Description implies active accuracy reroll behavior, but its effect table is empty.
2. `Net Cord Charm`
   - Same issue: description implies miss protection, but its effect table is empty.
3. `Training Ladder`
   - Description says upgrade system is pending, but the rest/camp system already upgrades cards.
4. Boss debuff upgrade generation
   - The card database currently auto-generates `+` variants for all authored cards, including boss debuffs. That should probably be excluded.

## 10. Best practical play advice

### If you only remember five things

1. Use the correct opener.
   - Serve on serve points.
   - Return on return points.
2. Use crosscourt to build safe pressure and open-court states.
3. Save down-the-line, forehand finishers, and power spikes for when the geometry is ready.
4. Do not volley from deep court or smash without a high ball.
5. Protect Condition in boss fights. Winning ugly with Guard and recovery is often better than forcing thin lines.

### Best default lines for newer players

#### Safe service point

- `Steady Serve`
- `Split Step` or `Recover Breath` if needed
- `Crosscourt Rally` or `Flat Cannon`

#### Safe return point

- `Deep Return` or `Block Return`
- `Crosscourt Rally`
- `Backhand Redirect` or `Down The Line`

#### Anti-net line

- `Chip Return` or `Slice Drag`
- `Lob Escape` or `Lobbed Return`
- `Passing Bullet` or `Down The Line`

#### Boss survival line

- Guard first
- use string/frame early
- keep potion for the swing point or deuce point
- only cash out big power when you actually have the geometry

## 11. Recommended tuning priorities

If the goal is cleaner balance and easier readability, the highest-value next moves are:

1. Exclude boss debuffs from auto-generated `+` upgrades.
2. Implement `Hawk-Eye Token` and `Net Cord Charm` for real.
3. Update `Training Ladder` text to match the actual camp upgrade system.
4. Slightly buff `Passing Bullet` and maybe `Lobbed Return`.
5. Watch `Hybrid String Job`, `Serve Clock`, `Big Sweet Spot`, and `Lucky Coin Toss` in win-rate probes.
