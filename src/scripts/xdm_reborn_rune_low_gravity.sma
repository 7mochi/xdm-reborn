#include <amxmodx>
#include <fun>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Low Gravity"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      4

#define PLUGIN                  "XDM Reborn Rune: Low Gravity"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fGravity;
new bool:g_bLowGravity[MAX_PLAYERS + 1];

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
        log_amx("[xdm_reborn] Low Gravity: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_low_gravity_value", "160",
        FCVAR_NONE, "Gravity value applied by the low gravity rune.",
        true, 0.0, true, 800.0), g_fGravity);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bLowGravity[i]) {
            restore_gravity(i);
            g_bLowGravity[i] = false;
        }
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bLowGravity[i]) {
            restore_gravity(i);
            g_bLowGravity[i] = false;
        }
    }
}

public xdm_rune_pickup(rune, player) {
    set_user_gravity(player, g_fGravity / 800.0);
    g_bLowGravity[player] = true;
}

public xdm_rune_drop(rune, player) {
    restore_gravity(player);
    g_bLowGravity[player] = false;
}

public xdm_rune_death(rune, victim, attacker) {
    restore_gravity(victim);
    g_bLowGravity[victim] = false;
}

public restore_gravity(player) {
    if (!is_user_connected(player)) return;

    set_user_gravity(player, 1.0);
}
