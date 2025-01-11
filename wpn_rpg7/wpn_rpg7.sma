/* AMX Mod X
*	RPG-7.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "RPG-7"
#define VERSION "1.1"
#define AUTHOR "KORD_12.7, Koshak"


// Weapon settings
#define WEAPON_NAME 			"weapon_rpg7"
#define WEAPON_NAME_SCOPED 		"weapon_rpg7_scp"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"rockets_rpg7"
#define WEAPON_PRIMARY_AMMO_MAX		5
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			1
#define WEAPON_DEFAULT_AMMO		1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			20
#define WEAPON_DAMAGE			200.0

// Hud
#define WEAPON_HUD_TXT_1		"sprites/weapon_rpg7.txt"
#define WEAPON_HUD_SPR_1		"sprites/weapon_rpg7.spr"
#define WEAPON_HUD_TXT_2		"sprites/weapon_rpg7_scp.txt"
#define WEAPON_HUD_SPR_2		"sprites/weapon_rpg7_scp.spr"

// Ammobox
#define AMMOBOX_CLASSNAME_1		"ammo_rpg7box"
#define AMMOBOX_CLASSNAME_2		"ammo_rpg7clip"

// Models
#define MODEL_WORLD			"models/w_rpg7.mdl"
#define MODEL_VIEW			"models/v_rpg7.mdl"
#define MODEL_VIEW_SCOPE		"models/v_rpg7_scp.mdl"
#define MODEL_PLAYER_1			"models/p_rpg7_1.mdl"
#define MODEL_PLAYER_2			"models/p_rpg7_2.mdl"
#define MODEL_CLIP_1			"models/w_rpg7_box_1.mdl"
#define MODEL_CLIP_2			"models/w_rpg7clip.mdl"
#define MODEL_ROCKET			"models/rpg7_rocket.mdl"

// Sounds
#define SOUND_FIRE			"weapons/rpg7_fire.wav"
#define SOUND_ZOOM			"weapons/sniper_zoom.wav"
#define SOUND_RELOAD_1			"weapons/rpg7_clip1.wav"
#define SOUND_RELOAD_2			"weapons/rpg7_clip2.wav"
#define SOUND_RELOAD_3			"weapons/rpg7_clip3.wav"
#define SOUND_ROCKET_FLY		"weapons/rpg7_rocket_fly.wav"

// Sprites
#define SPRITE_TRAIL			"sprites/smoke.spr"
#define SPRITE_EXPLODE			"sprites/rpg7_exp.spr"
#define SPRITE_EXPLODE_WATER		"sprites/WXplo1.spr"

// Rocket
#define ROCKET_VELOCITY			2000
#define ROCKET_CLASSNAME		"rpg7_rocket"

// Animation
#define ANIM_EXTENSION_1		"rpg"
#define ANIM_EXTENSION_2		"hive"

enum _:Animation
{
	ANIM_FIRE,
	ANIM_RELOAD,
	ANIM_DRAW_READY,
	ANIM_HOLSTER_READY,
	ANIM_DRAW_EMPTY,
	ANIM_HOLSTER_EMPTY,
	ANIM_IDLE_READY,
	ANIM_IDLE_EMPTY
};

#define CNAHGE_ANIM_EXT(%0,%1,%2) \
	wpnmod_set_anim_ext(%0, %1); \
	set_pev(%0, pev_weaponmodel2, %2)
	
#define Offset_iInZoom Offset_iuser1	

new g_iModelIndexTrail;
new g_iModelIndexFireball;
new g_iModelIndexWExplosion;

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_ROCKET);
	PRECACHE_MODEL(MODEL_CLIP_1);
	PRECACHE_MODEL(MODEL_CLIP_2);
	PRECACHE_MODEL(MODEL_PLAYER_1);
	PRECACHE_MODEL(MODEL_PLAYER_2);
	PRECACHE_MODEL(MODEL_VIEW_SCOPE);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_ZOOM);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_RELOAD_2);
	PRECACHE_SOUND(SOUND_RELOAD_3);
	PRECACHE_SOUND(SOUND_ROCKET_FLY);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	
	g_iModelIndexTrail = PRECACHE_MODEL(SPRITE_TRAIL);
	g_iModelIndexFireball = PRECACHE_MODEL(SPRITE_EXPLODE);
	g_iModelIndexWExplosion = PRECACHE_MODEL(SPRITE_EXPLODE_WATER);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iRPG7 = wpnmod_register_weapon
	
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
	
	new iAmmoLarge = wpnmod_register_ammobox(AMMOBOX_CLASSNAME_1);
	new iAmmoSingle = wpnmod_register_ammobox(AMMOBOX_CLASSNAME_2);
	
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_Spawn, "RPG7_Spawn");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_Deploy, "RPG7_Deploy");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_Idle, "RPG7_Idle");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_PrimaryAttack, "RPG7_PrimaryAttack");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_SecondaryAttack, "RPG7_SecondaryAttack");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_Reload, "RPG7_Reload");
	wpnmod_register_weapon_forward(iRPG7, Fwd_Wpn_Holster, "RPG7_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoLarge, Fwd_Ammo_Spawn, "AmmoLarge_Spawn");
	wpnmod_register_ammobox_forward(iAmmoLarge, Fwd_Ammo_AddAmmo, "AmmoLarge_AddAmmo");
	wpnmod_register_ammobox_forward(iAmmoSingle, Fwd_Ammo_Spawn, "AmmoSingle_Spawn");
	wpnmod_register_ammobox_forward(iAmmoSingle, Fwd_Ammo_AddAmmo, "AmmoSingle_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public RPG7_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public RPG7_Deploy(const iItem)
{
	if (wpnmod_get_offset_int(iItem, Offset_iClip))
	{
		return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER_1, ANIM_DRAW_READY, ANIM_EXTENSION_1);
	}
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER_2, ANIM_DRAW_EMPTY, ANIM_EXTENSION_2);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public RPG7_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		RPG7_SecondaryAttack(iItem, iPlayer);
	}
	
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public RPG7_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	new iAnim;
	
	if (iClip <= 0)
	{
		iAnim = ANIM_IDLE_EMPTY;
		CNAHGE_ANIM_EXT(iPlayer, ANIM_EXTENSION_2, MODEL_PLAYER_2);
	}
	else 
	{
		iAnim = ANIM_IDLE_READY;
		CNAHGE_ANIM_EXT(iPlayer, ANIM_EXTENSION_1, MODEL_PLAYER_1);
	}
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public RPG7_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.7);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, ANIM_FIRE);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	CNAHGE_ANIM_EXT(iPlayer, ANIM_EXTENSION_2, MODEL_PLAYER_2);
	RPG7_Fire(iPlayer);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public RPG7_SecondaryAttack(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		MakeZoom(iItem, iPlayer, WEAPON_NAME, MODEL_VIEW, 0.0);	
	}
	else
	{
		MakeZoom(iItem, iPlayer, WEAPON_NAME_SCOPED, MODEL_VIEW_SCOPE, 20.0);
	}
	
	emit_sound(iPlayer, CHAN_ITEM, SOUND_ZOOM, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}

MakeZoom(const iItem, const iPlayer, const szWeaponName[], const szViewModel[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
	wpnmod_set_offset_int(iItem, Offset_iInZoom, flFov != 0.0);
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo1));
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo2));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iSlot));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iPosition));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iId));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iFlags));
		message_end();
	}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public RPG7_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}

	if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		RPG7_SecondaryAttack(iItem, iPlayer);
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.6);
	wpnmod_set_think(iItem, "RPG7_CompleteReload");
	
	set_pev(iItem, pev_nextthink, get_gametime() + 2.6);
}

public RPG7_CompleteReload(const iItem, const iPlayer)
{
	CNAHGE_ANIM_EXT(iPlayer, ANIM_EXTENSION_1, MODEL_PLAYER_1);
}

//**********************************************
//* Launch a rocket                            *
//**********************************************

RPG7_Fire(const iPlayer)
{
	new iRocket;
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 6.0, 0.0);
	velocity_by_aim(iPlayer, ROCKET_VELOCITY, vecVelocity);
		
	// Create default contact grenade with module
	iRocket = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity, "Rocket_Explode");
	
	if (pev_valid(iRocket))
	{
		new Float: flGameTime = get_gametime();
		
		// Dont draw default fireball on explode and do not inflict damage
		set_pev(iRocket, pev_spawnflags, SF_EXPLOSION_NODAMAGE | SF_EXPLOSION_NOFIREBALL);
		
		// Set custom classname
		set_pev(iRocket, pev_classname, ROCKET_CLASSNAME);
		
		// Set movetype.
		set_pev(iRocket, pev_movetype, MOVETYPE_FLY);
		
		// Set custom damage, because default is 100
		set_pev(iRocket, pev_dmg, WEAPON_DAMAGE);
		
		// Make light
		set_pev(iRocket, pev_effects, pev(iRocket, pev_effects) | EF_LIGHT);
		
		// Set avelocity
		set_pev(iRocket, pev_avelocity, Float: {0.0, 0.0, 1000.0});
		
		// Set custom grenade model
		SET_MODEL(iRocket, MODEL_ROCKET);
		
		// Set rocket fly think callback
		wpnmod_set_think(iRocket, "Rocket_FlyThink");
		
		// set next think time
		set_pev(iRocket, pev_nextthink, flGameTime + 0.1);
		
		// Set max fly time
		set_pev(iRocket, pev_dmgtime, flGameTime + 3.0);
		
		// rocket trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(iRocket); // entity
		write_short(g_iModelIndexTrail); // model
		write_byte(10); // life
		write_byte(4); // width
		write_byte(224); // r, g, b
		write_byte(224); // r, g, b
		write_byte(255); // r, g, b
		write_byte(255); // brightness
		message_end();
		
		emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 1.0, 0.5, 0, PITCH_NORM);
	}
}

//**********************************************
//* Rocket fly think.          		       *
//**********************************************

public Rocket_FlyThink(const iRocket)
{
	static Float: flDmgTime;
	static Float: flGameTime;
	
	pev(iRocket, pev_dmgtime, flDmgTime);
	set_pev(iRocket, pev_nextthink, (flGameTime = get_gametime()) + 0.2);

	if (pev(iRocket, pev_waterlevel) != 0)
	{
		new Float: vecVelocity[3];
		
		pev(iRocket, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iRocket, pev_velocity, vecVelocity);
	}
	
	if (flDmgTime <= flGameTime)
	{
		set_pev(iRocket, pev_movetype, MOVETYPE_TOSS);
		set_pev(iRocket, pev_effects, pev(iRocket, pev_effects) &~ EF_LIGHT);
		
		emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 0.0, 0.0, SND_STOP, PITCH_NORM);
	}
}

//**********************************************
//* Rocket explode.          		       *
//**********************************************

public Rocket_Explode(const iRocket)
{	
	new iOwner;
	
	new Float: flDamage;
	new Float: vecOrigin[3];
	
	iOwner = pev(iRocket, pev_owner);
	
	pev(iRocket, pev_dmg, flDamage);
	pev(iRocket, pev_origin, vecOrigin);
	
	engfunc(EngFunc_MessageBegin,MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_WATER ? g_iModelIndexFireball : g_iModelIndexWExplosion);
	write_byte(35);
	write_byte(15); 
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_KILLBEAM); 
	write_short(iRocket);
	message_end(); 
	
	// Reset to attack owner too
	set_pev(iRocket, pev_owner, 0);
	
	// Lets damage
	wpnmod_radius_damage2(vecOrigin, iRocket, iOwner, flDamage, flDamage * 2.0, CLASS_NONE, DMG_BLAST);
	
	// Stop fly sound
	emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 0.0, 0.0, SND_STOP, PITCH_NORM);
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public AmmoLarge_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP_1);
}

public AmmoSingle_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP_2);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoLarge_AddAmmo(const iItem, const iPlayer)
{
	new iResult = 
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			iPlayer, 
			4, 
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

public AmmoSingle_AddAmmo(const iItem, const iPlayer)
{
	new iResult = 
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			iPlayer, 
			1, 
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
