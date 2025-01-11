#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

#pragma semicolon 1

#define PLUGIN "Weapon : Paladin"
#define VERSION "1.0.0"
#define AUTHOR "BIGs"

//Configs
#define WEAPON_NAME 			"weapon_paladin"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			2
#define WEAPON_PRIMARY_AMMO		"7.65"
#define WEAPON_PRIMARY_AMMO_MAX		90
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO	 	90
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			20
#define WEAPON_DAMAGE			20.0
#define WEAPON_DAMAGE_SECONDARY		60.0

// Models
#define MODEL_WORLD	"models/hl-hev/paladin/w_paladin.mdl"
#define MODEL_VIEW	"models/hl-hev/paladin/v_paladin.mdl"
#define MODEL_PLAYER	"models/hl-hev/paladin/p_paladin.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_paladin.txt"
#define WEAPON_HUD_BAR	"sprites/weapon_paladin.spr"
#define WEAPON_AMMO	"sprites/640hud7.spr"
#define WEAPON_BALL	"sprites/paladin_ball.spr"


// Sounds
#define SOUND_FIRE	"weapons/hl-hev/paladin/shoot.wav"
#define SOUND_FIRE_2	"weapons/hl-hev/paladin/shoot2.wav"
#define SOUND_IDLE 	"weapons/hl-hev/paladin/idle.wav"
#define SOUND_RELOAD "weapons/hl-hev/paladin/reload.wav"

// Animation
#define ANIM_EXTENSION	"mp5"

enum _:cz_VUL
{
	idle1,
	reload,
	draw,
	shoot1,
	shoot2,
	shoot3
};
 
new p_ball;


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new AK = wpnmod_register_weapon
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
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_Spawn, 		"AK_Spawn" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_Deploy, 		"AK_Deploy" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_Idle, 		"AK_Idle" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_PrimaryAttack,	"AK_PrimaryAttack" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_SecondaryAttack,	"AK_SecondaryAttack" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_Reload, 		"AK_Reload" );
	wpnmod_register_weapon_forward(AK, Fwd_Wpn_Holster, 		"AK_Holster" );
	
}
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE_2);
	PRECACHE_SOUND(SOUND_IDLE);
	PRECACHE_SOUND(SOUND_RELOAD);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
	PRECACHE_GENERIC(WEAPON_AMMO);
	p_ball = precache_model(WEAPON_BALL);
}
public AK_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public AK_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public AK_Holster(const iItem ,iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
public AK_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	wpnmod_send_weapon_anim(iItem, idle1);
	
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}
public AK_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, reload, 2.8);
}
public AK_PrimaryAttack(const iItem, const iPlayer, iClip)
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
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle,3.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, shoot1);
	
	//Random Recoil
	new Float:Vectors[3];
	Vectors[0] = random_float(0.00873 , 0.02618);
	Vectors[1] = random_float(0.00873 , 0.02618);
	Vectors[2] = random_float(0.00873 , 0.02618);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		Vectors, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_MORTAR, 
		1
	);
				
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	new Float:x = random_float(-2.0 , 2.0);
	new Float:y = random_float(-2.0 , 2.0);
	new Float:z = random_float(-2.0 , 2.0);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, x,y,z);
}
public AK_SecondaryAttack(const iItem, const iPlayer, iClip)
{
	if(iClip  >= 5)
	{
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 5);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.7);
		wpnmod_send_weapon_anim(iItem, shoot2);
		
		new Float:aOrigin[3];
		
		new TE_FLAG;
		TE_FLAG |= TE_EXPLFLAG_NODLIGHTS;
		TE_FLAG |= TE_EXPLFLAG_NOSOUND;
		TE_FLAG |= TE_EXPLFLAG_NOPARTICLES;
		
		fm_get_aim_origin(iPlayer , aOrigin);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, aOrigin[0]);
		engfunc(EngFunc_WriteCoord, aOrigin[1]);
		engfunc(EngFunc_WriteCoord, aOrigin[2]+30.0);
		write_short(p_ball);
		write_byte(10);
		write_byte(30);
		write_byte(TE_FLAG);
		message_end();
		
		
		new a = FM_NULLENT;
		while((a = find_ent_in_sphere(a, aOrigin, 60.0)) != 0)
		{
			if(pev(a, pev_takedamage) != DAMAGE_NO)
			{
				ExecuteHamB(Ham_TakeDamage, a, iPlayer, iPlayer, WEAPON_DAMAGE_SECONDARY, DMG_ENERGYBEAM);
			}
		}	
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE_2, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
}
