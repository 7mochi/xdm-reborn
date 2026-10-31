#include <amxmodx>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Super Crowbar"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      3

#define PLUGIN                  "XDM Reborn Rune: Super Crowbar"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fDamage;
new Float:g_fPlayerSpeedMultiplier;

new bool:g_bSpeedApplied[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, XDM_VERSION, AUTHOR);

    register_dictionary("xdm_reborn.txt");

    register_cvars();
    AutoExecConfig();

    g_iRune = xdm_register_rune(
        RUNE_DISPLAY_NAME,
        RUNE_DEFAULT_COUNT,
        RUNE_DEFAULT_COLOR
    );

    if (g_iRune == XDM_INVALID_RUNE) {
        log_amx("[xdm_reborn] Super Crowbar: registration failed");
        pause("ad");
        return;
    }

    RegisterHam(Ham_TakeDamage, "player", "fwd_take_damage_pre", 0);
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_super_crowbar_damage", "999.0",
        FCVAR_NONE, "Crowbar damage while the super crowbar rune is active.",
        true, 0.0, true, 100000.0), g_fDamage);
    bind_pcvar_float(create_cvar("xdm_rune_super_crowbar_player_speed_multiplier", "1.25",
        FCVAR_NONE, "Multiplier applied to xdm_player_speed while the super crowbar rune is active.",
        true, 1.0, true, 10.0), g_fPlayerSpeedMultiplier);
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bSpeedApplied[i]) {
            set_user_maxspeed(i, get_cvar_float("xdm_player_speed"));
            g_bSpeedApplied[i] = false;
        }
    }
}

public xdm_rune_pickup(rune, player) {
    if (!user_has_weapon(player, HLW_CROWBAR)) {
        give_item(player, "weapon_crowbar");
    }

    set_user_maxspeed(player, get_cvar_float("xdm_player_speed") * g_fPlayerSpeedMultiplier);
    g_bSpeedApplied[player] = true;
}

public xdm_rune_drop(rune, player) {
    restore_speed(player);
}

public xdm_rune_death(rune, victim, attacker) {
    restore_speed(victim);
}

public restore_speed(player) {
    if (g_bSpeedApplied[player]) {
        set_user_maxspeed(player, get_cvar_float("xdm_player_speed"));
        g_bSpeedApplied[player] = false;
    }
}

public fwd_take_damage_pre(victim, inflictor, attacker, Float:damage, damagebits) {
    if (attacker < 1 || attacker > MAX_PLAYERS) return HAM_IGNORED;

    if (is_valid_ent(inflictor)) {
        new szClass[32];
        entity_get_string(inflictor, EV_SZ_classname, szClass, charsmax(szClass));

        if (equal(szClass, "func_fly_crowbar")) return HAM_IGNORED;
    }

    if (xdm_get_user_rune(attacker) != g_iRune) return HAM_IGNORED;
    if (!(damagebits & DMG_CLUB)) return HAM_IGNORED;
    if (get_user_weapon(attacker) != HLW_CROWBAR) return HAM_IGNORED;

    SetHamParamFloat(4, g_fDamage);
    return HAM_IGNORED;
}
