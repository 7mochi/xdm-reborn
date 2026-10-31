#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Super Hook"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      6

#define PLUGIN                  "XDM Reborn Rune: Super Hook"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fDamage;
new Float:g_fSpeed;

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
        log_amx("[xdm_reborn] Super Hook: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_super_hook_damage", "50.0",
        FCVAR_NONE, "Damage dealt by the super hook rune.",
        true, 0.0, true, 10000.0), g_fDamage);
    bind_pcvar_float(create_cvar("xdm_rune_super_hook_speed", "1.5",
        FCVAR_NONE, "Grappling hook speed multiplier while the super hook rune is active.",
        true, 1.0, true, 10.0), g_fSpeed);
}

public xdm_rune_pickup(rune, player) {
    xdm_set_hook_speed(player, get_cvar_float("xdm_hook_speed") * g_fSpeed);
}

public xdm_rune_drop(rune, player) {
    xdm_set_hook_speed(player, 0.0);
}

public xdm_rune_death(rune, victim, attacker) {
    xdm_set_hook_speed(victim, 0.0);
}

public xdm_hook_start(player) {
    if (xdm_get_user_rune(player) != g_iRune) return;

    new viStart[3], viEnd[3];
    new Float:vfStart[3], Float:vfEnd[3];

    get_user_origin(player, viStart, 1);
    get_user_origin(player, viEnd, 3);

    vfStart[0] = float(viStart[0]);
    vfStart[1] = float(viStart[1]);
    vfStart[2] = float(viStart[2]);
    vfEnd[0] = float(viEnd[0]);
    vfEnd[1] = float(viEnd[1]);
    vfEnd[2] = float(viEnd[2]);

    engfunc(EngFunc_TraceLine, vfStart, vfEnd, 0, player, 0);
    new hit = get_tr2(0, TR_pHit);

    if (hit > 0 && hit != player && is_user_alive(hit)) {
        ExecuteHamB(Ham_TakeDamage, hit, player, player, g_fDamage, DMG_BULLET);
    }
}
