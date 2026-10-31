#include <amxmodx>
#include <hamsandwich>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Protection"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      7

#define PLUGIN                  "XDM Reborn Rune: Protection"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fMultiplier;

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
        log_amx("[xdm_reborn] Protection: registration failed");
        pause("ad");
        return;
    }

    RegisterHam(Ham_TakeDamage, "player", "fwd_take_damage_pre", 0);
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_protection_multiplier", "0.5",
        FCVAR_NONE, "Damage multiplier while the protection rune is active.",
        true, 0.0, true, 1.0), g_fMultiplier);
}

public fwd_take_damage_pre(victim, inflictor, attacker, Float:damage, damagebits) {
    if (xdm_get_user_rune(victim) != g_iRune) return HAM_IGNORED;
    if (damage <= 0.0) return HAM_IGNORED;

    SetHamParamFloat(4, damage * g_fMultiplier);
    return HAM_IGNORED;
}
