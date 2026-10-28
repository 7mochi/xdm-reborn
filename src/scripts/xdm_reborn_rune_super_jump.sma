#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Super Jump"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      15

#define PLUGIN                  "XDM Reborn Rune: Super Jump"
#define AUTHOR                  "7mochi"

#define SUPER_JUMP_SOUND "barney/ba_pain1.wav"
#define SUPER_JUMP_BOOST 100.0

new g_iRune;

new bool:g_bKeepLongJump;

new bool:g_bHadLongJump[MAX_PLAYERS + 1];
new bool:g_bGrantedLongJump[MAX_PLAYERS + 1];
new bool:g_bPendingBoost[MAX_PLAYERS + 1];
new bool:g_bJumpHeld[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_sound(SUPER_JUMP_SOUND);
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
        log_amx("[xdm_reborn] Super Jump: registration failed");
        pause("ad");
        return;
    }

    register_forward(FM_CmdStart, "fwd_cmd_start");
    register_forward(FM_PlayerPostThink, "fwd_player_postthink");
}

public register_cvars() {
    bind_pcvar_num(create_cvar("xdm_rune_super_jump_keep_longjump", "0",
        FCVAR_NONE, "Whether players keep the long jump module after dropping the super jump rune.",
        true, 0.0, true, 1.0), g_bKeepLongJump);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        g_bHadLongJump[i] = false;
        g_bGrantedLongJump[i] = false;
    }
}

public xdm_rune_pickup(rune, player) {
    g_bHadLongJump[player] = hl_get_user_longjump(player);
    g_bGrantedLongJump[player] = true;
    hl_set_user_longjump(player, true);
}

public xdm_rune_drop(rune, player) {
    remove_longjump(player);
}

public xdm_rune_death(rune, victim, attacker) {
    remove_longjump(victim);
}

public fwd_cmd_start(player, uc_handle, seed) {
    if (!is_user_alive(player)) {
        g_bJumpHeld[player] = false;
        return;
    }

    new buttons = get_uc(uc_handle, UC_Buttons);

    if (!(buttons & IN_JUMP)) {
        g_bJumpHeld[player] = false;
        return;
    }

    if (g_bJumpHeld[player]) return;
    g_bJumpHeld[player] = true;

    new flags = pev(player, pev_flags);
    new duck_button = pev(player, pev_button);

    if (!(flags & FL_ONGROUND)) return;
    if (!(buttons & IN_DUCK) && !(duck_button & IN_DUCK)) return;
    if (pev(player, pev_flDuckTime) <= 0) return;

    if (get_player_speed(player) <= 50.0) {
        return;
    }

    g_bPendingBoost[player] = true;
}

stock Float:get_player_speed(player) {
    new Float:velocity[3];
    pev(player, pev_velocity, velocity);
    return floatsqroot(velocity[0] * velocity[0] +
                       velocity[1] * velocity[1] +
                       velocity[2] * velocity[2]);
}

public fwd_player_postthink(player) {
    if (!g_bPendingBoost[player]) return;
    g_bPendingBoost[player] = false;

    if (!is_user_alive(player)) return;
    if (xdm_get_user_rune(player) != g_iRune) return;

    new Float:velocity[3];
    pev(player, pev_velocity, velocity);
    velocity[2] += SUPER_JUMP_BOOST;
    set_pev(player, pev_velocity, velocity);
    emit_sound(player, CHAN_VOICE, SUPER_JUMP_SOUND, 0.8, ATTN_NORM, 0, PITCH_NORM);
}

public remove_longjump(player) {
    if (!g_bGrantedLongJump[player]) return;
    if (!is_user_connected(player)) return;

    if (!g_bKeepLongJump && !g_bHadLongJump[player]) {
        hl_set_user_longjump(player, false);
    }

    g_bHadLongJump[player] = false;
    g_bGrantedLongJump[player] = false;
}
