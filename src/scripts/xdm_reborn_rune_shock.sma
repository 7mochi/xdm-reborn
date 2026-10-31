#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Shock"
#define RUNE_DEFAULT_COUNT      1
#define RUNE_DEFAULT_COLOR      1

#define PLUGIN                  "XDM Reborn Rune: Shock"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fDamage;
new Float:g_fRadius;
new Float:g_fCooldown;

new Float:g_vfLastUsed[MAX_PLAYERS + 1];
new g_iShockSprite;

public plugin_precache() {
    g_iShockSprite = precache_model("sprites/shock.spr");
    precache_sound("shock.wav");
    precache_sound("shock_deny.wav");
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
        log_amx("[xdm_reborn] Shock: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_shock_damage", "80.0",
        FCVAR_NONE, "Damage dealt by the shock rune.",
        true, 0.0, true, 10000.0), g_fDamage);
    bind_pcvar_float(create_cvar("xdm_rune_shock_radius", "200.0",
        FCVAR_NONE, "Radius of the shock rune.",
        true, 0.0, true, 10000.0), g_fRadius);
    bind_pcvar_float(create_cvar("xdm_rune_shock_cooldown", "3.0",
        FCVAR_NONE, "Cooldown of the shock rune.",
        true, 0.0, true, 600.0), g_fCooldown);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        g_vfLastUsed[i] = 0.0;
    }
}

public xdm_rune_pickup(rune, player) {
    g_vfLastUsed[player] = 0.0;
}

public xdm_rune_cooldown(rune, player) {
    emit_sound(player, CHAN_BODY, "shock_deny.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public xdm_rune_use(rune, player) {
    new Float:elapsed = get_gametime() - g_vfLastUsed[player];

    if (elapsed < g_fCooldown) {
        emit_sound(player, CHAN_BODY, "shock_deny.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        return;
    }

    g_vfLastUsed[player] = get_gametime();
    xdm_set_rune_cooldown(g_iRune, player, g_fCooldown);

    new Float:origin[3];
    entity_get_vector(player, EV_VEC_origin, origin);

    emit_sound(player, CHAN_BODY, "shock.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    create_shock_wave(origin);

    new Float:targetOrigin[3];
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (!is_user_alive(i) || i == player) continue;

        entity_get_vector(i, EV_VEC_origin, targetOrigin);
        new Float:distance = get_distance_f(origin, targetOrigin);

        if (distance > g_fRadius) continue;

        new Float:damage = g_fDamage;
        if (g_fRadius > 0.0) {
            damage *= 1.0 - (distance / g_fRadius);
        }

        if (damage > 0.0) {
            ExecuteHamB(Ham_TakeDamage, i, player, player, damage, DMG_SHOCK);
        }
    }
}

public create_shock_wave(const Float:origin[3]) {
    if (g_iShockSprite <= 0) return;

    message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
    write_byte(TE_BEAMCYLINDER);
    write_coord_f(origin[0]);
    write_coord_f(origin[1]);
    write_coord_f(origin[2]);
    write_coord_f(origin[0]);
    write_coord_f(origin[1]);
    write_coord_f(origin[2] + g_fRadius);
    write_short(g_iShockSprite);
    write_byte(0);
    write_byte(0);
    write_byte(6);
    write_byte(16);
    write_byte(0);
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(0);
    message_end();
}
