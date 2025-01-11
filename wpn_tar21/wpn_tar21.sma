/* AMX Mod X
*	Tavor Assault Rifle - 21.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>


#define PLUGIN "TAR-21: Tavor Assault Rifle"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7, Koshak"


// Weapon settings
#define WEAPON_NAME 			"weapon_tar21"
#define WEAPON_NAME_SIGHT 		"weapon_tar21_sight"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"556"
#define WEAPON_PRIMARY_AMMO_MAX		200
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		30
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			15.0

// Hud
#define WEAPON_HUD_SPR			"sprites/weapon_tar21.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_tar21.txt"
#define WEAPON_HUD_TXT_SIGHT		"sprites/weapon_tar21_sight.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_tar21clip"

// Models
#define MODEL_WORLD			"models/w_tar21_koshak.mdl"
#define MODEL_VIEW			"models/v_tar21_koshak_v2.mdl"
#define MODEL_VIEW_SIGHT		"models/v_tar21_sight_koshak.mdl"
#define MODEL_PLAYER			"models/p_tar21_koshak.mdl"
#define MODEL_SHELL			"models/shell_tar21.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/tar21_shoot1.wav"
#define SOUND_CLIP_IN			"weapons/tar21_clipin.wav"
#define SOUND_CLIP_OUT			"weapons/tar21_clipout.wav"
#define SOUND_BOLT_PULL			"weapons/tar21_boltpull.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	KOSHAK_HL = 0,
	
	ANIM_RELOAD,
	ANIM_RELOAD_2,
	ANIM_DRAW,
	
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_3,
	
	ANIM_FASTRUN_BEGIN,
	ANIM_FASTRUN_IDLE,
	ANIM_FASTRUN_END,
	
	ANIM_SIGHT_BEGIN,
	ANIM_SIGHT_END
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
	PRECACHE_MODEL(MODEL_VIEW_SIGHT);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_CLIP_IN);
	PRECACHE_SOUND(SOUND_CLIP_OUT);
	PRECACHE_SOUND(SOUND_BOLT_PULL);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_SIGHT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iTAR = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_Spawn, "TAR_Spawn");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_Deploy, "TAR_Deploy");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_Idle, "TAR_Idle");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_PrimaryAttack, "TAR_PrimaryAttack");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_SecondaryAttack, "TAR_SecondaryAttack");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_Reload, "TAR_Reload");
	wpnmod_register_weapon_forward(iTAR, Fwd_Wpn_Holster, "TAR_Holster");
	
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_Spawn, "Clip_Spawn");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_AddAmmo, "Clip_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public TAR_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public TAR_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public TAR_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		TAR_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public TAR_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, KOSHAK_HL);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public TAR_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.06);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT_1, ANIM_SHOOT_3));
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_2DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	
	vecPunchangle[0] = random_float(-1.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public TAR_SecondaryAttack(const iItem, const iPlayer)
{
	new iInZoom = wpnmod_get_offset_int(iItem, Offset_iInZoom);
	
	if (!iInZoom)
	{
		SetThink(iItem, "TAR_SightThink", 0.3);
	}
	else
	{
		MakeZoom(iItem, iPlayer, WEAPON_NAME, MODEL_VIEW, 0.0);
	}
	
	wpnmod_set_offset_int(iItem, Offset_iInZoom, !iInZoom);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.35);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
	wpnmod_send_weapon_anim(iItem, iInZoom ? ANIM_SIGHT_END : ANIM_SIGHT_BEGIN);
}

//**********************************************
//* Enable sight.                              *
//**********************************************

public TAR_SightThink(const iItem, const iPlayer)
{
	MakeZoom(iItem, iPlayer, WEAPON_NAME_SIGHT, MODEL_VIEW_SIGHT, 60.0);
}

//**********************************************
//* Apply zoom.                                *
//**********************************************

MakeZoom(const iItem, const iPlayer, const szWeaponName[], const szViewModel[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, floatround(flFov));
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo1));
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo2));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iSlot));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iPosition));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iId));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iFlags));
		message_end();
	}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public TAR_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	if (!wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.13);
	}
	else
	{
		TAR_SecondaryAttack(iItem, iPlayer);
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD_2, 3.46);
	}
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public Clip_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
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
