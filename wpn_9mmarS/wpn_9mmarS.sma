/* AMX Mod X
*	9mm SMG : SCOPED!!.
*
* 
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <hamsandwich>

//=========================== Some stuff from hl_wpnmod.inc ========================================

#define SET_MODEL(%0,%1) engfunc(EngFunc_SetModel, %0, %1)
#define PRECACHE_MODEL(%0) engfunc(EngFunc_PrecacheModel,%0)
#define PRECACHE_SOUND(%0) engfunc(EngFunc_PrecacheSound,%0)
#define PRECACHE_GENERIC(%0) engfunc(EngFunc_PrecacheGeneric,%0)

#define VECTOR_CONE_5DEGREES			Float:{ 0.0252, 0.0252, 0.0252 }
#define VECTOR_CONE_9DEGREES			Float:{ 0.00046, 0.00046, 0.00046 }

#define LOUD_GUN_VOLUME					1000
#define NORMAL_GUN_VOLUME				600
#define QUIET_GUN_VOLUME				200

#define	BRIGHT_GUN_FLASH				512
#define NORMAL_GUN_FLASH				256
#define	DIM_GUN_FLASH					128

enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1,
};

enum e_AmmoFwds
{
	Fwd_Ammo_Spawn,
	Fwd_Ammo_AddAmmo,

	Fwd_Ammo_End
};

enum e_WpnFwds
{
	Fwd_Wpn_Spawn,
	Fwd_Wpn_CanDeploy,
	Fwd_Wpn_Deploy,
	Fwd_Wpn_Idle,
	Fwd_Wpn_PrimaryAttack,
	Fwd_Wpn_SecondaryAttack,
	Fwd_Wpn_Reload,
	Fwd_Wpn_CanHolster,
	Fwd_Wpn_Holster,
	Fwd_Wpn_IsUseable,

	Fwd_Wpn_End
};

enum e_Offsets
{
	// Weapon
	Offset_flStartThrow,
	Offset_flReleaseThrow,
	Offset_iChargeReady,
	Offset_iInAttack,
	Offset_iFireState,
	Offset_iFireOnEmpty,				// True when the gun is empty and the player is still holding down the attack key(s)
	Offset_flPumpTime,
	Offset_iInSpecialReload,			// Are we in the middle of a reload for the shotguns
	Offset_flNextPrimaryAttack,			// Soonest time ItemPostFrame will call PrimaryAttack
	Offset_flNextSecondaryAttack,		// Soonest time ItemPostFrame will call SecondaryAttack
	Offset_flTimeWeaponIdle,			// Soonest time ItemPostFrame will call WeaponIdle
	Offset_iPrimaryAmmoType,			// "Primary" ammo index into players m_rgAmmo[]
	Offset_iSecondaryAmmoType,			// "Secondary" ammo index into players m_rgAmmo[]
	Offset_iClip,						// Number of shots left in the primary weapon clip, -1 it not used
	Offset_iInReload,					// Are we in the middle of a reload;
	Offset_iDefaultAmmo,				// How much ammo you get when you pick up this weapon as placed by a level designer.
	Offset_iInZoom,
	Offset_iFOV,
	Offset_iuser1,
	// Player
	Offset_flNextAttack,				// Cannot attack again until this time
	Offset_iWeaponVolume,				// How loud the player's weapon is right now
	Offset_iWeaponFlash,				// Brightness of the weapon flash
	
	Offset_End
};

native wpnmod_register_weapon(const szName[], const iSlot, const iPosition, const szAmmo1[], const iMaxAmmo1, const szAmmo2[], const iMaxAmmo2, const iMaxClip, const iFlags, const iWeight);
native wpnmod_register_weapon_forward(const iWeaponID, const e_WpnFwds: iForward, const szCallBack[]);
native wpnmod_register_ammobox(const szClassname[]);				
native wpnmod_register_ammobox_forward(const iWeaponID, const e_AmmoFwds: iForward, const szCallBack[]);	
native wpnmod_set_offset_int(const iEntity, const e_Offsets: iOffset, const iValue);
native wpnmod_set_offset_float(const iEntity, const e_Offsets: iOffset, const Float: flValue);
native wpnmod_get_offset_int(const iEntity, const e_Offsets: iOffset);
native Float: wpnmod_get_offset_float(const iEntity, const e_Offsets: iOffset);
native wpnmod_default_deploy(const iItem, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[]);
native wpnmod_default_reload(const iItem, const iClipSize, const iAnim, const Float: flDelay);
native wpnmod_fire_bullets(const iPlayer, const iAttacker, const iShotsCount, const Float: vecSpread[3], const Float: flDistance, const Float: flDamage, const bitsDamageType, const iTracerFreq);
native wpnmod_eject_brass(const iPlayer, const iShellModelIndex, const iSoundtype, const Float: flForwardScale, const Float: flUpScale, const Float: flRightScale);
native wpnmod_reset_empty_sound(const iItem);
native wpnmod_play_empty_sound(const iItem);
native wpnmod_send_weapon_anim(const iItem, const iAnim);
native wpnmod_set_player_anim(const iPlayer, const PLAYER_ANIM: iPlayerAnim);
native wpnmod_set_think(const iItem, const szCallBack[]);	

				
//==================================================================================================


#define PLUGIN "9MM SMG : SCOPED"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_9mmarS"
#define WEAPON_NAME_SCOPED 		"weapon_9mmars_scp"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"9mm"
#define WEAPON_PRIMARY_AMMO_MAX		250
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			35
#define WEAPON_DEFAULT_AMMO		35
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			12.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_9mmarS.txt"
#define WEAPON_HUD_SPR			"sprites/640hudsc2.spr"
#define WEAPON_HUD_TXT_2		"sprites/weapon_9mmarS.txt"
#define WEAPON_HUD_SPR_2		"sprites/640hudsc2.spr"

// Sounds
#define SOUND_FIRE_1			"weapons/hks1.wav"
#define SOUND_FIRE_2			"weapons/hks1.wav"
#define SOUND_FIRE_3			"weapons/hks1.wav"
#define SOUND_RELOAD_1			"weapons/cliprelease1.wav"
#define SOUND_ZOOM			"weapons/sniper_zoom.wav"

// Models
#define MODEL_WORLD			"models/w_9mmarS.mdl"
#define MODEL_VIEW_SCOPE		"models/v_rpg7_scp.mdl"
#define MODEL_VIEW			"models/v_9mmarS.mdl"
#define MODEL_PLAYER			"models/p_9mmarS.mdl"
#define MODEL_SHELL			"models/shell.mdl"

#define Offset_iInZoom		Offset_iuser1
// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_SLOWIDLE = 0,
	ANIM_IDLE,
	ANIM_LAUNCH,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_FIRE_3
};

new g_iShell;

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_VIEW_SCOPE);
	
	PRECACHE_SOUND(SOUND_FIRE_1);
	PRECACHE_SOUND(SOUND_FIRE_2);
	PRECACHE_SOUND(SOUND_FIRE_3);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_ZOOM);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	
	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iMMARS = wpnmod_register_weapon
	
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
		
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_Spawn, "MMARS_Spawn");
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_Deploy, "MMARS_Deploy");
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_Idle, "MMARS_Idle");
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_PrimaryAttack, "MMARS_PrimaryAttack");
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_SecondaryAttack, "MMARS_SecondaryAttack");	
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_Reload, "MMARS_Reload");
	wpnmod_register_weapon_forward(iMMARS, Fwd_Wpn_Holster, "MMARS_Holster");
	
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public MMARS_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public MMARS_Deploy(const iItem, const iPlayer, const iClip)
{
	M249_CheckBodyGroup(iItem, iClip);
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public MMARS_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MMARS_SecondaryAttack(iItem, iPlayer);
	}
		
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public MMARS_Idle(const iItem, const iPlayer, const iClip)
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

public MMARS_PrimaryAttack(const iItem, const iPlayer, iClip)
{	
	static aszFireSounds[][] = { SOUND_FIRE_1, SOUND_FIRE_2, SOUND_FIRE_3 };
	static Float: vecPunchangle[3];
	
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
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_3));
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		pev(iPlayer, pev_flags) & FL_DUCKING ? (VECTOR_CONE_9DEGREES) : (VECTOR_CONE_5DEGREES),
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		2
	);
	
	emit_sound(iPlayer, CHAN_WEAPON, aszFireSounds[random(sizeof aszFireSounds)], 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 16.0, -18.0, 6.0);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	
	M249_CheckBodyGroup(iItem, iClip);

	vecPunchangle[0] = random_float(-1.5, 1.5);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public MMARS_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 1.95);
	wpnmod_set_think(iItem, "M249_CompleteReload");
	
	set_pev(iItem, pev_nextthink, get_gametime() +0.01);
	set_pev(iItem, pev_body, 0);
}

//**********************************************
//* Called to send 2-nd part of reload anim.   *
//**********************************************

public M249_CompleteReload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, ANIM_RELOAD);
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

public MMARS_SecondaryAttack(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 0.0);	
	}
	else
	{
		MakeZoom(iItem, iPlayer, MODEL_VIEW, 20.0);
	}
	
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}

MakeZoom(const iItem, const iPlayer, const szViewModel[], const Float: flFov)
{
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
	wpnmod_set_offset_int(iItem, Offset_iInZoom, flFov != 0.0);
		}

