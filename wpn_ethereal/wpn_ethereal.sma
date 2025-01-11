/* AMX Mod X
*	Ethereal.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <beams>
#include <xs>


#define PLUGIN "Ethereal"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_ethereal"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"uranium"
#define WEAPON_PRIMARY_AMMO_MAX		100
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		30
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			40.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_ethereal.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_ethereal.spr"

// Models
#define MODEL_WORLD			"models/w_ethereal.mdl"
#define MODEL_VIEW			"models/v_ethereal_hev.mdl"
#define MODEL_PLAYER			"models/p_ethereal.mdl"

// Sounds
#define SOUND_FIRE			"weapons/ethereal-1.wav"
#define SOUND_DRAW			"weapons/ethereal_draw.wav"
#define SOUND_IDLE			"weapons/ethereal_idle1.wav"
#define SOUND_IMPACT			"weapons/shock_impact.wav"
#define SOUND_RELOAD			"weapons/ethereal_reload.wav"

// Sprites
#define SPRITE_LIGHTNING		"sprites/lgtning.spr"

// Beam
#define BEAM_LIFE			0.09
#define BEAM_COLOR			{100.0, 50.0, 253.0}
#define BEAM_BRIGHTNESS			255.0
#define BEAM_SCROLLRATE			10.0

// Animation
#define ANIM_EXTENSION			"gauss"

// Animation Sequence
enum _:Animation
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_FIRE_3
};

#define Beam_SetLife(%0,%1) \
	wpnmod_set_think(%0, "Beam_Remove"); \
	set_pev(%0, pev_nextthink, get_gametime() + %1)
	
//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(SPRITE_LIGHTNING);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DRAW);
	PRECACHE_SOUND(SOUND_IDLE);
	PRECACHE_SOUND(SOUND_IMPACT);
	PRECACHE_SOUND(SOUND_RELOAD);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iEthereal = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_Spawn, "Ethereal_Spawn");
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_Deploy, "Ethereal_Deploy");
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_Idle, "Ethereal_Idle");
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_Reload, "Ethereal_Reload");
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_Holster, "Ethereal_Holster");
	wpnmod_register_weapon_forward(iEthereal, Fwd_Wpn_PrimaryAttack, "Ethereal_PrimaryAttack");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public Ethereal_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public Ethereal_Deploy(const iItem, const iPlayer)
{
	// Start idle sound
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_IDLE, 0.4, ATTN_NORM, 0, PITCH_NORM);
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public Ethereal_Holster(const iItem, const iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
	
	// Stop idle sound
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_IDLE, 0.0, 0.0, SND_STOP, PITCH_NORM);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public Ethereal_Idle(const iItem, const iPlayer)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 10.03);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public Ethereal_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	new Float: vecSrc[3], Float: vecEnd[3], iBeam, iTrace = create_tr2();
	
	wpnmod_get_gun_position(iPlayer, vecSrc);
	global_get(glb_v_forward, vecEnd);
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, vecEnd);
	
	if (pev_valid((iBeam = Beam_Create(SPRITE_LIGHTNING, 25.0))))
	{
		Beam_PointEntInit(iBeam, vecEnd, iPlayer);
		Beam_SetEndAttachment(iBeam, 1);
		Beam_SetBrightness(iBeam, BEAM_BRIGHTNESS);
		Beam_SetScrollRate(iBeam, BEAM_SCROLLRATE);
		Beam_SetColor(iBeam, BEAM_COLOR);
		Beam_SetLife(iBeam, BEAM_LIFE);
	}
	
	wpnmod_radius_damage2(vecEnd, iPlayer, iPlayer, WEAPON_DAMAGE, WEAPON_DAMAGE * 2.0, CLASS_NONE, DMG_ENERGYBEAM | DMG_ALWAYSGIB);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	engfunc(EngFunc_EmitAmbientSound, 0, vecEnd, SOUND_IMPACT, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]);
	write_byte(10);
	write_byte(100);
	write_byte(50);
	write_byte(253);
	write_byte(255);
	write_byte(25);
	write_byte(1);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]);
	message_end();
	
	wpnmod_decal_trace(iTrace, engfunc(EngFunc_DecalIndex, "{smscorch1") + random_num(0, 2));
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.03);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_3));
	
	free_tr2(iTrace);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public Ethereal_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 3.03);
}

//**********************************************
//* Beam remove think.                         *
//**********************************************

public Beam_Remove(const iBeam)
{
	set_pev(iBeam, pev_flags, FL_KILLME);
}
