#if defined _xdm_reborn_included
    #endinput
#endif
#define _xdm_reborn_included

#include <xdm_reborn_const>

#pragma reqlib xdm_reborn
#if !defined AMXMODX_NOAUTOLOAD
    #pragma loadlib xdm_reborn
#endif

/**
 * Registers a rune for the lifetime of the core.
 *
 * The id and its translations are derived from display_name. For example,
 * "Super Crowbar" becomes the id "super_crowbar", the cvars
 * xdm_rune_super_crowbar_count and xdm_rune_super_crowbar_color, and the
 * translation keys XDM_RUNE_SUPER_CROWBAR_NAME and XDM_RUNE_SUPER_CROWBAR_DESC.
 *
 * The id is lowercase; runs of non-alphanumeric characters become underscores.
 * Registration fails if the id is empty, already used, too long, the rune
 * registry is full, or the cvars cannot be created.
 *
 * default_count is the number of runes spawned at map start (0..64). Zero also
 * excludes the rune from random-rune selection. default_color is the rune skin
 * color (0..15).
 *
 * The generated NAME and DESC keys must exist in xdm_reborn.txt for each
 * language used by the server.
 *
 * @param display_name   Name used to derive the id, cvars and translation keys
 * @param default_count  Default value for xdm_rune_<id>_count
 * @param default_color  Default value for xdm_rune_<id>_color
 *
 * @return               Rune index, or XDM_INVALID_RUNE on failure
 */
native xdm_register_rune(
    const display_name[],
    default_count = 1,
    default_color = 0
);

// Returns the player's active rune index or XDM_INVALID_RUNE.
native xdm_get_user_rune(player);

// Returns the registered rune index for id or XDM_INVALID_RUNE.
native xdm_find_rune(const id[]);

// Sets the cooldown for the player's active rune. The core blocks the use and
// shows XDM_RUNE_COOLDOWN while the cooldown is active. seconds <= 0 clears it.
native xdm_set_rune_cooldown(rune, player, Float:seconds);

// Sets the player's grappling hook speed. A value <= 0 uses the core speed.
native xdm_set_hook_speed(player, Float:speed);

// Called when the player starts pulling with +hook.
forward xdm_hook_start(player);

// Optional callbacks. A rune is usable when its plugin implements
// xdm_rune_use; the core only shows the use hint in that case.
forward xdm_rune_pickup(rune, player);
forward xdm_rune_use(rune, player);
forward xdm_rune_cooldown(rune, player);
forward xdm_rune_drop(rune, player);
forward xdm_rune_death(rune, victim, attacker);
forward xdm_rune_spawn(rune, player);
