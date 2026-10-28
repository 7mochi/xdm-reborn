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
  - **Regeneration**: restores HP and HEV over time.
  - **Trap**: unleashes an explosion when you die.
  - **Cloak**: makes you semi-invisible.
  - **Super speed**: increases your movement speed.
  - **Low gravity**: lowers gravity for you only.
  - **Super glock**: fires the glock at high speed.
  - **Super jump**: lets you jump higher.
  - **Teleport**: teleports you to a random location.
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
   directory; the committed configuration currently writes to `dist/dist/valve/`:

   ```sh
   cp -r dist/dist/valve/* /path/to/hlds/valve/
   ```

   This installs:

   - `addons/amxmodx/plugins/xdm_reborn.amxx` (required core)
   - `addons/amxmodx/plugins/xdm_reborn_rune_*.amxx` (optional rune plugins)
   - `addons/amxmodx/data/lang/xdm_reborn.txt`
   - `models/xdm_rune.mdl`
   - `sound/xdm.wav`, `sound/weapons/explode3.wav`, `sound/weapons/xbow_hit2.wav`
   - `sprites/blood.spr`, `sprites/dot.spr`, `sprites/shockwave.spr`, `sprites/zbeam3.spr`
   - `dlls/hl.dll` and `dlls/hl.so` (BugfixedHL server build)

   To install only some runes, copy the core and the desired
   `xdm_reborn_rune_*.amxx` files instead of the whole tree.

3. Add the core and the rune plugins you want to
   `addons/amxmodx/configs/plugins.ini`:

   ```ini
   xdm_reborn.amxx
   xdm_reborn_rune_regen.amxx
   xdm_reborn_rune_trap.amxx
   xdm_reborn_rune_cloak.amxx
   xdm_reborn_rune_super_speed.amxx
   xdm_reborn_rune_low_gravity.amxx
   xdm_reborn_rune_super_glock.amxx
   xdm_reborn_rune_super_jump.amxx
   xdm_reborn_rune_teleport.amxx
   ```

   Remove or comment a rune line to disable that rune.

4. Start the server. On first run AMXX creates the core configuration file and
   one configuration file for each installed rune plugin.

> The output paths are controlled by `.amxxpack.json`. The build log prints the
> exact directory; the committed configuration currently writes to
> `dist/dist/valve/`. Adjust `output` there if your server uses a different
> layout.

## Configuration

XDM Reborn does not ship a manual configuration file. AMXX creates and
maintains the files from the registered cvars:

- Core: `addons/amxmodx/configs/plugins/xdm_reborn.cfg`
- Rune plugins: `addons/amxmodx/configs/plugins/xdm_reborn_rune_<id>.cfg`

Older AMXX versions may place them directly under `addons/amxmodx/configs/`.

The generated files include every cvar with its description, default value and
allowed range. The main groups are:

| Group | Cvars | Description |
| --- | --- | --- |
| Player | `xdm_start_hp`, `xdm_start_hev`, `xdm_start_longjump`, `xdm_player_speed` | Starting health, armor, long jump and movement speed. |
| Loadout | `xdm_start_*`, `xdm_ban_*` | Weapons and ammo players start with, and entities to remove from the map. |
| Damage | `xdm_dmg_*` | Damage dealt by each weapon. |
| Reload | `xdm_reload_speed` | Reload time multiplier. Lower is faster. |
| Hook | `xdm_hook_enabled`, `xdm_hook_speed` | Grappling hook settings. |
| Flying crowbar | `xdm_flycrowbar_*` | Speed, damage, trail, glow and lifetime. |
| Rune spawns | `xdm_rune_<id>_count`, `xdm_rune_<id>_color` | Number and skin color of each registered rune. These live in the core config. |
| Rune tuning | `xdm_rune_regen_*`, `xdm_rune_trap_*`, `xdm_rune_cloak_alpha`, `xdm_rune_super_speed_velocity`, `xdm_rune_low_gravity_value`, `xdm_rune_super_glock_fire_rate`, `xdm_rune_super_jump_height`, `xdm_rune_teleport_*` | Per-rune behavior, in that rune's config. |

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
| `userune` | Use the active rune (super jump or teleport). |
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

Register one rune in `plugin_init`. Registration lasts until the core unloads:

```pawn
#include <amxmodx>
#include <xdm_reborn>

#define RUNE_ID "example"

new g_iRune = XDM_INVALID_RUNE;

public plugin_init() {
    register_plugin("XDM Reborn Rune: Example", "1.0.0", "you");

    g_iRune = xdm_register_rune(
        RUNE_ID, "Example",
        "EXAMPLE_NAME", "EXAMPLE_DESC",
        1, 0
    );

    if (g_iRune == XDM_INVALID_RUNE) {
        return;
    }
}
```

All five callbacks are optional. When present, they must be `public` and have
the declared signatures. A rune is usable when it implements `xdm_rune_use`;
there is no separate `usable` argument.

```pawn
public xdm_rune_pickup(rune, player) { }
public xdm_rune_use(rune, player) { }
public xdm_rune_drop(rune, player) { }
public xdm_rune_death(rune, victim, attacker) { }
public xdm_rune_spawn(rune, player) { }
```

A plugin that registers more than one rune must filter every callback by its
own rune indices. One rune per plugin is the recommended layout.

`xdm_register_rune` arguments are: ID, display name, name key, description
key, default count and default color. The core uses the shared rune model and
pickup sound. The core creates `xdm_rune_<id>_count` and
`xdm_rune_<id>_color`; the plugin should create its tuning cvars and call
`AutoExecConfig` in `plugin_init`.

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

Thanks to the original XDM team for the inspiration, and to:

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
- DarkZito (Tester)
- K3NS4N (Tester)
- Assassin (Tester)
- Dcarlox (Tester)
- Intel Extreme Masters (Tester)
