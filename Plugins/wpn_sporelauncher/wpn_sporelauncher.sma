/* AMX Mod X
*	Spore Launcher.
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
#include <xs>


#define PLUGIN "Spore Launcher"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_sporelauncher"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"spores"
#define WEAPON_PRIMARY_AMMO_MAX		20
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			5
#define WEAPON_DEFAULT_AMMO		5
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			20

// Spore settings
#define SPORE_DAMAGE			65.0
#define SPORE_PLANT_SPREAD		0.3
#define SPORE_PLANT_VELOCITY		800.0
#define SPORE_BOUNCE_TIME		2.0
#define SPORE_BOUNCE_VELOCITY		800
#define SPORE_FLY_VELOCITY		1200

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_sporelauncher.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_sporelauncher.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_spore"
#define AMMOBOX_GIVE_AMMO		1

// Models
#define MODEL_VIEW			"models/v_spore_launcher_hev.mdl"
#define MODEL_WORLD			"models/w_spore_launcher.mdl"
#define MODEL_PLAYER			"models/p_spore_launcher.mdl"
#define MODEL_SPORE			"models/spore.mdl"
#define MODEL_PLANT			"models/spore_ammo.mdl"

// Sprites
#define SPRITE_GLOW			"sprites/glow01.spr"
#define SPRITE_EXP_1			"sprites/spore_exp_01.spr"
#define SPRITE_EXP_2			"sprites/spore_exp_c_01.spr"
#define SPRITE_TINYSPIT			"sprites/tinyspit_spore.spr"

// Sounds
#define SOUND_PET			"weapons/splauncher_pet.wav"
#define SOUND_AMMO			"weapons/spore_ammo.wav"
#define SOUND_FIRE			"weapons/splauncher_fire.wav"
#define SOUND_BOUNCE			"weapons/splauncher_bounce.wav"
#define SOUND_RELOAD			"weapons/splauncher_reload.wav"
#define SOUND_IMPACT			"weapons/splauncher_impact.wav"

// Animation
#define ANIM_EXTENSION			"rpg"

enum _:SporeLauncherAnim
{
	ANIM_IDLE1 = 0,
	ANIM_FIDGET,
	ANIM_RELOAD_REACH,
	ANIM_RELOAD_LOAD,
	ANIM_RELOAD_AIM,
	ANIM_FIRE,
	ANIM_HOLSTER,
	ANIM_DRAW,
	ANIM_IDLE2
};

enum _:SporePlantAnim 
{
	ANIM_PLANT_IDLE = 0,
	ANIM_PLANT_SPAWNUP,
	ANIM_PLANT_SNATCHUP,
	ANIM_PLANT_SPAWNDOWN,
	ANIM_PLANT_SNATCHDOWN,
	ANIM_PLANT_IDLE1,
	ANIM_PLANT_IDLE2,
};

#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)
#define SET_ORIGIN(%0,%1) engfunc(EngFunc_SetOrigin,%0,%1)

new g_SpriteIndexTinyspit;
new g_SpriteIndexExplode1;
new g_SpriteIndexExplode2;

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_PLANT);
	PRECACHE_MODEL(MODEL_SPORE);
	PRECACHE_MODEL(SPRITE_GLOW);
	
	PRECACHE_SOUND(SOUND_PET);
	PRECACHE_SOUND(SOUND_AMMO);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_BOUNCE);
	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_IMPACT);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	g_SpriteIndexExplode1 = PRECACHE_MODEL(SPRITE_EXP_1);
	g_SpriteIndexExplode2 = PRECACHE_MODEL(SPRITE_EXP_2);
	g_SpriteIndexTinyspit = PRECACHE_MODEL(SPRITE_TINYSPIT);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iSporeLauncher = wpnmod_register_weapon
	
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
	
	new iAmmoSpore = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_Spawn, "SporeLauncher_Spawn");
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_Deploy, "SporeLauncher_Deploy");
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_PrimaryAttack, "SporeLauncher_PrimaryAttack");
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_SecondaryAttack, "SporeLauncher_SecondaryAttack");
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_Reload, "SporeLauncher_Reload");
	wpnmod_register_weapon_forward(iSporeLauncher, Fwd_Wpn_Idle, "SporeLauncher_Idle");
	
	wpnmod_register_ammobox_forward(iAmmoSpore, Fwd_Ammo_Spawn, "SporePlant_Spawn");
	
	// Take damage on spore plant
	RegisterHam(Ham_TakeDamage, "ammo_rpgclip", "SporePlant_TakeDamage");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public SporeLauncher_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Start animation
	set_pev(iItem, pev_framerate, 1.0);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public SporeLauncher_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public SporeLauncher_PrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmo)
{
	SporeLauncher_Fire(iItem, iPlayer, iClip, iAmmo, false);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public SporeLauncher_SecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmo)
{
	SporeLauncher_Fire(iItem, iPlayer, iClip, iAmmo, true);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public SporeLauncher_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	if (wpnmod_get_offset_float(iItem, Offset_flNextPrimaryAttack) > 0.0)
	{
		return;
	}
	
	new iInSpecialReload = wpnmod_get_offset_int(iItem, Offset_iInSpecialReload);
	
	if (!iInSpecialReload)
	{
		wpnmod_send_weapon_anim(iItem, ANIM_RELOAD_REACH);
		
		wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 1);
		wpnmod_set_offset_float(iPlayer, Offset_flNextAttack, 0.7);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.7);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.03);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.03);
		
		return;
	}
	else if (iInSpecialReload == 1)
	{
		if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
		{
			return;
		}
		
		wpnmod_send_weapon_anim(iItem, ANIM_RELOAD_LOAD);
		
		wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 2);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.03);
		
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip + 1);
		wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 1);
		
		wpnmod_set_player_ammo(iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - 1);
	}
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public SporeLauncher_Idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	new iInSpecialReload = wpnmod_get_offset_int(iItem, Offset_iInSpecialReload);
	
	if (!iClip && !iInSpecialReload && iAmmo)
	{
		SporeLauncher_Reload(iItem, iPlayer, iClip, iAmmo);
	}
	else if (iInSpecialReload != 0)
	{
		if (iClip != WEAPON_MAX_CLIP && iAmmo)
		{
			SporeLauncher_Reload(iItem, iPlayer, iClip, iAmmo);
		}
		else
		{
			wpnmod_send_weapon_anim(iItem, ANIM_RELOAD_AIM);
		
			wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
			wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.86);	
		}
	}
	else
	{
		new iAnim;
		new Float: flRand;
		new Float: flNextIdle;
		
		if ((flRand = random_float(0.0, 1.0)) <= 0.8)
		{
			iAnim = ANIM_IDLE1;
			flNextIdle = 2.03;
		}
		else if (flRand <= 0.9)
		{
			iAnim = ANIM_IDLE2;
			flNextIdle = 4.03;
		}
		else
		{
			iAnim = ANIM_FIDGET;
			flNextIdle = 4.03;
			
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_PET, 0.9, ATTN_NORM, 0, PITCH_NORM);
		}
		
		wpnmod_send_weapon_anim(iItem, iAnim);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
	}
}

//**********************************************
//* Sporelauncher fire.                        *
//**********************************************

SporeLauncher_Fire(const iItem, const iPlayer, iClip, const iAmmo, const bool: bBounce)
{
	if (iClip <= 0)
	{
		SporeLauncher_Reload(iItem, iPlayer, iClip, iAmmo);
		return;
	}

	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, NORMAL_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.5);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, iClip != 0 ? 0.5 : 0.75);
	
	wpnmod_send_weapon_anim(iItem, ANIM_FIRE);
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	velocity_by_aim(iPlayer, bBounce ? SPORE_BOUNCE_VELOCITY : SPORE_FLY_VELOCITY, vecVelocity);
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 8.0, -8.0);
	
	Spore_Create(vecOrigin, vecVelocity, iPlayer, bBounce);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

//**********************************************
//* Create and spawn spore.                    *
//**********************************************

#define Offset_iGlow Offset_iuser1
#define Offset_iBounce Offset_iuser2

Spore_Create(const Float: vecPosition[3], const Float: vecVelocity[3], const iOwner, const bool: bBounce)
{
	new iSpore, Float: vecAngles[3], Float: flGametime = get_gametime();

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		iSpore = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!pev_valid(iSpore))
	{
		return FM_NULLENT;
	}
	
	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);

	set_pev(iSpore, pev_classname, "spore");
	set_pev(iSpore, pev_solid, SOLID_BBOX);
	set_pev(iSpore, pev_dmg, SPORE_DAMAGE);
	set_pev(iSpore, pev_velocity, vecVelocity);
	set_pev(iSpore, pev_angles, vecAngles);
	set_pev(iSpore, pev_owner, iOwner);
	set_pev(iSpore, pev_gravity, 1.0);
	
	// We will explode spore later, so block dafult weaponmod effects.
	set_pev(iSpore, pev_spawnflags, ~(1 << SF_EXPLOSION_NODEBRIS));
	
	if (!bBounce)
	{
		set_pev(iSpore, pev_movetype, MOVETYPE_FLY);
		wpnmod_set_touch(iSpore, "Spore_RocketTouch");
	}
	else
	{
		set_pev(iSpore, pev_movetype, MOVETYPE_BOUNCE);
		set_pev(iSpore, pev_dmgtime, flGametime + SPORE_BOUNCE_TIME);
		wpnmod_set_touch(iSpore, "Spore_BounceTouch");
	}
	
	SET_MODEL(iSpore, MODEL_SPORE);
	SET_ORIGIN(iSpore, vecPosition);
	SET_SIZE(iSpore, Float: {0.0, 0.0, 0.0}, Float: {0.0, 0.0, 0.0});
	
	wpnmod_set_think(iSpore, "Spore_FlyThink");
	set_pev(iSpore, pev_nextthink, flGametime + 0.01);
	
	Spore_SetGlow(iSpore);
	wpnmod_set_offset_int(iSpore, Offset_iBounce, bBounce);
	
	return iSpore;
}

//**********************************************
//* Set glow effect to spore.                  *
//**********************************************

Spore_SetGlow(const iSpore)
{
	new iGlowSprite;
	
	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
	{
		iGlowSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!pev_valid(iGlowSprite))
	{
		return;
	}
	
	wpnmod_set_offset_int(iSpore, Offset_iGlow, iGlowSprite);
	
	set_pev(iGlowSprite, pev_classname, "spore_glow");
	set_pev(iGlowSprite, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(iGlowSprite, pev_solid, SOLID_NOT);
	
	set_pev(iGlowSprite, pev_skin, iSpore);
	set_pev(iGlowSprite, pev_body, 0);
	set_pev(iGlowSprite, pev_aiment, iSpore);
            
	set_pev(iGlowSprite, pev_scale, 0.8);
            
	set_pev(iGlowSprite, pev_renderfx, kRenderFxDistort);
	set_pev(iGlowSprite, pev_rendercolor, Float: {180.0, 180.0, 40.0});
	set_pev(iGlowSprite, pev_rendermode, kRenderTransAdd);
	set_pev(iGlowSprite, pev_renderamt, 100.0);
	
	SET_MODEL(iGlowSprite, SPRITE_GLOW);
}

//**********************************************
//* Spore fly think function.                  *
//**********************************************

public Spore_FlyThink(const iSpore)
{
	static Float: flDmgTime;
	static Float: vecOrigin[3];
	
	pev(iSpore, pev_origin, vecOrigin);
	pev(iSpore, pev_dmgtime, flDmgTime);
	
	if (wpnmod_get_offset_int(iSpore, Offset_iBounce) && flDmgTime <= get_gametime())
	{
		wpnmod_explode_entity(iSpore, .szCallBack = "Spore_Explode");
		return;
	}

	// Sprite spray
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, 0, 0);
	write_byte(TE_SPRITE_SPRAY);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);	
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, 0.0);
	engfunc(EngFunc_WriteCoord, 0.0);	
	engfunc(EngFunc_WriteCoord, 1.0);
	write_short(g_SpriteIndexTinyspit);
	write_byte(2);
	write_byte(20);
	write_byte(80);
	message_end();
	
	set_pev(iSpore, pev_nextthink, get_gametime () + 0.03);
}

//**********************************************
//* Spore touch functions.                     *
//**********************************************

public Spore_RocketTouch(const iSpore)
{
	wpnmod_explode_entity(iSpore, .szCallBack = "Spore_Explode");
}

public Spore_BounceTouch(const iSpore, const iOther)
{
	if (iOther == pev(iSpore, pev_owner))
	{
		return;
	}
	
	new Float: flTakeDmg;
	new Float: vecVelocity[3];
	
	pev(iOther, pev_takedamage, flTakeDmg);
	pev(iSpore, pev_velocity, vecVelocity);
	
	if (flTakeDmg > DAMAGE_NO)
	{
		wpnmod_explode_entity(iSpore, .szCallBack = "Spore_Explode");
		return;
	}
	
	if (pev(iSpore, pev_flags) & FL_ONGROUND)
	{
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iSpore, pev_velocity, vecVelocity);
	}
	else
	{
		emit_sound(iSpore, CHAN_VOICE, SOUND_BOUNCE, 0.25, ATTN_NORM, 0, PITCH_NORM);
	}
}

//**********************************************
//* Spore explode effects.                     *
//**********************************************

public Spore_Explode(const iSpore, const iTrace)
{
	new iSpriteGlow = wpnmod_get_offset_int(iSpore, Offset_iGlow);
	
	if (pev_valid(iSpriteGlow))
	{
		set_pev(iSpriteGlow, pev_flags, FL_KILLME);
	}
	
	new Float: vecSrc[3];
	new Float: vecOrigin[3];
	
	pev(iSpore, pev_origin, vecOrigin);
	get_tr2(iTrace, TR_vecEndPos, vecSrc);
	
	// Sprite spray
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE_SPRAY);
	engfunc(EngFunc_WriteCoord, vecSrc[0]);
	engfunc(EngFunc_WriteCoord, vecSrc[1]);	
	engfunc(EngFunc_WriteCoord, vecSrc[2]);
	engfunc(EngFunc_WriteCoord, 0);
	engfunc(EngFunc_WriteCoord, 0);	
	engfunc(EngFunc_WriteCoord, 0);	
	write_short(g_SpriteIndexTinyspit);
	write_byte(100);
	write_byte(40);
	write_byte(180);
	message_end();
	
	// Dynamic light
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecSrc[0]);
	engfunc(EngFunc_WriteCoord, vecSrc[1]);
	engfunc(EngFunc_WriteCoord, vecSrc[2]);
	write_byte(10);
	write_byte(15);
	write_byte(220);
	write_byte(40);
	write_byte(5);
	write_byte(10);
	message_end();
	
	// Explode effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);	
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);	
	write_short(random_num(0, 1) ? g_SpriteIndexExplode1 : g_SpriteIndexExplode2);
	write_byte(20);
	write_byte(128);
	message_end();
	
	// Impact sound
	emit_sound(iSpore, CHAN_VOICE, SOUND_IMPACT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	// Make decal
	wpnmod_decal_trace(iTrace, .szDecalName = random_num(0, 1) ? "{SPIT1" : "{SPIT2");
}

//**********************************************
//* Spore plant spawn.                         *
//**********************************************

#define SporePlant_SnatchDown(%0) \
	wpnmod_set_offset_int(%0, Offset_iStep, ANIM_PLANT_SNATCHDOWN); \
	SporePlant_Think(%0)
	
#define Offset_iStep Offset_iuser1
#define Offset_iEmpty Offset_iuser2

public SporePlant_Spawn(const iSporePlant)
{
	new Float: vecAngles[3];
	new Float: vecOrigin[3];
	
	pev(iSporePlant, pev_angles, vecAngles);
	pev(iSporePlant, pev_origin, vecOrigin);
	
	vecAngles[0] -= 90.0;
	vecOrigin[2] += 16.0;
	
	set_pev(iSporePlant, pev_angles, vecAngles);
	set_pev(iSporePlant, pev_origin, vecOrigin);
	
	set_pev(iSporePlant, pev_solid, SOLID_SLIDEBOX);
	set_pev(iSporePlant, pev_movetype, MOVETYPE_FLY);
	set_pev(iSporePlant, pev_takedamage, DAMAGE_YES);
	set_pev(iSporePlant, pev_health, 1.0);
	
	set_pev(iSporePlant, pev_sequence, ANIM_PLANT_IDLE1);
	set_pev(iSporePlant, pev_framerate, 1.0);
	set_pev(iSporePlant, pev_body, 1);
	
	wpnmod_set_touch(iSporePlant, "SporePlant_Touch");
	wpnmod_set_think(iSporePlant, "SporePlant_Think");
	
	SET_MODEL(iSporePlant, MODEL_PLANT);
	SET_SIZE(iSporePlant, Float: {-20.0, -20.0, -8.0}, Float: {20.0, 20.0, 16.0});
}

//**********************************************
//* Spore plant touch function.                *
//**********************************************

public SporePlant_Touch(const iSporePlant, const iPlayer)
{
	if (!ExecuteHamB(Ham_IsPlayer, iPlayer))
	{
		return;
	}
	
	if (wpnmod_get_offset_int(iSporePlant, Offset_iEmpty))
	{
		return;
	}
	
	if (ExecuteHamB(Ham_GiveAmmo, iPlayer, AMMOBOX_GIVE_AMMO, WEAPON_PRIMARY_AMMO, WEAPON_PRIMARY_AMMO_MAX) == -1)
	{
		return;
	}
	
	emit_sound(iPlayer, CHAN_AUTO, SOUND_AMMO, 1.0, ATTN_NORM, 0, PITCH_NORM);
	SporePlant_SnatchDown(iSporePlant);
}

//**********************************************
//* Spore plant think function.                *
//**********************************************

public SporePlant_Think(const iSporePlant)
{
	new iStep = wpnmod_get_offset_int(iSporePlant, Offset_iStep);
	
	if (iStep == ANIM_PLANT_SNATCHDOWN)
	{
		set_pev(iSporePlant, pev_sequence, ANIM_PLANT_SNATCHDOWN);
		set_pev(iSporePlant, pev_nextthink, get_gametime() + 0.7);
		set_pev(iSporePlant, pev_body, 0);
			
		wpnmod_set_offset_int(iSporePlant, Offset_iEmpty, true);
		wpnmod_set_offset_int(iSporePlant, Offset_iStep, ANIM_PLANT_IDLE);
	}
	else if (iStep == ANIM_PLANT_SPAWNDOWN)
	{
		set_pev(iSporePlant, pev_sequence, ANIM_PLANT_SPAWNDOWN);
		set_pev(iSporePlant, pev_nextthink, get_gametime() + 4.03);
		set_pev(iSporePlant, pev_body, 1);
			
		wpnmod_set_offset_int(iSporePlant, Offset_iStep, ANIM_PLANT_IDLE1);
	}
	else if (iStep == ANIM_PLANT_IDLE)
	{
		set_pev(iSporePlant, pev_sequence, ANIM_PLANT_IDLE);
		set_pev(iSporePlant, pev_nextthink, get_gametime() + 10.03);
			
		wpnmod_set_offset_int(iSporePlant, Offset_iStep, ANIM_PLANT_SPAWNDOWN);
	}
	else
	{
		set_pev(iSporePlant, pev_sequence, ANIM_PLANT_IDLE1);
		wpnmod_set_offset_int(iSporePlant, Offset_iEmpty, false);
	}
	
	set_pev(iSporePlant, pev_animtime, get_gametime() + 0.1);
}

//**********************************************
//* Spore plant take damage.                   *
//**********************************************

public SporePlant_TakeDamage(const iSporePlant)
{
	static szClassname[32];
	pev(iSporePlant, pev_classname, szClassname, charsmax(szClassname));
	
	if (!equali(AMMOBOX_CLASSNAME, szClassname))
	{
		return HAM_IGNORED;
	}
	
	if (wpnmod_get_offset_int(iSporePlant, Offset_iEmpty))
	{
		return HAM_SUPERCEDE;
	}
	
	new Float: vecUp[3];
	new Float: vecRight[3];
	new Float: vecOrigin[3];
	new Float: vecForward[3];
	
	pev(iSporePlant, pev_angles, vecOrigin);
	
	vecOrigin[0] -= 90.0;
	
	engfunc(EngFunc_MakeVectors, vecOrigin);
	global_get(glb_v_forward, vecForward);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_up, vecUp);

	new Float: x, Float: y, Float: z;
	
	do // get circular gaussian spread
	{
		x = random_float(-0.5, 0.5) + random_float(-0.5, 0.5);
		y = random_float(-0.5, 0.5) + random_float(-0.5, 0.5);
		z = x * x + y * y;
	} while (z > 1.0);
	
	pev(iSporePlant, pev_origin, vecOrigin);
	
	xs_vec_mul_scalar(vecUp, y * SPORE_PLANT_SPREAD, vecUp);
	xs_vec_mul_scalar(vecRight, x * SPORE_PLANT_SPREAD, vecRight);
	
	xs_vec_add(vecUp, vecForward, vecForward);
	xs_vec_add(vecRight, vecForward, vecForward);
	xs_vec_mul_scalar(vecForward, SPORE_PLANT_VELOCITY, vecForward);
	
	Spore_Create(vecOrigin, vecForward, iSporePlant, true);
	SporePlant_SnatchDown(iSporePlant);
		
	return HAM_SUPERCEDE;
}
