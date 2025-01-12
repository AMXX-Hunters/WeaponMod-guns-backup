/*
*	Weapon:KSG-12
*	Author:BIGs & X - RaY
*	
*	Thanks - Lev
*
*	Community HL-HEV | All For Half-Life [https://hl-hev.ru/]
*/
#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta_util>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN "Kel-Tec Shotgun"
#define VERSION "1.0.0"
#define AUTHOR "BIGs"


//Configs
#define WEAPON_NAME "weapon_ksg12"
#define WEAPON_SLOT	2
#define WEAPON_POSITION	1
#define WEAPON_PRIMARY_AMMO	"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX	125
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP	14
#define WEAPON_DEFAULT_AMMO	 125
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	10
#define WEAPON_DAMAGE	15.0

// Models
#define MODEL_WORLD	"models/w_ksg12.mdl"
#define MODEL_VIEW	"models/v_ksg12.mdl"
#define MODEL_PLAYER	"models/p_ksg12.mdl"


// Hud
#define WEAPON_HUD_TXT		"sprites/weapon_ksg12.txt"
#define WEAPON_HUD_CR		"sprites/640hud7.spr"
#define WEAPON_HUD_BAR		"sprites/640hud57.spr"
#define WEAPON_HUD_BAR_2	"sprites/640hud58.spr"


// Sounds
#define SOUND_FIRE	"weapons/hl-hev/ksg12.wav"
#define SOUND_REL_1 	"weapons/hl-hev/ksg12_after_reload.wav"
#define SOUND_REL_2 	"weapons/hl-hev/ksg12_start_reload.wav"
#define SOUND_DEPLOY "weapons/hl-hev/ksg12_insert.wav"

// Animation
#define ANIM_EXTENSION	"shotgun"
	
#define Offset_Mod Offset_iuser1

enum _:cz_VUL
{
	idle,
	shoot1,
	shoot2,
	insert,
	after_reload,
	start_reload,
	draw
}; 

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new KSG = wpnmod_register_weapon
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
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Spawn, 		"KSG_Spawn" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Deploy, 		"KSG_Deploy" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Idle, 		"KSG_Idle" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_PrimaryAttack,	"KSG_PrimaryAttack" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_SecondaryAttack,	"KSG_SecondaryAttack" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Reload, 		"KSG_Reload" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Holster, 		"KSG_Holster" );
}
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);

	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_REL_1);
	PRECACHE_SOUND(SOUND_REL_2);
	PRECACHE_SOUND(SOUND_DEPLOY);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
	PRECACHE_GENERIC(WEAPON_HUD_BAR_2);
	PRECACHE_GENERIC(WEAPON_HUD_CR);
}
public KSG_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public KSG_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.0);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack,2.0);	
	
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_REL_1, 0.9, ATTN_NORM, 0, PITCH_NORM);
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public KSG_Holster(const iItem ,iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
public KSG_Idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	//wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
	
	new fInSpecialReload = wpnmod_get_offset_int( iItem, Offset_iInSpecialReload );
	
	if( !iClip && !fInSpecialReload && iAmmo )
	{
		KSG_Reload( iItem, iPlayer, iClip, iAmmo );
	}
	else if( fInSpecialReload != 0)
	{
		if( iClip != WEAPON_MAX_CLIP && iAmmo)
		{
			KSG_Reload( iItem, iPlayer, iClip, iAmmo );
		}
		else
		{
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_REL_1, 0.9, ATTN_NORM, 0, PITCH_NORM);
			wpnmod_send_weapon_anim( iItem, after_reload);
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
		}
	}
}
public KSG_Reload(const iItem, const iPlayer, const iClip, const iAmmo )
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	switch (wpnmod_get_offset_int(iItem, Offset_iInSpecialReload))
	{
		case 0:
		{
			wpnmod_send_weapon_anim( iItem, start_reload);
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
			wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
		}
		case 1:
		{
			if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
				return;
				
			// was waiting for gun to move to side
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 2 );
			
			wpnmod_send_weapon_anim( iItem, insert);
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
		}
		default:
		{
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_DEPLOY, 0.9, ATTN_NORM, 0, PITCH_NORM);
			wpnmod_set_offset_int( iItem, Offset_iClip, iClip + 1 );
			wpnmod_set_player_ammo( iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - 1 );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
		}
	}

}
public KSG_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
		
		wpnmod_send_weapon_anim( iItem,shoot2);
			
		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			10, 
			VECTOR_CONE_1DEGREES, 
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_BULLET, 
			1
		);
		
		set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
		set_pev(iPlayer, pev_punchangle, Float: {-3.0, 0.0, 0.0});
	}else{	
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
		
		wpnmod_send_weapon_anim( iItem,shoot1);

		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			10, 
			VECTOR_CONE_10DEGREES, 
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_BULLET, 
			10
		);
		
		set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
		set_pev(iPlayer, pev_punchangle, Float: {-1.4, 0.0, 0.0});
	}
}
public KSG_SecondaryAttack(const iItem, const iPlayer)
{
	new iMod = wpnmod_get_offset_int(iItem, Offset_Mod);	

	wpnmod_set_offset_int(iItem, Offset_Mod, !iMod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.9);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.9);
	
	if(wpnmod_get_offset_int(iItem, Offset_Mod))
	{
		client_print( iPlayer, print_center, "Type : BuckShot Ammo");
	}else{
		client_print( iPlayer, print_center, "Type : Slugs Ammo" );
	}
}
