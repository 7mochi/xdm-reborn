/*
    XDM Reborn by 7mochi

    # About:
    XDM Reborn is a plugin inspired by XDM (Xtreme Deathmatch), it doesn't contain all the features of the original XDM and isn't compatible with its cfgs files. 
    The main goal of this plugin is to provide an alternative to the original XDM, which is closed source, old (2008 approx.) and only for windows. In which
    it's possible to add new features, do changes, etc.

    # Features:
    - Uses Bugfixed HL in the core, to disable the speed cap, plus it comes with new features, bugfixes and improvements.
    - Supports multilingual, currently only English and Spanish, but it's possible to add more
    - Faster firing and reloading for some weapons
    - Faster recharge for health and armor
    - Choose which weapons and ammo the player will start with (Configurable via cvars)
    - Choose how much damage each weapon does (Configurable via cvars)
    - You can throw the crowbar and kill enemies with it (Damage configurable via cvar)
    - Fly though the air with a grappling hook (You need to bind a key to "+hook" to use it).
    - TODO: Add damage to hook
    - TODO: Configurable fall damage
    - Runes: Enhance your gameplay with powerups that you can pick up from the ground (Configurable via cvars)
        - Regeneration: Regenerates HP and HEV from once in a while
        - Trap: When you die, an expansive wave is unleashed
        - Cloak: Become semi-invisible
        - Super speed: Move a lot faster
        - Low gravity: Decrease gravity just for you
        - Super glock: Shoot your glock at high speed.
        - Super jump: Jump higher than normal (You need to bind a key to "userune" to use it)
        - Teleport: Teleport to a random place
        - TODO: Shield: Reduce damage taken
    - Drop the rune you have to pick up another one (You need to bind a key to "droprune" to use it)

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
    - E-mail: flyingcatdm@gmail.com
    - Discord: _7mochi
    - Steam: https://steamcommunity.com/id/nanamochi/
*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <hlstocks>
#include <rog>
#include <xs>

#pragma semicolon 1

#define NUMBER_RUNES                8
#define SIZE_WEAPONS                14
#define SIZE_AMMO                   11
#define SIZE_BAN_WEAPONS            14
#define SIZE_AMMO_ENTS              9
#define SIZE_DAMAGE_WEAPONS         16
#define UNINITIALIZED_DESTINATION   72769.420

#define PLUGIN                      "XDM Reborn"
#define VERSION                     "1.0"
#define AUTHOR                      "7mochi"

enum (+=727) {
    TASK_HOOK_THINK = 72769,
    TASK_HUD_DETAILS_RUNE,
    TASK_DROP_RUNE,
    TASK_REGENERATION
}

enum {
    RUNE_NONE = 0,
    RUNE_REGEN,
    RUNE_TRAP,
    RUNE_CLOAK,
    RUNE_SUPER_SPEED,
    RUNE_LOW_GRAVITY,
    RUNE_SUPER_GLOCK,
    RUNE_SUPER_JUMP,
    RUNE_TELEPORT
}

new g_cvarStartHP;
new g_cvarStartHEV;
new g_cvarStartLongJump;
new g_cvarBanHealthKit;
new g_cvarBanBattery;
new g_cvarBanRecharge;
new g_cvarBanLongJump;
new g_cvarStartWeapons[SIZE_WEAPONS];
new g_cvarStartAmmo[SIZE_AMMO];
new g_cvarBanWeapons[SIZE_BAN_WEAPONS];
new g_cvarBanAmmo[SIZE_AMMO_ENTS];
new g_cvarXdmDamageWeapons[SIZE_DAMAGE_WEAPONS];
new g_cvarMpDamageWeapons[SIZE_DAMAGE_WEAPONS];

new g_cvarReloadSpeed;
new g_cvarPlayerSpeed;

new g_cvarFlyCrowbarSpeed;
new g_cvarFlyCrowbarTrail;
new g_cvarFlyCrowbarDamage;
new g_cvarFlyCrowbarRender;
new g_cvarFlyCrowbarLifetime;

new g_cvarHookEnabled;
new g_cvarHookSpeed;

new g_cvarRune[NUMBER_RUNES];
new g_cvarRuneColor[NUMBER_RUNES];

new g_cvarRegenFrequency;
new g_cvarRegenAmountHP;
new g_cvarRegenAmountHEV;
new g_cvarRegenMaxHP;
new g_cvarRegenMaxHEV;

new g_cvarTrapRadius;
new g_cvarTrapDamage;
new g_cvarTrapFragBonus;

new g_cvarCloakValue;

new g_cvarSuperSpeedVelocity;

new g_cvarLowGravityValue;
new g_cvarNormalGravityValue;

new g_cvarSuperGlockFireRate;

new g_cvarSuperJumpHeight;

new g_cvarTeleportDistance;
new g_cvarTeleportCooldown;

new const AG_GAMEMODE_FILE[] = "gamemodes/xdm.cfg";

new const RUNE_MODEL[] = "models/xdm_rune.mdl";
new const RUNE_PICKUP_SOUND[] = "xdm.wav";
new const RUNE_CLASSNAME[] = "func_rune";

new const FLY_CROWBAR_BLOOD_SPRITE[] = "sprites/blood.spr";
new const FLY_CROWBAR_BLOODSPRAY_SPRITE[] = "sprites/bloodspray.spr";
new const FLY_CROWBAR_TRAIL_SPRITE[] = "sprites/zbeam3.spr";
new const FLY_CROWBAR_CLASSNAME[] = "func_fly_crowbar";

new const HOOK_BEAM_SPRITE[] = "sprites/dot.spr";
new const HOOK_HIT_SOUND[] = "weapons/xbow_hit2.wav";

new const RUNE_TRAP_SHOCKWAVE_SPRITE[] = "sprites/shockwave.spr";
new const RUNE_TRAP_SHOCKWAVE_SOUND[] = "weapons/explode3.wav";
new const RUNE_TRAP_SHOCKWAVE_WEAPON_NAME[] = "Blast Explosion";

new const g_vszCvarStartWeapons[SIZE_WEAPONS][] = {
    "xdm_start_357",
    "xdm_start_mp5",
    "xdm_start_glock",
    "xdm_start_crossbow",
    "xdm_start_crowbar",
    "xdm_start_gauss",
    "xdm_start_egon",
    "xdm_start_hgrenade",
    "xdm_start_hornet",
    "xdm_start_rpg",
    "xdm_start_satchel",
    "xdm_start_shotgun",
    "xdm_start_snark",
    "xdm_start_tripmine",
};

new const g_vszCvarStartAmmo[SIZE_AMMO][] = {
    "xdm_start_bockshot",
    "xdm_start_9mmar",
    "xdm_start_m203",
    "xdm_start_357ammo",
    "xdm_start_uranium",
    "xdm_start_rockets",
    "xdm_start_bolts",
    "xdm_start_tripmine",
    "xdm_start_satchel",
    "xdm_start_hgrenade",
    "xdm_start_snark",
};

new const g_vszCvarBanWeapons[SIZE_BAN_WEAPONS][] = {
    "xdm_ban_357",
    "xdm_ban_mp5",
    "xdm_ban_glock",
    "xdm_ban_crossbow",
    "xdm_ban_crowbar",
    "xdm_ban_gauss",
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

new const g_vszXdmDamageWeapons[SIZE_DAMAGE_WEAPONS][] = {
    "xdm_dmg_crowbar",
    "xdm_dmg_glock",
    "xdm_dmg_357",
    "xdm_dmg_mp5",
    "xdm_dmg_shotgun",
    "xdm_dmg_bolts_normal",
    "xdm_dmg_bolts_explosion",
    "xdm_dmg_rpg",
    "xdm_dmg_gauss",
    "xdm_dmg_gauss_secondary",
    "xdm_dmg_egon",
    "xdm_dmg_hornet",
    "xdm_dmg_hgrenade",
    "xdm_dmg_satchel",
    "xdm_dmg_tripmine",
    "xdm_dmg_m203"
};

new const g_vszMpDamageWeapons[SIZE_DAMAGE_WEAPONS][] = {
    "mp_dmg_crowbar",
    "mp_dmg_glock",
    "mp_dmg_357",
    "mp_dmg_mp5",
    "mp_dmg_shotgun",
    "mp_dmg_xbow_scope",
    "mp_dmg_xbow_noscope",
    "mp_dmg_rpg",
    "mp_dmg_gauss_primary",
    "mp_dmg_gauss_secondary",
    "mp_dmg_egon",
    "mp_dmg_hornet",
    "mp_dmg_hgrenade",
    "mp_dmg_satchel",
    "mp_dmg_tripmine",
    "mp_dmg_m203",
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

new const g_vszCvarRuneNames[NUMBER_RUNES][] = {
    "xdm_numb_regen_runes",
    "xdm_numb_trap_runes",
    "xdm_numb_cloak_runes",
    "xdm_numb_super_speed_runes",
    "xdm_numb_low_grav_runes",
    "xdm_numb_super_glock_runes",
    "xdm_numb_super_jump_runes",
    "xdm_numb_teleport_runes",
};

new const g_vszCvarRuneColorNames[NUMBER_RUNES][] = {
    "xdm_color_regen_runes",
    "xdm_color_trap_runes",
    "xdm_color_cloak_runes",
    "xdm_color_super_speed_runes",
    "xdm_color_low_grav_runes",
    "xdm_color_super_glock_runes",
    "xdm_color_super_jump_runes",
    "xdm_color_teleport_runes",
};

new const g_vszDescriptionRunes[NUMBER_RUNES][] = {
    "DESCRIPTION_RUNE_REGEN",
    "DESCRIPTION_RUNE_TRAP",
    "DESCRIPTION_RUNE_CLOAK",
    "DESCRIPTION_RUNE_SUPER_SPEED",
    "DESCRIPTION_RUNE_LOW_GRAVITY",
    "DESCRIPTION_RUNE_SUPER_GLOCK",
    "DESCRIPTION_RUNE_SUPER_JUMP",
    "DESCRIPTION_RUNE_TELEPORT",
};

new const g_vszInflictorToIgnore[][] = {
    "world",
    "worldspawn",
    "trigger_hurt",
    "door_rotating",
    "door",
    "rotating",
    "env_explosion",
};

new bool:g_bGamePlayerEquipExists;
new bool:g_bIsAGServer;
new bool:g_vbHook[MAX_PLAYERS + 1];
new Float:g_vfHookTo[MAX_PLAYERS + 1][3];
new Float:g_vfTeleportLastUsed[MAX_PLAYERS + 1];
new g_iHudDisplayRuneDetails;
new g_iJuice;
new g_iPlayerHasRune[MAX_PLAYERS + 1];
new g_iShotgunOldSpecialReload[MAX_PLAYERS + 1];
new g_iOldClip[MAX_PLAYERS + 1];
new g_iTrailSprite;
new g_iBloodSprite;
new g_iBloodSpraySprite;
new g_iBeamSprite;
new g_iCylinderSprite;
new g_iDeathMsg;

public plugin_precache() {
    register_dictionary("xdm-reborn.txt");
    
    if (cvar_exists("sv_ag_version")) {
        g_bIsAGServer = true;
    }

    if (g_bIsAGServer) {
        if (!file_exists(AG_GAMEMODE_FILE)) {
            server_print("%l", "XDM_AG_GAMEMODE_NOT_FOUND");
            rename_file("xdm_ag.cfg", AG_GAMEMODE_FILE, 1);
        }
        
        new szGameMode[32];
        get_cvar_string("sv_ag_gamemode", szGameMode, charsmax(szGameMode));

        if (!equal(szGameMode, "xdm")) {
            server_print("%l", "XDM_AG_CANT_RUN");
            pause("ad");
            return;
        }
    } else {
        g_cvarStartHP = create_cvar("xdm_start_hp", "100");
        g_cvarStartHEV = create_cvar("xdm_start_hev", "0");
        g_cvarStartLongJump = create_cvar("xdm_start_longjump", "0");
        
        for (new i; i < sizeof g_cvarStartWeapons; i++) {
            g_cvarStartWeapons[i] = create_cvar(g_vszCvarStartWeapons[i], "0");
        }

        for (new i; i < sizeof g_cvarStartAmmo; i++) {
            g_cvarStartAmmo[i] = create_cvar(g_vszCvarStartAmmo[i], "0");
        }

        for (new i; i < sizeof g_cvarBanWeapons; i++) {
            g_cvarBanWeapons[i] = create_cvar(g_vszCvarBanWeapons[i], "0");
        }

        for (new i; i < sizeof g_cvarBanAmmo; i++) {
            g_cvarBanAmmo[i] = create_cvar(g_vszCvarBanAmmo[i], "0");
        }

        g_cvarBanHealthKit = create_cvar("xdm_ban_health_kit", "0");
        g_cvarBanBattery = create_cvar("xdm_ban_battery", "0");
        g_cvarBanRecharge = create_cvar("xdm_ban_recharge", "0");
        g_cvarBanLongJump = create_cvar("xdm_ban_longjump", "0");

        new szValue[32];
        for (new i = 0; i < SIZE_DAMAGE_WEAPONS; i++) {
            g_cvarMpDamageWeapons[i] = get_cvar_pointer(g_vszMpDamageWeapons[i]);

            get_pcvar_string(g_cvarMpDamageWeapons[i], szValue, charsmax(szValue));

            g_cvarXdmDamageWeapons[i] = create_cvar(g_vszXdmDamageWeapons[i], szValue);
            hook_cvar_change(g_cvarXdmDamageWeapons[i], "hook_cvar_xdm_damage_weapons");
        }
    }

    g_cvarReloadSpeed = create_cvar("xdm_reload_speed", "0.5");
    g_cvarPlayerSpeed = create_cvar("xdm_player_speed", "300.0");

    g_cvarFlyCrowbarSpeed = create_cvar("xdm_flycrowbar_speed", "1300");
    g_cvarFlyCrowbarTrail = create_cvar("xdm_flycrowbar_trail", "1");
    g_cvarFlyCrowbarDamage = create_cvar("xdm_flycrowbar_damage", "240.0");
    g_cvarFlyCrowbarRender = create_cvar("xdm_flycrowbar_render", "1");
    g_cvarFlyCrowbarLifetime = create_cvar("xdm_flycrowbar_lifetime", "15.0");

    g_cvarHookEnabled = create_cvar("xdm_hook_enabled", "1");
    g_cvarHookSpeed = create_cvar("xdm_hook_speed", "5");

    for (new i; i < sizeof g_cvarRune; i++) {
        g_cvarRune[i] = create_cvar(g_vszCvarRuneNames[i], "1");
        g_cvarRuneColor[i] = create_cvar(g_vszCvarRuneColorNames[i], "0");
    }

    g_cvarRegenFrequency = create_cvar("xdm_regen_frequency", "1.0");
    g_cvarRegenAmountHP = create_cvar("xdm_regen_amount_hp", "1");
    g_cvarRegenAmountHEV = create_cvar("xdm_regen_amount_hev", "1");
    g_cvarRegenMaxHP = create_cvar("xdm_regen_max_hp", "100");
    g_cvarRegenMaxHEV = create_cvar("xdm_regen_max_hev", "100");

    g_cvarTrapRadius = create_cvar("xdm_trap_radius", "500.0");
    g_cvarTrapDamage = create_cvar("xdm_trap_damage", "1000.0");
    g_cvarTrapFragBonus = create_cvar("xdm_trap_frag_bonus", "1");

    g_cvarCloakValue = create_cvar("xdm_cloak_value", "80");

    g_cvarSuperSpeedVelocity = create_cvar("xdm_super_speed_velocity", "600.0");

    g_cvarLowGravityValue = create_cvar("xdm_low_gravity_value", "400");
    g_cvarNormalGravityValue = get_cvar_pointer("sv_gravity");

    g_cvarSuperGlockFireRate = create_cvar("xdm_super_glock_fire_rate", "9999.0");

    g_cvarSuperJumpHeight = create_cvar("xdm_super_jump_height", "550.0");

    g_cvarTeleportDistance = create_cvar("xdm_teleport_distance", "100.0");
    g_cvarTeleportCooldown = create_cvar("xdm_teleport_cooldown", "15.0");
    
    precache_model(RUNE_MODEL);
    g_iTrailSprite = precache_model(FLY_CROWBAR_TRAIL_SPRITE);
    g_iBloodSprite = precache_model(FLY_CROWBAR_BLOOD_SPRITE);
    g_iBloodSpraySprite = precache_model(FLY_CROWBAR_BLOODSPRAY_SPRITE);
    g_iBeamSprite = precache_model(HOOK_BEAM_SPRITE);
    g_iCylinderSprite = precache_model(RUNE_TRAP_SHOCKWAVE_SPRITE);
    
    precache_sound(RUNE_PICKUP_SOUND);
    precache_sound(HOOK_HIT_SOUND);
    precache_sound(RUNE_TRAP_SHOCKWAVE_SOUND);

    g_iDeathMsg = get_user_msgid("DeathMsg");

    if (!g_bIsAGServer) {
        server_cmd("exec xdm.cfg");
        server_exec();
    }

    set_cvar_float("sv_maxspeed", get_pcvar_float(g_cvarSuperSpeedVelocity));
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_forward(FM_GetGameDescription, "fwd_game_description");
    
    register_clcmd("spectate", "cmd_spectate");
    register_clcmd("userune", "cmd_userune");
    register_clcmd("droprune", "cmd_droprune");

    register_concmd("+hook", "cmd_hook_enable");
    register_concmd("-hook", "cmd_hook_disable");

    register_think(FLY_CROWBAR_CLASSNAME, "fly_crowbar_think");

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

    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "fwd_glock_primary_attack_pre", 0);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "fwd_glock_primary_attack_post", 1);
    
    RegisterHam(Ham_Killed, "player", "fwd_player_killed"); // TODO: Maybe hook on post instead of pre?
    RegisterHam(Ham_Spawn, "player", "fwd_player_spawn_post", 1);

    RegisterHam(Ham_Use, "func_healthcharger", "fwd_use_charger_pre", 0);
    RegisterHam(Ham_Use, "func_healthcharger", "fwd_use_hp_charger_post", 1);
    RegisterHam(Ham_Use, "func_recharge", "fwd_use_charger_pre", 0);
    RegisterHam(Ham_Use, "func_recharge", "fwd_use_hev_charger_post", 1);

    g_iHudDisplayRuneDetails = CreateHudSyncObj();

    if (!g_bIsAGServer) {
        remove_banned_entities();
    }
}

public plugin_cfg() {
    g_bGamePlayerEquipExists = find_game_player_equip() ? true : false;
    
    ROGInitialize(200.0);

    for (new i; i < sizeof g_cvarRune; i++) {
        for (new j; j < get_pcvar_num(g_cvarRune[i]); j++) {
            spawn_rune(i + 1);
        }
    }

    ROGInitialize(get_pcvar_float(g_cvarTeleportDistance));
}

public client_disconnected(iPlayer) {
    drop_rune(iPlayer);
    return PLUGIN_HANDLED;
}

public cmd_spectate(iPlayer) {
    drop_rune(iPlayer);
}

public cmd_userune(iPlayer) {
    switch (g_iPlayerHasRune[iPlayer]) {
        case RUNE_NONE:
            client_print(iPlayer, print_chat, "%l", "USERUNE_NO_RUNE");
        case RUNE_SUPER_JUMP:
            rune_super_jump(iPlayer);
        case RUNE_TELEPORT:
            rune_teleport(iPlayer);
    }

    return PLUGIN_HANDLED;
}

public cmd_droprune(iPlayer) {
    drop_rune(iPlayer);
    return PLUGIN_HANDLED;
}

public cmd_hook_enable(iPlayer) {
    if (!get_pcvar_num(g_cvarHookEnabled) || g_vbHook[iPlayer]) return PLUGIN_HANDLED;

    set_user_gravity(iPlayer, 0.0);
    set_task(0.1, "hook_think", iPlayer + TASK_HOOK_THINK, "", 0, "b");

    g_vbHook[iPlayer] = true;
    g_vfHookTo[iPlayer][0] = UNINITIALIZED_DESTINATION;
    
    hook_think(iPlayer + TASK_HOOK_THINK);
    emit_sound(iPlayer, CHAN_VOICE, HOOK_HIT_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);

    return PLUGIN_HANDLED;
}

public cmd_hook_disable(iPlayer) {
    if (is_user_alive(iPlayer)) {
        if (g_iPlayerHasRune[iPlayer] == RUNE_LOW_GRAVITY) {
            rune_low_gravity(iPlayer);
        } else {
            set_user_gravity(iPlayer, get_pcvar_float(g_cvarNormalGravityValue) / 800.0);
        }
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
    yCoord = floatpower(vfVelocity[0], 2.0) + floatpower(vfVelocity[1], 2.0) + floatpower(vfVelocity[2], 2.0);
    xCoord = (get_pcvar_float(g_cvarHookSpeed) * 120.0) / floatsqroot(yCoord);

    vfVelocity[0] *= xCoord;
    vfVelocity[1] *= xCoord;
    vfVelocity[2] *= xCoord;

    entity_set_vector(iPlayer, EV_VEC_velocity, vfVelocity);
    
    return PLUGIN_CONTINUE;
}

public set_initial_equipment(iPlayer) {
    hl_set_user_health(iPlayer, get_pcvar_num(g_cvarStartHP));
    hl_set_user_armor(iPlayer, get_pcvar_num(g_cvarStartHEV));

    if (get_pcvar_bool(g_cvarStartLongJump)) {
        hl_set_user_longjump(iPlayer, true);
    }
    
    for (new i; i < SIZE_WEAPONS; i++) {
        if (get_pcvar_num(g_cvarStartWeapons[i])) {
            give_item(iPlayer, g_vszWeaponClass[i]);
        }
    }

    for (new i; i < SIZE_AMMO; i++) {
        if (get_pcvar_num(g_cvarStartAmmo[i]) != 0) {
            set_ent_data(iPlayer, "CBasePlayer", "m_rgAmmo", get_pcvar_num(g_cvarStartAmmo[i]), i + 1);
        }
    }
}

public remove_banned_entities() {
    for (new i; i < SIZE_BAN_WEAPONS; i++) {
        if (get_pcvar_num(g_cvarBanWeapons[i])) {
            remove_entity_name(g_vszWeaponClass[i]);
        }
    }

    for (new i; i < SIZE_AMMO_ENTS; i++) {
        if (get_pcvar_num(g_cvarBanAmmo[i])) {
            remove_entity_name(g_vszAmmoClass[i]);
        }
    }

    if (get_pcvar_num(g_cvarBanHealthKit)) {
        remove_entity_name("item_healthkit");
    }

    if (get_pcvar_num(g_cvarBanBattery)) {
        remove_entity_name("item_battery");
    }

    if (get_pcvar_num(g_cvarBanLongJump)) {
        remove_entity_name("item_longjump");
    }
}

public hook_cvar_xdm_damage_weapons(pcvar, const szOldValue[], const szNewValue[]) {
    for (new i; i < sizeof g_cvarXdmDamageWeapons; i++) {
        if (g_cvarXdmDamageWeapons[i] == pcvar) {
            set_pcvar_string(g_cvarMpDamageWeapons[i], szNewValue);
            return;
        }
    }
}

public fwd_game_description() {
    forward_return(FMV_STRING, PLUGIN + " " + VERSION);
    return FMRES_SUPERCEDE;
}

public fwd_player_killed(iVictim, iAttacker) {
    if (g_iPlayerHasRune[iVictim] == RUNE_TRAP) {
        rune_trap(iVictim, iAttacker);
    }
    drop_rune(iVictim);
}

public fwd_player_spawn_post(iPlayer) {
    if (is_user_alive(iPlayer)) {
        set_user_maxspeed(iPlayer, get_pcvar_float(g_cvarPlayerSpeed));

        if (!g_bGamePlayerEquipExists && !g_bIsAGServer) {
            hl_strip_user_weapon(iPlayer, HLW_GLOCK);
            hl_strip_user_weapon(iPlayer, HLW_CROWBAR);
            set_initial_equipment(iPlayer);
        }
    }
}

public fwd_use_charger_pre(iEntity, iPlayer) {
    if (get_pcvar_bool(g_cvarBanRecharge)) return HAM_SUPERCEDE;

    g_iJuice = get_ent_data(iEntity, "CRecharge", "m_iJuice");

    return HAM_IGNORED;
}

public fwd_use_hp_charger_post(iEntity, iPlayer) {
    if (get_pcvar_bool(g_cvarBanRecharge)) return HAM_SUPERCEDE;
    
    new iJuicePost = get_ent_data(iEntity, "CRecharge", "m_iJuice");
    if (g_iJuice != iJuicePost) {
        hl_set_user_health(iPlayer, min(100, hl_get_user_health(iPlayer) + 4));
        set_ent_data(iEntity, "CRecharge", "m_iJuice", max(0, iJuicePost - 4));
    }

    return HAM_IGNORED;
}

public fwd_use_hev_charger_post(iEntity, iPlayer) {
    if (get_pcvar_bool(g_cvarBanRecharge)) return HAM_SUPERCEDE;
    
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

    if (g_iPlayerHasRune[iPlayer] == RUNE_NONE) {
        g_iPlayerHasRune[iPlayer] = entity_get_int(iRune, EV_INT_iuser1);
        set_task(0.1, "show_hud_details_rune", iPlayer + TASK_HUD_DETAILS_RUNE, _, _, "b");

        switch (g_iPlayerHasRune[iPlayer]) {
            case RUNE_REGEN:
                set_task(get_pcvar_float(g_cvarRegenFrequency), "rune_regeneration", iPlayer + TASK_REGENERATION, _, _, "b");
            case RUNE_CLOAK:
                rune_cloak(iPlayer, get_pcvar_num(g_cvarCloakValue));
            case RUNE_SUPER_SPEED:
                rune_super_speed(iPlayer);
            case RUNE_LOW_GRAVITY:
                rune_low_gravity(iPlayer);
        }
        
        emit_sound(iPlayer, CHAN_STATIC, RUNE_PICKUP_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
        remove_entity(iRune);
    }

    return PLUGIN_HANDLED;
}

public fwd_weapons_custom_reload_rate(iWeapon) {
    if (get_ent_data(iWeapon, "CBasePlayerWeapon", "m_fInReload")) {
        new iPlayer = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");

        new Float:fNextAttack = get_ent_data_float(iPlayer, "CBaseMonster", "m_flNextAttack") *
                                get_pcvar_float(g_cvarReloadSpeed);
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
                                        get_pcvar_float(g_cvarReloadSpeed);
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
    
    set_ent_data_float(iCrowbar, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.5);
    ExecuteHam(Ham_RemovePlayerItem, iPlayer, iCrowbar);
    user_has_weapon(iPlayer, HLW_CROWBAR, 0);
    ExecuteHamB(Ham_Item_Kill, iCrowbar);

    return HAM_IGNORED;
}

public fwd_crowbar_item_add(iCrowbar) {
    remove_task(iCrowbar);
}

public fwd_glock_primary_attack_pre(iGlock) {
    new iPlayer = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");

    if (g_iPlayerHasRune[iPlayer] == RUNE_SUPER_GLOCK) {
        g_iOldClip[iPlayer] = get_ent_data(iGlock, "CBasePlayerWeapon", "m_iClip");
    }
}

public fwd_glock_primary_attack_post(iGlock) {
    new iPlayer = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");

    if (g_iPlayerHasRune[iPlayer] == RUNE_SUPER_GLOCK) {
        set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flNextSecondaryAttack", get_pcvar_float(g_cvarSuperGlockFireRate));

        if (g_iOldClip[iPlayer] <= 0) return;

        set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.10);

        if (get_ent_data(iGlock, "CBasePlayerWeapon", "m_iClip") != 0) {
            set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0);
        } else {
            set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3);
        }
    }
}

public spawn_fly_crowbar(iPlayer) {
    new iCrowbar = create_entity("info_target");

    if (is_valid_ent(iCrowbar)) {
        new Float:vfOrigin[3], Float:vfAngles[3], Float:vfVelocity[3];

        get_projective_position(iPlayer, vfOrigin);

        entity_get_vector(iPlayer, EV_VEC_v_angle, vfAngles);
        vfAngles[0] = 90.0;
        vfAngles[2] = floatadd(vfAngles[2], -90.0);

        velocity_by_aim(iPlayer, get_pcvar_num(g_cvarFlyCrowbarSpeed) + get_speed(iPlayer), vfVelocity);
        
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

        if (get_pcvar_num(g_cvarFlyCrowbarTrail)) {
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
        ExecuteHamB(Ham_TakeDamage, iTouched, iToucher, entity_get_edict(iToucher, EV_ENT_owner), get_pcvar_float(g_cvarFlyCrowbarDamage), DMG_CLUB);
        
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

    new iCrowbar = create_entity("weapon_crowbar");

    DispatchSpawn(iCrowbar);
    entity_set_int(iCrowbar, EV_INT_spawnflags, SF_NORESPAWN);

    vfAngles[0] = 0.0;
    vfAngles[2] = 0.0;

    entity_set_vector(iCrowbar, EV_VEC_origin, vfOrigin);
    entity_set_vector(iCrowbar, EV_VEC_angles, vfAngles);

    if (get_pcvar_num(g_cvarFlyCrowbarRender)) {
        fm_set_rendering(iCrowbar, kRenderFxGlowShell, 55 + random(200), 55 + random(200), 55 + random(200), kRenderNormal);
    }

    set_task(get_pcvar_float(g_cvarFlyCrowbarLifetime), "fly_crowbar_lifetime", iCrowbar);
}

public fly_crowbar_lifetime(iCrowbar) {
    if (is_valid_ent(iCrowbar)) {
        remove_entity(iCrowbar);
    }
}

public spawn_rune(iRuneType) {
    new Float:vfOrigin[3];
    ROGGetOrigin(vfOrigin);
    new iRune = create_entity("info_target");

    if (is_valid_ent(iRune)) {
        entity_set_string(iRune, EV_SZ_classname, RUNE_CLASSNAME);
        entity_set_model(iRune, RUNE_MODEL);
        entity_set_float(iRune, EV_FL_framerate, 1.0);
        entity_set_int(iRune, EV_INT_solid, SOLID_TRIGGER);
        entity_set_vector(iRune, EV_VEC_origin, vfOrigin);
        entity_set_int(iRune, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[iRuneType - 1]));
        entity_set_int(iRune, EV_INT_iuser1, iRuneType);
        drop_to_floor(iRune);
    }

    return PLUGIN_HANDLED;
}

public drop_rune(iPlayer) {
    if (g_iPlayerHasRune[iPlayer] > RUNE_NONE) {
        new iRune = create_entity("info_target");

        if (is_valid_ent(iRune)) {
            new Float:vfPlayerOrigin[3], Float:vfPlayerAngles[3], Float:vfPlayerVelocity[3];
            entity_get_vector(iPlayer, EV_VEC_origin, vfPlayerOrigin);
            velocity_by_aim(iPlayer, 400, vfPlayerVelocity);
            vfPlayerAngles[0] = 0.0;
            vfPlayerAngles[1] = 0.0;
            vfPlayerAngles[2] = 0.0;

            entity_set_string(iRune, EV_SZ_classname, RUNE_CLASSNAME);
            entity_set_model(iRune, RUNE_MODEL);
            entity_set_float(iRune, EV_FL_framerate, 1.0);
            entity_set_int(iRune, EV_INT_solid, SOLID_TRIGGER);
            entity_set_origin(iRune, vfPlayerOrigin);
            entity_set_int(iRune, EV_INT_skin, get_pcvar_num(g_cvarRuneColor[g_iPlayerHasRune[iPlayer] - 1]));
            entity_set_int(iRune, EV_INT_iuser1, g_iPlayerHasRune[iPlayer]);
            entity_set_vector(iRune, EV_VEC_angles, vfPlayerAngles);
            entity_set_vector(iRune, EV_VEC_velocity, vfPlayerVelocity);
            entity_set_int(iRune, EV_INT_movetype, MOVETYPE_TOSS);
            entity_set_edict(iRune, EV_ENT_aiment, 0);
            entity_set_int(iRune, EV_INT_solid, SOLID_TRIGGER);
            drop_to_floor(iRune);
        }

        switch (g_iPlayerHasRune[iPlayer]) {
            case RUNE_REGEN:
                remove_task(iPlayer + TASK_REGENERATION);
            case RUNE_CLOAK:
                remove_cloak(iPlayer);
            case RUNE_SUPER_SPEED:
                remove_super_speed(iPlayer);
            case RUNE_LOW_GRAVITY:
                remove_low_gravity(iPlayer);
        }

        set_task(0.1, "remove_player_rune", iPlayer + TASK_DROP_RUNE);
        ClearSyncHud(iPlayer, g_iHudDisplayRuneDetails);
        remove_task(iPlayer + TASK_HUD_DETAILS_RUNE);
    }

    return PLUGIN_HANDLED;
}

public remove_player_rune(iTask) {
    new iPlayer = iTask - TASK_DROP_RUNE;
    g_iPlayerHasRune[iPlayer] = RUNE_NONE;
    remove_task(iTask);
}

public show_hud_details_rune(iTask) {
    new iPlayer = iTask - TASK_HUD_DETAILS_RUNE;
    set_hudmessage(0, 255, 0, 0.05, 0.02, 0, 0.0, 10.0, 0.2, 0.2, 1);
    ShowSyncHudMsg(iPlayer, g_iHudDisplayRuneDetails, "%l", g_vszDescriptionRunes[g_iPlayerHasRune[iPlayer] - 1]);
}

public rune_regeneration(iTask) {
    new iPlayer = iTask - TASK_REGENERATION;

    if (is_user_alive(iPlayer)) {
        hl_set_user_health(iPlayer, hl_get_user_health(iPlayer) + get_pcvar_num(g_cvarRegenAmountHP));
        hl_set_user_armor(iPlayer, hl_get_user_armor(iPlayer) + get_pcvar_num(g_cvarRegenAmountHEV));

        if (hl_get_user_health(iPlayer) >= get_pcvar_num(g_cvarRegenMaxHP)) {
            hl_set_user_health(iPlayer, get_pcvar_num(g_cvarRegenMaxHP));
        }

        if (get_user_armor(iPlayer) >= get_pcvar_num(g_cvarRegenMaxHEV)) {
            hl_set_user_armor(iPlayer, get_pcvar_num(g_cvarRegenMaxHEV));
        }
    }
}

public rune_trap(iVictim, iAttacker) {
    new szWeapon[30];
    read_data(4, szWeapon, charsmax(szWeapon));

    for (new i; i < sizeof g_vszInflictorToIgnore; i++) {
        if (equal(szWeapon, g_vszInflictorToIgnore[i])) {
            return PLUGIN_CONTINUE;
        }
    }

    new viVictimOrigin[3];
    get_user_origin(iVictim, viVictimOrigin);
    
    new Float:fRadius = get_pcvar_float(g_cvarTrapRadius);
    create_beam_cylinder(viVictimOrigin, 120.0, g_iCylinderSprite, 0, 0, 6, 16, 0, random(255), random(255), random(255), 255, 0);
    create_beam_cylinder(viVictimOrigin, 320.0, g_iCylinderSprite, 0, 0, 6, 16, 0, random(255), random(255), random(255), 255, 0);
    create_beam_cylinder(viVictimOrigin, fRadius, g_iCylinderSprite, 0, 0, 6, 16, 0, random(255), random(255), random(255), 255, 0);
    create_explosion(iVictim, iAttacker, get_pcvar_float(g_cvarTrapDamage), fRadius);
    emit_sound(iVictim, CHAN_BODY, RUNE_TRAP_SHOCKWAVE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return PLUGIN_HANDLED;
}

public rune_cloak(iPlayer, iAlpha) {
    set_user_rendering(iPlayer, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, iAlpha);
}

public remove_cloak(iPlayer) {
    set_user_rendering(iPlayer, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
}

public rune_super_speed(iPlayer) {
    entity_set_float(iPlayer, EV_FL_maxspeed, get_pcvar_float(g_cvarSuperSpeedVelocity));
}

public remove_super_speed(iPlayer) {
    entity_set_float(iPlayer, EV_FL_maxspeed, get_pcvar_float(g_cvarPlayerSpeed));
}

public rune_low_gravity(iPlayer) {
    set_user_gravity(iPlayer, get_pcvar_float(g_cvarLowGravityValue) / 800.0);
}

public remove_low_gravity(iPlayer) {
    set_user_gravity(iPlayer, get_pcvar_float(g_cvarNormalGravityValue) / 800.0);
}

public rune_super_jump(iPlayer) {
    if (get_entity_flags(iPlayer) & FL_ONGROUND) {
        new Float:vfVelocity[3];
        entity_get_vector(iPlayer, EV_VEC_velocity, vfVelocity);

        vfVelocity[2] = get_pcvar_float(g_cvarSuperJumpHeight);
        entity_set_vector(iPlayer, EV_VEC_velocity, vfVelocity);

        return PLUGIN_HANDLED;
    }

    return PLUGIN_HANDLED;
}

public rune_teleport(iPlayer) {
    new Float:fCooldownTime = get_pcvar_float(g_cvarTeleportCooldown);
    new Float:fElapsedTime = get_gametime() - g_vfTeleportLastUsed[iPlayer];

    if (fElapsedTime < fCooldownTime) {
        client_print(iPlayer, print_chat, "%l", "USERUNE_TELEPORT_COOLDOWN", fCooldownTime - fElapsedTime);
        return PLUGIN_HANDLED;
    }

    g_vfTeleportLastUsed[iPlayer] = get_gametime();

    new Float:vfOrigin[3];
    ROGGetOrigin(vfOrigin);
    entity_set_vector(iPlayer, EV_VEC_origin, vfOrigin);

    return PLUGIN_CONTINUE;
}

public create_beam_cylinder(viOrigin[3], Float:fRadius, iSprite, iStartFrameRate, iFrameRate, iLife, iWidth,
                            iAmplitude, iRed, iGreen, iBlue, iBrightness, iSpeed) {
    message_begin(MSG_PVS, SVC_TEMPENTITY, viOrigin); 
    write_byte(TE_BEAMCYLINDER);
    write_coord(viOrigin[0]);
    write_coord(viOrigin[1]);
    write_coord(viOrigin[2]);
    write_coord(viOrigin[0]);
    write_coord(viOrigin[1]);
    write_coord_f(viOrigin[2] + fRadius);
    write_short(iSprite);
    write_byte(iStartFrameRate);
    write_byte(iFrameRate);
    write_byte(iLife);
    write_byte(iWidth);
    write_byte(iAmplitude);
    write_byte(iRed);
    write_byte(iGreen);
    write_byte(iBlue);
    write_byte(iBrightness);
    write_byte(iSpeed);
    message_end();
}

public create_explosion(iVictim, iAttacker, Float:fDamage, Float:fRange) {
    new Float:vfVictimOrigin[3], Float:vfAttackerOrigin[3];
    new Float:fDistance, Float:fTempDamage;
    entity_get_vector(iVictim, EV_VEC_origin, vfVictimOrigin);

    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (is_user_alive(i) && iVictim != i) {
            entity_get_vector(i, EV_VEC_origin, vfAttackerOrigin);
            fDistance = get_distance_f(vfVictimOrigin, vfAttackerOrigin);

            if (fDistance <= fRange) {
                fTempDamage = fDamage - (fDamage / fRange) * fDistance;
                fakedamage(i, RUNE_TRAP_SHOCKWAVE_WEAPON_NAME, fTempDamage, DMG_BLAST);
                message_begin(MSG_BROADCAST, g_iDeathMsg);
                write_byte(iVictim);
                write_byte(i);
                write_byte(0);
                write_string(RUNE_TRAP_SHOCKWAVE_WEAPON_NAME);
                message_end();
            }
        }
    }

    if (iVictim != iAttacker) {
        set_user_frags(iVictim, get_user_frags(iVictim) + get_pcvar_num(g_cvarTrapFragBonus));
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