# Free Auras — changelog

Newest first. Each release's notes come from `CHANGELOG.md` at the time it was published.

## Free Auras 1.2.0

- **Seven new class packs** (new), one aura each: a column under your character, built on one shared engine, with a Demo mode that plays a fake fight:
  - **Warrior**: stances to click, Sunder Armor as hand-drawn strokes on your target, rage showing what a queued Heroic Strike or Cleave will take, main-hand and off-hand swing timers, the main row of your stance (Overpower, Revenge and Execute light up, with blades on both sides), cooldowns with their effect, and a Battle Shout bar;
  - **Paladin**: your seal in a medallion (gold ring: the seal's time; pink ring: your Judgement on the target; dashed ring: Seal echo), mana with the 5-second rule, swing, the main row, defensives, and your auras to click;
  - **Hunter**: Auto Shot as a bow drawn tight, red at the end where an Aimed Shot or Multi-Shot would clip it; mana, your pet's health, focus and happiness, stings and Hunter's Mark on one time scale, shots, traps, aspects to click and the ammo left;
  - **Mage**: Forever's four arcane charges as runes on an arc, mana with the 5-second rule, procs lighting their spell (Heating Up, Fingers of Frost, Missile Barrage) with cold and fire glows on the sides, and defensives;
  - **Priest**: Power Word: Shield as a bubble that cracks as it runs out, Weakened Soul as a dark ring, your damage over time on one scale, who has your Shield and your Renew, the main row and utility;
  - **Warlock**: your damage over time as burning fuses on one time scale (red when less than a cast is left), soul shards with Healthstone and Soulstone, mana, your demon, Nightfall and Decimation lighting their spell;
  - **Druid**: forms to click, a column that follows your form (combo points or Lacerate as strokes, the power of the form with your real mana under it, leaves for the form changes your mana still allows), Clearcasting, Nature's Grace and Eclipse on the sides.
- **Range** for the ranged classes (Hunter, Mage, Priest, Warlock): the distance to your enemy target, green in range of your main spell, red out of range (orange in the hunter's dead zone), and icons turning red when their spell is out of range; both can be turned off.
- **Preview** (new): a Preview button on each pack card (and `/fauras preview <pack>`, `/fauras preview off`) shows the pack moving in its Demo mode, whatever your class, without installing it; drag the bar over it to move it, click it to close. Every pack, the Rogue one included (its six real auras run on a simulated game).
- **Rogue column** and **Shaman column** (new): two more packs built the same way, next to the existing Rogue and Shaman packs: combo points or Maelstrom Weapon as strokes, energy or mana, swing timers, buffs, bleeds and shocks on one time scale, your shield, the main row and cooldowns.
- **The packs window** is now a row of class tiles (a dot shows an installed pack, orange when an update is ready); the packs of the chosen class are shown side by side, with Install, Reinstall and Preview. No more scrolling.
- Your buffs are also recognised by name out of combat, so the packs follow them in combat even when Forever uses its own spell ids.
- In combat, when the game hides numbers from addons, the packs only hand them to the game (bars, curves) and follow your own casts for cooldowns and effects.

## Free Auras 1.1.0

- **Shaman pack 1.0.10** (new), one aura in the middle of the screen:
  - Stormstrike as a spirit wolf in the colours of your weapon imbue (Windfury, Flametongue, Frostbrand, Rockbiter, or a spectral wolf without one), always in full colour with an even black outline, and it follows an imbue cast or lost in combat too; the lightning under it turns from grey to blue, left to right, while Stormstrike recharges, and flashes once when it is ready again (also after an Improved Stormstrike reset);
  - Lightning Shield or Water Shield: one small orb per charge with little arcs of lightning, around the wolf or in a row (left, below, right), the order they go in your choice;
  - Maelstrom Weapon: small clouds with little arcs in an arc above the wolf (left, right, left, right), the storm cloud in the middle at 5 stacks with lightning around the wolf (the storm and the burst of lightning when you reach 5 can each be turned off);
  - orbs turning either way, clouds upright or pointing at the wolf, sizes and distances in the aura's options, and a Demo mode that plays a fake fight;
  - shield charges and Maelstrom stacks also in combat, when the game hides the numbers from addons: each orb and cloud (and its little arcs) is shown or cut by a native aura slot that the game fills itself (ForeverAuras' AuraOverlay), the aura never reads the hidden numbers.

## Free Auras 1.0.0

First release.

- Install ready-made **ForeverAuras** packs from one window (`/fauras`, or the Free Hub button), your class first. Install and Update go through ForeverAuras' own import window, so you see what comes in before it does.
- A message at login (once per version) when a pack you installed has an update.
- The pictures the packs use come with the addon.
- **Rogue pack 1.1.4**, one compact column under your character:
  - combo points as hand-drawn tally marks;
  - energy with a Shank preview (Flash of Steel included), red when it would overflow;
  - Slice and Dice, Blade Flurry, Adrenaline Rush, and your Rupture and Garrote on the target, on one moving time scale;
  - cooldowns in two full-width rows, with the time left of their effect on the icons (Kidney Shot, Gouge, Blind, Evasion, Sprint, Vanish...); Riposte lights up after a parry;
  - trinkets: left click uses, right click swaps;
  - weapons and poisons side by side, greyed when unpoisoned; left click applies a poison, right click swaps a weapon, in combat too;
  - optional Slice and Dice lightning bolt.
