/* AMX Mod X
*	AK-47: Avtomat Kalashnikova.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/


// UNDEFINE TO USE CSO MODEL BY KOSHAK
//#define _CSO_

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "AK-47: Avtomat Kalashnikova"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_ak47"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"762x39"
#define WEAPON_PRIMARY_AMMO_MAX		90
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			30
#define WEAPON_DEFAULT_AMMO		30
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			16.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_ak47.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_ak47.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_ak47clip"

// Models and sounds
#define MODEL_CLIP			"models/w_ak47_clip.mdl"
#define MODEL_SHELL			"models/shell_762x39.mdl"

#if defined _CSO_
	#define MODEL_WORLD		"models/w_ak47_cso.mdl"
	#define MODEL_VIEW		"models/v_ak47_cso.mdl"
	#define MODEL_PLAYER		"models/p_ak47_cso.mdl"
	
	#define SOUND_COCK		"weapons/ak47_boltpull.wav"
	#define SOUND_FIRE		"weapons/ak47-1.wav"
	#define SOUND_RELOAD_1		"weapons/ak47_clipin.wav"
	#define SOUND_RELOAD_2		"weapons/ak47_clipout.wav"
#else
	#define MODEL_WORLD		"models/w_ak47_fa.mdl"
	#define MODEL_VIEW		"models/v_ak47_fa.mdl"
	#define MODEL_PLAYER		"models/p_ak47_fa.mdl"
	
	#define SOUND_COCK		"weapons/ak47_cock.wav"
	#define SOUND_FIRE		"weapons/ak47_fire1.wav"
	#define SOUND_RELOAD_1		"weapons/ak47_magin.wav"
	#define SOUND_RELOAD_2		"weapons/ak47_magout.wav"
#endif

#define SOUND_MISS_1			"weapons/bayonet_slash1.wav"
#define SOUND_MISS_2			"weapons/bayonet_slash2.wav"
#define SOUND_MISS_3			"weapons/bayonet_slash3.wav"

#define SOUND_HIT_WALL			"weapons/bayonet_hit_wall.wav"
#define SOUND_HIT_FLESH_1		"weapons/knife_hit_flesh1.wav"
#define SOUND_HIT_FLESH_2		"weapons/knife_hit_flesh2.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
#if defined _CSO_
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DEPLOY,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_FIRE_3,
	ANIM_STAB
#else
	ANIM_IDLE_1,
	ANIM_IDLE_2,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_STAB,
	ANIM_RELOAD_A,
	ANIM_RELOAD_A_EMPTY,
	ANIM_RELOAD_B,
	ANIM_RELOAD_B_EMPTY,
	ANIM_DEPLOY,
	ANIM_HOLSTER
#endif
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
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_COCK);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_MISS_1);
	PRECACHE_SOUND(SOUND_MISS_2);
	PRECACHE_SOUND(SOUND_MISS_3);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_RELOAD_2);
	PRECACHE_SOUND(SOUND_HIT_WALL);
	PRECACHE_SOUND(SOUND_HIT_FLESH_1);
	PRECACHE_SOUND(SOUND_HIT_FLESH_2);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iAK47 = wpnmod_register_weapon
	
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
	
	new iAmmoAK47= wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_Spawn, "AK47_Spawn");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_Deploy, "AK47_Deploy");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_Idle, "AK47_Idle");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_PrimaryAttack, "AK47_PrimaryAttack");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_SecondaryAttack, "AK47_SecondaryAttack");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_Reload, "AK47_Reload");
	wpnmod_register_weapon_forward(iAK47, Fwd_Wpn_Holster, "AK47_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoAK47, Fwd_Ammo_Spawn, "AmmoAK47_Spawn");
	wpnmod_register_ammobox_forward(iAmmoAK47, Fwd_Ammo_AddAmmo, "AmmoAK47_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public AK47_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public AK47_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DEPLOY, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public AK47_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public AK47_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
#if defined _CSO_
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
#else		
	new iAnim;
	new Float: flNextIdle;
	
	if (random_float(0.0, 1.0) <= 0.75)
	{
		iAnim = ANIM_IDLE_1;
		flNextIdle = 5.0;
	}
	else 
	{
		iAnim = ANIM_IDLE_2;
		flNextIdle = 6.2;
	}
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
#endif
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public AK47_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
#if defined _CSO_
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_3));
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 16.0, -12.0, 10.0);
#else
	wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_2));
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 18.0, -12.0, 4.0);
#endif
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_2DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		3
	);
	
	vecPunchangle[0] = random_float(-2.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public AK47_SecondaryAttack(const iItem, const iPlayer)
{
	wpnmod_set_think(iItem, "AK47_Stab");
	wpnmod_send_weapon_anim(iItem, ANIM_STAB);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.65);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.65);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
	
	set_pev(iItem, pev_nextthink, get_gametime() + 0.3);
}

//**********************************************
//* Think functions.                           *
//**********************************************

public AK47_Stab(const iItem, const iPlayer)
{
	#define Offset_trHit Offset_iuser1
	#define Instance(%0) ((%0 == -1) ? 0 : %0)
	
	new iClass;
	new iTrace;
	new iEntity;
	new iHitWorld;
	
	new Float: vecSrc[3];
	new Float: vecEnd[3];
	new Float: vecUp[3];
	new Float: vecAngle[3];
	new Float: vecRight[3];
	new Float: vecForward[3];
	
	new Float: flFraction;
	
	iTrace = create_tr2();
	
	pev(iPlayer, pev_v_angle, vecAngle);
	engfunc(EngFunc_MakeVectors, vecAngle);
	
	GetGunPosition(iPlayer, vecSrc);
	
	global_get(glb_v_up, vecUp);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_forward, vecForward);

	xs_vec_mul_scalar(vecUp, -2.0, vecUp);
	xs_vec_mul_scalar(vecRight, 1.0, vecRight);
	xs_vec_mul_scalar(vecForward, 48.0, vecForward);
		
	xs_vec_add(vecUp, vecRight, vecRight);
	xs_vec_add(vecRight, vecForward, vecForward);
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
	
	switch (random_num(0, 2))
	{
		case 0: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 1: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 2: emit_sound(iPlayer, CHAN_WEAPON, SOUND_MISS_3, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	if (flFraction < 1.0)
	{
		iHitWorld = true;
		iEntity = Instance(get_tr2(iTrace, TR_pHit));
		
		wpnmod_clear_multi_damage();
		
		pev(iPlayer, pev_v_angle, vecAngle);
		engfunc(EngFunc_MakeVectors, vecAngle);	
		
		global_get(glb_v_forward, vecForward);
		ExecuteHamB(Ham_TraceAttack, iEntity, iPlayer, WEAPON_DAMAGE * 2.5, vecForward, iTrace, DMG_CLUB | DMG_NEVERGIB);
		
		wpnmod_apply_multi_damage(iPlayer, iPlayer);
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
			
		if (iEntity && (iClass = ExecuteHamB(Ham_Classify, iEntity)) != CLASS_NONE && iClass != CLASS_MACHINE)
		{
			switch (random_num(0, 1))
			{
				case 0: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_FLESH_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 1: emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_FLESH_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
				
			if (!ExecuteHamB(Ham_IsAlive, iEntity))
			{
				return;
			}
				
			iHitWorld = false;
		}
			
		if (iHitWorld)
		{
			wpnmod_set_offset_int(iItem, Offset_trHit, iTrace);
			emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_WALL, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		wpnmod_set_think(iItem, "AK47_Smack");
		set_pev(iItem, pev_nextthink, get_gametime() + 0.1);
	}

	free_tr2(iTrace);
}

public AK47_Smack(const iItem)
{
	new iTrace = wpnmod_get_offset_int(iItem, Offset_trHit);
	
	UTIL_DecalTrace(iTrace, get_decal_index("{shot1") + random_num(0, 4));
	free_tr2(iTrace);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public AK47_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
#if defined _CSO_
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.45);
#else
	new iAnim;
	new iInSpecialReload;
	
	new Float: flNextReload = 2.05;
	
	iAnim = (iInSpecialReload = wpnmod_get_offset_int(iItem, Offset_iInSpecialReload)) ? ANIM_RELOAD_B : ANIM_RELOAD_A;
	
	if (!iClip)
	{
		iAnim ++;
		flNextReload = 2.52;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, iAnim, flNextReload);
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, !iInSpecialReload);
#endif	
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public AmmoAK47_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoAK47_AddAmmo(const iItem, const iPlayer)
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

//**********************************************
//* Some usefull stocks.                       *
//**********************************************

stock FindHullIntersection(const Float: vecSrc[3], &iTrace, const Float: vecMins[3], const Float: vecMaxs[3], const iEntity)
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
	
	#define write_coord_f(%0) engfunc(EngFunc_WriteCoord,%0)
    
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(iMessage);
	write_coord_f(vecEndPos[0]);
	write_coord_f(vecEndPos[1]);
	write_coord_f(vecEndPos[2]);
	write_byte(iDecalIndex);
	
	#undef write_coord_f
        
	if (iEntity)
	{
		write_short(iEntity);
	}
    
	message_end();
} 

stock GetGunPosition(const iPlayer, Float: vecResult[3])
{
	new Float: vecViewOfs[3];
	
	pev(iPlayer, pev_origin, vecResult);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
    
	xs_vec_add(vecResult, vecViewOfs, vecResult);
} 
