/* AMX Mod X
 * Desert Eagle for WeaponMod
 *
 * http://hldm.org - Russian Half-Life DeathMatch Commynity
 * http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
 * 
 *
 * This file is provided as is (no warranties)
*/


#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "Desert Eagle"
#define VERSION "1.0"
#define AUTHOR "ET-NiK"


// Weapon settings
#define WEAPON_NAME 			"weapon_deagle"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			3
#define WEAPON_PRIMARY_AMMO		"357"
#define WEAPON_PRIMARY_AMMO_MAX		36
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			9
#define WEAPON_DEFAULT_AMMO		14
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			12
#define WEAPON_DAMAGE			60.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_deagle.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_deagle.spr"

// Models
#define MODEL_WORLD			"models/w_deagle.mdl"
#define MODEL_VIEW			"models/v_deagle.mdl"
#define MODEL_PLAYER			"models/p_deagle.mdl"

// Sounds
#define SOUND_FIRE			"weapons/deagle_shot1.wav"
#define SOUND_RELOAD			"weapons/deagle_reload.wav"

// Animation
#define ANIM_EXTENSION			"python"

enum _:deagle
{
	PYTHON_IDLE1,
	PYTHON_FIDGET1,
	PYTHON_FIRE1,
	PYTHON_RELOAD,
	PYTHON_HOLSTER,
	PYTHON_DRAW,
	PYTHON_IDLE2,
	PYTHON_IDLE3
}

public plugin_precache()
{
    PRECACHE_MODEL(MODEL_VIEW);
    PRECACHE_MODEL(MODEL_WORLD);
    PRECACHE_MODEL(MODEL_PLAYER);
   
    PRECACHE_SOUND(SOUND_FIRE);
    PRECACHE_SOUND(SOUND_RELOAD);
    
    PRECACHE_GENERIC(WEAPON_HUD_TXT);
    PRECACHE_GENERIC(WEAPON_HUD_SPR);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new deagle_id = wpnmod_register_weapon
	(
		WEAPON_NAME,
		WEAPON_SLOT,
		WEAPON_POSITION,
		WEAPON_PRIMARY_AMMO,
		WEAPON_PRIMARY_AMMO_MAX,
		WEAPON_SECONDARY_AMMO,
		WEAPON_SECONDARY_AMMO_MAX,
		WEAPON_MAX_CLIP,
		WEAPON_FLAGS,
		WEAPON_WEIGHT
	);
	
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_Spawn, "deagle_spawn");
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_Deploy, "deagle_deploy");
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_Idle, "deagle_idle");
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_PrimaryAttack, "deagle_primaryattack");
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_Reload, "deagle_reload");
	wpnmod_register_weapon_forward(deagle_id, Fwd_Wpn_Holster, "deagle_holster");
}

public deagle_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public deagle_deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, PYTHON_DRAW, ANIM_EXTENSION);
}

public deagle_holster(const iItem)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public deagle_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, PYTHON_IDLE1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.5);
}

public deagle_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, PYTHON_RELOAD, 2.0);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public deagle_primaryattack(const iItem, const iPlayer, iClip)
{
	static Float: flZVel;
	static Float: vecAngle[3];
	static Float: vecForward[3];
	static Float: vecVelocity[3];
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	wpnmod_fire_bullets(iPlayer,iPlayer,1, VECTOR_CONE_2DEGREES, 8192.0, WEAPON_DAMAGE, DMG_BULLET | DMG_NEVERGIB, 3);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.4);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, PYTHON_FIRE1);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	global_get(glb_v_forward, vecForward);
	
	pev(iPlayer, pev_v_angle, vecAngle);
	pev(iPlayer, pev_velocity, vecVelocity);
	pev(iPlayer, pev_punchangle, vecPunchangle);
	
	xs_vec_add(vecAngle, vecPunchangle, vecPunchangle);
	engfunc(EngFunc_MakeVectors, vecPunchangle);
	
	flZVel = vecVelocity[2];
	
	xs_vec_mul_scalar(vecForward, 35.0, vecPunchangle);
	xs_vec_sub(vecVelocity, vecPunchangle, vecVelocity);
	
	vecPunchangle[2] = 1.0;
	vecVelocity[2] = flZVel;
	
	vecPunchangle[0] = -8.0;
	vecPunchangle[1] = random_float(-2.0, 2.0);
	 
	set_pev(iPlayer, pev_velocity, vecVelocity);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
