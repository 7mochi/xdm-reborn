#include <amxmodx>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Regeneration"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      7

#define PLUGIN                  "XDM Reborn Rune: Regeneration"
#define AUTHOR                  "7mochi"

#define TASK_REGEN              69727420

new g_iRune;

new Float:g_fFrequency;
new g_iAmountHP;
new g_iAmountHEV;
new g_iMaxHP;
new g_iMaxHEV;

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
        log_amx("[xdm_reborn] Regeneration: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_regeneration_frequency", "0.5",
        FCVAR_NONE, "Seconds between regeneration ticks.",
        true, 0.01, true, 60.0), g_fFrequency);
    bind_pcvar_num(create_cvar("xdm_rune_regeneration_amount_hp", "2",
        FCVAR_NONE, "Health restored per regeneration tick.",
        true, 0.0, true, 1000.0), g_iAmountHP);
    bind_pcvar_num(create_cvar("xdm_rune_regeneration_amount_hev", "1",
        FCVAR_NONE, "Armor restored per regeneration tick.",
        true, 0.0, true, 1000.0), g_iAmountHEV);
    bind_pcvar_num(create_cvar("xdm_rune_regeneration_max_hp", "100",
        FCVAR_NONE, "Maximum health the regeneration rune can restore.",
        true, 0.0, true, 1000.0), g_iMaxHP);
    bind_pcvar_num(create_cvar("xdm_rune_regeneration_max_hev", "100",
        FCVAR_NONE, "Maximum armor the regeneration rune can restore.",
        true, 0.0, true, 1000.0), g_iMaxHEV);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        remove_task(i + TASK_REGEN);
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        remove_task(i + TASK_REGEN);
    }
}

public xdm_rune_pickup(rune, player) {
    set_task(g_fFrequency, "task_regen", player + TASK_REGEN, _, _, "b");
}

public xdm_rune_drop(rune, player) {
    remove_task(player + TASK_REGEN);
}

public xdm_rune_death(rune, victim, attacker) {
    remove_task(victim + TASK_REGEN);
}

public task_regen(task) {
    new player = task - TASK_REGEN;

    if (!is_user_alive(player)) return;

    new hp = hl_get_user_health(player) + g_iAmountHP;
    new hev = hl_get_user_armor(player) + g_iAmountHEV;

    if (g_iMaxHP > 0) {
        hl_set_user_health(player, min(hp, g_iMaxHP));
    }

    if (g_iMaxHEV > 0) {
        hl_set_user_armor(player, min(hev, g_iMaxHEV));
    }
}
