/* AMX Mod X
*	CREDITS TO THE DIAMOND TEAM FOR THE MODELS
*
*
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>


#define PLUGIN "MEDKIT"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_medkit"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"miracleseed"
#define WEAPON_PRIMARY_AMMO_MAX		100
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		20
#define WEAPON_FLAGS			ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_LIMITINWORLD
#define WEAPON_WEIGHT			-1

// Hud
#define WEAPON_HUD_SPR			"sprites/tfchud06.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_medkit.txt"

// Models
#define MODEL_WORLD			"models/w_pmedkit.mdl"
#define MODEL_VIEW			"models/v_medkit.mdl"
#define MODEL_PLAYER			"models/p_medkit.mdl"

// Animation
#define ANIM_EXTENSION			"tripmine"

enum _:Animation
{
	ANIM_IDLE1 = 0,
	ANIM_IDLE2,
	ANIM_LONGUSE,
	ANIM_USE,
	ANIM_HOLSTER,	
	ANIM_DRAW
};

//**********************************************
	
#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
#define Offset_iInZoom Offset_iuser1

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}
//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iMED = wpnmod_register_weapon
	
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
	
	
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_Spawn, "MED_Spawn");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_Deploy, "MED_Deploy");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_Idle, "MED_Idle");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_PrimaryAttack, "MED_PrimaryAttack");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_SecondaryAttack, "MED_SecondaryAttack");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_Reload, "MED_Reload");
	wpnmod_register_weapon_forward(iMED, Fwd_Wpn_Holster, "MED_Holster");

}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public MED_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************
public MED_Deploy(const iItem, const iPlayer, const iClip, const iAmmo)
{
	new iUserhealth = get_user_health(iPlayer);
	if(iUserhealth<=99 || iUserhealth != 0 || iAmmo != 0){
		wpnmod_set_think(iItem, "Health_Recharge");
		set_pev(iItem,pev_nextthink,get_gametime()+0.3);
	}
	
	if(!wpnmod_set_think(iItem, "Health_Recharge") || iUserhealth == 100)
	{
		wpnmod_set_think(iItem, "Ammo_Recharge");
		set_pev(iItem,pev_nextthink,get_gametime()+0.000001);
	}
	{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
	}
}


//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public MED_Holster(const iItem, const iPlayer, const iAmmo)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}



//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public MED_Idle(const iItem)
{
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}


public Ammo_Recharge(const iItem,const iPlayer,const iClip,const iAmmo){
new iAmmoAll;
iAmmoAll = WEAPON_DEFAULT_AMMO + 80;
if(iAmmo<iAmmoAll){
wpnmod_set_player_ammo(iPlayer,WEAPON_PRIMARY_AMMO,iAmmo + 1);
set_pev(iItem,pev_nextthink,get_gametime()+0.4400001);
wpnmod_send_weapon_anim(iItem, ANIM_IDLE2);
if(iAmmo==iAmmoAll)
{
return;
}	
}
	
}

public Health_Recharge(const iItem,const iPlayer,const iClip,const iAmmo)
{
	new iUserhealth = get_user_health(iPlayer);
	if(iUserhealth >= 100 || iAmmo <= 0)
	{
	wpnmod_set_think(iItem, "Ammo_Recharge");
	set_pev(iItem,pev_nextthink,get_gametime()+0.001);
	return;
	}
	if(iUserhealth<=99 || iUserhealth != 0){	

		fm_set_user_health(iPlayer, iUserhealth + 1);
		wpnmod_set_player_ammo(iPlayer,WEAPON_PRIMARY_AMMO,iAmmo - 1);
		set_pev(iItem,pev_nextthink,get_gametime()+0.04);
	}
	
}


