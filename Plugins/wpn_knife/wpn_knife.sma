/* AMX Mod X
*	Combat Knife.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "Combat Knife"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_knife"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			3 // NULL
#define WEAPON_PRIMARY_AMMO		""
#define WEAPON_PRIMARY_AMMO_MAX		-1
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		-1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			0
#define WEAPON_DAMAGE			10.0
#define WEAPON_DAMAGE_STAB		40.0
#define WEAPON_DAMAGE_BACK		1000.0

#define	KNIFE_BODYHIT_VOLUME		128
#define	KNIFE_WALLHIT_VOLUME		512

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_knife.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_knife.spr"

// Models
#define MODEL_WORLD			"models/w_knife.mdl"
#define MODEL_VIEW			"models/v_knife.mdl"
#define MODEL_PLAYER			"models/p_knife.mdl"

// Sounds
#define SOUND_MISS_1			"weapons/knife1.wav"
#define SOUND_MISS_2			"weapons/knife2.wav"
#define SOUND_MISS_3			"weapons/knife3.wav"
#define SOUND_HIT_WALL_1		"weapons/knife_hit_wall1.wav"
#define SOUND_HIT_WALL_2		"weapons/knife_hit_wall2.wav"
#define SOUND_HIT_FLESH_1		"weapons/knife_hit_flesh1.wav"
#define SOUND_HIT_FLESH_2		"weapons/knife_hit_flesh2.wav"

// Animation
#define ANIM_EXTENSION			"crowbar"

enum _:Animation 
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_HOLSTER,
	ANIM_ATTACK1HIT,
	ANIM_ATTACK1MISS,
	ANIM_ATTACK2MISS,
	ANIM_ATTACK2HIT,
	ANIM_ATTACK3MISS,
	ANIM_ATTACK3HIT,
	ANIM_IDLE2,
	ANIM_IDLE3,
	ANIM_CHARGE,
	ANIM_STAB
};

new g_sModelIndexBloodDrop;
new g_sModelIndexBloodSpray;

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_MISS_1);
	PRECACHE_SOUND(SOUND_MISS_2);
	PRECACHE_SOUND(SOUND_MISS_3);
	PRECACHE_SOUND(SOUND_HIT_WALL_1);
	PRECACHE_SOUND(SOUND_HIT_WALL_2);
	PRECACHE_SOUND(SOUND_HIT_FLESH_1);
	PRECACHE_SOUND(SOUND_HIT_FLESH_2);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	g_sModelIndexBloodDrop = PRECACHE_MODEL("sprites/blood.spr");
	g_sModelIndexBloodSpray = PRECACHE_MODEL("sprites/bloodspray.spr");
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iKnife = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iKnife, Fwd_Wpn_Spawn, "Knife_Spawn");
	wpnmod_register_weapon_forward(iKnife, Fwd_Wpn_Deploy, "Knife_Deploy");
	wpnmod_register_weapon_forward(iKnife, Fwd_Wpn_Idle, "Knife_Idle");
	wpnmod_register_weapon_forward(iKnife, Fwd_Wpn_PrimaryAttack, "Knife_PrimaryAttack");
	wpnmod_register_weapon_forward(iKnife, Fwd_Wpn_SecondaryAttack, "Knife_SecondaryAttack");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public Knife_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public Knife_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public Knife_Idle(const iItem)
{
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	new iAnim;
	new Float: flRand;
	new Float: flNextIdle;
	
	if ((flRand = random_float(0.0, 1.0)) <= 0.8)
	{
		iAnim = ANIM_IDLE2;
		flNextIdle = 5.4;
	}
	else if (flRand <= 0.9)
	{
		iAnim = ANIM_IDLE;
		flNextIdle = 2.7;
	}
	else
	{
		iAnim = ANIM_IDLE3;
		flNextIdle = 5.4;
	}
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public Knife_PrimaryAttack(const iItem, const iPlayer)
{
	switch (random_num(0, 2))
	{
		case 0: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 1: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 2: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_3, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	if (!Knife_Swing(iItem, iPlayer, 1, 0))
	{
		wpnmod_set_think(iItem, "Knife_SwingAgain");
		set_pev(iItem, pev_nextthink, get_gametime() + 0.1);
	}

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public Knife_SecondaryAttack(const iItem)
{
	wpnmod_set_think(iItem, "Knife_Stab");
	wpnmod_send_weapon_anim(iItem, ANIM_CHARGE);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.4);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.4);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
	
	set_pev(iItem, pev_nextthink, get_gametime() + 0.7);
}

//**********************************************
//* Knife damage functions.                    *
//**********************************************

FindHullIntersection(const Float: vecSrc[3], &iTrace, const Float: vecMins[3], const Float: vecMaxs[3], const iEntity)
{
	new i, j, k;
	new iTempTrace;
	
	new Float: vecEnd[3];
	new Float: flDistance;
	new Float: flFraction;
	new Float: vecEndPos[3];
	new Float: vecHullEnd[3];
	new Float: flThisDistance;
	new Float: vecMinMaxs[2][3];
	
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

Knife_Swing(const iItem, const iPlayer, const iFirst, const iStab)
{
	#define Offset_trHit Offset_iuser1
	#define Offset_iSwing Offset_iuser2
	
	#define Instance(%0) ((%0 == -1) ? 0 : %0)
	
	new iClass;
	new iTrace;
	new iSwing;
	new iDidHit;
	new iEntity;
	new iHitWorld;
	new iHitgroup;
	new iBloodColor;
	
	new Float: vecSrc[3];
	new Float: vecEnd[3];
	new Float: vecAngle[3];
	new Float: vecRight[3];
	new Float: vecForward[3];
	
	new Float: flDamage;
	new Float: flFraction;
	
	iTrace = create_tr2();
	iSwing = wpnmod_get_offset_int(iItem, Offset_iSwing);
	
	pev(iPlayer, pev_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	
	GetGunPosition(iPlayer, vecSrc);
	
	global_get(glb_v_right, vecRight);
	global_get(glb_v_forward, vecForward);
	
	if (!iStab)
	{
		xs_vec_mul_scalar(vecForward, 32.0, vecForward);
		xs_vec_add(vecForward, vecSrc, vecEnd);
	}
	else
	{
		xs_vec_mul_scalar(vecRight, 6.0, vecRight);
		xs_vec_mul_scalar(vecForward, 42.0, vecForward);
		
		xs_vec_add(vecRight, vecForward, vecForward);
		xs_vec_add(vecForward, vecSrc, vecEnd);
	}
	
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
	
	if (flFraction >= 1.0)
	{
		if (iFirst)
		{
			if (!iStab)
			{		
				switch ((iSwing++) % 3)
				{
					case 0: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK1MISS);
					case 1: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK2MISS);
					case 2: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK3MISS);
				}
					
				wpnmod_set_offset_int(iItem, Offset_iSwing, iSwing);
				wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.5);
				wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
			}
			
			wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
		}
	}
	else
	{
		if (!iStab)
		{	
			switch ((iSwing++) % 3)
			{
				case 0: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK1HIT);
				case 1: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK2HIT);
				case 2: wpnmod_send_weapon_anim(iItem, ANIM_ATTACK3HIT);
			}
			
			wpnmod_set_offset_int(iItem, Offset_iSwing, iSwing);
		}
		
		iDidHit = true;
		iEntity = Instance(get_tr2(iTrace, TR_pHit));
		flDamage = iStab ? WEAPON_DAMAGE_STAB : WEAPON_DAMAGE;
		
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);

		if (pev_valid(iEntity))
		{
			GetCenter(iEntity, vecSrc);
			GetCenter(iPlayer, vecEnd);
		       
			xs_vec_sub(vecEnd, vecSrc, vecEnd);
			xs_vec_normalize(vecEnd, vecEnd);
		       
			pev(iEntity, pev_angles, vecAngle);
			engfunc(EngFunc_MakeVectors, vecAngle);
		       
			global_get(glb_v_forward, vecForward);
			xs_vec_mul_scalar(vecEnd, -1.0, vecEnd);
		       
			if (xs_vec_dot(vecForward, vecEnd) > 0.3)
			{
				flDamage = WEAPON_DAMAGE_BACK;
			}
			
			if ((iHitgroup = get_tr2(iTrace, TR_iHitgroup)) == HIT_HEAD)
			{
				flDamage *= 3.0;
			}
			
			if (ExecuteHamB(Ham_IsPlayer, iEntity))
			{
				wpnmod_set_offset_int(iEntity, Offset_iLastHitGroup, iHitgroup);
			}
			
			if ((iBloodColor = ExecuteHamB(Ham_BloodColor, iEntity)) != -1)
			{
				pev(iPlayer, pev_v_angle, vecAngle);
				engfunc(EngFunc_MakeVectors, vecAngle);
				
				global_get(glb_v_forward, vecForward);
				get_tr2(iTrace, TR_vecEndPos, vecEnd);
				
				xs_vec_mul_scalar(vecForward, 4.0, vecSrc);
				xs_vec_sub(vecEnd, vecSrc, vecEnd);
						
				UTIL_BloodDrips(vecEnd, iBloodColor, floatround(flDamage));
				ExecuteHamB(Ham_TraceBleed, iEntity, flDamage, vecForward, iTrace, DMG_CLUB | DMG_NEVERGIB);
			}
			
			ExecuteHamB(Ham_TakeDamage, iEntity, iPlayer, iPlayer, flDamage, DMG_CLUB | DMG_NEVERGIB);
		}
		
		iHitWorld = true;
			
		if (iEntity && (iClass = ExecuteHamB(Ham_Classify, iEntity)) != CLASS_NONE && iClass != CLASS_MACHINE)
		{
			switch (random_num(0, 1))
			{
				case 0: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_FLESH_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 1: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_FLESH_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
				
			wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, KNIFE_BODYHIT_VOLUME);
				
			if (!ExecuteHamB(Ham_IsAlive, iEntity))
			{
				return true;
			}
				
			iHitWorld = false;
		}
			
		if (iHitWorld)
		{
			switch (random_num(0, 1))
			{
				case 0: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_WALL_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 1: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_WALL_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
				
			wpnmod_set_offset_int(iItem, Offset_trHit, iTrace);
		}
			
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, KNIFE_WALLHIT_VOLUME);
			
		if (!iStab)
		{
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.2);
		}
		
		wpnmod_set_think(iItem, "Knife_Smack");
		set_pev(iItem, pev_nextthink, get_gametime() + 0.2);
	}

	free_tr2(iTrace);
	return iDidHit;
}

//**********************************************
//* Knife think functions.                     *
//**********************************************

public Knife_Stab(const iItem, const iPlayer)
{
	wpnmod_send_weapon_anim(iItem, ANIM_STAB);
	
	switch (random_num(0, 2))
	{
		case 0: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 1: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 2: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_3, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	Knife_Swing(iItem, iPlayer, 1, 1);
}

public Knife_SwingAgain(const iItem, const iPlayer)
{
	Knife_Swing(iItem, iPlayer, 0, 0);
}

public Knife_Smack(const iItem)
{
	new iTrace = wpnmod_get_offset_int(iItem, Offset_trHit);
	
	UTIL_DecalTrace(iTrace, get_decal_index("{shot1") + random_num(0, 4));
	free_tr2(iTrace);
}

//**********************************************
//* Some usefull stocks.                       *
//**********************************************
 
stock GetGunPosition(const iPlayer, Float: vecResult[3])
{
	new Float: vecViewOfs[3];
	
	pev(iPlayer, pev_origin, vecResult);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
    
	xs_vec_add(vecResult, vecViewOfs, vecResult);
} 
 
stock GetCenter(const iEntity, Float: vecSrc[3])
{
        new Float: vecAbsMax[3];
        new Float: vecAbsMin[3];
       
        pev(iEntity, pev_absmax, vecAbsMax);
        pev(iEntity, pev_absmin, vecAbsMin);
       
        xs_vec_add(vecAbsMax, vecAbsMin, vecSrc);
        xs_vec_mul_scalar(vecSrc, 0.5, vecSrc);
}

stock UTIL_BloodDrips(const Float: vecOrigin[3], const iColor, iAmount)
{
	if (iColor == -1 || !iAmount)
	{
		return;
	}
	
	iAmount *= 2;
	
	if (iAmount > 255)
	{
		iAmount = 255;
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_sModelIndexBloodSpray);
	write_short(g_sModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

stock UTIL_DecalTrace(const iTrace, iDecalIndex)
{
	new iHit;
	new iEntity;
	new iMessage;
	
	new Float: flFraction;
	new Float: vecEndPos[3];
	
	if (iDecalIndex < 0 || get_tr2(iTrace, TR_flFraction, flFraction) && flFraction == 1.0)
	{
		return;
	}
        
	if (pev_valid((iHit = get_tr2(iTrace, TR_pHit))))
	{
		if (iHit && !((pev(iHit, pev_solid) == SOLID_BSP) || (pev(iHit, pev_movetype) == MOVETYPE_PUSHSTEP)))
		{
			return;
		}
		
		iEntity = iHit;
	}
	else
	{
		iEntity = 0;
	}
        
	iMessage = TE_DECAL;
	
	if (iEntity != 0)
	{
		if (iDecalIndex > 255)
		{
			iMessage = TE_DECALHIGH;
			iDecalIndex -= 256;
		}
	}
	else
	{
		iMessage = TE_WORLDDECAL;
		
		if (iDecalIndex > 255)
		{
			iMessage = TE_WORLDDECALHIGH;
			iDecalIndex -= 256;
		}
	}
    
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(iMessage);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_byte(iDecalIndex);
        
	if (iEntity)
	{
		write_short(iEntity);
	}
    
	message_end();
} 
