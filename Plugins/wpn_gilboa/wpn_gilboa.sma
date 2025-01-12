/*
*	Community HL-HEV | All for Half-Life
*	Author : BIGs [hl-hev.ru]
*	Thanks :
*	Koshak [infotex58.ru] - Laser Dot
*/

#include <amxmodx>
#include <hl_wpnmod>
#include <xs>
#include <hamsandwich>
#pragma semicolon 1

#define PLUGIN "Gilboa"
#define VERSION "1.0.0"
#define AUTHOR "BIGs"

//Configs
#define WEAPON_NAME "weapon_gilboa"
#define WEAPON_SLOT	3
#define WEAPON_POSITION	3
#define WEAPON_PRIMARY_AMMO	"556"
#define WEAPON_PRIMARY_AMMO_MAX	180
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP	30
#define WEAPON_DEFAULT_AMMO	 180
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	20
#define WEAPON_DAMAGE	50.0

// Models
#define MODEL_WORLD	"models/w_gilboa.mdl"
#define MODEL_VIEW	"models/v_gilboa.mdl"
#define MODEL_PLAYER	"models/p_gilboa.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_gilboa.txt"
#define WEAPON_HUD_BAR	"sprites/640hud115.spr"
#define WEAPON_HUD_AMMO	"sprites/640hud116.spr"

// Sounds
#define SOUND_FIRE	"weapons/gilboa-1.wav"
#define SOUND_RELOAD	"weapons/gilboa_clipin1.wav"
#define SOUND_DEPLOY "weapons/deploy.wav"
#define SOUND_SIGHT			"weapons/desert_eagle_sight.wav"
#define SOUND_SIGHT_2			"weapons/desert_eagle_sight2.wav"

// Animation
#define ANIM_EXTENSION	"crossbow"

//Reaload
#define NO_RECOIL     Float:{ 0.01, 0.01, 0.01 }

#define Offset_pSpot Offset_iuser1
#define Offset_fSpotActive Offset_iuser2

#define SET_ORIGIN(%0,%1) engfunc(EngFunc_SetOrigin,%0,%1)

public plugin_init() {
	register_plugin(
	
		PLUGIN, 
		VERSION, 
		AUTHOR
	);
	
	new gilboa = wpnmod_register_weapon
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
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_Spawn, 		"GIL_Spawn" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_Deploy, 		"GIL_Deploy" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_Idle, 		"GIL_Idle" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_PrimaryAttack,	"GIL_PrimaryAttack" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_SecondaryAttack,	"GIL_SecondaryAttack" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_Reload, 		"GIL_Reload" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_Holster, 		"GIL_Holster" );
	wpnmod_register_weapon_forward(gilboa, Fwd_Wpn_ItemPostFrame, "Eagle_PostFrame");
}

