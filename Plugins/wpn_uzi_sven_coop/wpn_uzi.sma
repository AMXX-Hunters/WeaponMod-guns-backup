#pragma semicolon 1

#include <amxmodx>
#include <hl_wpnmod>

#define PLUGIN "Uzi"
#define VERSION "1.0"
#define AUTHOR "X-RaY" //Modif by BIGs


// Weapon settings
#define WEAPON_NAME "weapon_uzi"
#define WEAPON_SLOT	2
#define WEAPON_POSITION	3
#define WEAPON_PRIMARY_AMMO	"9mm"
#define WEAPON_PRIMARY_AMMO_MAX	10
#define WEAPON_SECONDARY_AMMO	"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP	30
#define WEAPON_DEFAULT_AMMO	 200
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	20
#define WEAPON_DAMAGE	38.6

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_uzi.txt"
#define WEAPON_HUD_SPR	"sprites/640hudsc.spr"

// Models
#define MODEL_WORLD	"models/w_uzi.mdl"
#define MODEL_VIEW	"models/v_uzi.mdl"
#define MODEL_PLAYER	"models/p_uzi.mdl"

// Sounds
#define SOUND_FIRE	"weapons/uzi/shoot1.wav"
#define SOUND_FIRE_0	 "weapons/uzi/shoot2.wav"
#define SOUND_FIRE_1 	"weapons/uzi/shoot3.wav"
#define SOUND_RELOAD	"weapons/uzi/reload1.wav"
#define SOUND_RELOAD_0	"weapons/uzi/reload2.wav"
#define SOUND_RELOAD_1	"weapons/uzi/reload3.wav"
#define SOUND_DEPLOY "weapons/uzi/deploy.wav"

// Animation
#define ANIM_EXTENSION	"python"

// Animation Sequence
enum _:eUzi
{
	UZI_IDLE_1 = 0,
	UZI_IDLE_2,
	UZI_IDLE_3,
	UZI_RELOAD,
	UZI_DRAW,
	UZI_SHOOT
}; 

//**********************************************
//* Precache resources *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);

	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_RELOAD_0);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE_0);
	PRECACHE_SOUND(SOUND_FIRE_1);
	PRECACHE_SOUND(SOUND_DEPLOY);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
}
//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iUzi = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_Spawn, 		"UZI_Spawn" );
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_Deploy, 		"UZI_Deploy" );
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_Idle, 		"UZI_Idle" );
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_PrimaryAttack,	"UZI_PrimaryAttack" );
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_Reload, 		"UZI_Reload" );
	wpnmod_register_weapon_forward(iUzi, Fwd_Wpn_Holster, 		"UZI_Holster" );
}
//**********************************************
//* Weapon spawn.                              *
//**********************************************

public UZI_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public UZI_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);

	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, UZI_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public UZI_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public UZI_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, UZI_IDLE_1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
}



//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public UZI_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, UZI_RELOAD, 3.3);
}
//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public UZI_PrimaryAttack(const iItem, const iPlayer, iClip)
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
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, UZI_SHOOT);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_6DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
			
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-4.0, 0.0, 0.0});
}
