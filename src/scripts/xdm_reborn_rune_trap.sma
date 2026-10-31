#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <fun>
#include <hlstocks>
#include <xdm_reborn>

#pragma semicolon 1

#define RUNE_DISPLAY_NAME       "Trap"
#define RUNE_DEFAULT_COUNT      1
#define RUNE_DEFAULT_COLOR      0

#define PLUGIN                  "XDM Reborn Rune: Trap"
#define AUTHOR                  "7mochi"

#define TRAP_WEAPON_NAME        "Blast Explosion"

new g_iRune;

new Float:g_fRadius;
new Float:g_fDamage;
new g_iFragBonus;

new g_iCylinderSprite;
new g_iDeathMsg;

public plugin_precache() {
    g_iCylinderSprite = precache_model("sprites/shockwave.spr");
    precache_sound("weapons/explode3.wav");
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
        log_amx("[xdm_reborn] Trap: registration failed");
        pause("ad");
        return;
    }

    g_iDeathMsg = get_user_msgid("DeathMsg");
}

public register_cvars() {
    bind_pcvar_float(create_cvar("xdm_rune_trap_radius", "625.0",
        FCVAR_NONE, "Radius of the trap rune explosion.",
        true, 0.0, true, 10000.0), g_fRadius);
    bind_pcvar_float(create_cvar("xdm_rune_trap_damage", "250.0",
        FCVAR_NONE, "Damage of the trap rune explosion.",
        true, 0.0, true, 100000.0), g_fDamage);
    bind_pcvar_num(create_cvar("xdm_rune_trap_frag_bonus", "0",
        FCVAR_NONE, "Extra frags awarded for a trap rune kill.",
        true, 0.0, true, 100.0), g_iFragBonus);
}

public xdm_rune_death(rune, victim, attacker) {
    new origin[3];
    get_user_origin(victim, origin);

    create_beam_cylinder(origin, 120.0, g_iCylinderSprite, 0, 0, 6, 16, 0,
        random(255), random(255), random(255), 255, 0);
    create_beam_cylinder(origin, 320.0, g_iCylinderSprite, 0, 0, 6, 16, 0,
        random(255), random(255), random(255), 255, 0);
    create_beam_cylinder(origin, g_fRadius, g_iCylinderSprite, 0, 0, 6, 16, 0,
        random(255), random(255), random(255), 255, 0);
    create_explosion(victim, attacker, g_fDamage, g_fRadius);
    emit_sound(victim, CHAN_BODY, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0,
        PITCH_NORM);
}

public create_beam_cylinder(viOrigin[3], Float:fRadius, iSprite, iStartFrameRate, iFrameRate, iLife, iWidth,
                     iAmplitude, iRed, iGreen, iBlue, iBrightness, iSpeed) {
    message_begin(MSG_PVS, SVC_TEMPENTITY, viOrigin);
    write_byte(TE_BEAMCYLINDER);
    write_coord(viOrigin[0]);
    write_coord(viOrigin[1]);
    write_coord(viOrigin[2]);
    write_coord(viOrigin[0]);
    write_coord(viOrigin[1]);
    write_coord_f(viOrigin[2] + fRadius);
    write_short(iSprite);
    write_byte(iStartFrameRate);
    write_byte(iFrameRate);
    write_byte(iLife);
    write_byte(iWidth);
    write_byte(iAmplitude);
    write_byte(iRed);
    write_byte(iGreen);
    write_byte(iBlue);
    write_byte(iBrightness);
    write_byte(iSpeed);
    message_end();
}

public create_explosion(iVictim, iAttacker, Float:fDamage, Float:fRange) {
    if (fRange <= 0.0) return;

    new Float:vfVictimOrigin[3], Float:vfAttackerOrigin[3];
    new Float:fDistance, Float:fTempDamage;
    entity_get_vector(iVictim, EV_VEC_origin, vfVictimOrigin);

    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (is_user_alive(i) && iVictim != i) {
            entity_get_vector(i, EV_VEC_origin, vfAttackerOrigin);
            fDistance = get_distance_f(vfVictimOrigin, vfAttackerOrigin);

            if (fDistance <= fRange) {
                fTempDamage = fDamage - (fDamage / fRange) * fDistance;
                fakedamage(i, TRAP_WEAPON_NAME, fTempDamage, DMG_BLAST);
                message_begin(MSG_BROADCAST, g_iDeathMsg);
                write_byte(iVictim);
                write_byte(i);
                write_byte(0);
                write_string(TRAP_WEAPON_NAME);
                message_end();

                if (iVictim != iAttacker && is_user_connected(iAttacker)) {
                    set_user_frags(iVictim, get_user_frags(iVictim) + g_iFragBonus);
                }
            }
        }
    }
}
