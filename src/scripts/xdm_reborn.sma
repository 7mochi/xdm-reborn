/*
    XDM Reborn by 7mochi

    # About:
    XDM Reborn is an open-source AMX Mod X plugin inspired by XDM (Xtreme Deathmatch).
    It brings fast-paced Half-Life deathmatch with configurable loadouts, weapon damage,
    a grappling hook, a throwable crowbar and rune powerups.

    The original XDM is closed source, old and Windows-only. XDM Reborn aims to be a
    modern alternative that is easy to configure, extend and run.

    XDM Reborn is not compatible with the original XDM .cfg files. All settings are
    regular AMXX cvars and are documented in an auto-generated config file.

    # Features:
    - Built on top of BugfixedHL for bug fixes, improvements and uncapped speed.
    - Configurable starting health, armor, weapons and ammo.
    - Ban weapons, ammo, health kits, batteries, chargers and long jump modules.
    - Configurable damage for each weapon.
    - Faster firing and reloading for selected weapons.
    - Faster health and HEV charger recharge.
    - Flying crowbar: throw your crowbar with secondary attack.
    - Grappling hook, bound to "+hook".
    - Optional rune plugins:
        - Cloak: makes you semi-invisible.
        - Haste: weapons cycle twice as fast.
        - Low Gravity: lowers gravity for you only.
        - Protection: halves incoming damage.
        - Regeneration: restores HP and HEV over time.
        - Shield: temporary immunity with "userune".
        - Shock: damages nearby players with "userune".
        - Super Crowbar: massive crowbar damage.
        - Super Glock: unlimited ammo and a 40 FOV sniper mode.
        - Super Hook: faster grapple that deals damage.
        - Super Jump: grants the long jump module.
        - Super Speed: increases your movement speed.
        - Teleport: teleports you to a random destination.
        - Booby Trap: explodes when you die.
        - Vampire: heals you for damage dealt.
    - Random rune pickups: every 5 seconds, each one changes to another enabled rune;
      picking it up grants the rune currently shown.
    - Pick up runes, then use them with "userune" or drop them with "droprune".
    - English and Spanish translations.

    # Thanks to:
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

    # Testers:
    - DarkZito
    - K3NS4N
    - Assassin
    - Dcarlox
    - Intel Extreme Masters

    # Contact:
    - E-mail: alonso.caychop@protonmail.com
    - Discord: _7mochi_
    - Steam: https://steamcommunity.com/id/_7mochi/
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <hlstocks>
#include <rog>
#include <xs>
#include <xdm_reborn_const>

#pragma semicolon 1

#define SIZE_WEAPONS                14
#define XDM_RANDOM_RUNE             -2
#define SIZE_AMMO                   7
#define SIZE_BAN_WEAPONS            14
#define SIZE_AMMO_ENTS              9
#define SIZE_DAMAGE_WEAPONS         16
#define UNINITIALIZED_DESTINATION   72769.420

#define PLUGIN                      "XDM Reborn"
#define AUTHOR                      "7mochi"

enum _:WeaponDefaultData {
    WEAPON_CVAR,
    WEAPON_DEFAULT
};

enum _:DamageWeaponData {
    DAMAGE_CVAR,
    DAMAGE_DEFAULT,
    DAMAGE_MP_CVAR
};

enum {
    TASK_HOOK_THINK = 72769,
    TASK_RUNE_HUD = 72770
}

new g_cvarXdmDamageWeapons[SIZE_DAMAGE_WEAPONS];
new g_cvarMpDamageWeapons[SIZE_DAMAGE_WEAPONS];

new g_iStartHP;
new g_iStartHEV;
new bool:g_bStartLongJump;
new bool:g_bBanHealthKit;
new bool:g_bBanBattery;
new bool:g_bBanRecharge;
new bool:g_bBanLongJump;
new g_iStartWeapons[SIZE_WEAPONS];
new g_iStartAmmo[SIZE_AMMO];
new g_iBanWeapons[SIZE_BAN_WEAPONS];
new g_iBanAmmo[SIZE_AMMO_ENTS];
new Float:g_fXdmDamageWeapons[SIZE_DAMAGE_WEAPONS];

new Float:g_fReloadSpeed;
new Float:g_fPlayerSpeed;

new g_iFlyCrowbarSpeed;
new bool:g_bFlyCrowbarTrail;
new Float:g_fFlyCrowbarDamage;
new bool:g_bFlyCrowbarRender;
new Float:g_fFlyCrowbarLifetime;
new Float:g_fFlyCrowbarCycle;

new bool:g_bHookEnabled;
new Float:g_fHookSpeed;
new g_iRandomRuneCount;

new const RUNE_MODEL[] = "models/xdm_rune.mdl";
new const RUNE_PICKUP_SOUND[] = "xdm.wav";
new const RUNE_CLASSNAME[] = "func_rune";

new const FLY_CROWBAR_BLOOD_SPRITE[] = "sprites/blood.spr";
new const FLY_CROWBAR_BLOODSPRAY_SPRITE[] = "sprites/bloodspray.spr";
new const FLY_CROWBAR_TRAIL_SPRITE[] = "sprites/zbeam3.spr";
new const FLY_CROWBAR_CLASSNAME[] = "func_fly_crowbar";

new const HOOK_BEAM_SPRITE[] = "sprites/dot.spr";
new const HOOK_HIT_SOUND[] = "weapons/xbow_hit2.wav";

new const g_vszStartWeapons[SIZE_WEAPONS][WeaponDefaultData][] = {
    {"xdm_start_gauss", "1"},
    {"xdm_start_357", "1"},
    {"xdm_start_mp5", "1"},
    {"xdm_start_glock", "1"},
    {"xdm_start_crossbow", "1"},
    {"xdm_start_crowbar", "1"},
    {"xdm_start_egon", "0"},
    {"xdm_start_hgrenade", "0"},
    {"xdm_start_hornet", "0"},
    {"xdm_start_rpg", "1"},
    {"xdm_start_satchel", "0"},
    {"xdm_start_shotgun", "1"},
    {"xdm_start_snark", "0"},
    {"xdm_start_tripmine", "0"},
};

new const g_vszStartAmmo[SIZE_AMMO][WeaponDefaultData][] = {
    {"xdm_start_bockshot", "84"},
    {"xdm_start_9mmar", "100"},
    {"xdm_start_m203", "2"},
    {"xdm_start_357ammo", "36"},
    {"xdm_start_uranium", "100"},
    {"xdm_start_rockets", "1"},
    {"xdm_start_bolts", "50"},
};

new const g_vszCvarBanWeapons[SIZE_BAN_WEAPONS][] = {
    "xdm_ban_gauss",
    "xdm_ban_357",
    "xdm_ban_mp5",
    "xdm_ban_glock",
    "xdm_ban_crossbow",
    "xdm_ban_crowbar",
    "xdm_ban_egon",
    "xdm_ban_hgrenade",
    "xdm_ban_hornet",
    "xdm_ban_rpg",
    "xdm_ban_satchel",
    "xdm_ban_shotgun",
    "xdm_ban_snark",
    "xdm_ban_tripmine",
};

new const g_vszCvarBanAmmo[SIZE_AMMO_ENTS][] = {
    "xdm_ban_357ammo",
    "xdm_ban_9mmar",
    "xdm_ban_9mmar",
    "xdm_ban_9mmar",
    "xdm_ban_m203",
    "xdm_ban_bolts",
    "xdm_ban_uranium",
    "xdm_ban_rockets",
    "xdm_ban_buckshot"
};

new const g_vszDamageWeapons[SIZE_DAMAGE_WEAPONS][DamageWeaponData][] = {
    {"xdm_dmg_crowbar", "30", "mp_dmg_crowbar"},
    {"xdm_dmg_glock", "12", "mp_dmg_glock"},
    {"xdm_dmg_357", "40", "mp_dmg_357"},
    {"xdm_dmg_mp5", "12", "mp_dmg_mp5"},
    {"xdm_dmg_shotgun", "20", "mp_dmg_shotgun"},
    {"xdm_dmg_bolts_normal", "120", "mp_dmg_xbow_scope"},
    {"xdm_dmg_bolts_explosion", "50", "mp_dmg_xbow_noscope"},
    {"xdm_dmg_rpg", "120", "mp_dmg_rpg"},
    {"xdm_dmg_gauss", "20", "mp_dmg_gauss_primary"},
    {"xdm_dmg_gauss_secondary", "200", "mp_dmg_gauss_secondary"},
    {"xdm_dmg_egon", "14", "mp_dmg_egon"},
    {"xdm_dmg_hornet", "16", "mp_dmg_hornet"},
    {"xdm_dmg_hgrenade", "100", "mp_dmg_hgrenade"},
    {"xdm_dmg_satchel", "120", "mp_dmg_satchel"},
    {"xdm_dmg_tripmine", "150", "mp_dmg_tripmine"},
    {"xdm_dmg_m203", "100", "mp_dmg_m203"}
};

new const g_vszWeaponClass[][] = {
    "weapon_gauss",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_9mmhandgun",
    "weapon_crossbow",
    "weapon_crowbar",
    "weapon_egon",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_rpg",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
};

new const g_vszAmmoClass[][] = {
    "ammo_357",
    "ammo_9mmAR",
    "ammo_9mmbox",
    "ammo_9mmclip",
    "ammo_ARgrenades",
    "ammo_crossbow",
    "ammo_gaussclip",
    "ammo_rpgclip",
    "ammo_buckshot"
};

new const g_vszCustomReloadRateWeapons[][] = {
    "weapon_glock",
    "weapon_357",
    "weapon_mp5",
    "weapon_crossbow",
    "weapon_rpg",
};

new bool:g_bGamePlayerEquipExists;
new bool:g_bIsAGServer;
new bool:g_vbHook[MAX_PLAYERS + 1];
new Float:g_vfHookTo[MAX_PLAYERS + 1][3];
new Float:g_vfHookGravity[MAX_PLAYERS + 1];
new Float:g_vfHookSpeed[MAX_PLAYERS + 1];
new g_iFwdHookStart = -1;
new g_iHudDisplayRuneStatus;
new g_iJuice;
new g_iShotgunOldSpecialReload[MAX_PLAYERS + 1];
new g_iOldClip[MAX_PLAYERS + 1];
new g_iTrailSprite;
new g_iBloodSprite;
new g_iBloodSpraySprite;
new g_iBeamSprite;

new Trie:g_tRuneIds;
new g_szRuneId[XDM_MAX_RUNES][XDM_RUNE_ID_LENGTH];
new g_szRuneDisplayName[XDM_MAX_RUNES][XDM_RUNE_DISPLAY_NAME_LENGTH];
new g_szRuneNameKey[XDM_MAX_RUNES][XDM_RUNE_KEY_LENGTH];
new g_szRuneDescKey[XDM_MAX_RUNES][XDM_RUNE_KEY_LENGTH];
new bool:g_bRuneRegistered[XDM_MAX_RUNES];
new bool:g_bRuneUsable[XDM_MAX_RUNES];
new g_cvarRuneCount[XDM_MAX_RUNES];
new g_cvarRuneColor[XDM_MAX_RUNES];
new g_iFwdPickup[XDM_MAX_RUNES];
new g_iFwdUse[XDM_MAX_RUNES];
new g_iFwdCooldown[XDM_MAX_RUNES];
new g_iFwdDrop[XDM_MAX_RUNES];
new g_iFwdDeath[XDM_MAX_RUNES];
new g_iFwdSpawn[XDM_MAX_RUNES];
new g_iPlayerRune[MAX_PLAYERS + 1];
new g_iRuneCooldown[MAX_PLAYERS + 1];
new Float:g_vfRuneCooldown[MAX_PLAYERS + 1];
new Float:g_vfPickupCooldown[MAX_PLAYERS + 1];

public plugin_natives() {
    g_tRuneIds = TrieCreate();

    for (new i; i < XDM_MAX_RUNES; i++) {
        g_iFwdPickup[i] = -1;
        g_iFwdUse[i] = -1;
        g_iFwdCooldown[i] = -1;
        g_iFwdDrop[i] = -1;
        g_iFwdDeath[i] = -1;
        g_iFwdSpawn[i] = -1;
        g_cvarRuneCount[i] = 0;
        g_cvarRuneColor[i] = 0;
        g_bRuneRegistered[i] = false;
        g_bRuneUsable[i] = false;
        g_szRuneId[i][0] = 0;
        g_szRuneDisplayName[i][0] = 0;
        g_szRuneNameKey[i][0] = 0;
        g_szRuneDescKey[i][0] = 0;
    }

    for (new i; i <= MAX_PLAYERS; i++) {
        g_iPlayerRune[i] = XDM_INVALID_RUNE;
        g_iRuneCooldown[i] = XDM_INVALID_RUNE;
        g_vfRuneCooldown[i] = 0.0;
        g_vfPickupCooldown[i] = 0.0;
        g_vbHook[i] = false;
        g_vfHookGravity[i] = 0.0;
        g_vfHookSpeed[i] = 0.0;
    }

    register_library("xdm_reborn");

    register_native("xdm_register_rune", "native_xdm_register_rune");
    register_native("xdm_get_user_rune", "native_xdm_get_user_rune");
    register_native("xdm_find_rune", "native_xdm_find_rune");
    register_native("xdm_set_rune_cooldown", "native_xdm_set_rune_cooldown");
    register_native("xdm_set_hook_speed", "native_xdm_set_hook_speed");
}

public plugin_precache() {
    register_dictionary("xdm_reborn.txt");

    precache_model(RUNE_MODEL);
    g_iTrailSprite = precache_model(FLY_CROWBAR_TRAIL_SPRITE);
    g_iBloodSprite = precache_model(FLY_CROWBAR_BLOOD_SPRITE);
    g_iBloodSpraySprite = precache_model(FLY_CROWBAR_BLOODSPRAY_SPRITE);
    g_iBeamSprite = precache_model(HOOK_BEAM_SPRITE);

    precache_sound(RUNE_PICKUP_SOUND);
    precache_sound(HOOK_HIT_SOUND);
}

public plugin_init() {
    register_plugin(PLUGIN, XDM_VERSION, AUTHOR);

    g_bIsAGServer = cvar_exists("sv_ag_version") ? true : false;

    register_cvars();

    AutoExecConfig();

    register_forward(FM_GetGameDescription, "fwd_game_description");

    register_clcmd("spectate", "cmd_spectate");
    register_clcmd("userune", "cmd_use_rune");
    register_clcmd("droprune", "cmd_drop_rune");

    register_concmd("+hook", "cmd_hook_enable");
    register_concmd("-hook", "cmd_hook_disable");

    register_think(FLY_CROWBAR_CLASSNAME, "fly_crowbar_think");
    register_think(RUNE_CLASSNAME, "rune_think");

    register_touch(RUNE_CLASSNAME, "player", "fwd_pickup_rune");
    register_touch(FLY_CROWBAR_CLASSNAME, "*", "fwd_fly_crowbar_impact");

    for (new i = 0; i < sizeof g_vszCustomReloadRateWeapons; i++) {
        RegisterHam(Ham_Weapon_Reload, g_vszCustomReloadRateWeapons[i], "fwd_weapons_custom_reload_rate", 1);
    }
    RegisterHam(Ham_Weapon_Reload, "weapon_shotgun", "fwd_shotgun_custom_reload_rate_pre", 0);
    RegisterHam(Ham_Weapon_Reload, "weapon_shotgun", "fwd_shotgun_custom_reload_rate_post", 1);

    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "fwd_shotgun_primary_attack_pre", 0);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "fwd_shotgun_primary_attack_post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "fwd_shotgun_secondary_attack_pre", 0);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "fwd_shotgun_secondary_attack_post", 1);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_crossbow", "fwd_crossbow_primary_attack_post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_crossbow", "fwd_crossbow_secondary_attack_post", 1);

    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_crowbar", "fwd_crowbar_secondary_attack");
    RegisterHam(Ham_Item_AddToPlayer, "weapon_crowbar", "fwd_crowbar_item_add");
    RegisterHam(Ham_Item_AddDuplicate, "weapon_crowbar", "fwd_crowbar_item_add");

    RegisterHam(Ham_Killed, "player", "fwd_player_killed");
    RegisterHam(Ham_Spawn, "player", "fwd_player_spawn_post", 1);

    RegisterHam(Ham_Use, "func_healthcharger", "fwd_use_charger_pre", 0);
    RegisterHam(Ham_Use, "func_healthcharger", "fwd_use_hp_charger_post", 1);
    RegisterHam(Ham_Use, "func_recharge", "fwd_use_charger_pre", 0);
    RegisterHam(Ham_Use, "func_recharge", "fwd_use_hev_charger_post", 1);

    g_iFwdHookStart = CreateMultiForward("xdm_hook_start", ET_IGNORE, FP_CELL);

    g_iHudDisplayRuneStatus = CreateHudSyncObj();
}

public register_cvars() {
    new szDescription[96];

    if (!g_bIsAGServer) {
        bind_pcvar_num(create_cvar("xdm_start_hp", "100", FCVAR_NONE, "Health the player starts with.", true, 0.0, true, 1000.0), g_iStartHP);
        bind_pcvar_num(create_cvar("xdm_start_hev", "50", FCVAR_NONE, "Armor the player starts with.", true, 0.0, true, 1000.0), g_iStartHEV);
        bind_pcvar_num(create_cvar("xdm_start_longjump", "1", FCVAR_NONE, "Whether the player starts with the long jump module.", true, 0.0, true, 1.0), g_bStartLongJump);

        for (new i; i < sizeof g_vszStartWeapons; i++) {
            formatex(szDescription, charsmax(szDescription), "Whether the player starts with %s.", g_vszStartWeapons[i][WEAPON_CVAR]);
            bind_pcvar_num(create_cvar(g_vszStartWeapons[i][WEAPON_CVAR], g_vszStartWeapons[i][WEAPON_DEFAULT], FCVAR_NONE, szDescription, true, 0.0, true, 1.0), g_iStartWeapons[i]);
        }

        for (new i; i < sizeof g_vszStartAmmo; i++) {
            formatex(szDescription, charsmax(szDescription), "Amount of ammo the player starts with for %s.", g_vszStartAmmo[i][WEAPON_CVAR]);
            bind_pcvar_num(create_cvar(g_vszStartAmmo[i][WEAPON_CVAR], g_vszStartAmmo[i][WEAPON_DEFAULT], FCVAR_NONE, szDescription, true, 0.0, true, 999.0), g_iStartAmmo[i]);
        }

        for (new i; i < sizeof g_vszCvarBanWeapons; i++) {
            formatex(szDescription, charsmax(szDescription), "Whether %s entities are banned.", g_vszCvarBanWeapons[i]);
            bind_pcvar_num(create_cvar(g_vszCvarBanWeapons[i], "0", FCVAR_NONE, szDescription, true, 0.0, true, 1.0), g_iBanWeapons[i]);
        }

        for (new i; i < sizeof g_vszCvarBanAmmo; i++) {
            formatex(szDescription, charsmax(szDescription), "Whether %s entities are banned.", g_vszCvarBanAmmo[i]);
            bind_pcvar_num(create_cvar(g_vszCvarBanAmmo[i], "0", FCVAR_NONE, szDescription, true, 0.0, true, 1.0), g_iBanAmmo[i]);
        }

        bind_pcvar_num(create_cvar("xdm_ban_health_kit", "0", FCVAR_NONE, "Whether health kit entities are banned.", true, 0.0, true, 1.0), g_bBanHealthKit);
        bind_pcvar_num(create_cvar("xdm_ban_battery", "0", FCVAR_NONE, "Whether battery entities are banned.", true, 0.0, true, 1.0), g_bBanBattery);
        bind_pcvar_num(create_cvar("xdm_ban_recharge", "0", FCVAR_NONE, "Whether health and HEV chargers are banned.", true, 0.0, true, 1.0), g_bBanRecharge);
        bind_pcvar_num(create_cvar("xdm_ban_longjump", "0", FCVAR_NONE, "Whether long jump module entities are banned.", true, 0.0, true, 1.0), g_bBanLongJump);

        for (new i = 0; i < SIZE_DAMAGE_WEAPONS; i++) {
            g_cvarMpDamageWeapons[i] = get_cvar_pointer(g_vszDamageWeapons[i][DAMAGE_MP_CVAR]);

            formatex(szDescription, charsmax(szDescription), "Damage dealt by %s.", g_vszDamageWeapons[i][DAMAGE_CVAR]);
            g_cvarXdmDamageWeapons[i] = create_cvar(g_vszDamageWeapons[i][DAMAGE_CVAR], g_vszDamageWeapons[i][DAMAGE_DEFAULT], FCVAR_NONE, szDescription, true, 0.0, true, 10000.0);
            bind_pcvar_float(g_cvarXdmDamageWeapons[i], g_fXdmDamageWeapons[i]);
            hook_cvar_change(g_cvarXdmDamageWeapons[i], "hook_cvar_xdm_damage_weapons");
        }
    }

    bind_pcvar_float(create_cvar("xdm_reload_speed", "0.5", FCVAR_NONE, "Multiplier applied to weapon reload time. Lower is faster.", true, 0.01, true, 10.0), g_fReloadSpeed);
    bind_pcvar_float(create_cvar("xdm_player_speed", "300.0", FCVAR_NONE, "Maximum speed of the player.", true, 0.0, true, 3000.0), g_fPlayerSpeed);

    bind_pcvar_num(create_cvar("xdm_flycrowbar_speed", "1500", FCVAR_NONE, "Speed of the flying crowbar.", true, 0.0, true, 10000.0), g_iFlyCrowbarSpeed);
    bind_pcvar_num(create_cvar("xdm_flycrowbar_trail", "1", FCVAR_NONE, "Whether the flying crowbar has a trail.", true, 0.0, true, 1.0), g_bFlyCrowbarTrail);
    bind_pcvar_float(create_cvar("xdm_flycrowbar_damage", "125.0", FCVAR_NONE, "Damage dealt by the flying crowbar.", true, 0.0, true, 10000.0), g_fFlyCrowbarDamage);
    bind_pcvar_num(create_cvar("xdm_flycrowbar_render", "1", FCVAR_NONE, "Whether the dropped crowbar glows.", true, 0.0, true, 1.0), g_bFlyCrowbarRender);
    bind_pcvar_float(create_cvar("xdm_flycrowbar_lifetime", "15.0", FCVAR_NONE, "Time before a dropped crowbar is removed.", true, 0.0, true, 600.0), g_fFlyCrowbarLifetime);
    bind_pcvar_float(create_cvar("xdm_flycrowbar_cycle", "1.0", FCVAR_NONE, "Secondary attack cooldown of the flying crowbar.", true, 0.0, true, 10.0), g_fFlyCrowbarCycle);

    bind_pcvar_num(create_cvar("xdm_hook_enabled", "1", FCVAR_NONE, "Whether the grappling hook is enabled.", true, 0.0, true, 1.0), g_bHookEnabled);
    bind_pcvar_float(create_cvar("xdm_hook_speed", "7.0", FCVAR_NONE, "Speed of the grappling hook.", true, 0.0, true, 100.0), g_fHookSpeed);
    bind_pcvar_num(create_cvar("xdm_rune_random_count", "0", FCVAR_NONE, "Number of random runes to spawn.", true, 0.0, true, 64.0), g_iRandomRuneCount);
}

public OnConfigsExecuted() {
    sync_mp_damage_cvars();

    if (!g_bIsAGServer) {
        remove_banned_entities();
    }

    g_bGamePlayerEquipExists = find_game_player_equip() ? true : false;

    ROGInitialize(200.0);

    new maxPlayers = get_maxplayers();

    for (new i = 1; i <= MAX_PLAYERS; i++) {
        rune_reset_player(i, i <= maxPlayers);
        g_vbHook[i] = false;
        g_vfHookGravity[i] = 0.0;
        g_vfHookSpeed[i] = 0.0;
    }

    for (new i; i < XDM_MAX_RUNES; i++) {
        if (!g_bRuneRegistered[i]) {
            continue;
        }

        new count = get_pcvar_num(g_cvarRuneCount[i]);
        for (new j; j < count; j++) {
            rune_spawn(i);
        }
    }

    new randomCount = g_iRandomRuneCount;
    for (new i; i < randomCount; i++) {
        rune_spawn_random();
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        remove_task(i + TASK_RUNE_HUD);
    }

    for (new i; i < XDM_MAX_RUNES; i++) {
        rune_destroy_forwards(i);
    }

    if (g_iFwdHookStart >= 0) {
        DestroyForward(g_iFwdHookStart);
        g_iFwdHookStart = -1;
    }

    if (g_tRuneIds != Invalid_Trie) {
        TrieDestroy(g_tRuneIds);
        g_tRuneIds = Invalid_Trie;
    }
}

public native_xdm_register_rune(const iPluginId, const iArgc) {
    if (iArgc != 3) {
        log_error(AMX_ERR_PARAMS, "[xdm_reborn] xdm_register_rune expects 3 arguments, got %d.", iArgc);
        return XDM_INVALID_RUNE;
    }

    new id[XDM_RUNE_ID_LENGTH];
    new displayName[XDM_RUNE_DISPLAY_NAME_LENGTH];

    get_string(1, displayName, charsmax(displayName));

    new defaultCount = get_param(2);
    new defaultColor = get_param(3);

    if (displayName[0] == 0) {
        log_amx("[xdm_reborn] Rune has an empty display name.");
        return XDM_INVALID_RUNE;
    }

    if (!rune_id_from_display_name(displayName, id, charsmax(id)) || !rune_valid_id(id)) {
        log_amx("[xdm_reborn] Cannot derive a valid rune id from '%s'.", displayName);
        return XDM_INVALID_RUNE;
    }

    if (TrieKeyExists(g_tRuneIds, id)) {
        log_amx("[xdm_reborn] Rune '%s' is already registered.", id);
        return XDM_INVALID_RUNE;
    }

    new index = rune_find_free_slot();
    if (index == XDM_INVALID_RUNE) {
        log_amx("[xdm_reborn] Cannot register rune '%s': registry is full.", id);
        return XDM_INVALID_RUNE;
    }

    defaultCount = clamp(defaultCount, 0, 64);
    defaultColor = clamp(defaultColor, 0, 15);

    copy(g_szRuneId[index], charsmax(g_szRuneId[]), id);
    copy(g_szRuneDisplayName[index], charsmax(g_szRuneDisplayName[]), displayName);
    rune_build_lang_key(id, "NAME", g_szRuneNameKey[index], charsmax(g_szRuneNameKey[]));
    rune_build_lang_key(id, "DESC", g_szRuneDescKey[index], charsmax(g_szRuneDescKey[]));

    new szCvar[64];
    new szValue[16];
    new szDescription[96];

    formatex(szCvar, charsmax(szCvar), "xdm_rune_%s_count", id);
    formatex(szDescription, charsmax(szDescription), "Number of %s runes to spawn.", displayName);
    formatex(szValue, charsmax(szValue), "%d", defaultCount);
    g_cvarRuneCount[index] = create_cvar(szCvar, szValue, FCVAR_NONE, szDescription, true, 0.0, true, 64.0);

    formatex(szCvar, charsmax(szCvar), "xdm_rune_%s_color", id);
    formatex(szDescription, charsmax(szDescription), "Skin color of %s runes.", displayName);
    formatex(szValue, charsmax(szValue), "%d", defaultColor);
    g_cvarRuneColor[index] = create_cvar(szCvar, szValue, FCVAR_NONE, szDescription, true, 0.0, true, 15.0);

    if (!g_cvarRuneCount[index] || !g_cvarRuneColor[index]) {
        log_amx("[xdm_reborn] Cannot create cvars for rune '%s'.", id);
        rune_clear_slot(index);
        return XDM_INVALID_RUNE;
    }

    g_iFwdPickup[index] = rune_create_forward(iPluginId, "xdm_rune_pickup", 2);
    g_iFwdUse[index] = rune_create_forward(iPluginId, "xdm_rune_use", 2);
    g_iFwdCooldown[index] = rune_create_forward(iPluginId, "xdm_rune_cooldown", 2);
    g_iFwdDrop[index] = rune_create_forward(iPluginId, "xdm_rune_drop", 2);
    g_iFwdDeath[index] = rune_create_forward(iPluginId, "xdm_rune_death", 3);
    g_iFwdSpawn[index] = rune_create_forward(iPluginId, "xdm_rune_spawn", 2);

    g_bRuneUsable[index] = g_iFwdUse[index] >= 0;
    g_bRuneRegistered[index] = true;
    TrieSetCell(g_tRuneIds, id, index);

    return index;
}

public native_xdm_get_user_rune(const iPluginId, const iArgc) {
    if (iArgc != 1) {
        log_error(AMX_ERR_PARAMS, "[xdm_reborn] xdm_get_user_rune expects 1 argument, got %d.", iArgc);
        return XDM_INVALID_RUNE;
    }

    new player = get_param(1);
    if (player < 1 || player > MAX_PLAYERS) {
        return XDM_INVALID_RUNE;
    }

    return g_iPlayerRune[player];
}

public native_xdm_find_rune(const iPluginId, const iArgc) {
    if (iArgc != 1) {
        log_error(AMX_ERR_PARAMS, "[xdm_reborn] xdm_find_rune expects 1 argument, got %d.", iArgc);
        return XDM_INVALID_RUNE;
    }

    new id[XDM_RUNE_ID_LENGTH];
    get_string(1, id, charsmax(id));

    new index;
    if (!TrieGetCell(g_tRuneIds, id, index)) {
        return XDM_INVALID_RUNE;
    }

    if (index < 0 || index >= XDM_MAX_RUNES || !g_bRuneRegistered[index]) {
        return XDM_INVALID_RUNE;
    }

    return index;
}

public native_xdm_set_rune_cooldown(const iPluginId, const iArgc) {
    if (iArgc != 3) {
        log_error(AMX_ERR_PARAMS, "[xdm_reborn] xdm_set_rune_cooldown expects 3 arguments, got %d.", iArgc);
        return 0;
    }

    new rune = get_param(1);
    new player = get_param(2);
    new Float:seconds = get_param_f(3);

    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return 0;
    }

    if (player < 1 || player > MAX_PLAYERS || g_iPlayerRune[player] != rune) {
        return 0;
    }

    if (seconds <= 0.0) {
        g_iRuneCooldown[player] = XDM_INVALID_RUNE;
        g_vfRuneCooldown[player] = 0.0;
        return 1;
    }

    g_iRuneCooldown[player] = rune;
    g_vfRuneCooldown[player] = get_gametime() + seconds;
    return 1;
}

public native_xdm_set_hook_speed(const iPluginId, const iArgc) {
    if (iArgc != 2) {
        log_error(AMX_ERR_PARAMS, "[xdm_reborn] xdm_set_hook_speed expects 2 arguments, got %d.", iArgc);
        return 0;
    }

    new player = get_param(1);
    if (player < 1 || player > MAX_PLAYERS) {
        return 0;
    }

    new Float:speed = get_param_f(2);
    g_vfHookSpeed[player] = speed > 0.0 ? speed : 0.0;
    return 1;
}

stock hook_execute_start(player) {
    if (g_iFwdHookStart < 0) {
        return;
    }

    new ret;
    ExecuteForward(g_iFwdHookStart, ret, player);
}

stock bool:player_has_rune_id(player, const id[]) {
    if (player < 1 || player > MAX_PLAYERS) {
        return false;
    }

    new rune = g_iPlayerRune[player];
    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return false;
    }

    if (equal(g_szRuneId[rune], id)) {
        return true;
    }

    return false;
}

stock rune_build_lang_key(const id[], const suffix[], output[], maxLength) {
    new upper[XDM_RUNE_ID_LENGTH];
    new length = strlen(id);

    for (new i; i < length; i++) {
        new character = id[i];
        if (character >= 'a' && character <= 'z') {
            character -= 'a' - 'A';
        }

        upper[i] = character;
    }

    upper[length] = 0;
    formatex(output, maxLength, "XDM_RUNE_%s_%s", upper, suffix);
}

stock bool:rune_id_from_display_name(const displayName[], id[], maxLength) {
    new length = strlen(displayName);
    new position;
    new bool:separator = true;

    for (new i; i < length; i++) {
        new character = displayName[i];

        if (character >= 'A' && character <= 'Z') {
            character += 'a' - 'A';
        }

        if ((character >= 'a' && character <= 'z') ||
            (character >= '0' && character <= '9')) {
            if (position >= maxLength - 1) {
                return false;
            }

            id[position++] = character;
            separator = false;
        } else if (!separator && position > 0) {
            if (position >= maxLength - 1) {
                return false;
            }

            id[position++] = '_';
            separator = true;
        }
    }

    if (position > 0 && id[position - 1] == '_') {
        position--;
    }

    id[position] = 0;
    return position > 0;
}

stock bool:rune_valid_id(const id[]) {
    new length = strlen(id);
    if (length == 0 || length >= XDM_RUNE_ID_LENGTH) {
        return false;
    }

    for (new i; i < length; i++) {
        new character = id[i];
        if (!((character >= 'a' && character <= 'z') ||
              (character >= '0' && character <= '9') ||
              character == '_')) {
            return false;
        }
    }

    return true;
}

stock rune_find_free_slot() {
    for (new i; i < XDM_MAX_RUNES; i++) {
        if (!g_bRuneRegistered[i]) {
            return i;
        }
    }

    return XDM_INVALID_RUNE;
}

stock rune_create_forward(plugin, const func[], cells) {
    if (get_func_id(func, plugin) == -1) {
        return -1;
    }

    new handle;
    switch (cells) {
        case 2: {
            handle = CreateOneForward(plugin, func, FP_CELL, FP_CELL);
        }
        case 3: {
            handle = CreateOneForward(plugin, func, FP_CELL, FP_CELL, FP_CELL);
        }
        default: {
            return -1;
        }
    }

    if (handle < 0) {
        log_amx("[xdm_reborn] Failed to create callback forward '%s'.", func);
    }

    return handle;
}

stock rune_destroy_forwards(index) {
    if (index < 0 || index >= XDM_MAX_RUNES) {
        return;
    }

    if (g_iFwdPickup[index] >= 0) {
        DestroyForward(g_iFwdPickup[index]);
        g_iFwdPickup[index] = -1;
    }

    if (g_iFwdUse[index] >= 0) {
        DestroyForward(g_iFwdUse[index]);
        g_iFwdUse[index] = -1;
    }

    if (g_iFwdCooldown[index] >= 0) {
        DestroyForward(g_iFwdCooldown[index]);
        g_iFwdCooldown[index] = -1;
    }

    if (g_iFwdDrop[index] >= 0) {
        DestroyForward(g_iFwdDrop[index]);
        g_iFwdDrop[index] = -1;
    }

    if (g_iFwdDeath[index] >= 0) {
        DestroyForward(g_iFwdDeath[index]);
        g_iFwdDeath[index] = -1;
    }

    if (g_iFwdSpawn[index] >= 0) {
        DestroyForward(g_iFwdSpawn[index]);
        g_iFwdSpawn[index] = -1;
    }
}

stock rune_execute_pickup(index, player) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdPickup[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdPickup[index], ret, index, player)) {
        log_amx("[xdm_reborn] Rune '%s' pickup callback failed.", g_szRuneId[index]);
    }
}

stock rune_execute_use(index, player) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdUse[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdUse[index], ret, index, player)) {
        log_amx("[xdm_reborn] Rune '%s' use callback failed.", g_szRuneId[index]);
    }
}

stock rune_execute_cooldown(index, player) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdCooldown[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdCooldown[index], ret, index, player)) {
        log_amx("[xdm_reborn] Rune '%s' cooldown callback failed.", g_szRuneId[index]);
    }
}

stock rune_execute_drop(index, player) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdDrop[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdDrop[index], ret, index, player)) {
        log_amx("[xdm_reborn] Rune '%s' drop callback failed.", g_szRuneId[index]);
    }
}

stock rune_execute_death(index, victim, attacker) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdDeath[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdDeath[index], ret, index, victim, attacker)) {
        log_amx("[xdm_reborn] Rune '%s' death callback failed.", g_szRuneId[index]);
    }
}

stock rune_execute_spawn(index, player) {
    if (index < 0 || index >= XDM_MAX_RUNES || g_iFwdSpawn[index] < 0) {
        return;
    }

    new ret;
    if (!ExecuteForward(g_iFwdSpawn[index], ret, index, player)) {
        log_amx("[xdm_reborn] Rune '%s' spawn callback failed.", g_szRuneId[index]);
    }
}

stock rune_spawn(index) {
    if (index < 0 || index >= XDM_MAX_RUNES || !g_bRuneRegistered[index]) {
        return;
    }

    new Float:origin[3];
    ROGGetOrigin(origin);

    new entity = create_entity("info_target");
    if (!entity) {
        log_amx("[xdm_reborn] Cannot create rune entity for '%s'.", g_szRuneId[index]);
        return;
    }

    entity_set_string(entity, EV_SZ_classname, RUNE_CLASSNAME);
    entity_set_model(entity, RUNE_MODEL);
    entity_set_float(entity, EV_FL_framerate, 1.0);
    entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
    entity_set_origin(entity, origin);
    entity_set_int(entity, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[index]));
    entity_set_int(entity, EV_INT_iuser1, index);
    drop_to_floor(entity);
}

stock rune_random_index() {
    new candidates[XDM_MAX_RUNES];
    new total;

    for (new i; i < XDM_MAX_RUNES; i++) {
        if (!g_bRuneRegistered[i]) {
            continue;
        }

        if (get_pcvar_num(g_cvarRuneCount[i]) <= 0) {
            continue;
        }

        candidates[total++] = i;
    }

    if (!total) {
        return XDM_INVALID_RUNE;
    }

    return candidates[random(total)];
}

stock rune_spawn_random() {
    new index = rune_random_index();
    if (index == XDM_INVALID_RUNE) {
        return;
    }

    new Float:origin[3];
    ROGGetOrigin(origin);

    new entity = create_entity("info_target");
    if (!entity) {
        return;
    }

    entity_set_string(entity, EV_SZ_classname, RUNE_CLASSNAME);
    entity_set_model(entity, RUNE_MODEL);
    entity_set_float(entity, EV_FL_framerate, 1.0);
    entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
    entity_set_origin(entity, origin);
    entity_set_int(entity, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[index]));
    entity_set_int(entity, EV_INT_iuser1, XDM_RANDOM_RUNE);
    entity_set_int(entity, EV_INT_iuser2, index);
    entity_set_int(entity, EV_INT_iuser3, 1);
    entity_set_float(entity, EV_FL_nextthink, get_gametime() + 5.0);
    drop_to_floor(entity);
}

public rune_think(entity) {
    if (!pev_valid(entity)) return;

    if (entity_get_int(entity, EV_INT_iuser1) != XDM_RANDOM_RUNE) return;

    new index = rune_random_index();
    if (index != XDM_INVALID_RUNE) {
        entity_set_int(entity, EV_INT_iuser2, index);
        entity_set_int(entity, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[index]));
    }

    entity_set_float(entity, EV_FL_nextthink, get_gametime() + 5.0);
}

stock rune_drop(player, bool:drop, bool:notify) {
    remove_task(player + TASK_RUNE_HUD);

    new rune = g_iPlayerRune[player];
    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return;
    }

    rune_execute_drop(rune, player);

    if (drop) {
        new Float:origin[3];
        new Float:angles[3];
        new Float:velocity[3];

        entity_get_vector(player, EV_VEC_origin, origin);
        entity_get_vector(player, EV_VEC_angles, angles);
        velocity_by_aim(player, 400, velocity);

        new entity = create_entity("info_target");
        if (entity) {
            entity_set_string(entity, EV_SZ_classname, RUNE_CLASSNAME);
            entity_set_model(entity, RUNE_MODEL);
            entity_set_float(entity, EV_FL_framerate, 1.0);
            entity_set_origin(entity, origin);
            entity_set_vector(entity, EV_VEC_angles, angles);
            entity_set_vector(entity, EV_VEC_velocity, velocity);
            entity_set_int(entity, EV_INT_movetype, MOVETYPE_TOSS);
            entity_set_int(entity, EV_INT_solid, SOLID_TRIGGER);
            entity_set_edict(entity, EV_ENT_aiment, 0);
            entity_set_int(entity, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[rune]));
            entity_set_int(entity, EV_INT_iuser1, rune);
            drop_to_floor(entity);
        } else {
            log_amx("[xdm_reborn] Cannot drop rune '%s'.", g_szRuneId[rune]);
        }
    }

    ClearSyncHud(player, g_iHudDisplayRuneStatus);

    if (notify) {
        rune_show_discarded(player, rune);
    }

    g_iPlayerRune[player] = XDM_INVALID_RUNE;
    g_iRuneCooldown[player] = XDM_INVALID_RUNE;
    g_vfRuneCooldown[player] = 0.0;
    g_vfPickupCooldown[player] = get_gametime() + 0.1;
}

stock rune_get_hud_text(player, rune, title[], titleLength, description[], descriptionLength) {
    if (g_szRuneNameKey[rune][0]) {
        formatex(title, titleLength, "%L", player, g_szRuneNameKey[rune]);
    } else {
        copy(title, titleLength, g_szRuneDisplayName[rune]);
    }

    if (g_szRuneDescKey[rune][0]) {
        formatex(description, descriptionLength, "%L", player, g_szRuneDescKey[rune]);
    } else {
        description[0] = 0;
    }
}

stock rune_show_pickup(player) {
    new rune = g_iPlayerRune[player];
    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return;
    }

    new title[64];
    new description[256];
    new message[512];
    rune_get_hud_text(player, rune, title, charsmax(title), description, charsmax(description));

    set_hudmessage(0, 255, 0, 0.04, 0.9, 0, 0.5, 5.0, 0.0, 3.0, 4);

    if (description[0]) {
        formatex(message, charsmax(message), "%s: %s", title, description);
    } else {
        copy(message, charsmax(message), title);
    }

    show_hudmessage(player, "%s", message);
}

stock rune_show_status(player) {
    new rune = g_iPlayerRune[player];
    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return;
    }

    new title[64];
    new description[256];
    rune_get_hud_text(player, rune, title, charsmax(title), description, charsmax(description));

    set_hudmessage(100, 100, 255, 0.45, 1.6, 0, 0.0, 9999.0, 0.0, 0.0, 3);
    ShowSyncHudMsg(player, g_iHudDisplayRuneStatus, "%s", title);
}

stock rune_show_discarded(player, rune) {
    new title[64];
    new description[256];
    new message[256];
    rune_get_hud_text(player, rune, title, charsmax(title), description, charsmax(description));

    formatex(message, charsmax(message), "%s: %L", title, player, "XDM_RUNE_DISCARDED");
    set_hudmessage(255, 0, 0, 0.04, 0.9, 0, 0.5, 5.0, 0.0, 3.0, 4);
    show_hudmessage(player, "%s", message);
}

stock rune_start_hud(player) {
    remove_task(player + TASK_RUNE_HUD);

    rune_show_pickup(player);
    set_task(8.0, "task_rune_hud", player + TASK_RUNE_HUD);
}

public task_rune_hud(task) {
    new player = task - TASK_RUNE_HUD;
    new rune = g_iPlayerRune[player];

    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        return;
    }

    rune_show_status(player);
}

stock rune_reset_player(player, bool:clear_hud) {
    remove_task(player + TASK_RUNE_HUD);
    g_iPlayerRune[player] = XDM_INVALID_RUNE;
    g_iRuneCooldown[player] = XDM_INVALID_RUNE;
    g_vfRuneCooldown[player] = 0.0;
    g_vfPickupCooldown[player] = 0.0;

    if (clear_hud) {
        ClearSyncHud(player, g_iHudDisplayRuneStatus);
    }
}

stock rune_clear_slot(index) {
    g_szRuneId[index][0] = 0;
    g_szRuneDisplayName[index][0] = 0;
    g_szRuneNameKey[index][0] = 0;
    g_szRuneDescKey[index][0] = 0;
    g_bRuneRegistered[index] = false;
    g_bRuneUsable[index] = false;
    g_cvarRuneCount[index] = 0;
    g_cvarRuneColor[index] = 0;
}

stock sync_mp_damage_cvars() {
    if (g_bIsAGServer) {
        return;
    }

    for (new i = 0; i < SIZE_DAMAGE_WEAPONS; i++) {
        if (g_cvarMpDamageWeapons[i]) {
            set_pcvar_float(g_cvarMpDamageWeapons[i], g_fXdmDamageWeapons[i]);
        }
    }
}

public client_putinserver(iPlayer) {
    rune_reset_player(iPlayer, false);
    g_vbHook[iPlayer] = false;
    g_vfHookGravity[iPlayer] = 0.0;
    g_vfHookSpeed[iPlayer] = 0.0;
}

public client_disconnected(iPlayer) {
    rune_drop(iPlayer, true, false);
    return PLUGIN_HANDLED;
}

public cmd_spectate(iPlayer) {
    rune_drop(iPlayer, true, false);
}

public cmd_use_rune(iPlayer) {
    new rune = g_iPlayerRune[iPlayer];

    if (rune < 0 || rune >= XDM_MAX_RUNES || !g_bRuneRegistered[rune]) {
        client_print(iPlayer, print_chat, "%l", "XDM_RUNE_NONE");
        return PLUGIN_HANDLED;
    }

    if (!is_user_alive(iPlayer)) {
        client_print(iPlayer, print_chat, "%l", "XDM_RUNE_DEAD");
        return PLUGIN_HANDLED;
    }

    if (!g_bRuneUsable[rune]) {
        client_print(iPlayer, print_chat, "%l", "XDM_RUNE_NOT_USABLE");
        return PLUGIN_HANDLED;
    }

    new Float:now = get_gametime();
    if (g_iRuneCooldown[iPlayer] == rune && now < g_vfRuneCooldown[iPlayer]) {
        client_print(iPlayer, print_chat, "%l", "XDM_RUNE_COOLDOWN",
            g_vfRuneCooldown[iPlayer] - now);
        rune_execute_cooldown(rune, iPlayer);
        return PLUGIN_HANDLED;
    }

    rune_execute_use(rune, iPlayer);
    return PLUGIN_HANDLED;
}

public cmd_drop_rune(iPlayer) {
    rune_drop(iPlayer, true, true);
    return PLUGIN_HANDLED;
}

public cmd_hook_enable(iPlayer) {
    if (!g_bHookEnabled || g_vbHook[iPlayer]) return PLUGIN_HANDLED;

    g_vfHookGravity[iPlayer] = entity_get_float(iPlayer, EV_FL_gravity);
    set_user_gravity(iPlayer, 0.0);
    set_task(0.1, "hook_think", iPlayer + TASK_HOOK_THINK, "", 0, "b");

    g_vbHook[iPlayer] = true;
    g_vfHookTo[iPlayer][0] = UNINITIALIZED_DESTINATION;

    hook_execute_start(iPlayer);
    hook_think(iPlayer + TASK_HOOK_THINK);
    emit_sound(iPlayer, CHAN_VOICE, HOOK_HIT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);

    return PLUGIN_HANDLED;
}

public cmd_hook_disable(iPlayer) {
    if (is_user_alive(iPlayer) &&
        entity_get_float(iPlayer, EV_FL_gravity) == 0.0) {
        entity_set_float(iPlayer, EV_FL_gravity, g_vfHookGravity[iPlayer]);
    }

    g_vbHook[iPlayer] = false;
    return PLUGIN_HANDLED;
}

public hook_think(iTask) {
    new iPlayer = iTask - TASK_HOOK_THINK;

    if (!is_user_alive(iPlayer)) g_vbHook[iPlayer] = false;

    if (!g_vbHook[iPlayer]) {
        remove_task(iPlayer + TASK_HOOK_THINK);
        return PLUGIN_HANDLED;
    }

    static Float:vfOrigin[3];
    entity_get_vector(iPlayer, EV_VEC_origin, vfOrigin);

    if (g_vfHookTo[iPlayer][0] == UNINITIALIZED_DESTINATION) {
        static viOrigin2[3];
        get_user_origin(iPlayer, viOrigin2, 3);
        g_vfHookTo[iPlayer][0] = float(viOrigin2[0]);
        g_vfHookTo[iPlayer][1] = float(viOrigin2[1]);
        g_vfHookTo[iPlayer][2] = float(viOrigin2[2]);
    }

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(1);
    write_short(iPlayer);
    write_coord_f(g_vfHookTo[iPlayer][0]);
    write_coord_f(g_vfHookTo[iPlayer][1]);
    write_coord_f(g_vfHookTo[iPlayer][2]);
    write_short(g_iBeamSprite);
    write_byte(1);
    write_byte(1);
    write_byte(2);
    write_byte(5);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    write_byte(255);
    write_byte(200);
    write_byte(0);
    message_end();

    static Float:vfVelocity[3];
    vfVelocity[0] = (g_vfHookTo[iPlayer][0] - vfOrigin[0]) * 3.0;
    vfVelocity[1] = (g_vfHookTo[iPlayer][1] - vfOrigin[1]) * 3.0;
    vfVelocity[2] = (g_vfHookTo[iPlayer][2] - vfOrigin[2]) * 3.0;

    static Float:xCoord, Float:yCoord;
    new Float:fHookSpeed = g_vfHookSpeed[iPlayer] > 0.0 ? g_vfHookSpeed[iPlayer] : g_fHookSpeed;

    yCoord = floatpower(vfVelocity[0], 2.0) + floatpower(vfVelocity[1], 2.0) + floatpower(vfVelocity[2], 2.0);
    xCoord = (fHookSpeed * 120.0) / floatsqroot(yCoord);

    vfVelocity[0] *= xCoord;
    vfVelocity[1] *= xCoord;
    vfVelocity[2] *= xCoord;

    entity_set_vector(iPlayer, EV_VEC_velocity, vfVelocity);

    return PLUGIN_CONTINUE;
}

public set_initial_equipment(iPlayer) {
    hl_set_user_health(iPlayer, g_iStartHP);
    hl_set_user_armor(iPlayer, g_iStartHEV);

    if (g_bStartLongJump) {
        hl_set_user_longjump(iPlayer, true);
    }

    for (new i; i < SIZE_WEAPONS; i++) {
        if (g_iStartWeapons[i]) {
            give_item(iPlayer, g_vszWeaponClass[i]);
        }
    }

    for (new i; i < SIZE_AMMO; i++) {
        if (g_iStartAmmo[i] != 0) {
            set_ent_data(iPlayer, "CBasePlayer", "m_rgAmmo", g_iStartAmmo[i], i + 1);
        }
    }
}

public remove_banned_entities() {
    for (new i; i < SIZE_BAN_WEAPONS; i++) {
        if (g_iBanWeapons[i]) {
            remove_entity_name(g_vszWeaponClass[i]);
        }
    }

    for (new i; i < SIZE_AMMO_ENTS; i++) {
        if (g_iBanAmmo[i]) {
            remove_entity_name(g_vszAmmoClass[i]);
        }
    }

    if (g_bBanHealthKit) {
        remove_entity_name("item_healthkit");
    }

    if (g_bBanBattery) {
        remove_entity_name("item_battery");
    }

    if (g_bBanLongJump) {
        remove_entity_name("item_longjump");
    }
}

public hook_cvar_xdm_damage_weapons(pcvar, const szOldValue[], const szNewValue[]) {
    for (new i; i < sizeof g_cvarXdmDamageWeapons; i++) {
        if (g_cvarXdmDamageWeapons[i] == pcvar) {
            if (g_cvarMpDamageWeapons[i]) {
                set_pcvar_string(g_cvarMpDamageWeapons[i], szNewValue);
            }

            return;
        }
    }
}

public fwd_game_description() {
    forward_return(FMV_STRING, PLUGIN + " " + XDM_VERSION);
    return FMRES_SUPERCEDE;
}

public fwd_player_killed(iVictim, iAttacker) {
    new rune = g_iPlayerRune[iVictim];

    if (rune >= 0 && rune < XDM_MAX_RUNES && g_bRuneRegistered[rune]) {
        rune_execute_death(rune, iVictim, iAttacker);
        rune_drop(iVictim, true, false);
    }
}

public fwd_player_spawn_post(iPlayer) {
    if (is_user_alive(iPlayer)) {
        set_user_maxspeed(iPlayer, g_fPlayerSpeed);

        if (!g_bGamePlayerEquipExists && !g_bIsAGServer) {
            hl_strip_user_weapon(iPlayer, HLW_GLOCK);
            hl_strip_user_weapon(iPlayer, HLW_CROWBAR);
            set_initial_equipment(iPlayer);
        }

        new rune = g_iPlayerRune[iPlayer];
        if (rune >= 0 && rune < XDM_MAX_RUNES && g_bRuneRegistered[rune]) {
            rune_execute_spawn(rune, iPlayer);
        }
    }
}

public fwd_use_charger_pre(iEntity, iPlayer) {
    if (g_bBanRecharge) return HAM_SUPERCEDE;

    g_iJuice = get_ent_data(iEntity, "CRecharge", "m_iJuice");

    return HAM_IGNORED;
}

public fwd_use_hp_charger_post(iEntity, iPlayer) {
    if (g_bBanRecharge) return HAM_SUPERCEDE;

    new iJuicePost = get_ent_data(iEntity, "CRecharge", "m_iJuice");
    if (g_iJuice != iJuicePost) {
        hl_set_user_health(iPlayer, min(100, hl_get_user_health(iPlayer) + 4));
        set_ent_data(iEntity, "CRecharge", "m_iJuice", max(0, iJuicePost - 4));
    }

    return HAM_IGNORED;
}

public fwd_use_hev_charger_post(iEntity, iPlayer) {
    if (g_bBanRecharge) return HAM_SUPERCEDE;

    new iJuicePost = get_ent_data(iEntity, "CRecharge", "m_iJuice");
    if (g_iJuice != iJuicePost) {
        hl_set_user_armor(iPlayer, min(100, hl_get_user_armor(iPlayer) + 4));
        set_ent_data(iEntity, "CRecharge", "m_iJuice", max(0, iJuicePost - 4));
    }

    return HAM_IGNORED;
}

public find_game_player_equip() {
    new iEntity;
    while ((iEntity = find_ent_by_class(iEntity, "game_player_equip"))) {
        if (!(entity_get_int(iEntity, EV_INT_spawnflags) & SF_PLAYEREQUIP_USEONLY)) return iEntity;
    }

    return 0;
}

public fwd_pickup_rune(iRune, iPlayer) {
    if (!pev_valid(iRune)) return PLUGIN_HANDLED;

    if (g_iPlayerRune[iPlayer] != XDM_INVALID_RUNE) return PLUGIN_HANDLED;

    if (get_gametime() < g_vfPickupCooldown[iPlayer]) return PLUGIN_HANDLED;

    new index = entity_get_int(iRune, EV_INT_iuser1);

    if (index == XDM_RANDOM_RUNE) {
        index = entity_get_int(iRune, EV_INT_iuser2);
    }

    if (index < 0 || index >= XDM_MAX_RUNES || !g_bRuneRegistered[index]) {
        return PLUGIN_HANDLED;
    }

    g_iPlayerRune[iPlayer] = index;
    g_iRuneCooldown[iPlayer] = XDM_INVALID_RUNE;
    g_vfRuneCooldown[iPlayer] = 0.0;
    rune_execute_pickup(index, iPlayer);
    emit_sound(iPlayer, CHAN_STATIC, RUNE_PICKUP_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
    rune_start_hud(iPlayer);
    remove_entity(iRune);

    return PLUGIN_HANDLED;
}

public fwd_weapons_custom_reload_rate(iWeapon) {
    if (get_ent_data(iWeapon, "CBasePlayerWeapon", "m_fInReload")) {
        new iPlayer = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");

        new Float:fNextAttack = get_ent_data_float(iPlayer, "CBaseMonster", "m_flNextAttack") *
                                g_fReloadSpeed;
        set_ent_data_float(iPlayer, "CBaseMonster", "m_flNextAttack", fNextAttack);
    }
}

public fwd_shotgun_custom_reload_rate_pre(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");
    g_iShotgunOldSpecialReload[iPlayer] = get_ent_data(iShotgun, "CBasePlayerWeapon", "m_fInSpecialReload");
}

public fwd_shotgun_custom_reload_rate_post(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");

    switch (g_iShotgunOldSpecialReload[iPlayer]) {
        case 0:
            if (get_ent_data(iShotgun, "CBasePlayerWeapon", "m_fInSpecialReload") == 1) {
                new Float:fNextAttack = get_ent_data_float(iPlayer, "CBaseMonster", "m_flNextAttack") *
                                        g_fReloadSpeed;
                set_ent_data_float(iPlayer, "CBaseMonster", "m_flNextAttack", fNextAttack);
                set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.1);
                set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.6);
                set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.6);
            }
        case 1:
            if (get_ent_data(iShotgun, "CBasePlayerWeapon", "m_fInSpecialReload") == 2) {
                set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.1);
            }
    }
}

public fwd_shotgun_primary_attack_pre(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");
    g_iOldClip[iPlayer] = get_ent_data(iShotgun, "CBasePlayerWeapon", "m_iClip");
}

public fwd_shotgun_primary_attack_post(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");

    if (g_iOldClip[iPlayer] <= 0) return;

    set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.5);

    if (get_ent_data(iShotgun, "CBasePlayerWeapon", "m_iClip") != 0) {
        set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0);
    } else {
        set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3);
    }
}

public fwd_shotgun_secondary_attack_pre(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");
    g_iOldClip[iPlayer] = get_ent_data(iShotgun, "CBasePlayerWeapon", "m_iClip");
}

public fwd_shotgun_secondary_attack_post(iShotgun) {
    new iPlayer = get_ent_data_entity(iShotgun, "CBasePlayerItem", "m_pPlayer");

    if (g_iOldClip[iPlayer] <= 1) return;

    set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.8);

    if (get_ent_data(iShotgun, "CBasePlayerWeapon", "m_iClip") != 0) {
        set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 3.0);
    } else {
        set_ent_data_float(iShotgun, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.85);
    }
}

public fwd_crossbow_primary_attack_post(iCrossbow) {
    set_ent_data_float(iCrossbow, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.5);
}

public fwd_crossbow_secondary_attack_post(iCrossbow) {
    set_ent_data_float(iCrossbow, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.5);
}

public fwd_crowbar_secondary_attack(iCrowbar) {
    new iPlayer = get_ent_data_entity(iCrowbar, "CBasePlayerItem", "m_pPlayer");

    if (!spawn_fly_crowbar(iPlayer)) {
        return HAM_IGNORED;
    }

    set_ent_data_float(iCrowbar, "CBasePlayerWeapon", "m_flNextSecondaryAttack", get_gametime() + g_fFlyCrowbarCycle);

    if (!player_has_rune_id(iPlayer, "super_crowbar")) {
        ExecuteHam(Ham_RemovePlayerItem, iPlayer, iCrowbar);
        user_has_weapon(iPlayer, HLW_CROWBAR, 0);
        ExecuteHamB(Ham_Item_Kill, iCrowbar);
    }

    return HAM_IGNORED;
}

public fwd_crowbar_item_add(iCrowbar) {
    remove_task(iCrowbar);
}

public spawn_fly_crowbar(iPlayer) {
    new iCrowbar = create_entity("info_target");

    if (is_valid_ent(iCrowbar)) {
        new Float:vfOrigin[3], Float:vfAngles[3], Float:vfVelocity[3];

        get_projective_position(iPlayer, vfOrigin);

        entity_get_vector(iPlayer, EV_VEC_v_angle, vfAngles);
        vfAngles[0] = 90.0;
        vfAngles[2] = floatadd(vfAngles[2], -90.0);

        velocity_by_aim(iPlayer, g_iFlyCrowbarSpeed + get_speed(iPlayer), vfVelocity);

        entity_set_string(iCrowbar, EV_SZ_classname, FLY_CROWBAR_CLASSNAME);
        entity_set_model(iCrowbar, "models/w_crowbar.mdl");
        entity_set_size(iCrowbar, Float:{-4.0, -4.0, -4.0} , Float:{4.0, 4.0, 4.0});
        entity_set_origin(iCrowbar, vfOrigin);
        entity_set_edict(iCrowbar, EV_ENT_owner, iPlayer);
        entity_set_vector(iCrowbar, EV_VEC_angles, vfAngles);
        entity_set_vector(iCrowbar, EV_VEC_velocity, vfVelocity);
        entity_set_float(iCrowbar, EV_FL_nextthink, get_gametime() + 0.1);
        entity_set_int(iCrowbar, EV_INT_movetype, MOVETYPE_TOSS);
        entity_set_int(iCrowbar, EV_INT_solid, SOLID_BBOX);

        if (g_bFlyCrowbarTrail) {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
            write_byte(TE_BEAMFOLLOW);
            write_short(iCrowbar);
            write_short(g_iTrailSprite);
            write_byte(15);
            write_byte(2);
            write_byte(55 + random(200));
            write_byte(55 + random(200));
            write_byte(55 + random(200));
            write_byte(255);
            message_end();
        }

        emit_sound(iPlayer, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.90, ATTN_NORM, 0, PITCH_NORM);
        set_task(0.1, "fly_crowbar_whizz", iCrowbar);
    }

    return PLUGIN_HANDLED;
}

public fly_crowbar_whizz(iCrowbar) {
    if (is_valid_ent(iCrowbar)) {
        emit_sound(iCrowbar, CHAN_WEAPON, "weapons/cbar_miss1.wav", 0.90, ATTN_NORM, 0, PITCH_NORM);
        set_task(0.2, "fly_crowbar_whizz", iCrowbar);
    }
}

public fly_crowbar_think(iCrowbar) {
    new Float:vfAngles[3];
    entity_get_vector(iCrowbar, EV_VEC_angles, vfAngles);
    vfAngles[0] = floatadd(vfAngles[0], -15.0);

    entity_set_vector(iCrowbar, EV_VEC_angles, vfAngles);
    entity_set_float(iCrowbar, EV_FL_nextthink, get_gametime() + 0.01);
}

public fwd_fly_crowbar_impact(iToucher, iTouched) {
    new Float: vfOrigin[3], Float:vfAngles[3];
    new iOwner = entity_get_edict(iToucher, EV_ENT_owner);

    entity_get_vector(iToucher, EV_VEC_origin, vfOrigin);
    entity_get_vector(iToucher, EV_VEC_angles, vfAngles);

    if (!is_user_connected(iTouched)) {
        emit_sound(iTouched, CHAN_WEAPON, "weapons/cbar_hit1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);

        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vfOrigin, 0);
        write_byte(TE_SPARKS);
        engfunc(EngFunc_WriteCoord, vfOrigin[0]);
        engfunc(EngFunc_WriteCoord, vfOrigin[1]);
        engfunc(EngFunc_WriteCoord, vfOrigin[2]);
        message_end();
    } else {
        emit_sound(iTouched, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM);
        ExecuteHamB(Ham_TakeDamage, iTouched, iToucher, iOwner, g_fFlyCrowbarDamage, DMG_CLUB);

        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vfOrigin, 0);
        write_byte(TE_BLOODSPRITE);
        engfunc(EngFunc_WriteCoord, vfOrigin[0] + random_num(-20, 20));
        engfunc(EngFunc_WriteCoord, vfOrigin[1] + random_num(-20, 20));
        engfunc(EngFunc_WriteCoord, vfOrigin[2] + random_num(-20, 20));
        write_short(g_iBloodSpraySprite);
        write_short(g_iBloodSprite);
        write_byte(248);
        write_byte(15);
        message_end();
    }

    remove_entity(iToucher);

    if (!is_user_connected(iOwner) || !player_has_rune_id(iOwner, "super_crowbar")) {
        new iCrowbar = create_entity("weapon_crowbar");

        DispatchSpawn(iCrowbar);
        entity_set_int(iCrowbar, EV_INT_spawnflags, SF_NORESPAWN);

        vfAngles[0] = 0.0;
        vfAngles[2] = 0.0;

        entity_set_vector(iCrowbar, EV_VEC_origin, vfOrigin);
        entity_set_vector(iCrowbar, EV_VEC_angles, vfAngles);

        if (g_bFlyCrowbarRender) {
            fm_set_rendering(iCrowbar, kRenderFxGlowShell, 55 + random(200), 55 + random(200), 55 + random(200), kRenderNormal);
        }

        set_task(g_fFlyCrowbarLifetime, "fly_crowbar_lifetime", iCrowbar);
    }
}

public fly_crowbar_lifetime(iCrowbar) {
    if (is_valid_ent(iCrowbar)) {
        remove_entity(iCrowbar);
    }
}

public get_projective_position(iPlayer, Float:vfOrigin[3]) {
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];

	get_weapon_position(iPlayer, vfOrigin);

	global_get(glb_v_forward, fForward);
	global_get(glb_v_right, fRight);
	global_get(glb_v_up, fUp);

	xs_vec_mul_scalar(fForward, 6.0, fForward);
	xs_vec_mul_scalar(fRight, 2.0, fRight);
	xs_vec_mul_scalar(fUp, -2.0, fUp);

	xs_vec_add(vfOrigin, fForward, vfOrigin);
	xs_vec_add(vfOrigin, fRight, vfOrigin);
	xs_vec_add(vfOrigin, fUp, vfOrigin);
}

public get_weapon_position(iPlayer, Float:vfOrigin[3]) {
    new Float:viewOfs[3];

    entity_get_vector(iPlayer, EV_VEC_origin, vfOrigin);
    entity_get_vector(iPlayer, EV_VEC_view_ofs, viewOfs);

    xs_vec_add(vfOrigin, viewOfs, vfOrigin);
}
