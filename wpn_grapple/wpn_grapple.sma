/* AMX Mod X
*	Barnacle Grapple.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <beams>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "Barnacle Grapple"
#define VERSION "1.1"
#define AUTHOR "KORD_12.7"
 

// Weapon settings
#define WEAPON_NAME 			"weapon_grapple"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"" // NULL
#define WEAPON_PRIMARY_AMMO_MAX		-1
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		-1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			21

// Grapple settings
#define GRAPPLE_FLY_VELOCITY		1500
#define GRAPPLE_PULL_VELOCITY		400.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_grapple.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_grapple.spr"

// Models
#define MODEL_VIEW			"models/v_bgrap_koshak.mdl"
#define MODEL_WORLD			"models/w_bgrap.mdl"
#define MODEL_PLAYER			"models/p_bgrap.mdl"
#define MODEL_TONGUE_TIP		"models/shock_effect.mdl"

// Sprites
#define SPRITE_TONGUE			"sprites/tongue.spr"

// Sounds
#define SOUND_DRAW			"weapons/alienweap_draw.wav"
#define SOUND_WAIT			"weapons/bgrapple_wait.wav"
#define SOUND_PULL			"weapons/bgrapple_pull.wav"
#define SOUND_FIRE			"weapons/bgrapple_fire.wav"
#define SOUND_COUGH			"weapons/bgrapple_cough.wav"
#define SOUND_CHEW_1			"barnacle/bcl_chew1.wav"
#define SOUND_CHEW_2			"barnacle/bcl_chew2.wav"
#define SOUND_CHEW_3			"barnacle/bcl_chew3.wav"
#define SOUND_IMPACT			"weapons/bgrapple_impact.wav"
#define SOUND_RELEASE			"weapons/bgrapple_release.wav"

// Animation
#define ANIM_EXTENSION			"gauss"

enum _:GrappleAnim
{
	ANIM_BREATHE = 0,
	ANIM_LONGIDLE,
	ANIM_SHORTIDLE,
	ANIM_COUGH,
	ANIM_DOWN,
	ANIM_UP,
	ANIM_FIRE,
	ANIM_FIREWAITING,
	ANIM_FIREREACHED,
	ANIM_FIRETRAVEL,
	ANIM_FIRERELEASE
};

#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)
#define SET_ORIGIN(%0,%1) engfunc(EngFunc_SetOrigin,%0,%1)

enum
{
	FIRE_OFF, 
	FIRE_CHARGE
}

#define Offset_iTip	Offset_iuser1
#define Offset_iBeam	Offset_iuser2

#define Offset_iPull	Offset_iuser1
#define Offset_iTarget	Offset_iuser2

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(SPRITE_TONGUE);
	PRECACHE_MODEL(MODEL_TONGUE_TIP);
	
	PRECACHE_SOUND(SOUND_DRAW);
	PRECACHE_SOUND(SOUND_WAIT);
	PRECACHE_SOUND(SOUND_PULL);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_COUGH);
	PRECACHE_SOUND(SOUND_CHEW_1);
	PRECACHE_SOUND(SOUND_CHEW_2);
	PRECACHE_SOUND(SOUND_CHEW_3);
	PRECACHE_SOUND(SOUND_IMPACT);
	PRECACHE_SOUND(SOUND_RELEASE);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR); 
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iGrapple = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_Spawn, "Grapple_Spawn");
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_Deploy, "Grapple_Deploy");
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_PrimaryAttack, "Grapple_PrimaryAttack");
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_SecondaryAttack, "Grapple_SecondaryAttack");
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_Idle, "Grapple_Idle");
	wpnmod_register_weapon_forward(iGrapple, Fwd_Wpn_Holster, "Grapple_Holster");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public Grapple_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public Grapple_Deploy(const iItem)
{
	wpnmod_set_offset_int(iItem, Offset_iFireState, FIRE_OFF);
	
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_UP, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public Grapple_Holster(const iItem)
{
	Grapple_DestroyEffect(iItem);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public Grapple_Idle(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	if (wpnmod_get_offset_int(iItem, Offset_iFireState) != FIRE_OFF)
	{
		 Grapple_EndAttack(iItem, iPlayer);
		 return;
	}
	
	new iAnim;
	new Float: flRand;
	new Float: flNextIdle;
		
	if ((flRand = random_float(0.0, 1.0)) > 0.5)
	{
		if (flRand > 0.95)
		{
			iAnim = ANIM_COUGH;
			flNextIdle = 4.63;
		}
		else
		{
			iAnim = ANIM_BREATHE;
			flNextIdle = 2.6;
		}
	}
	else
	{
		iAnim = ANIM_LONGIDLE;
		flNextIdle = 10.03;
	}
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public Grapple_PrimaryAttack(const iItem, const iPlayer)
{
	Grapple_StartAttack(iItem, iPlayer, true);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public Grapple_SecondaryAttack(const iItem, const iPlayer)
{
	Grapple_StartAttack(iItem, iPlayer, false);
}

//**********************************************
//* Start Grapple attack.                      *
//**********************************************

Grapple_StartAttack(const iItem, const iPlayer, const bool: bPull)
{
	static iFireState;
	static iGrappleTip;
	
	static Float: flGameTime;
	
	flGameTime = get_gametime();
	iFireState = wpnmod_get_offset_int(iItem, Offset_iFireState);
	iGrappleTip = wpnmod_get_offset_int(iItem, Offset_iTip);
	
	wpnmod_set_offset_float(iItem, Offset_flReleaseThrow, bPull ? 0.0 : 1.0);
	
	if (iFireState == FIRE_OFF)
	{
		set_pev(iPlayer, pev_punchangle, Float: {-2.0, 0.0, 0.0});
		
		wpnmod_send_weapon_anim(iItem, ANIM_FIRE);
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
			
		wpnmod_set_offset_int(iItem, Offset_iFireState, FIRE_CHARGE);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.1);
		wpnmod_set_offset_float(iItem, Offset_flPumpTime, flGameTime + 0.5);
		wpnmod_set_offset_float(iItem, Offset_flStartThrow, flGameTime + 0.5);
	
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	else if (iFireState == FIRE_CHARGE && pev_valid(iGrappleTip))
	{
		if (wpnmod_get_offset_float(iItem, Offset_flStartThrow) < flGameTime)
		{
			if (wpnmod_get_offset_int(iGrappleTip, Offset_iPull))
			{
				wpnmod_send_weapon_anim(iItem, ANIM_FIRETRAVEL);
				wpnmod_set_offset_float(iItem, Offset_flStartThrow, flGameTime + 0.68);
			}
			else
			{
				wpnmod_send_weapon_anim(iItem, ANIM_FIREWAITING);
				wpnmod_set_offset_float(iItem, Offset_flStartThrow, flGameTime + 0.24);
			}
		}	
					
		if (wpnmod_get_offset_float(iItem, Offset_flPumpTime) < flGameTime)
		{
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_PULL, 0.9, ATTN_NORM, 0, PITCH_NORM);
			wpnmod_set_offset_float(iItem, Offset_flPumpTime, flGameTime + 0.68);
		}
			
		if (bPull)
		{
			Grapple_Stab(iItem, iPlayer);
		}
	}
	
	Grapple_UpdateEffect(iItem, iPlayer);
}

//**********************************************
//* End Grapple attack.                        *
//**********************************************

Grapple_EndAttack(const iItem, const iPlayer)
{
	Grapple_DestroyEffect(iItem);
	wpnmod_send_weapon_anim(iItem, ANIM_FIRERELEASE);
	
	wpnmod_set_offset_int(iItem, Offset_iFireState, FIRE_OFF);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.9);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_PULL, 0.0, 0.0, SND_STOP, PITCH_NORM);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELEASE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

//**********************************************
//* Tongue tip effects.                        *
//**********************************************

Grapple_UpdateEffect(const iItem, const iPlayer)
{
	static iTip, iBeam;
	
	iTip = wpnmod_get_offset_int(iItem, Offset_iTip);
	
	if (!pev_valid(iTip))
	{
		Grapple_CreateEffect(iItem, iPlayer);
	}
	
	iBeam = wpnmod_get_offset_int(iItem, Offset_iBeam);
	
	if (pev_valid(iBeam))
	{
		Beam_RelinkBeam(iBeam);
	}
}

Grapple_DestroyEffect(const iItem)
{
	new iBeam = wpnmod_get_offset_int(iItem, Offset_iBeam);
	
	if (pev_valid(iBeam))
	{
		set_pev(iBeam, pev_flags, FL_KILLME);
		wpnmod_set_offset_int(iItem, Offset_iBeam, FM_NULLENT);
	}
	
	new iTip = wpnmod_get_offset_int(iItem, Offset_iTip);
	
	if (pev_valid(iTip))
	{
		set_pev(iTip, pev_flags, FL_KILLME);
		wpnmod_set_offset_int(iItem, Offset_iTip, FM_NULLENT);
	}
}

Grapple_CreateEffect(const iItem, const iPlayer)
{
	Grapple_DestroyEffect(iItem);
	
	new iTip; 
	new iBeam;
	
	new Float: vecOrigin[3];
	new Float: vecAngles[3];
	new Float: vecVelocity[3];
	
	velocity_by_aim(iPlayer, GRAPPLE_FLY_VELOCITY, vecVelocity);
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 8.0, -8.0);
	
	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		iTip = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (pev_valid(iTip))
	{
		engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	
		set_pev(iTip, pev_classname, "grapple_tip");
		set_pev(iTip, pev_solid, SOLID_BBOX);
		set_pev(iTip, pev_movetype, MOVETYPE_FLY);
		set_pev(iTip, pev_velocity, vecVelocity);
		set_pev(iTip, pev_angles, vecAngles);
		set_pev(iTip, pev_owner, iPlayer);
		set_pev(iTip, pev_iuser4, iItem);
		
		SET_ORIGIN(iTip, vecOrigin);
		SET_MODEL(iTip, MODEL_TONGUE_TIP);
		SET_SIZE(iTip, Float: {0.0, 0.0, 0.0}, Float: {0.0, 0.0, 0.0});
		
		wpnmod_set_offset_int(iItem, Offset_iTip, iTip);
	
		if (pev_valid((iBeam = Beam_Create(SPRITE_TONGUE, 15.0))))
		{
			set_pev(iBeam, pev_classname, "tongue_beam");
			
			Beam_EntsInit(iBeam, iTip, iPlayer);
			Beam_SetFlags(iBeam, BEAM_FSOLID);
			Beam_SetEndAttachment(iBeam, 1);
			Beam_SetBrightness(iBeam, 100.0);

			wpnmod_set_offset_int(iItem, Offset_iBeam, iBeam);
		}
		
		wpnmod_set_think(iTip, "GrappleTip_FlyThink");
		wpnmod_set_touch(iTip, "GrappleTip_TongueTouch");
		
		set_pev(iTip, pev_nextthink, get_gametime() + 0.1);
	}
}

//**********************************************
//* Tongue tip think funcs.                    *
//**********************************************

public GrappleTip_FlyThink(const iGrappleTip)
{
	static iItem;
	static iOwner;
	
	iItem = pev(iGrappleTip, pev_iuser4);
	iOwner = pev(iGrappleTip, pev_owner);
	
	set_pev(iGrappleTip, pev_nextthink, get_gametime() + 0.1);
	
	if (!ExecuteHamB(Ham_IsInWorld, iGrappleTip))
	{
		Grapple_EndAttack(iItem, iOwner);
	}
}

public GrappleTip_PullThink(const iGrappleTip)
{
	static iItem;
	static iOwner;
	static iTarget;
	
	static Float: flDistance;
	static Float: vecVelocity[3];
	static Float: vecPlayerOrigin[3];
	static Float: vecGrappleOrigin[3];
	
	iItem = pev(iGrappleTip, pev_iuser4);
	iOwner = pev(iGrappleTip, pev_owner);
	iTarget = wpnmod_get_offset_int(iGrappleTip, Offset_iTarget);
	
	if (pev_valid(iTarget) && ExecuteHamB(Ham_Classify, iTarget) && !ExecuteHamB(Ham_IsAlive, iTarget))
	{
		Grapple_EndAttack(iItem, iOwner);
		return;
	}
	
	set_pev(iGrappleTip, pev_nextthink, get_gametime() + 0.1);
	
	if (!wpnmod_get_offset_int(iGrappleTip, Offset_iPull) || wpnmod_get_offset_float(iItem, Offset_flReleaseThrow))
	{
		return;
	}
	
	pev(iOwner, pev_origin, vecPlayerOrigin);
	pev(iGrappleTip, pev_origin, vecGrappleOrigin);
	
	flDistance = get_distance_f(vecGrappleOrigin, vecPlayerOrigin);
	
	if (flDistance)
	{
		xs_vec_sub(vecGrappleOrigin, vecPlayerOrigin, vecGrappleOrigin);
		xs_vec_mul_scalar(vecGrappleOrigin, GRAPPLE_PULL_VELOCITY / flDistance, vecVelocity);
		set_pev(iOwner, pev_velocity, vecVelocity);
	}
}

//**********************************************
//* Tongue tip touch func.                     *
//**********************************************

public GrappleTip_TongueTouch(const iGrappleTip, const iOther)
{
	new iHit;
	new iItem;
	new iOwner;
	
	new szClassName[32];
	new szTextureName[13];
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	iItem = pev(iGrappleTip, pev_iuser4);
	iOwner = pev(iGrappleTip, pev_owner);
	
	pev(iGrappleTip, pev_origin, vecOrigin);
	pev(iGrappleTip, pev_velocity, vecVelocity);
	
	if (pev(iOther, pev_flags) & (FL_CLIENT | FL_MONSTER))
	{
		iHit = true;
		
		set_pev(iGrappleTip, pev_movetype, MOVETYPE_FOLLOW);
		set_pev(iGrappleTip, pev_skin, iOther);
		set_pev(iGrappleTip, pev_body, 0);
		set_pev(iGrappleTip, pev_aiment, iOther);
	}
	else
	{
		pev(iOther, pev_classname, szClassName, charsmax(szClassName));
		
		if (equali(szClassName, "ammo_spore"))
		{
			iHit = true;
		}
		else
		{
			xs_vec_normalize(vecVelocity, vecVelocity);
			xs_vec_mul_scalar(vecVelocity, 8.0, vecVelocity);
			xs_vec_add(vecVelocity, vecOrigin, vecVelocity);
			
			engfunc(EngFunc_TraceTexture, iOther, vecOrigin, vecVelocity, szTextureName, charsmax(szTextureName));
			
			if (equali(szTextureName, "xeno_grapple"))
			{
				iHit = true;
			}
		}	
	}
	
	if (!iHit)
	{
		Grapple_EndAttack(iItem, iOwner);
	}
	else
	{
		wpnmod_set_think(iGrappleTip, "GrappleTip_PullThink");
		set_pev(iGrappleTip, pev_nextthink, get_gametime() + 0.1);
		
		emit_sound(iOwner, CHAN_ITEM, SOUND_IMPACT, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	
	set_pev(iGrappleTip, pev_solid, SOLID_NOT);
	set_pev(iGrappleTip, pev_velocity, Float: {0.0, 0.0, 0.0});
	
	wpnmod_set_offset_int(iGrappleTip, Offset_iPull, iHit);
	wpnmod_set_offset_int(iGrappleTip, Offset_iTarget, iOther);
}

//**********************************************
//* Make damage to victim.                     *
//**********************************************

public Grapple_Stab(const iItem, const iPlayer)
{
	new Float: flDmgTime;
	new Float: flGameTime = get_gametime();
	
	pev(iItem, pev_dmgtime, flDmgTime);
	
	if (flDmgTime > flGameTime)
	{
		return;
	}
	
	set_pev(iItem, pev_dmgtime, flGameTime + 0.5);
	
	#define Instance(%0) ((%0 == -1) ? 0 : %0)
	
	new iTrace;
	new iTarget;
	new iEntity;
	new iGrappleTip;
	
	new Float: vecSrc[3];
	new Float: vecEnd[3];
	new Float: vecAngle[3];
	new Float: vecForward[3];
	new Float: flFraction;
	
	iTrace = create_tr2();
	iGrappleTip = wpnmod_get_offset_int(iItem, Offset_iTip);
	iTarget = wpnmod_get_offset_int(iGrappleTip, Offset_iTarget);
	
	pev(iPlayer, pev_origin, vecSrc);
	pev(iPlayer, pev_v_angle, vecAngle);
	
	engfunc(EngFunc_MakeVectors, vecAngle);	
	global_get(glb_v_forward, vecForward);
	
	xs_vec_mul_scalar(vecForward, 32.0, vecForward);
	xs_vec_add(vecForward, vecSrc, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);
		
		if (flFraction < 1.0)
		{
			new iHit = Instance(get_tr2(iTrace, TR_pHit));
			
			if (!iHit || ExecuteHamB(Ham_IsBSPModel, iHit))
			{
				FindHullIntersection(vecSrc, iTrace, Float: {-16.0, -16.0, -18.0}, Float: {16.0,  16.0,  18.0}, iPlayer);
			}
			
			get_tr2(iTrace, TR_vecEndPos, vecEnd);
		}
	}
	
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		iEntity = Instance(get_tr2(iTrace, TR_pHit));
		
		if (iEntity && ExecuteHamB(Ham_Classify, iEntity) != CLASS_NONE && iEntity == iTarget)
		{
			wpnmod_clear_multi_damage();
			
			pev(iPlayer, pev_v_angle, vecAngle);
			engfunc(EngFunc_MakeVectors, vecAngle);	
			
			global_get(glb_v_forward, vecForward);
			ExecuteHamB(Ham_TraceAttack, iEntity, iPlayer, 50.0, vecForward, iTrace, DMG_SLASH | DMG_ALWAYSGIB);
			
			wpnmod_apply_multi_damage(iPlayer, iPlayer);
				
			switch (random_num(0, 1))
			{
				case 0: emit_sound(iPlayer, CHAN_ITEM, SOUND_CHEW_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 1: emit_sound(iPlayer, CHAN_ITEM, SOUND_CHEW_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 2: emit_sound(iPlayer, CHAN_ITEM, SOUND_CHEW_3, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
		}
	}

	free_tr2(iTrace);
}

//**********************************************
//* Some usefull stocks.                       *
//**********************************************

stock FindHullIntersection(const Float: vecSrc[3], &iTrace, const Float: vecMins[3], const Float: vecMaxs[3], const iEntity)
{
	new i, j, k;
	new iTempTrace;
	
	new Float: vecEnd[3];
	new Float: vecEndPos[3];
	new Float: vecHullEnd[3];
	new Float: vecMinMaxs[2][3];
	
	new Float: flDistance;
	new Float: flFraction;
	new Float: flThisDistance;
	
	flDistance = 999999.0;
	
	xs_vec_copy(vecMins, vecMinMaxs[0]);
	xs_vec_copy(vecMaxs, vecMinMaxs[1]);
	
	get_tr2(iTrace, TR_vecEndPos, vecHullEnd);
	
	xs_vec_sub(vecHullEnd, vecSrc, vecHullEnd);
	xs_vec_mul_scalar(vecHullEnd, 2.0, vecHullEnd);
	xs_vec_add(vecHullEnd, vecSrc, vecHullEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecHullEnd, DONT_IGNORE_MONSTERS, iEntity, (iTempTrace = create_tr2()));
	get_tr2(iTempTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		free_tr2(iTrace);
		
		iTrace = iTempTrace;
		return;
	}
	
	for (i = 0; i < 2; i++)
	{
		for (j = 0; j < 2; j++)
		{
			for (k = 0; k < 2; k++)
			{
				vecEnd[0] = vecHullEnd[0] + vecMinMaxs[i][0];
				vecEnd[1] = vecHullEnd[1] + vecMinMaxs[j][1];
				vecEnd[2] = vecHullEnd[2] + vecMinMaxs[k][2];
				
				engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iEntity, iTempTrace);
				get_tr2(iTempTrace, TR_flFraction, flFraction);
				
				if (flFraction < 1.0)
				{
					get_tr2(iTempTrace, TR_vecEndPos, vecEndPos);
					xs_vec_sub(vecEndPos, vecSrc, vecEndPos);
					
					if ((flThisDistance = xs_vec_len(vecEndPos)) < flDistance)
					{
						free_tr2(iTrace);
						
						iTrace = iTempTrace;
						flDistance = flThisDistance;
					}
				}
			}
		}
	}
}