enum _:g_GIL
{
	idle1,
	reload,
	draw,
	shoot1,
	shoot2
}; 
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DEPLOY);
	
	PRECACHE_SOUND(SOUND_SIGHT_2);
	PRECACHE_SOUND(SOUND_SIGHT);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
	PRECACHE_GENERIC(WEAPON_HUD_AMMO);
}
public Eagle_PostFrame(const iItem, const iPlayer)
{
	EagleSpot_Update(iItem, iPlayer);
}
public GIL_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public GIL_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.2);

	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw , ANIM_EXTENSION);
}
public GIL_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
public GIL_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}

	wpnmod_send_weapon_anim(iItem, idle1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 15.0);
}
public GIL_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	Eagle_LaserSpotSuspend(iItem,  1.7);
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, reload, 2.8);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, ATTN_NORM, 0, PITCH_NORM);
}
public GIL_PrimaryAttack(const iItem, const iPlayer, iClip)
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
		
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.10);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 15.0);
		
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
		
		new reload = random_num(0 ,1);
		switch(reload)
			{
				case 0 :
				{
					wpnmod_send_weapon_anim(iItem, shoot1);	
				}
				case 1 :
				{
					wpnmod_send_weapon_anim(iItem, shoot2);
				}
			}
		
		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			1, 
			NO_RECOIL, 
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_BULLET | DMG_NEVERGIB, 
			4
		);
				
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
		
		set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
		set_pev(iPlayer, pev_punchangle, Float: {-4.0, 0.0, 0.0});

}
public GIL_SecondaryAttack(iItem,iPlayer ,iClip)
{
	if (iClip <= 0)
	{
		return;
	}
	
	new iSpotActive = wpnmod_get_offset_int(iItem, Offset_fSpotActive);
		
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.5);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.0);
	wpnmod_set_offset_int(iItem, Offset_fSpotActive, !iSpotActive);
		
	if (!iSpotActive)
	{
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_SIGHT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		Eagle_LaserSpotDestroy(iItem);
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_SIGHT_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
}
//**********************************************
//* Create and spawn laser sight.              *
//**********************************************
EagleSpot_CreateSpot()
{
	new iEagleSpot;
	static iszAllocStringCached;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		iEagleSpot = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (pev_valid(iEagleSpot))
	{
		set_pev(iEagleSpot, pev_classname, "eagle_spot");
		
		set_pev(iEagleSpot, pev_movetype, MOVETYPE_NONE);
		set_pev(iEagleSpot, pev_solid, SOLID_NOT);
		set_pev(iEagleSpot, pev_scale, 0.5);
	
		set_pev(iEagleSpot, pev_rendermode, kRenderGlow);
		set_pev(iEagleSpot, pev_renderfx, kRenderFxNoDissipation);
		set_pev(iEagleSpot, pev_renderamt, 255.0);
		
		SET_MODEL(iEagleSpot, "sprites/laserdot.spr");
	}
	
	return iEagleSpot;
}

//**********************************************
//* Update laser sight position.               *
//**********************************************

EagleSpot_Update(const iItem, const iPlayer)
{
	static iSpotEntity;
	static iSpotActive;
	
	iSpotEntity = wpnmod_get_offset_int(iItem, Offset_pSpot);
	iSpotActive = wpnmod_get_offset_int(iItem, Offset_fSpotActive);
	
	if (iSpotActive)
	{
		if (!pev_valid(iSpotEntity))
		{
			wpnmod_set_offset_int(iItem, Offset_pSpot, (iSpotEntity = EagleSpot_CreateSpot()));
		}
		
		static iTrace;
		
		static Float: vecSrc[3];
		static Float: vecEnd[3];
		
		wpnmod_get_gun_position(iPlayer, vecSrc);
		global_get(glb_v_forward, vecEnd);
	
		xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd);
		xs_vec_add(vecSrc, vecEnd, vecEnd);
	
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, (iTrace = create_tr2()));
		
		get_tr2(iTrace, TR_vecEndPos, vecEnd);
		free_tr2(iTrace);
		
		SET_ORIGIN(iSpotEntity, vecEnd);
	}
}

//**********************************************
//* Remove laser sight.                        *
//**********************************************

Eagle_LaserSpotDestroy(const iItem)
{
	new iLaserSpot = wpnmod_get_offset_int(iItem, Offset_pSpot);
		
	if (pev_valid(iLaserSpot))
	{
		ExecuteHamB(Ham_Killed, iLaserSpot, 0, 0);
		wpnmod_set_offset_int(iItem, Offset_pSpot, FM_NULLENT);
	}
}

//**********************************************
//* Make the laser sight invisible.            *
//**********************************************

Eagle_LaserSpotSuspend(const iItem, const Float: flSuspendTime)
{
	new iLaserSpot = wpnmod_get_offset_int(iItem, Offset_pSpot);
		
	if (!pev_valid(iLaserSpot))
	{
		return;
	}
	
	wpnmod_set_think(iLaserSpot, "EagleSpot_Revive");
	
	set_pev(iLaserSpot, pev_effects, pev(iLaserSpot, pev_effects) | EF_NODRAW);
	set_pev(iLaserSpot, pev_nextthink, get_gametime() + flSuspendTime);
}

//**********************************************
//* Bring a suspended laser sight back.        *
//**********************************************

public EagleSpot_Revive(const iEagleSpot)
{
	set_pev(iEagleSpot, pev_effects, pev(iEagleSpot, pev_effects) & ~EF_NODRAW);
}
