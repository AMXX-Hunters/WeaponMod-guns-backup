#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <fakemeta_util>


#define PLUGIN "HL: Electric Guitar"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_eguitar"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"Doremi"
#define WEAPON_PRIMARY_AMMO_MAX		140
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			35
#define WEAPON_DEFAULT_AMMO		35
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			25
#define WEAPON_DAMAGE			19.0

// Hud
#define WEAPON_HUD_SPR			"sprites/weapon_eguitar.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_eguitar.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_Eguitarclip"

// Models
#define MODEL_WORLD			"models/w_eguitar.mdl"
#define MODEL_VIEW			"models/v_eguitar.mdl"
#define MODEL_CLIP			"models/w_eguitarclip.mdl"
#define MODEL_PLAYER			"models/p_eguitar.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/gt-1.wav"

// Animation
#define ANIM_EXTENSION_1		"mp5"

enum _:Animation
{
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT,
	ANIM_SHOOT2,	
	ANIM_SHOOT3
	

};

//**********************************************
	
#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iEGT = wpnmod_register_weapon
	
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
	
	new iAmmoEguitar = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_Spawn, "EGT_Spawn");
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_Deploy, "EGT_Deploy");
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_Idle, "EGT_Idle");
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_PrimaryAttack, "EGT_PrimaryAttack");
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_Reload, "EGT_Reload");
	wpnmod_register_weapon_forward(iEGT, Fwd_Wpn_Holster, "EGT_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoEguitar, Fwd_Ammo_Spawn, "AmmoEguitar_Spawn");
	wpnmod_register_ammobox_forward(iAmmoEguitar, Fwd_Ammo_AddAmmo, "AmmoEguitar_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public EGT_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public EGT_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION_1);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public EGT_Holster(const iItem, const iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public EGT_Idle(const iItem)
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

public EGT_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	new iUserArmor = get_user_armor(iPlayer);
	static Float: vecPunchangle[3];
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.091);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.130000001);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.115);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);	
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_SHOOT, ANIM_SHOOT2));
	
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
		6
	);
	
	
	vecPunchangle[0] = random_float(-2.0, 0.0);
	set_pev(iPlayer, pev_punchangle, float: {-2.5, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	if(iUserArmor<=100)
		{
		wpnmod_set_think(iItem, "Stage1_Recharge");
		set_pev(iItem, pev_nextthink, get_gametime() +0.000001);
		}
	if(iUserArmor<200 && iUserArmor>=101)
		{
		wpnmod_set_think(iItem, "Stage2_Recharge");
		set_pev(iItem, pev_nextthink, get_gametime() +0.000001);
		}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************
public EGT_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.65);
	wpnmod_set_think(iItem, "Egt_CompleteReload");
	
	set_pev(iItem, pev_nextthink, get_gametime() + 0.000000001);
	set_pev(iItem, pev_body, 0);
}

//**********************************************
//* Called to send 2-nd part of reload anim.   *
//**********************************************

public Egt_CompleteReload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, ANIM_RELOAD);
}

//**********************************************
//* Called to send 1st Think of Primary Attack *
//**********************************************
public Stage1_Recharge(const iItem, const iPlayer, const iClip)
{
new iUserArmor = get_user_armor(iPlayer);
fm_set_user_armor(iPlayer, iUserArmor + 3);
}
//**********************************************
//* Called to send 2nd Think of Primary Attack *
//**********************************************
public Stage2_Recharge(const iItem, const iPlayer, const iClip)
{
new iUserArmor = get_user_armor(iPlayer);
fm_set_user_armor(iPlayer, iUserArmor + 1);
}

public AmmoEguitar_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoEguitar_AddAmmo(const iItem, const iPlayer)
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
