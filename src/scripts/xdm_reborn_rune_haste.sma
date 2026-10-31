#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Haste"
#define RUNE_DEFAULT_COUNT      2
#define RUNE_DEFAULT_COLOR      4

#define PLUGIN                  "XDM Reborn Rune: Haste"
#define AUTHOR                  "7mochi"

new g_iRune;

new Float:g_fCycleMultiplier;

new const g_vszWeaponClasses[][] = {
    "weapon_gauss",
    "weapon_357",
    "weapon_9mmAR",
    "weapon_9mmhandgun",
    "weapon_crossbow",
    "weapon_crowbar",
    "weapon_egon",
    "weapon_handgrenade",
    "weapon_hornetgun",
    "weapon_rpg",
    "weapon_satchel",
    "weapon_shotgun",
    "weapon_snark",
    "weapon_tripmine",
};

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
        log_amx("[xdm_reborn] Haste: registration failed");
        pause("ad");
        return;
    }

    for (new i; i < sizeof g_vszWeaponClasses; i++) {
        RegisterHam(Ham_Weapon_PrimaryAttack, g_vszWeaponClasses[i],
            "fwd_primary_attack_post", 1);
        RegisterHam(Ham_Weapon_SecondaryAttack, g_vszWeaponClasses[i],
            "fwd_secondary_attack_post", 1);
    }
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_haste_cycle_multiplier", "0.5",
        FCVAR_NONE, "Multiplier applied to weapon attack cycle while the haste rune is active.",
        true, 0.01, true, 10.0), g_fCycleMultiplier);
}

public fwd_primary_attack_post(iWeapon) {
    new player = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");

    if (xdm_get_user_rune(player) != g_iRune) return;

    new Float:fNextAttack = get_ent_data_float(iWeapon, "CBasePlayerWeapon",
        "m_flNextPrimaryAttack");

    if (fNextAttack <= 0.0) return;

    new Float:fNow = get_gametime();

    if (fNextAttack > fNow) {
        set_ent_data_float(iWeapon, "CBasePlayerWeapon", "m_flNextPrimaryAttack",
            fNow + (fNextAttack - fNow) * g_fCycleMultiplier);
    } else {
        set_ent_data_float(iWeapon, "CBasePlayerWeapon", "m_flNextPrimaryAttack",
            fNextAttack * g_fCycleMultiplier);
    }
}

public fwd_secondary_attack_post(iWeapon) {
    new player = get_ent_data_entity(iWeapon, "CBasePlayerItem", "m_pPlayer");

    if (xdm_get_user_rune(player) != g_iRune) return;

    new Float:fNextAttack = get_ent_data_float(iWeapon, "CBasePlayerWeapon",
        "m_flNextSecondaryAttack");

    if (fNextAttack <= 0.0) return;

    new Float:fNow = get_gametime();

    if (fNextAttack > fNow) {
        set_ent_data_float(iWeapon, "CBasePlayerWeapon", "m_flNextSecondaryAttack",
            fNow + (fNextAttack - fNow) * g_fCycleMultiplier);
    } else {
        set_ent_data_float(iWeapon, "CBasePlayerWeapon", "m_flNextSecondaryAttack",
            fNextAttack * g_fCycleMultiplier);
    }
}
