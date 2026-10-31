#include <amxmodx>
#include <hamsandwich>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Vampire"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      9

#define PLUGIN                  "XDM Reborn Rune: Vampire"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fHealthMultiplier;
new Float:g_fArmorMultiplier;
new g_iMaxHealth;
new g_iMaxArmor;

new g_iVictimHealth[MAX_PLAYERS + 1];

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
        log_amx("[xdm_reborn] Vampire: registration failed");
        pause("ad");
        return;
    }

    RegisterHam(Ham_TakeDamage, "player", "fwd_take_damage_pre", 0);
    RegisterHam(Ham_TakeDamage, "player", "fwd_take_damage_post", 1);
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_vampire_health_multiplier", "0.5",
        FCVAR_NONE, "Health gained per point of health damage dealt.",
        true, 0.0, true, 100.0), g_fHealthMultiplier);
    bind_pcvar_float(create_cvar("xdm_rune_vampire_armor_multiplier", "0.25",
        FCVAR_NONE, "Armor gained per point of health damage dealt.",
        true, 0.0, true, 100.0), g_fArmorMultiplier);
    bind_pcvar_num(create_cvar("xdm_rune_vampire_max_health", "150",
        FCVAR_NONE, "Maximum health the vampire rune can restore.",
        true, 0.0, true, 100000.0), g_iMaxHealth);
    bind_pcvar_num(create_cvar("xdm_rune_vampire_max_armor", "100",
        FCVAR_NONE, "Maximum armor the vampire rune can restore.",
        true, 0.0, true, 100000.0), g_iMaxArmor);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        g_iVictimHealth[i] = 0;
    }
}

public fwd_take_damage_pre(victim, inflictor, attacker, Float:damage, damagebits) {
    g_iVictimHealth[victim] = hl_get_user_health(victim);
    return HAM_IGNORED;
}

public fwd_take_damage_post(victim, inflictor, attacker, Float:damage, damagebits) {
    if (attacker < 1 || attacker > MAX_PLAYERS) return;
    if (attacker == victim) return;
    if (!is_user_alive(attacker)) return;
    if (xdm_get_user_rune(attacker) != g_iRune) return;

    new lost = g_iVictimHealth[victim] - hl_get_user_health(victim);
    if (lost <= 0) return;

    new Float:dealt = damage;
    if (dealt <= 0.0) {
        dealt = float(lost);
    }

    if (g_iMaxHealth > 0) {
        new health = hl_get_user_health(attacker);
        if (health < g_iMaxHealth) {
            new gain = floatround(dealt * g_fHealthMultiplier);
            hl_set_user_health(attacker, min(health + gain, g_iMaxHealth));
        }
    }

    if (g_iMaxArmor > 0) {
        new armor = hl_get_user_armor(attacker);
        if (armor < g_iMaxArmor) {
            new gain = floatround(dealt * g_fArmorMultiplier);
            hl_set_user_armor(attacker, min(armor + gain, g_iMaxArmor));
        }
    }
}
