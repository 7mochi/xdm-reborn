#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Shield"
#define RUNE_DEFAULT_COUNT      1
#define RUNE_DEFAULT_COLOR      13

#define PLUGIN                  "XDM Reborn Rune: Shield"
#define AUTHOR                  "7mochi"

#define TASK_SHIELD_END         2000

new g_iRune;

new Float:g_fDuration;
new Float:g_fCooldown;

new bool:g_bActive[MAX_PLAYERS + 1];
new Float:g_fUntil[MAX_PLAYERS + 1];
new Float:g_fReady[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_sound("shield.wav");
    precache_sound("shield_deny.wav");
}

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
        log_amx("[xdm_reborn] Shield: registration failed");
        pause("ad");
        return;
    }

    RegisterHam(Ham_TakeDamage, "player", "fwd_take_damage_pre", 0);
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_shield_duration", "3.0",
        FCVAR_NONE, "Duration of the shield rune immunity.",
        true, 0.1, true, 600.0), g_fDuration);
    bind_pcvar_float(create_cvar("xdm_rune_shield_cooldown", "10.0",
        FCVAR_NONE, "Cooldown of the shield rune.",
        true, 0.0, true, 600.0), g_fCooldown);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        remove_task(i + TASK_SHIELD_END);
        end_shield(i);
        g_fReady[i] = 0.0;
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        remove_task(i + TASK_SHIELD_END);
        end_shield(i);
    }
}

public xdm_rune_pickup(rune, player) {
    g_fReady[player] = 0.0;
}

public xdm_rune_cooldown(rune, player) {
    emit_sound(player, CHAN_BODY, "shield_deny.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public xdm_rune_use(rune, player) {
    new Float:now = get_gametime();

    if (now < g_fReady[player]) {
        emit_sound(player, CHAN_BODY, "shield_deny.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        return;
    }

    g_bActive[player] = true;
    g_fUntil[player] = now + g_fDuration;
    g_fReady[player] = now + g_fCooldown;
    xdm_set_rune_cooldown(g_iRune, player, g_fCooldown);

    set_user_rendering(player, kRenderFxGlowShell, 150, 250, 0, kRenderNormal, 16);
    emit_sound(player, CHAN_BODY, "shield.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    remove_task(player + TASK_SHIELD_END);
    set_task(g_fDuration, "task_shield_end", player + TASK_SHIELD_END);
}

public xdm_rune_drop(rune, player) {
    remove_task(player + TASK_SHIELD_END);
    end_shield(player);
}

public xdm_rune_death(rune, victim, attacker) {
    remove_task(victim + TASK_SHIELD_END);
    end_shield(victim);
}

public task_shield_end(task) {
    new player = task - TASK_SHIELD_END;

    end_shield(player);
}

public end_shield(player) {
    g_bActive[player] = false;
    g_fUntil[player] = 0.0;

    if (player >= 1 && player <= MAX_PLAYERS && is_user_connected(player)) {
        set_user_rendering(player, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
    }
}

public fwd_take_damage_pre(victim, inflictor, attacker, Float:damage, damagebits) {
    if (!g_bActive[victim]) return HAM_IGNORED;
    if (get_gametime() > g_fUntil[victim]) return HAM_IGNORED;

    return HAM_SUPERCEDE;
}
