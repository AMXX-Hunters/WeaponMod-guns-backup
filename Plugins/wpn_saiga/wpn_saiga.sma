#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#pragma semicolon 1
#pragma ctrlchar  '\'
#define PLUGIN "Saiga"
#define VERSION "1.0.0"
#define AUTHOR "BIGs"

//Configs
#define WEAPON_NAME "weapon_saiga"
#define WEAPON_SLOT	2
#define WEAPON_POSITION	5
#define WEAPON_PRIMARY_AMMO	"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX	50
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	0
#define WEAPON_MAX_CLIP	7
#define WEAPON_DEFAULT_AMMO	 50
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	20
#define WEAPON_DAMAGE	25.0
#define WEAPON_RATE_OF_FIRE	0.4
// Models
#define MODEL_WORLD	"models/w_saiga.mdl"
#define MODEL_VIEW	"models/v_saiga.mdl"
#define MODEL_PLAYER	"models/p_saiga.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_saiga.txt"
#define WEAPON_HUD_BAR	"sprites/weapon_saiga.spr"

// Sounds
#define SOUND_FIRE	"weapons/saiga_shoot1.wav"
#define SOUND_RELOAD	"weapons/saiga_clipout.wav"
#define SOUND_DEPLOY "weapons/saiga_zatvor.wav"

// Animation
#define ANIM_EXTENSION	"shotgun"

public plugin_init() 
{
	register_plugin(
	
	PLUGIN,
	VERSION,
	AUTHOR
	);
	new saiga = wpnmod_register_weapon
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
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_Spawn, 		"S12_Spawn" );
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_Deploy, 		"S12_Deploy" );
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_Idle, 		"S12_Idle" );
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_PrimaryAttack,	"S12_PrimaryAttack" );
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_Reload, 		"S12_Reload" );
	wpnmod_register_weapon_forward(saiga, Fwd_Wpn_Holster, 		"S12_Holster" );
}
enum _:cz_VUL
{
	idle1,
	shoot1,
	shoot2,
	reload_1,
	reload_2,
	reload_3,
	draw,
	reload_4
}; 
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DEPLOY);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
	
}
public S12_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public S12_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_DEPLOY, 1.0, ATTN_NORM, 0, PITCH_NORM);
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public S12_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
public S12_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}

	wpnmod_send_weapon_anim(iItem, idle1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
}
public S12_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, reload_1,3.0);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, ATTN_NORM, 0, PITCH_NORM);
}
public S12_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
		return;
	}
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_fire_bullets(
	iPlayer,
	iPlayer,
	10,
	VECTOR_CONE_15DEGREES,
	3048.0,
	WEAPON_DAMAGE,
	DMG_BULLET,
	15
	);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, WEAPON_RATE_OF_FIRE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, shoot1);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
}
