#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>

#define PLUGIN "dbarrel"
#define VERSION "1.2"
#define AUTHOR "dima_mark7"

// Weapon settings
#define WEAPON_NAME 			"weapon_dbarrel"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			1
#define WEAPON_PRIMARY_AMMO		"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX		125
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			2
#define WEAPON_DEFAULT_AMMO		32
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			40.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_dbarrel.txt"
#define WEAPON_HUD_AMMO			"sprites/ammo_dbarrel.spr"
#define WEAPON_HUD_SPR			"sprites/weapon_dbarrel.spr"

// Models
#define MODEL_WORLD			"models/w_dbarrel.mdl"
#define MODEL_VIEW			"models/v_dbarrel_hev.mdl"
#define MODEL_PLAYER			"models/p_dbarrel.mdl"

// Sounds
#define SOUND_FIRE			"weapons/dbarrel_shoot.wav"
#define SOUND_DRAW			"weapons/dbarrel_draw.wav"
#define SOUND_RELOAD_1			"weapons/dbarrel_foley1.wav"
#define SOUND_RELOAD_2			"weapons/dbarrel_foley2.wav"
#define SOUND_RELOAD_3			"weapons/dbarrel_foley3.wav"
#define SOUND_RELOAD_4			"weapons/dbarrel_foley4.wav"

// Animation
#define ANIM_EXTENSION			"shotgun"

enum _:dbarrel
{
	DB_IDLE,
	DB_SHOOT_1,
	DB_SHOOT_2,
	DB_SHOOT_3,
	DB_RELOAD,
	DB_DRAW
}

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DRAW);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_RELOAD_2);
	PRECACHE_SOUND(SOUND_RELOAD_3);
	PRECACHE_SOUND(SOUND_RELOAD_4);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_AMMO);
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new idbarrel = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_Spawn, "dbarrel_spawn");
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_Deploy, "dbarrel_deploy");
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_Idle, "dbarrel_idle");
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_PrimaryAttack, "dbarrel_primaryattack");
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_Reload, "dbarrel_reload");
	wpnmod_register_weapon_forward(idbarrel, Fwd_Wpn_Holster, "dbarrel_holster");
}

public dbarrel_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public dbarrel_deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, DB_DRAW, ANIM_EXTENSION);
}

public dbarrel_holster(const iItem)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public dbarrel_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, DB_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.5);
}

public dbarrel_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, DB_RELOAD, 1.67);
}

public dbarrel_primaryattack(const iItem, const iPlayer, iClip)
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
	wpnmod_fire_bullets(iPlayer,iPlayer,8,VECTOR_CONE_15DEGREES,3048.0,WEAPON_DAMAGE,DMG_BULLET,8)
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(DB_SHOOT_1, DB_SHOOT_2));

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
	
	vecPunchangle[2] = 0.0;
	vecVelocity[2] = flZVel;
	
	vecPunchangle[0] = random_float(-2.0, 2.0);
	vecPunchangle[1] = random_float(-2.0, 2.0);
	 
	set_pev(iPlayer, pev_velocity, vecVelocity);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
