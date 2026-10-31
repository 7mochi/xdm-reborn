# XDM Reborn

XDM Reborn is an open-source AMX Mod X plugin inspired by
[XDM (Xtreme Deathmatch)](https://www.gamefront.com/games/half-life/file/half-life-xtreme-deathmatch-v1-1-installer).
It brings fast-paced Half-Life deathmatch with configurable loadouts, weapon
damage, a grappling hook, a throwable crowbar and rune powerups.

The original XDM is closed source, old and windows-only. XDM Reborn aims to be
a modern alternative that is easy to configure, extend and run.

## Features

- Built on top of BugfixedHL for bug fixes, improvements and uncapped speed.
- Configurable starting health, armor, weapons and ammo.
- Ban weapons, ammo, health kits, batteries, chargers and long jump modules.
- Configurable damage for each weapon.
- Faster firing and reloading for selected weapons.
- Faster health and HEV charger recharge.
- Flying crowbar: throw your crowbar with secondary attack.
- Grappling hook, bound to `+hook`.
- Optional rune plugins:
  - **Cloak**: makes you semi-invisible.
  - **Haste**: weapons cycle twice as fast.
  - **Low Gravity**: lowers gravity for you only.
  - **Protection**: halves incoming damage.
  - **Regeneration**: restores HP and HEV over time.
  - **Shield**: temporary immunity with `userune`.
  - **Shock**: damages nearby players with `userune`.
  - **Super Crowbar**: massive crowbar damage.
  - **Super Glock**: unlimited ammo and a 40 FOV sniper mode.
  - **Super Hook**: faster grapple that deals damage.
  - **Super Jump**: long jump plus the original +100 Z jump boost and grunt sound. Set `xdm_start_longjump 0` if you want the rune's long jump to be exclusive; the boost still applies while the rune is held.
  - **Super Speed**: increases your movement speed.
  - **Teleport**: teleports you to a random player spawn point.
  - **Booby Trap**: explodes when you die.
  - **Vampire**: heals you for damage dealt.
- Optional random rune pickups: every 5 seconds, each one changes to another rune whose
  spawn count is above zero; picking it up grants the rune currently shown.
- Original XDM rune HUD with pickup, persistent status and discard messages.
- Pick up runes, then use them with `userune` or drop them with `droprune`.
- English and Spanish translations.

The core plugin is required. Each rune is a separate optional plugin, so you
can install only the runes you want and add new ones without recompiling the
core.

XDM Reborn is not compatible with the original XDM `.cfg` files. All settings
are regular AMXX cvars and are documented in an auto-generated config file.

## Requirements

- Half-Life Dedicated Server (HLDS).
- [Metamod-r](https://github.com/theAsmodai/metamod-r).
- AMX Mod X 1.9 or newer (1.10 recommended).
- [BugfixedHL-Rebased](https://github.com/tmp64/BugfixedHL-Rebased) server
  DLLs, or an Adrenaline Gamer (AG) server.

The build downloads the BugfixedHL 1.13.2 server DLLs automatically. If your
server already runs BugfixedHL, you can skip copying them.

## Installation

1. Build the plugin (see [Building](#building)) or download a release.
2. Copy the generated server files into your mod directory (`valve` for
   Half-Life, `ag` for Adrenaline Gamer). The build log prints the exact output
   directory; the committed configuration currently writes to `dist/valve/`:

   ```sh
   cp -r dist/valve/* /path/to/hlds/valve/
   ```

   This installs:

   - `addons/amxmodx/plugins/xdm_reborn.amxx` (required core)
   - `addons/amxmodx/plugins/xdm_reborn_rune_*.amxx` (optional rune plugins)
   - `addons/amxmodx/configs/plugins-xdm_reborn.ini`
   - `addons/amxmodx/data/lang/xdm_reborn.txt`
   - `models/xdm_rune.mdl`
   - `sound/xdm.wav`, `sound/weapons/explode3.wav`, `sound/weapons/xbow_hit2.wav`
   - `sprites/blood.spr`, `sprites/dot.spr`, `sprites/shockwave.spr`, `sprites/zbeam3.spr`
   - `dlls/hl.dll` and `dlls/hl.so` (BugfixedHL server build)

   To install only some runes, copy the core and the desired
   `xdm_reborn_rune_*.amxx` files instead of the whole tree.

3. XDM Reborn ships `addons/amxmodx/configs/plugins-xdm_reborn.ini`.
   AMXX automatically loads every `configs/plugins-*.ini`, so you do not need
   to add these plugins to `plugins.ini`. The file enables the core and all
   runes; comment out a rune line to disable it. If you install only some
   runes, also comment out the lines for the runes you did not copy.

   If you previously added XDM Reborn plugins to `plugins.ini`, remove those
   lines to avoid loading them twice.

4. Start the server. On first run AMXX creates the core configuration file and
   one configuration file for each installed rune plugin.

> The output paths are controlled by `.amxxpack.json`. The build log prints the
> exact directory; the committed configuration currently writes to
> `dist/valve/`. Adjust `output` there if your server uses a different
> layout.

## Configuration

XDM Reborn does not ship a manual configuration file. AMXX creates and
maintains the files from the registered cvars:

- Core: `addons/amxmodx/configs/xdm_reborn.cfg`
- Rune plugins: `addons/amxmodx/configs/xdm_reborn_rune_<plugin>.cfg`

`<plugin>` is the rune plugin filename without `.amxx`, for example
`xdm_reborn_rune_regen.cfg` or `xdm_reborn_rune_super_crowbar.cfg`.

The generated files include every cvar with its description, default value and
allowed range. The main groups are:

| Group | Cvars | Description |
| --- | --- | --- |
| Player | `xdm_start_hp`, `xdm_start_hev`, `xdm_start_longjump`, `xdm_player_speed` | Starting health, armor, long jump and movement speed. |
| Loadout | `xdm_start_*`, `xdm_ban_*` | Weapons and ammo players start with, and entities to remove from the map. |
| Damage | `xdm_dmg_*` | Damage dealt by each weapon. |
| Reload | `xdm_reload_speed` | Reload time multiplier. Lower is faster. |
| Hook | `xdm_hook_enabled`, `xdm_hook_speed`, `xdm_rune_super_hook_*` | Grappling hook settings and super hook tuning. |
| Flying crowbar | `xdm_flycrowbar_*` | Speed, damage, cycle, trail, glow and lifetime. |
| Rune spawns | `xdm_rune_<id>_count`, `xdm_rune_<id>_color`, `xdm_rune_random_count` | Number and skin color of each registered rune, plus random-rune spawns. These live in the core config. |
| Rune tuning | `xdm_rune_regeneration_*`, `xdm_rune_trap_*`, `xdm_rune_cloak_alpha`, `xdm_rune_super_speed_velocity`, `xdm_rune_low_gravity_value`, `xdm_rune_super_glock_*`, `xdm_rune_super_jump_*`, `xdm_rune_teleport_*`, `xdm_rune_shock_*`, `xdm_rune_super_crowbar_*`, `xdm_rune_haste_*`, `xdm_rune_protection_*`, `xdm_rune_vampire_*`, `xdm_rune_shield_*` | Per-rune behavior, in that rune's config. |

Adding or removing a rune plugin changes the set of `xdm_rune_<id>_*` cvars in
the core config. Delete `xdm_reborn.cfg` and restart the map so AMXX regenerates
it with the current rune set. Rune tuning files are independent and can stay.

If you raise `xdm_player_speed` above the engine's `sv_maxspeed` (320 by
default) without the Super Speed plugin, set `sv_maxspeed` manually or install
Super Speed. That plugin owns the global `sv_maxspeed` value.

On AG servers, the core AG gamemode remains responsible for the starting
loadout, bans and weapon damage. The XDM-specific cvars (rune plugins, hook,
flying crowbar, etc.) still apply.

## Commands

| Command | Description |
| --- | --- |
| `+hook` / `-hook` | Enable or disable the grappling hook. |
| `userune` | Use the active rune (shock, shield or teleport). |
| `droprune` | Drop the active rune. |
| `spectate` | Enter spectator mode; also drops the active rune. |

Example binds:

```cfg
bind mouse3 +hook
bind e userune
bind q droprune
```

## Developing runes

Runes are ordinary AMXX plugins that link against the core library through
`xdm_reborn.inc`. The include declares `#pragma reqlib xdm_reborn`, so a rune
plugin fails to load cleanly when the core is missing.

Register one rune in `plugin_init`. Registration lasts until the core unloads. The rune ID used by
`xdm_find_rune`, the generated cvars, and the translation keys are derived
from the display name: lowercase ID with runs of non-alphanumeric characters
replaced by `_`, and keys `XDM_RUNE_<ID>_NAME` / `XDM_RUNE_<ID>_DESC`.

```pawn
#include <amxmodx>
#include <xdm_reborn>

new g_iRune;

public plugin_init() {
    register_plugin("XDM Reborn Rune: Example", "1.0.0", "you");

    g_iRune = xdm_register_rune(
        "Example",
        1,
        0
    );

    if (g_iRune == XDM_INVALID_RUNE) {
        return;
    }
}
```

All six callbacks are optional. When present, they must be `public` and have
the declared signatures. A rune is usable when it implements `xdm_rune_use`;
there is no separate `usable` argument.

```pawn
public xdm_rune_pickup(rune, player) { }
public xdm_rune_use(rune, player) { }
public xdm_rune_cooldown(rune, player) { }
public xdm_rune_drop(rune, player) { }
public xdm_rune_death(rune, victim, attacker) { }
public xdm_rune_spawn(rune, player) { }
```

Usable runes can call `xdm_set_rune_cooldown(rune, player, seconds)` after a
successful use. The core blocks `userune` while that cooldown is active, shows
`XDM_RUNE_COOLDOWN`, and calls `xdm_rune_cooldown` so the rune can play its own
denial sound or effect.

A plugin that registers more than one rune must filter every callback by its
own rune indices. One rune per plugin is the recommended layout.

Hook-based runes can use `xdm_set_hook_speed(player, speed)` to override the
core hook speed and implement `xdm_hook_start(player)` for hook-start effects.
The core does not contain rune-specific hook logic.

`xdm_register_rune` arguments are: display name, default count and default
color. The core derives the ID and translation keys from the display name,
uses the shared rune model and pickup sound, and creates `xdm_rune_<id>_count`
and `xdm_rune_<id>_color`. The plugin should create its tuning cvars and call
`AutoExecConfig()` in `plugin_init`.

The core owns spawning, pickup, drop, death, HUD, coarse player state and
cleanup. A rune plugin owns its effects, must precache any custom assets it
uses, and must clean its player effects in its callbacks and in `plugin_end`
when they outlive a map change. It must not call an unregister native.

Compatibility is compile-time through `#pragma reqlib` and the public
include; there is no runtime API version native or constant. The shared
plugin version is `XDM_VERSION`.

## Building

### Requirements

- Node.js 14 or newer.
- npm.

The AMXX compiler and third-party assets are downloaded by `amxxpack`; no
system compiler is required.

### Standard build

```sh
npm install
npm run build
```

`npm install` installs the npm dependencies and runs the `install` lifecycle
script, which executes `amxxpack install`. That downloads the AMXX compiler and
the BugfixedHL server DLLs listed in `.amxxpack.json`. If your package manager
does not run lifecycle scripts, run the install step explicitly:

```sh
npm install
npm run install
npm run build
```

Other useful scripts:

```sh
npm run watch   # rebuild on changes
npm run clean   # remove generated compiler, thirdparty and dist folders
```

### Nix (optional, recommended on NixOS)

```sh
nix develop

just install
just build
```

`just install` runs the npm install steps and patches `.compiler/amxxpc`.
Re-run it after upgrading the AMXX compiler. Other tasks: `just watch`,
`just clean`.

## Credits

### Thanks to

- The original XDM team for the inspiration
- ConnorMcLeod
- rtxa
- Th3-822
- joropito
- GHW_Chronic
- Anonimo
- GordonFreeman
- Gauss
- LetiLetiLepestok
- Lev
- Turanga_Leela
- HamletEagle

### Testers

- DarkZito
- K3NS4N
- Assassin
- Dcarlox
- Intel Extreme Masters

### Contact

- E-mail: alonso.caychop@protonmail.com
- Discord: `_7mochi_`
- Steam: <https://steamcommunity.com/id/_7mochi/>
