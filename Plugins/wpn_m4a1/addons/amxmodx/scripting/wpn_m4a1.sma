/* AMX Mod X
*	CREDITS TO THE DIAMOND TEAM FOR THE MODELS
*
*
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>


#define PLUGIN "M4A1"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_m4a1"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"5561"
#define WEAPON_PRIMARY_AMMO_MAX		150
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		30
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			23.0

// Hud
#define WEAPON_HUD_SPR			"sprites/640hud1.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_m4a1.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_m4a1clip"


// Models
#define MODEL_WORLD			"models/w_m4a1.mdl"
#define MODEL_VIEW			"models/v_m4a1.mdl"
#define MODEL_PLAYER			"models/p_m4a1.mdl"
#define MODEL_SHELL			"models/shell.mdl"
#define MODEL_CLIP			"models/w_m4a1clip.mdl"

// Sounds
#define SOUND_SHOOT			"m4a1/hks1.wav"
#define SOUND_CLIP_OUT			"items/cliprelease1.wav"
#define SOUND_CLIP_IN			"items/clipinsert1.wav"
#define SOUND_BOLT_PULL			"weapons/t_m4_boltpull.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_IDLE1 = 0,
	ANIM_IDLE2,
	ANIM_GRENADE,
	ANIM_RELOAD,
	ANIM_DRAW,	
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_3,
	

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
	PRECACHE_MODEL(MODEL_CLIP);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_CLIP_OUT);
	PRECACHE_SOUND(SOUND_CLIP_IN);
	PRECACHE_SOUND(SOUND_BOLT_PULL);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iM4A1 = wpnmod_register_weapon
	
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
	
	new iClip = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_Spawn, "M4A1_Spawn");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_Deploy, "M4A1_Deploy");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_Idle, "M4A1_Idle");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_PrimaryAttack, "M4A1_PrimaryAttack");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_SecondaryAttack, "M4A1_SecondaryAttack");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_Reload, "M4A1_Reload");
	wpnmod_register_weapon_forward(iM4A1, Fwd_Wpn_Holster, "M4A1_Holster");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_Spawn, "Clip_Spawn");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_AddAmmo, "Clip_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public M4A1_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public M4A1_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public M4A1_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		M4A1_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public M4A1_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public M4A1_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	static Float: vecPunchangle[1];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.101);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.094);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT_1, ANIM_SHOOT_3));
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
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
	
	vecPunchangle[0] = random_float(0.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public M4A1_SecondaryAttack(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 0.0);	
	}
	else
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 20.0);
	}
	
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

public M4A1_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	if (!wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.01);
	}
	else
	{
		M4A1_SecondaryAttack(iItem, iPlayer);
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.09);
	}
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public Clip_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
	
	// Setting sub-model
	set_pev(iItem, pev_body, 1);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public Clip_AddAmmo(const iItem, const iPlayer)
{
	new iResult = 
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			iPlayer, 
			WEAPON_MAX_CLIP, 
			WEAPON_PRIMARY_AMMO, 
			WEAPON_PRIMARY_AMMO_MAX
		) != -1
	);
	
	if (iResult)
	{
		emit_sound(iItem, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	return iResult;
}
