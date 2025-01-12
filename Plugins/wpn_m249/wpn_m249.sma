/* AMX Mod X
*	M249: Squad Automatic Weapon.
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
#include <xs>


#define PLUGIN "M249: Squad Automatic Weapon"
#define VERSION "1.0a"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_m249"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"556"
#define WEAPON_PRIMARY_AMMO_MAX		200
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			50
#define WEAPON_DEFAULT_AMMO		50
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			15.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_m249.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_m249.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_556"

// Models
#define MODEL_WORLD			"models/w_saw.mdl"
#define MODEL_VIEW			"models/v_saw.mdl"
#define MODEL_PLAYER			"models/p_saw.mdl"
#define MODEL_CLIP			"models/w_saw_clip.mdl"
#define MODEL_SHELL			"models/saw_shell.mdl"
#define MODEL_LINK			"models/saw_link.mdl"

// Sounds
#define SOUND_FIRE_1			"weapons/saw_fire1.wav"
#define SOUND_FIRE_2			"weapons/saw_fire2.wav"
#define SOUND_FIRE_3			"weapons/saw_fire3.wav"
#define SOUND_RELOAD_1			"weapons/saw_reload.wav"
#define SOUND_RELOAD_2			"weapons/saw_reload2.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_SLOWIDLE = 0,
	ANIM_IDLE,
	ANIM_RELOAD_START,
	ANIM_RELOAD_END,
	ANIM_HOLSTER,
	ANIM_DRAW,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_FIRE_3
};

new g_iShell, g_iLink;

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_LINK);
	
	PRECACHE_SOUND(SOUND_FIRE_1);
	PRECACHE_SOUND(SOUND_FIRE_2);
	PRECACHE_SOUND(SOUND_FIRE_3);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_RELOAD_2);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
	g_iLink = PRECACHE_MODEL(MODEL_LINK);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iM249 = wpnmod_register_weapon
	
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
	
	new iAmmo556 = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_Spawn, "M249_Spawn");
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_Deploy, "M249_Deploy");
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_Idle, "M249_Idle");
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_PrimaryAttack, "M249_PrimaryAttack");
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_Reload, "M249_Reload");
	wpnmod_register_weapon_forward(iM249, Fwd_Wpn_Holster, "M249_Holster");
	
	wpnmod_register_ammobox_forward(iAmmo556, Fwd_Ammo_Spawn, "Ammo556_Spawn");
	wpnmod_register_ammobox_forward(iAmmo556, Fwd_Ammo_AddAmmo, "Ammo556_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public M249_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public M249_Deploy(const iItem, const iPlayer, const iClip)
{
	M249_CheckBodyGroup(iItem, iClip);
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public M249_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public M249_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	new iAnim;
	new Float: flNextIdle;
	
	if (random_float(0.0, 1.0) <= 0.75)
	{
		iAnim = ANIM_SLOWIDLE;
		flNextIdle = 5.0;
	}
	else 
	{
		iAnim = ANIM_IDLE;
		flNextIdle = 6.2;
	}
	
	M249_CheckBodyGroup(iItem, iClip);
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public M249_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	static Float: vecAngle[3];
	static Float: vecForward[3];
	static Float: vecVelocity[3];
	static Float: vecPunchangle[3];
	
	static aszFireSounds[][] = { SOUND_FIRE_1, SOUND_FIRE_2, SOUND_FIRE_3 };
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.067);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_3));
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		pev(iPlayer, pev_flags) & FL_DUCKING ? (VECTOR_CONE_5DEGREES) : (VECTOR_CONE_9DEGREES), 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		2
	);
	
	emit_sound(iPlayer, CHAN_WEAPON, aszFireSounds[random(sizeof aszFireSounds)], 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 16.0, -18.0, 6.0);
	
	if (iClip % 2)
	{
		wpnmod_eject_brass(iPlayer, g_iLink, 1, 16.0, -18.0, 6.0);
	}
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	
	M249_CheckBodyGroup(iItem, iClip);
	
	pev(iPlayer, pev_v_angle, vecAngle);
	pev(iPlayer, pev_velocity, vecVelocity);
	pev(iPlayer, pev_punchangle, vecPunchangle);
	
	xs_vec_add(vecAngle, vecPunchangle, vecPunchangle);
	engfunc(EngFunc_MakeVectors, vecPunchangle);
	
	global_get(glb_v_forward, vecForward);
	
	xs_vec_mul_scalar(vecForward, 35.0, vecPunchangle);
	xs_vec_sub(vecVelocity, vecPunchangle, vecVelocity);
	
	vecPunchangle[0] = random_float(-2.0, 2.0);
	vecPunchangle[1] = random_float(-2.0, 2.0);
	vecPunchangle[2] = 0.0;
	 
	set_pev(iPlayer, pev_velocity, vecVelocity);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public M249_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD_START, 4.1);
	wpnmod_set_think(iItem, "M249_CompleteReload");
	
	set_pev(iItem, pev_nextthink, get_gametime() + 1.52);
	set_pev(iItem, pev_body, 0);
}

//**********************************************
//* Called to send 2-nd part of reload anim.   *
//**********************************************

public M249_CompleteReload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, ANIM_RELOAD_END);
}

//**********************************************
//* Set weapon chain bodygroup.                *
//**********************************************

M249_CheckBodyGroup(const iItem, const iClip)
{
	if (!iClip)
	{
		set_pev(iItem, pev_body, 8);
		
	}
	else if (iClip < 9)
	{
		set_pev(iItem, pev_body, 9 - iClip);
	}
	else
	{
		set_pev(iItem, pev_body, 0);
	}
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public Ammo556_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public Ammo556_AddAmmo(const iItem, const iPlayer)
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
