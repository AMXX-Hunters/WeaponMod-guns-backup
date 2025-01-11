#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <hl_wpnmod>


#define PLUGIN "Armor Piercing Sniper Rifle"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_huntingsniper"
#define WEAPON_SLOT			4
#define WEAPON_POSITION			3
#define WEAPON_PRIMARY_AMMO		"762experimental"
#define WEAPON_PRIMARY_AMMO_MAX		8
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			2
#define WEAPON_DEFAULT_AMMO		1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			20
#define WEAPON_DAMAGE			1000.0

// Hud
#define WEAPON_HUD_TXT_1		"sprites/weapon_huntingsniper.txt"
#define WEAPON_HUD_TXT_2		"sprites/weapon_huntingsniper_scp.txt"
#define WEAPON_HUD_SPR_1		"sprites/weapon_huntingsniper.spr"
#define WEAPON_HUD_SPR_2		"sprites/ofch2.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_762experimental"

// Models
#define MODEL_WORLD			"models/weapon/w_remm4.mdl"
#define MODEL_VIEW			"models/weapon/v_remm4.mdl"
#define MODEL_PLAYER			"models/weapon/p_remm4.mdl"
#define MODEL_CLIP			"models/weapon/w_remm4clip.mdl"

// Sounds
#define SOUND_FIRE			"weapons/remm4/sniper_fire.wav"
#define SOUND_ZOOM			"weapons/remm4/sniper_zoom.wav"
#define SOUND_BOLT_1			"weapons/remm4/sniper_bolt1.wav"
#define SOUND_RELOAD_1			"weapons/remm4/sniper_reload_first_seq.wav"

// Animation
#define ANIM_EXTENSION			"gauss"

enum _:Animation
{
	ANIM_DRAW = 0,
	ANIM_SLOWIDLE,
	ANIM_FIRE,
	ANIM_FIRELASTROUND,
	ANIM_RELOAD,
	ANIM_RELOAD2,
	ANIM_RELOAD3,
	ANIM_SLOWIDLEEMPTY,
	ANIM_HOLSTER
};

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
	PRECACHE_SOUND(SOUND_ZOOM);
	PRECACHE_SOUND(SOUND_BOLT_1);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	
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
	
	new iREMM4 = wpnmod_register_weapon
	
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
	
	new iAmmo762experimental = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_Spawn, "REMM4_Spawn");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_Deploy, "REMM4_Deploy");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_Idle, "REMM4_Idle");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_PrimaryAttack, "REMM4_PrimaryAttack");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_SecondaryAttack, "REMM4_SecondaryAttack");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_Reload, "REMM4_Reload");
	wpnmod_register_weapon_forward(iREMM4, Fwd_Wpn_Holster, "REMM4_Holster");
	
	wpnmod_register_ammobox_forward(iAmmo762experimental, Fwd_Ammo_Spawn, "Ammo762experimental_Spawn");
	wpnmod_register_ammobox_forward(iAmmo762experimental, Fwd_Ammo_AddAmmo, "Ammo762experimental_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public REMM4_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);

	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public REMM4_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public REMM4_Holster(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		REMM4_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public REMM4_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, iClip ? ANIM_SLOWIDLE : ANIM_SLOWIDLEEMPTY);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public REMM4_PrimaryAttack(const iItem, const iPlayer, iClip)
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
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.08001);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_send_weapon_anim(iItem, iClip ? ANIM_FIRE : ANIM_FIRELASTROUND);
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		Float: {0.0001, 0.0001, 0.0001}, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		0
	);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-25.0, 0.0, 0.0});
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public REMM4_SecondaryAttack(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_sniperrifle", 0.0);
		
	}
	else if (flFov != 20.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_sniperrifle_scp", 20.0);
	}
	
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}

MakeZoom(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	set_pev(iPlayer, pev_fov, flFov);
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public REMM4_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		REMM4_SecondaryAttack(iItem, iPlayer);
	}
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.83);

	wpnmod_set_think(iItem, "REMM4_CompleteReload");
	set_pev(iItem, pev_nextthink, get_gametime() + 2.3);
}

//**********************************************
//* Called to send 2-nd part of reload anim.   *
//**********************************************

public REMM4_CompleteReload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, ANIM_RELOAD2);
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public Ammo762experimental_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public Ammo762experimental_AddAmmo(const iItem, const iPlayer)
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
