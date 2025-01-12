#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <fakemeta_util>


#define PLUGIN "HL: SKULL11"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_skull11"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"skull56"
#define WEAPON_PRIMARY_AMMO_MAX		250
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			100
#define WEAPON_DEFAULT_AMMO		100
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			27
#define WEAPON_DAMAGE			25.0

// Hud
#define WEAPON_HUD_SPR			"sprites/640hud717.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_skull11.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_skull56"

// Models
#define MODEL_WORLD			"models/w_skull11.mdl"
#define MODEL_VIEW			"models/v_skull11.mdl"
#define MODEL_PLAYER			"models/p_skull11.mdl"
#define MODEL_SHELL			"models/shell.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/skull11_shoot1.wav"
#define SOUND_ZOOM			"weapons/sniper_zoom.wav"

// Animation
#define ANIM_EXTENSION_1		"mp5"

new Float: ms;

enum _:Animation
{
	ANIM_IDLE,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_RELOAD1,
	ANIM_DRAW
};

//**********************************************
	
#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
		
#define Offset_iInZoom Offset_iuser1

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_ZOOM);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iSKULL11 = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_Spawn, "SKULL11_Spawn");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_Deploy, "SKULL11_Deploy");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_Idle, "SKULL11_Idle");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_PrimaryAttack, "SKULL11_PrimaryAttack");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_SecondaryAttack, "SKULL11_SecondaryAttack");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_Reload, "SKULL11_Reload");
	wpnmod_register_weapon_forward(iSKULL11, Fwd_Wpn_Holster, "SKULL11_Holster");
}

public plugin_cfg(){
	ms = get_cvar_float("sv_maxspeed");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public SKULL11_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public SKULL11_Deploy(const iItem, const iPlayer, const iClip)
{
	fm_set_user_maxspeed(iPlayer,225.0);
	{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION_1);
	}
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public SKULL11_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		SKULL11_SecondaryAttack(iItem, iPlayer);
		fm_set_user_maxspeed(iPlayer,ms);
	}

	// Cancel any reload in progress.
	fm_set_user_maxspeed(iPlayer,ms);
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public SKULL11_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public SKULL11_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	static Float: vecPunchangle[3];
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.091);
		return;
	}
	
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.248);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.415);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);	
		
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
		wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT_1, ANIM_SHOOT_2));
	
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
		wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE+20, 
		DMG_BULLET | DMG_NEVERGIB, 
		6
	);
	
		static iShellModelIndex;
		if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
		vecPunchangle[0] = random_float(-2.0, 0.0);
		set_pev(iPlayer, pev_punchangle, float: {-2.0, 0.0, 0.0});
		set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	}
	else {
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1401);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.415);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);	
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT_1, ANIM_SHOOT_2));
	
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
		6
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	vecPunchangle[0] = random_float(-2.0, -2.0);
	set_pev(iPlayer, pev_punchangle, float: {-1.5, 1.5});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	}
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public SKULL11_SecondaryAttack(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 0.0);
		fm_set_user_maxspeed(iPlayer,225.0);
	}
	else
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 50.0);
		fm_set_user_maxspeed(iPlayer,115.0);
	}
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}

//**********************************************
//* Apply zoom.                                *
//**********************************************

MakeZoom(const iItem, const iPlayer, const szViewModel[], const Float: flFov)
{
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
	wpnmod_set_offset_int(iItem, Offset_iInZoom, flFov != 0.0);
		}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public SKULL11_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	if (!wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD1, 3.6199);
	}
	else
	{
	SKULL11_SecondaryAttack(iItem, iPlayer);
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD1, 3.6199);
	fm_set_user_maxspeed(iPlayer,225.0);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
