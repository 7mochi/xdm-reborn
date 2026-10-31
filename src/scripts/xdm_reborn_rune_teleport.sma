#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Teleport"
#define RUNE_DEFAULT_COUNT      1
#define RUNE_DEFAULT_COLOR      14

#define PLUGIN                  "XDM Reborn Rune: Teleport"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fCooldown;
new Float:g_vfLastUsed[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_sound("debris/beamstart7.wav");
    precache_sound("tentacle/te_search2.wav");
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
        log_amx("[xdm_reborn] Teleport: registration failed");
        pause("ad");
        return;
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_teleport_cooldown", "5.0",
        FCVAR_NONE, "Cooldown of the teleport rune.",
        true, 0.0, true, 600.0), g_fCooldown);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        g_vfLastUsed[i] = get_gametime() - g_fCooldown;
    }
}

public xdm_rune_pickup(rune, player) {
    g_vfLastUsed[player] = get_gametime() - g_fCooldown;
}

public xdm_rune_cooldown(rune, player) {
    emit_sound(player, CHAN_BODY, "tentacle/te_search2.wav", VOL_NORM, ATTN_NORM, 0,
        PITCH_NORM);
}

public xdm_rune_use(rune, player) {
    new Float:elapsed = get_gametime() - g_vfLastUsed[player];

    if (elapsed < g_fCooldown) {
        client_print(player, print_chat, "%l", "XDM_RUNE_COOLDOWN",
            g_fCooldown - elapsed);
        emit_sound(player, CHAN_BODY, "tentacle/te_search2.wav", VOL_NORM, ATTN_NORM, 0,
            PITCH_NORM);
        return;
    }

    new destination = find_random_teleport_destination();
    if (!destination) {
        return;
    }

    g_vfLastUsed[player] = get_gametime();
    xdm_set_rune_cooldown(g_iRune, player, g_fCooldown);

    new Float:origin[3], Float:angles[3], Float:velocity[3];
    entity_get_vector(destination, EV_VEC_origin, origin);
    entity_get_vector(destination, EV_VEC_angles, angles);
    entity_get_vector(destination, EV_VEC_velocity, velocity);
    origin[2] += 1.0;

    client_cmd(player, "-hook");
    emit_sound(player, CHAN_BODY, "debris/beamstart7.wav", VOL_NORM, ATTN_NORM, 0,
        PITCH_NORM);

    entity_set_origin(player, origin);
    entity_set_vector(player, EV_VEC_angles, angles);
    entity_set_vector(player, EV_VEC_velocity, velocity);

    set_pev(player, pev_gravity, 1.0);
}

public find_random_teleport_destination() {
    new destination = find_random_spawn("info_player_deathmatch");

    if (!destination) {
        destination = find_random_spawn("info_player_start");
    }

    if (!destination) {
        destination = find_random_spawn("info_player_coop");
    }

    return destination;
}

stock find_random_spawn(const className[]) {
    new destination = 0;
    new count = 0;
    new entity = -1;

    while ((entity = find_ent_by_class(entity, className))) {
        count++;

        if (random(count) == 0) {
            destination = entity;
        }
    }

    return destination;
}
