#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "HL_CARTRED"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE/RYANTABS123"


// Weapon settings
#define WEAPON_NAME 			"weapon_cartred"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"cartclip"
#define WEAPON_PRIMARY_AMMO_MAX		240
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			60
#define WEAPON_DEFAULT_AMMO		60
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			25
#define WEAPON_DAMAGE			23.0

// Hud
#define WEAPON_HUD_SPR		        "sprites/cso/640hud105.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_cartred.txt"

// Models
#define MODEL_WORLD			"models/w_cartred.mdl"
#define MODEL_VIEW			"models/v_cartred.mdl"
#define MODEL_PLAYER			"models/p_cartred.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/cartred_shoot1.wav"
#define SOUND_SHOOT_MOD                 "weapons/cartred_shoot2.wav"
#define SOUND_ZOOM			"weapons/sniper_zoom.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation_svdex
{
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_CHANGERIFLE,
	RIFLE_IDLE,
	RIFLE_RELOAD,
	RIFLE_DRAW,
	RIFLE_SHOOT1,
	RIFLE_SHOOT2,
	RIFLE_SHOOT3,
	RIFLE_CHANGEMG	
};

#define Offset_Mod Offset_iuser1
#define Offset_iInZoom Offset_iuser2

#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_SHOOT_MOD);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iCART = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_Spawn, "CART_Spawn");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_Deploy, "CART_Deploy");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_Idle, "CART_Idle");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_PrimaryAttack, "CART_PrimaryAttack");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_SecondaryAttack, "CART_SecondaryAttack");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_Reload, "CART_Reload");
	wpnmod_register_weapon_forward(iCART, Fwd_Wpn_Holster, "CART_Holster");
}


public CART_Spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}


public CART_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);	
}

public CART_Holster(const iItem, const iPlayer, const szViewModel[], const Float: flFov)
{
	new Mod = wpnmod_get_offset_int(iItem, Offset_Mod);
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
	if (wpnmod_get_offset_int(iItem, Offset_Mod)){
	wpnmod_set_offset_int(iItem, Offset_Mod, !Mod);
	}
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
	wpnmod_set_offset_int(iItem, Offset_iInZoom, flFov == 0.0);
	}
}


public CART_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
        if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_send_weapon_anim(iItem, RIFLE_IDLE); 
        }
        else
        {
        wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
        }

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public CART_PrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmo)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	RIFLE_Fire(iItem, iPlayer, iClip);
	}
	
	else
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_5DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	vecPunchangle[0] = random_float(-1.0, 1.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
        }
}

public CART_Reload(const iItem, const iPlayer, const iClip, const iAmmo ,const szViewModel[], const Float: flFov)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
		{
		return;	
		}
	if(wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 0.0);
	}
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, RIFLE_RELOAD,3.69);
	}
	if(!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD,3.27);
	}
}

public CART_SecondaryAttack(const iItem, const iPlayer)
{
	new Mod = wpnmod_get_offset_int(iItem, Offset_Mod);
	if(wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 0.0);
	}
	else
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 50.0);
	}
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
	}
	if(!wpnmod_get_offset_int(iItem, Offset_Mod)){
	wpnmod_set_offset_int(iItem, Offset_Mod, !Mod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 3.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 3.1);
	wpnmod_send_weapon_anim(iItem, Mod ? RIFLE_CHANGEMG : ANIM_CHANGERIFLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}
}

MakeZoom(const iItem, const iPlayer, const szViewModel[], const Float: flFov)
{
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
	wpnmod_set_offset_int(iItem, Offset_iInZoom, flFov != 0.0);
}


RIFLE_Fire(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	else
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.16);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, RIFLE_SHOOT1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT_MOD, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_2DEGREES, 
		8192.0, 
		WEAPON_DAMAGE+7, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	set_pev(iPlayer, pev_punchangle, float: {-1.5, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
        }
}
