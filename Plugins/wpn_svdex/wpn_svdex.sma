#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "[Weapon Mod : SVDex]"
#define VERSION "0.9"
#define AUTHOR "[Grenade - NiHiLaNTh]"


// Weapon settings
#define WEAPON_NAME 			"weapon_svdex"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"9.56"
#define WEAPON_PRIMARY_AMMO_MAX		100
#define WEAPON_SECONDARY_AMMO		"ARgrenades"
#define WEAPON_SECONDARY_AMMO_MAX	10
#define WEAPON_MAX_CLIP			20
#define WEAPON_DEFAULT_AMMO		20
#define WEAPON_FLAGS			4
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			30.0
#define GRENADE_DAMAGE			70.0

// Hud
#define WEAPON_HUD_SPR		        "sprites/cso/640hud41.spr"
#define WEAPON_HUD_SPR_2		"sprites/cso/640hud42.spr"
#define WEAPON_HUD_SPR_3		"sprites/cso/640hud7.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_svdex.txt"

// Models
#define MODEL_WORLD			"models/weapons/w_svdex.mdl"
#define MODEL_VIEW			"models/weapons/v_svdex.mdl"
#define MODEL_PLAYER			"models/weapons/p_svdex.mdl"
#define MODEL_SHELL			"models/weapons/shell762.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/svdex-1.wav"
#define SOUND_SHOOT_MOD                 "weapons/svdex-2.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation_svdex
{
	ANIM_IDLE,
        ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
        MOD_IDLE,
	MOD_SHOOT_1,
	MOD_SHOOT_2,
        MOD_DRAW,
        MOD_START,
        MOD_END
};

#define Offset_Mod Offset_iuser1

#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)

#define GRENADE_VELOCITY		1500
#define GRENADE_CLASSNAME		"grenade"

new g_iszGrenadeClassName;

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
        PRECACHE_SOUND(SOUND_SHOOT_MOD);

        PRECACHE_SOUND("weapons/svdex-clipin.wav");
        PRECACHE_SOUND("weapons/svdex-clipon.wav");
        PRECACHE_SOUND("weapons/svdex-clipout.wav");

        PRECACHE_SOUND("weapons/svdex-foley1.wav");
        PRECACHE_SOUND("weapons/svdex-foley2.wav");
        PRECACHE_SOUND("weapons/svdex-foley3.wav");
        PRECACHE_SOUND("weapons/svdex-foley4.wav");
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
        PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
        PRECACHE_GENERIC(WEAPON_HUD_SPR_3);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);

        g_iszGrenadeClassName = engfunc(EngFunc_AllocString, GRENADE_CLASSNAME);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new isvdex = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_Spawn, "svdex_Spawn");
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_Deploy, "svdex_Deploy");
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_Idle, "svdex_Idle");
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_PrimaryAttack, "svdex_PrimaryAttack");
        wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_SecondaryAttack, "svdex_SecondaryAttack");
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_Reload, "svdex_Reload");
	wpnmod_register_weapon_forward(isvdex, Fwd_Wpn_Holster, "svdex_Holster");
}


public svdex_Spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}


public svdex_Deploy(const iItem, const iPlayer, const iClip)
{
	if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, MOD_DRAW, ANIM_EXTENSION);
        }
        else
        {
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
        }

        return; 
}

public svdex_Holster(const iItem, const iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}


public svdex_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
        if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_send_weapon_anim(iItem, MOD_IDLE); 
        }
        else
        {
        wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
        }

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public svdex_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
        if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{

        if(wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) <= 0)
        return;       
    
        Grenade_Fire(iItem, iPlayer, false, iClip);

        }
        else
        {
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.6);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT);
	
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
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	
	vecPunchangle[0] = random_float(-1.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
        }
}

public svdex_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP || wpnmod_get_offset_int(iItem, Offset_Mod))
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.4);
}

public svdex_SecondaryAttack(const iItem, const iPlayer)
{
	new Mod = wpnmod_get_offset_int(iItem, Offset_Mod);
	
	wpnmod_set_offset_int(iItem, Offset_Mod, !Mod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.0);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 2.0);
	wpnmod_send_weapon_anim(iItem, Mod ? MOD_END : MOD_START);
}

Grenade_Fire(const iItem, const iPlayer, const iToss, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.15);
		return;
	}
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_send_weapon_anim(iItem, MOD_SHOOT_1);
	
        wpnmod_set_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO, wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) - 1);

	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.8);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 2.8);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, (iClip != 0) ? 5.0 : 0.75);
	
	set_pev(iPlayer, pev_punchangle, Float:{ -7.0, -0.0, 0.0 });
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT_MOD, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	velocity_by_aim(iPlayer, GRENADE_VELOCITY, vecVelocity);
	wpnmod_get_gun_position(iPlayer, vecOrigin, .flUpScale = -2.0);
	
	if (iToss)
	{
		state stTimedGrenade;
	}
	else
	{
		state stContactGrenade;
	}
	
	LaunchGrenade(iPlayer, vecOrigin, vecVelocity);
}

LaunchGrenade(const iPlayer, const Float: vecOrigin[3], const Float: vecVelocity[3]) <stContactGrenade>
{
	new iGrenade = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity);
	
	if (pev_valid(iGrenade))
	{
		set_pev(iGrenade, pev_dmg, GRENADE_DAMAGE);
		set_pev_string(iGrenade, pev_classname, g_iszGrenadeClassName);
	}
}

LaunchGrenade(const iPlayer, const Float: vecOrigin[3], const Float: vecVelocity[3]) <stTimedGrenade>
{
	new iGrenade = wpnmod_fire_timed_grenade(iPlayer, vecOrigin, vecVelocity);
		
	if (pev_valid(iGrenade))
	{
		set_pev(iGrenade, pev_dmg, GRENADE_DAMAGE);
		set_pev(iGrenade, pev_avelocity, Float: {300.0, 300.0, 300.0});
		set_pev_string(iGrenade, pev_classname, g_iszGrenadeClassName);
			
		SET_MODEL(iGrenade, "models/grenade.mdl");
		SET_SIZE(iGrenade, Float: {-4.0, -4.0, -4.0}, Float: {4.0, 4.0, 4.0});
	}
}