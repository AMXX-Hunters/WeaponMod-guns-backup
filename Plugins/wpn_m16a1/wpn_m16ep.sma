/*
**************************************************
*	Community HL-HEV | All for Half-Life      
*						      
*	Plugin : [WeaponMod] Colt M16A1	      
*	Author : BIGs [https://hl-hev.ru]	      
*						      
*	Thanks : X-RaY 			      
*			-> HEV Model Hands	      
*		HL-HEV Team			      
*			-> Idea and resources	      
**************************************************
*/
#include <amxmodx>
#include <hl_wpnmod>

#define PLUGIN "Weapon : Colt M16"
#define VERSION "1.0.6"
#define AUTHOR "BIGs"

#pragma semicolon 1
#pragma ctrlchar  '\'

//Configs
#define WEAPON_NAME "weapon_m16a1ep"
#define WEAPON_SLOT	3
#define WEAPON_POSITION	5
#define WEAPON_PRIMARY_AMMO	"556"
#define WEAPON_PRIMARY_AMMO_MAX	200
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	0
#define WEAPON_MAX_CLIP	30
#define WEAPON_DEFAULT_AMMO	 200
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	20
#define WEAPON_DAMAGE	70.0

// Models
#define MODEL_WORLD	"models/hl-hev/m16a1/w_m16a1ep.mdl"
#define MODEL_VIEW	"models/hl-hev/m16a1/v_m16a1ep_hev.mdl"
#define MODEL_PLAYER	"models/hl-hev/m16a1/p_m16a1ep.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_m16a1ep.txt"
#define WEAPON_HUD_BAR	"sprites/640hud79.spr"

// Sounds
#define SOUND_FIRE	"weapons/hl-hev/m16a1/m16a1ep_shoot.wav"
#define SOUND_BOLTUP 	"weapons/hl-hev/m16a1/m16a1ep_boltpull.wav"
#define SOUND_RELOAD	"weapons/hl-hev/m16a1/m16a1ep_clipout.wav"
#define SOUND_DEPLOY "weapons/hl-hev/m16a1/m16a1ep_deploy.wav"
#define SOUND_CLIPIN "weapons/hl-hev/m16a1/m16a1ep_clipin.wav"

// Animation
#define ANIM_EXTENSION	"mp5"

#define Offset_Mod Offset_iuser1

enum _:cz_VUL
{
	idle1,
	shoot1,
	shoot2,
	reload,
	draw,
	shoot3,
	shoot4
}; 
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new M16 = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_Spawn, 		"M16_Spawn" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_Deploy, 		"M16_Deploy" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_Idle, 		"M16_Idle" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_PrimaryAttack,	"M16_PrimaryAttack" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_SecondaryAttack,	"M16_SecondaryAttack" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_Reload, 		"M16_Reload" );
	wpnmod_register_weapon_forward(M16, Fwd_Wpn_Holster, 		"M16_Holster" );
}
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_CLIPIN);
	PRECACHE_SOUND(SOUND_BOLTUP);
	PRECACHE_SOUND(SOUND_DEPLOY);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
}
public M16_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public M16_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_DEPLOY, 0.9, ATTN_NORM, 0, PITCH_NORM);

	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public M16_Holster(const iItem , iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	set_task(0.8 , "M16_SoundHolster" , iPlayer);
}
public M16_SoundHolster(iPlayer)
{
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}
public M16_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}

	wpnmod_send_weapon_anim(iItem, idle1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
}
public M16_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, reload, 4.0);
	//Clip out
	set_task(1.8 , "M16_Reload_Step1" , iPlayer);
	//Clip in
	set_task(3.0 , "M16_Reload_Step2" , iPlayer);
	//Boltup
	set_task(3.8 , "M16_Reload_Step1" , iPlayer);
}
public M16_Reload_Step1(iPlayer)
{
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 0.9, ATTN_NORM, 0, PITCH_NORM);
}
public M16_Reload_Step2(iPlayer)
{
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_CLIPIN, 0.9, ATTN_NORM, 0, PITCH_NORM);
}
public M16_Reload_Step3(iPlayer)
{
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_BOLTUP, 0.9, ATTN_NORM, 0, PITCH_NORM);
}
public M16_PrimaryAttack(const iItem, const iPlayer, iClip)
{
		if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
		{
			wpnmod_play_empty_sound(iItem);
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
			return;
		}
		
		if (wpnmod_get_offset_int(iItem, Offset_Mod))
		{
		
			wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
			wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
			wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
			
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.1);
			wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
			
			wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
			wpnmod_send_weapon_anim(iItem, shoot1);
			
			wpnmod_fire_bullets
			(
				iPlayer, 
				iPlayer, 
				1, 
				VECTOR_CONE_1DEGREES, 
				8192.0, 
				WEAPON_DAMAGE, 
				DMG_BULLET | DMG_NEVERGIB, 
				1
			);
					
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
			
			set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
			set_pev(iPlayer, pev_punchangle, Float: {-1.0, 0.0, 0.0});
			wpnmod_set_think(iItem,"Next_Attack");
			set_pev(iItem, pev_nextthink, get_gametime() + 0.08);
			set_pev(iItem, pev_body, 0);
		}else{
			wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
			wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
			wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
			
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
			wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
			
			wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
			wpnmod_send_weapon_anim(iItem, shoot2);
			
			wpnmod_fire_bullets
			(
				iPlayer, 
				iPlayer, 
				1, 
				VECTOR_CONE_1DEGREES, 
				8192.0, 
				WEAPON_DAMAGE, 
				DMG_BULLET | DMG_NEVERGIB, 
				1
			);
					
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
			
			set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
			set_pev(iPlayer, pev_punchangle, Float: {-1.0, 0.0, 0.0});
		}
}
public M16_SecondaryAttack(iItem,iPlayer ,iClip)
{
	new Mod = wpnmod_get_offset_int(iItem, Offset_Mod);
	
	wpnmod_set_offset_int(iItem, Offset_Mod, !Mod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.03);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.2);
	if(wpnmod_get_offset_int(iItem, Offset_Mod)){
		client_print( iPlayer, print_center, "Burst-Fire Mode");
	}else{
		client_print( iPlayer, print_center, "Automatic Mode" );
	}
}
public Next_Attack(const iItem, iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.6);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, shoot1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		1
	);
	set_pev(iPlayer, pev_punchangle, float: {-1.0, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	wpnmod_set_think(iItem, "Next_2ndAttack");
	set_pev(iItem, pev_nextthink, get_gametime() + 0.08);
	set_pev(iItem, pev_body, 0);
	}
}

public Next_2ndAttack(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.35);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, shoot1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		1
	);
	set_pev(iPlayer, pev_punchangle, float: {-1.0, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	}
}
