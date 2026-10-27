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
- Rune powerups:
  - **Regeneration**: restores HP and HEV over time.
  - **Trap**: unleashes an explosion when you die.
  - **Cloak**: makes you semi-invisible.
  - **Super speed**: increases your movement speed.
  - **Low gravity**: lowers gravity for you only.
  - **Super glock**: fires the glock at high speed.
  - **Super jump**: lets you jump higher.
  - **Teleport**: teleports you to a random location.
- Pick up, use and drop runes.
- English and Spanish translations.

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
   Half-Life, `ag` for Adrenaline Gamer):

   ```sh
   cp -r dist/valve/* /path/to/hlds/valve/
   ```

   This installs:

   - `addons/amxmodx/plugins/xdm-reborn.amxx`
   - `addons/amxmodx/data/lang/xdm-reborn.txt`
   - `models/xdm_rune.mdl`
   - `sound/xdm.wav`, `sound/weapons/explode3.wav`, `sound/weapons/xbow_hit2.wav`
   - `sprites/blood.spr`, `sprites/dot.spr`, `sprites/shockwave.spr`, `sprites/zbeam3.spr`
   - `dlls/hl.dll` and `dlls/hl.so` (BugfixedHL server build)

3. Add the plugin to `addons/amxmodx/configs/plugins.ini`:

   ```ini
   xdm-reborn.amxx
   ```

4. Start the server. On first run AMXX creates the configuration file
   automatically.

> The output paths are controlled by `.amxxpack.json`. The default
> configuration writes to `dist/valve/`. Adjust `output` there if your server
> uses a different layout.

## Configuration

XDM Reborn does not ship a manual configuration file. AMXX creates and
maintains it from the registered cvars:

- AMXX 1.10: `addons/amxmodx/configs/plugins/plugin-xdm-reborn.cfg`
- Older versions may place it directly under `addons/amxmodx/configs/`.

The generated file includes every cvar with its description, default value and
allowed range. The main groups are:

| Group | Cvars | Description |
| --- | --- | --- |
| Player | `xdm_start_hp`, `xdm_start_hev`, `xdm_start_longjump`, `xdm_player_speed` | Starting health, armor, long jump and movement speed. |
| Loadout | `xdm_start_*`, `xdm_ban_*` | Weapons and ammo players start with, and entities to remove from the map. |
| Damage | `xdm_dmg_*` | Damage dealt by each weapon. |
| Reload | `xdm_reload_speed` | Reload time multiplier. Lower is faster. |
| Hook | `xdm_hook_enabled`, `xdm_hook_speed` | Grappling hook settings. |
| Flying crowbar | `xdm_flycrowbar_*` | Speed, damage, trail, glow and lifetime. |
| Runes | `xdm_numb_*`, `xdm_color_*` | Number and color of each rune spawned on the map. |
| Rune tuning | `xdm_regen_*`, `xdm_trap_*`, `xdm_cloak_value`, `xdm_super_*`, `xdm_low_gravity_value`, `xdm_teleport_*` | Per-rune behavior. |

On AG servers, the core AG gamemode remains responsible for the starting
loadout, bans and weapon damage. The XDM-specific cvars (runes, hook, flying
crowbar, etc.) still apply.

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
