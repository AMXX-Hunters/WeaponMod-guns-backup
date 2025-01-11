#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>


#define PLUGIN "weapon_cbowex"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_cbowex"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"Tube"
#define WEAPON_PRIMARY_AMMO_MAX		200
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			50
#define WEAPON_DEFAULT_AMMO		50
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			35
#define WEAPON_DAMAGE			22.0

// Hud
#define WEAPON_HUD_SPR			"sprites/640hud121.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_cbowex.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_cbowtube"


// Models
#define MODEL_WORLD			"models/w_cbowex.mdl"
#define MODEL_VIEW			"models/v_cbowex_gflip.mdl"
#define MODEL_PLAYER			"models/p_cbowex.mdl"
#define MODEL_CLIP			"models/w_cbowex_clip.mdl"

// Sounds
#define SOUND_FIRE			"weapons/cbow/cbowex_shoot1.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_IDLE,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_RELOAD,
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
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_CLIP);
	
	PRECACHE_SOUND(SOUND_FIRE);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iCBOWEX = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_Spawn, "CBOW_Spawn");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_Deploy, "CBOW_Deploy");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_Idle, "CBOW_Idle");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_PrimaryAttack, "CBOW_PrimaryAttack");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_SecondaryAttack, "CBOW_SecondaryAttack");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_Reload, "CBOW_Reload");
	wpnmod_register_weapon_forward(iCBOWEX, Fwd_Wpn_Holster, "CBOW_Holster");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_Spawn, "Clip_Spawn");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_AddAmmo, "Clip_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public CBOW_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public CBOW_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public CBOW_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		CBOW_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public CBOW_Idle(const iItem)
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

public CBOW_PrimaryAttack(const iItem, const iPlayer, const iClip)
{	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.391);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.134);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT_1, ANIM_SHOOT_2));
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		Float: {0.0001, 0.0001, 0.0001}, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-1.0, 0.0, 0.0});
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public CBOW_SecondaryAttack(const iItem, const iPlayer)
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

public CBOW_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	if (!wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.41);
	}
	else
	{
		CBOW_SecondaryAttack(iItem, iPlayer);
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.49);
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
