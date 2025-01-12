#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <fakemeta_util>
#include <fakemeta>


#define PLUGIN "HL: InfinitySingleBlack"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_infinitysb"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"infclip"
#define WEAPON_PRIMARY_AMMO_MAX		120
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			25
#define WEAPON_DEFAULT_AMMO		25
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			20
#define WEAPON_DAMAGE			45.0

// Hud
#define WEAPON_HUD_SPR_1		"sprites/weapon_infini.spr"
#define WEAPON_HUD_SPR_2		"sprites/weapon_infini_s.spr"

#define WEAPON_HUD_TXT			"sprites/weapon_infinitysb.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_infiniclip"

// Models
#define MODEL_WORLD			"models/w_infinitysb.mdl"
#define MODEL_VIEW			"models/v_infinitysb.mdl"
#define MODEL_PLAYER			"models/p_infinitysb.mdl"
#define MODEL_CLIP			"models/w_infiniclip.mdl"
#define MODEL_SHELL			"models/shell.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/infinityss_shoot1.wav"

// Animation
#define ANIM_EXTENSION			"9mmhandgun"


new Float: ms;

enum _:Animation
{
	ANIM_IDLE,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_EMPTY,
	ANIM_RELOAD,
	ANIM_DRAW
};

new g_iShell;
//**********************************************
#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)	
#define Offset_Stance Offset_iuser1

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	
	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
}


//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iINFINITY = wpnmod_register_weapon
	
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
	new iAmmoInfinity = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_Spawn, "INFINITY_Spawn");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_Deploy, "INFINITY_Deploy");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_Idle, "INFINITY_Idle");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_PrimaryAttack, "INFINITY_PrimaryAttack");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_SecondaryAttack, "INFINITY_SecondaryAttack");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_Reload, "INFINITY_Reload");
	wpnmod_register_weapon_forward(iINFINITY, Fwd_Wpn_Holster, "INFINITY_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoInfinity, Fwd_Ammo_Spawn, "AmmoInfinity_Spawn");
	wpnmod_register_ammobox_forward(iAmmoInfinity, Fwd_Ammo_AddAmmo, "AmmoInfinity_AddAmmo");
}

public plugin_cfg(){
	ms = get_cvar_float("sv_maxspeed");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public INFINITY_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public INFINITY_Deploy(const iItem, const iPlayer, const iClip)
{
	fm_set_user_maxspeed(iPlayer,ms);
	{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
	}
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public INFINITY_Holster(const iItem, const iPlayer)
{
	fm_set_user_maxspeed(iPlayer,ms);
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public INFINITY_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	wpnmod_set_think(iItem, "Return_NormalStance");
	set_pev(iItem, pev_nextthink, get_gametime() + 0.00000000000000001);
	set_pev(iItem, pev_body, 0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public INFINITY_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_think(iItem, "MS_Reduction");
	set_pev(iItem, pev_nextthink, get_gametime() + 0.00000000000000001);
	set_pev(iItem, pev_body, 0);
}

public INFINITY_Reload(const iItem, const iPlayer, const iClip, iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.95);
	fm_set_user_maxspeed(iPlayer,ms);

}
public MS_Reduction(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	fm_set_user_maxspeed(iPlayer, 195.0);
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.167);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.81);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.8);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT_1);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES,
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		2
	);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 16.0, -18.0, 1.0);
	

	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, float: {-1.0, 0.0 ,0.0});
	wpnmod_set_think(iItem, "Return_NormalStance");
	set_pev(iItem, pev_nextthink, get_gametime() + 1.8);
	set_pev(iItem, pev_body, 0);
}

public Return_NormalStance(const iItem, const iPlayer)
{
new Stance = wpnmod_get_offset_int(iItem, Offset_Stance);
wpnmod_set_offset_int(iItem, Offset_Stance, !Stance);
fm_set_user_maxspeed(iPlayer,ms);
}

public INFINITY_SecondaryAttack(const iItem, const iPlayer, const iClip ,const iAmmo)
{
	static Float: flZVel;
	static Float: vecAngle[3];
	static Float: vecForward[3];
	static Float: vecVelocity[3];
	static Float: vecPunchangle[3];
	
	if(pev(iPlayer, pev_flags) == FL_DUCKING)
	{
	return;
	}
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.327);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.21);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.8);

	global_get(glb_v_forward, vecForward);
	
	pev(iPlayer, pev_v_angle, vecAngle);
	pev(iPlayer, pev_velocity, vecVelocity);
	
	xs_vec_add(vecAngle, vecPunchangle, vecPunchangle);
	engfunc(EngFunc_MakeVectors, vecPunchangle);
	
	flZVel = vecVelocity[2];
	
	xs_vec_mul_scalar(vecForward, -650.0, vecPunchangle);
	xs_vec_sub(vecVelocity, vecPunchangle, vecVelocity);
	
	vecVelocity[2] = flZVel;
	 
	set_pev(iPlayer, pev_velocity, vecVelocity);
}

public AmmoInfinity_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoInfinity_AddAmmo(const iItem, const iPlayer)
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
