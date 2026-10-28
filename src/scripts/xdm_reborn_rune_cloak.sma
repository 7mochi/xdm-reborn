#include <amxmodx>
#include <fun>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Cloak"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      11

#define PLUGIN                  "XDM Reborn Rune: Cloak"
#define AUTHOR                  "7mochi"

new g_iRune;

new g_iCloakAlpha;
new bool:g_bCloaked[MAX_PLAYERS + 1];

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
        log_amx("[xdm_reborn] Cloak: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_num(create_cvar("xdm_rune_cloak_alpha", "80", FCVAR_NONE, "Alpha value of the cloak rune.", true, 0.0, true, 255.0), g_iCloakAlpha);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bCloaked[i]) {
            restore_alpha(i);
            g_bCloaked[i] = false;
        }
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bCloaked[i]) {
            restore_alpha(i);
            g_bCloaked[i] = false;
        }
    }
}

public xdm_rune_pickup(rune, player) {
    set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha,
        g_iCloakAlpha);
    g_bCloaked[player] = true;
}

public xdm_rune_drop(rune, player) {
    restore_alpha(player);
    g_bCloaked[player] = false;
}

public xdm_rune_death(rune, victim, attacker) {
    restore_alpha(victim);
    g_bCloaked[victim] = false;
}

public restore_alpha(player) {
    if (!is_user_connected(player)) return;

    set_user_rendering(player, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}
