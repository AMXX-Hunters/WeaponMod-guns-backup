/* AMX Mod X
*	M1 Garand.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <hl_wpnmod>
#include <xs>

#define PLUGIN "M1 Garand"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7 (Basic Code) and BG Rampo (Optimized code)"

// Weapon settings
#define WEAPON_NAME 			"weapon_garand"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"556 En-Block"
#define WEAPON_PRIMARY_AMMO_MAX		80
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			8
#define WEAPON_DEFAULT_AMMO		8
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			100.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_garand.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_garandclip"

// Models and sounds
#define MODEL_CLIP			"models/w_garand_clip.mdl"
#define MODEL_SHELL			"models/shell_762x39.mdl"

#define MODEL_WORLD		"models/w_garand.mdl"
#define MODEL_VIEW		"models/v_garand.mdl"
#define MODEL_PLAYER		"models/p_garand.mdl"
	
#define SOUND_FIRE		"weapons/garand_fire1.wav"
#define SOUND_FIRE2		"weapons/garand_fire2.wav"

#define SOUND_MISS_1			"weapons/garand_slash1.wav"
#define SOUND_MISS_2			"weapons/garand_slash2.wav"
#define SOUND_MISS_3			"weapons/garand_slash3.wav"

#define SOUND_HIT_WALL			"weapons/garand_hit_wall.wav"
#define SOUND_HIT_FLESH_1		"weapons/garand_hit_flesh1.wav"
#define SOUND_HIT_FLESH_2		"weapons/garand_hit_flesh2.wav"

// Animation
#define ANIM_EXTENSION			"bow"

enum _:Animation
{
	ANIM_IDLE_1,
	ANIM_FIRE_1,
	ANIM_FIRE_2,
	ANIM_FIRE_3,
	ANIM_FIRE_EMPTY,
	ANIM_RELOAD,
	ANIM_DEPLOY,
	ANIM_IDLE_2,
	ANIM_DEPLOY_EMPTY,
	ANIM_STAB,
	ANIM_STAB_EMPTY
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
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE2);
	PRECACHE_SOUND(SOUND_MISS_1);
	PRECACHE_SOUND(SOUND_MISS_2);
	PRECACHE_SOUND(SOUND_MISS_3);
	PRECACHE_SOUND(SOUND_HIT_WALL);
	PRECACHE_SOUND(SOUND_HIT_FLESH_1);
	PRECACHE_SOUND(SOUND_HIT_FLESH_2);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	
	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new igarand = wpnmod_register_weapon
	
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
	
	new iAmmogarand= wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_Spawn, "garand_Spawn");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_Deploy, "garand_Deploy");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_Idle, "garand_Idle");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_PrimaryAttack, "garand_PrimaryAttack");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_SecondaryAttack, "garand_SecondaryAttack");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_Reload, "garand_Reload");
	wpnmod_register_weapon_forward(igarand, Fwd_Wpn_Holster, "garand_Holster");
	
	wpnmod_register_ammobox_forward(iAmmogarand, Fwd_Ammo_Spawn, "Ammogarand_Spawn");
	wpnmod_register_ammobox_forward(iAmmogarand, Fwd_Ammo_AddAmmo, "Ammogarand_AddAmmo");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public garand_Spawn(const iItem)
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

public garand_Deploy(const iItem, const iPlayer, const iClip)
{
	new anim;
	if ( iClip >= 1)
	{
		anim = ANIM_DEPLOY;
	}
	else
	{
		anim = ANIM_DEPLOY_EMPTY;
	}
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, anim, ANIM_EXTENSION);	
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public garand_Holster(const iItem)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public garand_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	if ( iClip >= 1)
	{
		wpnmod_send_weapon_anim(iItem, ANIM_IDLE_1);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, ANIM_IDLE_2);
	}
	
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.2);

}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public garand_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.65);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.65);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.45);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.95);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);

	if ( iClip > 1)
	{
		wpnmod_send_weapon_anim(iItem, random_num(ANIM_FIRE_1, ANIM_FIRE_2));
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	else if (iClip == 1)
	{
		wpnmod_send_weapon_anim(iItem, ANIM_FIRE_EMPTY);
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	
	wpnmod_eject_brass(iPlayer, g_iShell, 1, 18.0, -12.0, 4.0);

	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_2DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		1
	);
	
	vecPunchangle[0] = random_float(-1.75, 1.75);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public garand_SecondaryAttack(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_think(iItem, "garand_Stab");

	if ( iClip >= 1)
	{
		wpnmod_send_weapon_anim(iItem, ANIM_STAB);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, ANIM_STAB_EMPTY);
	}
	
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.05);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.95);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.0);
	
	set_pev(iItem, pev_nextthink, get_gametime() + 0.1);
}

//**********************************************
//* Think functions.                           *
//**********************************************

public garand_Stab(const iItem, const iPlayer)
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
		
		wpnmod_set_think(iItem, "garand_Smack");
		set_pev(iItem, pev_nextthink, get_gametime() + 0.1);
	}

	free_tr2(iTrace);
}

public garand_Smack(const iItem)
{
	new iTrace = wpnmod_get_offset_int(iItem, Offset_trHit);
	
	UTIL_DecalTrace(iTrace, get_decal_index("{shot1") + random_num(0, 4));
	free_tr2(iTrace);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public garand_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP || iClip != 0)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP,ANIM_RELOAD, 3.05);
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public Ammogarand_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public Ammogarand_AddAmmo(const iItem, const iPlayer)
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
