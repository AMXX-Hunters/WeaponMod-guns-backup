#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <hl_wpnmod>


#define PLUGIN "m4a1scope"
#define VERSION "1.1"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_m4a1scope"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"90"
#define WEAPON_PRIMARY_AMMO_MAX		30
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		30
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			26
#define WEAPON_DAMAGE			25.0

// Hud
#define WEAPON_HUD_TXT_1		"sprites/weapon_m4a1scope.txt"
#define WEAPON_HUD_TXT_2		"sprites/weapon_m4a1scope_scp.txt"
#define WEAPON_HUD_SPR_1		"sprites/weapon_m4a1scope.spr"
#define WEAPON_HUD_SPR_2		"sprites/m4a1_scope.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_556"

// Models
#define MODEL_WORLD			"models/w_m4a1scope.mdl"
#define MODEL_VIEW			"models/v_m4a1scope.mdl"
#define MODEL_PLAYER			"models/p_m4a1scope.mdl"
#define MODEL_SHELL			"models/shell_tar21.mdl"

// Sounds
#define SOUND_FIRE			"weapons/m4a1_shoot1.wav"
#define SOUND_ZOOM			"weapons/sniper_zoom.wav"
#define SOUND_R1			"weapons/m4a1_boltpull.wav"
#define SOUND_R2			"weapons/m4a1_clipin.wav"
#define SOUND_R3			"weapons/m4a1_clipout.wav"
#define SOUND_R4			"weapons/m4a1_deploy.wav"


// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_FIRE1,
	ANIM_FIRE2,
	ANIM_FIRE3,	
};

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_SHELL);
		
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_ZOOM);
	PRECACHE_SOUND(SOUND_R1);
	PRECACHE_SOUND(SOUND_R2);
	PRECACHE_SOUND(SOUND_R3);
	PRECACHE_SOUND(SOUND_R4);
		
	PRECACHE_GENERIC(WEAPON_HUD_TXT_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new im4a1scope = wpnmod_register_weapon
	
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
	
	
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_Spawn, "m4a1scope_Spawn");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_Deploy, "m4a1scope_Deploy");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_Idle, "m4a1scope_Idle");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_PrimaryAttack, "m4a1scope_PrimaryAttack");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_SecondaryAttack, "m4a1scope_SecondaryAttack");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_Reload, "m4a1scope_Reload");
	wpnmod_register_weapon_forward(im4a1scope, Fwd_Wpn_Holster, "m4a1scope_Holster");
	

}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public m4a1scope_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);

	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public m4a1scope_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public m4a1scope_Holster(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		m4a1scope_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public m4a1scope_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.12);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public m4a1scope_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.08);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.12);
	
	wpnmod_send_weapon_anim(iItem, iClip ? ANIM_FIRE1 : ANIM_FIRE2 );
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		Float: {0.01, 0.01, 0.01}, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		0
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -12.0, 10.0);
	}
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-1.0, 0.0, 0.0});
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public m4a1scope_SecondaryAttack(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_m4a1scope", 0.0);
		
	}
	else if (flFov != 20.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_m4a1scope_scp", 20.0);
	}
	
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.4);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.3);
}

MakeZoom(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(WEAPON_PRIMARY_AMMO_MAX);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(WEAPON_SECONDARY_AMMO_MAX);
		write_byte(WEAPON_SLOT - 1);
		write_byte(WEAPON_POSITION - 1);
		write_byte(get_user_weapon(iPlayer));
		write_byte(WEAPON_FLAGS);
		message_end();
	}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public m4a1scope_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		m4a1scope_SecondaryAttack(iItem, iPlayer);
	}
	
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}

	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.08);
}

