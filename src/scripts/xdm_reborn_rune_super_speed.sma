#include <amxmodx>
#include <fun>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Super Speed"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      3

#define PLUGIN                  "XDM Reborn Rune: Super Speed"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fVelocity;
new bool:g_bSuperSpeed[MAX_PLAYERS + 1];

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
        log_amx("[xdm_reborn] Super Speed: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_super_speed_velocity", "500.0",
        FCVAR_NONE, "Maximum speed granted by the super speed rune.",
        true, 0.0, true, 3000.0), g_fVelocity);
}

public OnConfigsExecuted() {
    new Float:speed = get_cvar_float("xdm_player_speed");
    set_cvar_float("sv_maxspeed", floatmax(speed, g_fVelocity));

    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bSuperSpeed[i]) {
            restore_speed(i);
            g_bSuperSpeed[i] = false;
        }
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bSuperSpeed[i]) {
            restore_speed(i);
            g_bSuperSpeed[i] = false;
        }
    }
}

public xdm_rune_pickup(rune, player) {
    set_user_maxspeed(player, g_fVelocity);
    g_bSuperSpeed[player] = true;
}

public xdm_rune_drop(rune, player) {
    restore_speed(player);
    g_bSuperSpeed[player] = false;
}

public xdm_rune_death(rune, victim, attacker) {
    restore_speed(victim);
    g_bSuperSpeed[victim] = false;
}

public restore_speed(player) {
    if (!is_user_connected(player)) return;

    set_user_maxspeed(player, get_cvar_float("xdm_player_speed"));
}
