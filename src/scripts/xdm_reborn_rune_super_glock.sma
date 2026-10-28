#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Super Glock"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      1

#define PLUGIN                  "XDM Reborn Rune: Super Glock"
#define AUTHOR                  "7mochi"

new g_iRune;

#define PLAYER_M_I_FOV          0x3c4
#define SECONDARY_SUPPRESS      9999.0

new Float:g_fFireRate = 0.10;
new Float:g_fZoomFov = 40.0;

new bool:g_bZoomed[MAX_PLAYERS + 1];
new bool:g_bM2Held[MAX_PLAYERS + 1];

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
        log_amx("[xdm_reborn] Super Glock: registration failed");
        pause("ad");
        return;
    }

    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun",
        "fwd_glock_primary_attack_pre", 0);
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun",
        "fwd_glock_primary_attack_post", 1);
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmhandgun",
        "fwd_glock_secondary_attack_pre", 0);
    RegisterHam(Ham_Item_Deploy, "weapon_9mmhandgun",
        "fwd_glock_deploy", 1);
    RegisterHam(Ham_Item_Holster, "weapon_9mmhandgun",
        "fwd_glock_holster", 1);
    register_forward(FM_PlayerPreThink, "fwd_player_prethink");
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_super_glock_fire_rate", "0.10",
        FCVAR_NONE, "Primary attack delay of the super glock rune.",
        true, 0.01, true, 2.0), g_fFireRate);
    bind_pcvar_float(create_cvar("xdm_rune_super_glock_zoom_fov", "40.0",
        FCVAR_NONE, "Field of view used by the super glock sniper mode.",
        true, 1.0, true, 179.0), g_fZoomFov);
}

public OnConfigsExecuted() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bZoomed[i]) {
            set_player_zoom(i, false);
        }
    }
}

public plugin_end() {
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (g_bZoomed[i]) {
            set_player_zoom(i, false);
        }
    }
}

public xdm_rune_pickup(rune, player) {
    if (!user_has_weapon(player, HLW_GLOCK)) {
        give_item(player, "weapon_9mmhandgun");
    }

    set_player_zoom(player, false);
    suppress_glock_secondary(hl_user_has_weapon(player, HLW_GLOCK));
}

public xdm_rune_drop(rune, player) {
    reset_zoom(player);
    restore_glock_secondary(hl_user_has_weapon(player, HLW_GLOCK));
}

public xdm_rune_death(rune, victim, attacker) {
    reset_zoom(victim);
    restore_glock_secondary(hl_user_has_weapon(victim, HLW_GLOCK));
}

public reset_zoom(player) {
    set_player_zoom(player, false);
}

stock set_player_zoom(player, bool:zoomed) {
    g_bZoomed[player] = zoomed;

    new iFov = zoomed ? clamp(floatround(g_fZoomFov), 1, 179) : 0;
    set_pdata_int(player, PLAYER_M_I_FOV, iFov, 5);
    set_pev(player, pev_fov, zoomed ? g_fZoomFov : 0.0);
}

public fwd_glock_deploy(iGlock) {
    new player = glock_player(iGlock);
    if (!player) return;

    reset_zoom(player);

    if (xdm_get_user_rune(player) == g_iRune) {
        suppress_glock_secondary(iGlock);
    } else {
        restore_glock_secondary(iGlock);
    }
}

public fwd_glock_holster(iGlock) {
    new player = glock_player(iGlock);
    if (!player) return;

    reset_zoom(player);
}

public fwd_player_prethink(player) {
    if (!is_user_connected(player) || !is_user_alive(player)) {
        g_bM2Held[player] = false;
        return;
    }

    new bool:down = (pev(player, pev_button) & IN_ATTACK2) != 0;

    if (!down) {
        g_bM2Held[player] = false;
        return;
    }

    if (g_bM2Held[player]) return;
    g_bM2Held[player] = true;

    if (xdm_get_user_rune(player) != g_iRune) return;

    new iGlock = hl_user_has_weapon(player, HLW_GLOCK);
    if (!iGlock || hl_get_user_weapon_ent(player) != iGlock) return;

    set_player_zoom(player, !g_bZoomed[player]);
    suppress_glock_secondary(iGlock);
}

stock suppress_glock_secondary(iGlock) {
    if (!pev_valid(iGlock)) return;

    set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flNextSecondaryAttack",
        SECONDARY_SUPPRESS);
}

stock restore_glock_secondary(iGlock) {
    if (!pev_valid(iGlock)) return;

    set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.0);
}

stock glock_player(iGlock) {
    if (!pev_valid(iGlock)) return 0;

    new player = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");
    return (player >= 1 && player <= MAX_PLAYERS) ? player : 0;
}

public fwd_glock_primary_attack_pre(iGlock) {
    new player = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");

    if (xdm_get_user_rune(player) != g_iRune) return;

    new clip = get_ent_data(iGlock, "CBasePlayerWeapon", "m_iClip");
    if (clip > 0) {
        set_ent_data(iGlock, "CBasePlayerWeapon", "m_iClip", clip + 1);
    }
}

public fwd_glock_primary_attack_post(iGlock) {
    new player = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");

    if (xdm_get_user_rune(player) != g_iRune) return;

    set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flNextPrimaryAttack",
        g_fFireRate);
    suppress_glock_secondary(iGlock);

    if (get_ent_data(iGlock, "CBasePlayerWeapon", "m_iClip") != 0) {
        set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0);
    } else {
        set_ent_data_float(iGlock, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3);
    }
}

public fwd_glock_secondary_attack_pre(iGlock) {
    new player = get_ent_data_entity(iGlock, "CBasePlayerItem", "m_pPlayer");

    if (xdm_get_user_rune(player) != g_iRune) {
        return HAM_IGNORED;
    }

    suppress_glock_secondary(iGlock);

    return HAM_SUPERCEDE;
}
