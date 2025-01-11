/* AMX Mod X
*	Lightsaber.
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


#define PLUGIN "Lightsaber"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7"


// Weapon settings
#define WEAPON_NAME 			"weapon_lightsaber"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			5 // NULL
#define WEAPON_PRIMARY_AMMO		""
#define WEAPON_PRIMARY_AMMO_MAX		-1
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		-1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			0

// Damage
#define WEAPON_DAMAGE			20.0
#define WEAPON_RADIUS_SWING		64.0
#define WEAPON_RADIUS_STAB		32.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_lightsaber.txt"
#define WEAPON_HUD_SPR			"sprites/hud_weapons1.spr"

// Models
#define MODEL_WORLD			"models/w_lightsaber.mdl"
#define MODEL_VIEW			"models/v_lightsaber.mdl"
#define MODEL_PLAYER_ON			"models/p_lightsaber_on.mdl"
#define MODEL_PLAYER_OFF		"models/p_lightsaber_off.mdl"

// Animation
#define ANIM_EXTENSION			"crowbar"

enum _:eAnimation 
{
	ANIM_IDLE = 0,
	ANIM_ON,
	ANIM_OFF,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_IDLE2,
	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
	ANIM_MIDSLASH3,
	ANIM_OFF_IDLE,
	ANIM_OFF_SLASH	
};

// Sounds	
enum _: eSounds
{
	SND_IDLE,
	SND_OFF,
	SND_HIT_WALL_1,
	SND_HIT_WALL_2,
	SND_HIT_WALL_3,
	SND_HIT_FLESH_1,
	SND_HIT_FLESH_2,
	SND_HIT_FLESH_3,
	
	SND_END
}
	
new const g_szSounds[SND_END][] =
{
	"weapons/sfsword_idle.wav",
	"weapons/sfsword_off.wav",
	"weapons/sfsword_wall1.wav",
	"weapons/sfsword_wall2.wav",
	"weapons/knife_hit_wall2.wav",
	"weapons/sfsword_hit1.wav",
	"weapons/sfsword_hit2.wav",
	"weapons/sfsword_off_hit.wav"
};

//**********************************************

#define wpnmod_set_think2(%0,%1,%2)			\
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)
	
#define Offset_bIsOn Offset_iuser1
#define Offset_bForced Offset_iuser2
#define Offset_iSwing Offset_iuser3

//**********************************************

enum _:eAttacks
{
	ATTACK_SLASH_1,
	ATTACK_SLASH_2,
	ATTACK_SLASH_3,
	ATTACK_SLASH_DOUBLE
}

new g_iszPlayerModelOn;
new g_iszPlayerModelOff;
	
//**********************************************
//* Precache resources                         *
//**********************************************

#define PRECACHE_MODEL2(%0) PrecacheSoundsFromModel(%0)

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER_ON);
	PRECACHE_MODEL(MODEL_PLAYER_OFF);
	PRECACHE_MODEL2(MODEL_VIEW);
	
	for (new i = 0; i < SND_END; i++)
	{
		PRECACHE_SOUND(g_szSounds[i]);
	}
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	g_iszPlayerModelOn = engfunc(EngFunc_AllocString, MODEL_PLAYER_ON);
	g_iszPlayerModelOff = engfunc(EngFunc_AllocString, MODEL_PLAYER_OFF);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iLightSaber = wpnmod_register_weapon
	
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
	
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_Spawn, "LightSaber_Spawn");
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_Deploy, "LightSaber_Deploy");
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_Holster, "LightSaber_Holster");
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_Idle, "LightSaber_Idle");
	//wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_ItemPostFrame, "LightSaber_ItemPostFrame");
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_PrimaryAttack, "LightSaber_PrimaryAttack");
	wpnmod_register_weapon_forward(iLightSaber, Fwd_Wpn_SecondaryAttack, "LightSaber_SecondaryAttack");
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public LightSaber_Spawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public LightSaber_Deploy(const iItem, const iPlayer)
{
	// Apply default deploy.
	new iResult = wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER_ON, ANIM_DRAW, ANIM_EXTENSION);
	
	// Override default delays.
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.53);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.53);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.53);
	wpnmod_set_offset_float(iPlayer, Offset_flNextAttack, 0.0);
	
	// Lightsaber is on by default.
	wpnmod_set_offset_int(iItem, Offset_bIsOn, true);
	wpnmod_set_offset_int(iItem, Offset_bForced, false);
	
	return iResult;
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public LightSaber_Holster(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_int(iItem, Offset_bIsOn))
	{
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, g_szSounds[SND_OFF], 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, g_szSounds[SND_IDLE], 0.0, 0.0, SND_STOP, PITCH_NORM);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public LightSaber_Idle(const iItem, const iPlayer)
{
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	if (!wpnmod_get_offset_int(iItem, Offset_bIsOn))
	{
		wpnmod_send_weapon_anim(iItem, ANIM_OFF_IDLE);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.05);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 10.1);
	
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, g_szSounds[SND_IDLE], 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}

//**********************************************
//* Doing some weapon stuff.                   *
//**********************************************
/*
public LightSaber_ItemPostFrame(const iItem, const iPlayer)
{
	if (pev(iPlayer, pev_waterlevel) != 3 
		&& wpnmod_get_offset_int(iItem, Offset_bForced) 
		&& wpnmod_get_offset_float(iItem, Offset_flNextSecondaryAttack) <= 0.0)
	{
		// We get out from water.
		// Time to enable lightsaber again.
		LightSaber_SecondaryAttack(iItem, iPlayer);
		wpnmod_set_offset_int(iItem, Offset_bForced, false);
	}
	
	if (wpnmod_get_offset_int(iItem, Offset_bIsOn))
	{
		// Can't work under water!
		if (pev(iPlayer, pev_waterlevel) == 3)
		{
			// Disable lightsaber.
			LightSaber_SecondaryAttack(iItem, iPlayer);
			
			// Re enable later.
			wpnmod_set_offset_int(iItem, Offset_bForced, true);
		}
		
		static Float: flGametime, Float: vecOrigin[3];
		
		if (wpnmod_get_offset_float(iItem, Offset_fuser1) < (flGametime = get_gametime()))
		{
			pev(iPlayer, pev_origin, vecOrigin);
				
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_DLIGHT);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);	// X
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);	// Y
			engfunc(EngFunc_WriteCoord, vecOrigin[2]);	// Z
			write_byte(12);		// radius * 0.1
			write_byte(0);		// r
			write_byte(100);		// g
			write_byte(0);		// b
			write_byte(3);		// time * 10
			write_byte(0);		// decay * 0.1
			message_end();
				
			wpnmod_set_offset_float(iItem, Offset_fuser1, flGametime + 0.08);
		}
	}
}
*/
//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************
	
public  LightSaber_PrimaryAttack(const iItem, const iPlayer)
{
	if (!wpnmod_get_offset_int(iItem, Offset_bIsOn))
	{
		wpnmod_set_think2(iItem, "LightSaber_Stab", 0.35);
		wpnmod_send_weapon_anim(iItem, ANIM_OFF_SLASH);
	}
	else
	{
		new iStep = wpnmod_get_offset_int(iItem, Offset_iSwing) % eAttacks;
	
		switch (iStep)
		{
			case ATTACK_SLASH_DOUBLE:
			{
				wpnmod_send_weapon_anim(iItem, ANIM_STAB);
			}
			
			case ATTACK_SLASH_1..ATTACK_SLASH_3:
			{
				wpnmod_send_weapon_anim(iItem, ANIM_MIDSLASH1 + iStep);
			}
		}
		
		wpnmod_set_think2(iItem, "LightSaber_Swing", 0.35);
		wpnmod_set_offset_int(iItem, Offset_iSwing, wpnmod_get_offset_int(iItem, Offset_iSwing) + 1);
	}
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.53);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.53);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.53);
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public LightSaber_SecondaryAttack(const iItem, const iPlayer)
{
	if (!wpnmod_get_offset_int(iItem, Offset_bIsOn))
	{
		// Don't activate lightsaber under water.
		if (pev(iPlayer, pev_waterlevel) == 3)
		{
			return;
		}
		
		// Send "on" animation.
		wpnmod_send_weapon_anim(iItem, ANIM_ON);
		
		// Change p_ model.
		set_pev_string(iPlayer, pev_weaponmodel2, g_iszPlayerModelOn);
	}
	else
	{
		// Stop idle sound.
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, g_szSounds[SND_IDLE], 0.0, 0.0, SND_STOP, PITCH_NORM);
		
		// Send "off" animation.
		wpnmod_send_weapon_anim(iItem, ANIM_OFF);
		
		// Change p_ model.
		set_pev_string(iPlayer, pev_weaponmodel2, g_iszPlayerModelOff);
	}
	
	wpnmod_set_offset_int(iItem, Offset_bIsOn, !wpnmod_get_offset_int(iItem, Offset_bIsOn));
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.65);
	
	// Remove think.
	wpnmod_set_think(iItem, "");
}

//**********************************************
//* Think functions.                           *
//**********************************************

public LightSaber_Swing(const iItem, const iPlayer)
{
	new Float: flUpBase = 14.0;
	new Float: flRightBase = 14.0;
	new Float: flRightModifier = 2.0;
	
	switch ((wpnmod_get_offset_int(iItem, Offset_iSwing) - 1) % eAttacks)
	{
		case ATTACK_SLASH_2:
		{
			flRightBase *= -1.0;
			flRightModifier *= -1.0;
		}
		
		case ATTACK_SLASH_DOUBLE:
		{
			// Set attack animation on player model again.
			wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
				
			// Set 2-nd attack think.
			wpnmod_set_think2(iItem, "LightSaber_SwingAgain", 0.3);
		}
	}
	
	for (new i = 0; i < 12; i++)
	{
		LightSaber_Attack(iPlayer, flUpBase -= 2.0, flRightBase -= flRightModifier);
	}
}

public LightSaber_SwingAgain(const iItem, const iPlayer)
{	
	for (new Float: flRightBase = -14.0, i = 0; i < 14; i++)
	{
		LightSaber_Attack(iPlayer, .flRightScale = flRightBase += 2.0);
	}
}

public LightSaber_Stab(const iItem, const iPlayer)
{
	LightSaber_Attack(iPlayer, .bStab = true);
}

//**********************************************
//* Attack function.                           *
//**********************************************

LightSaber_Attack(const iPlayer, const Float: flRightScale = 1.0, const Float: flUpScale = 1.0, const bool: bStab = false)
{
	new iTrace;
	new iEntity;
	
	new Float: vecSrc[3];
	new Float: vecEnd[3];
	
	new Float: flFraction;
	
	wpnmod_get_gun_position(iPlayer, vecSrc);
	wpnmod_get_gun_position(iPlayer, vecEnd, bStab ? WEAPON_RADIUS_STAB : WEAPON_RADIUS_SWING, flRightScale, flUpScale);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, (iTrace = create_tr2()));
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);
		
		if (flFraction < 1.0)
		{
			iEntity = INSTANCE(get_tr2(iTrace, TR_pHit));
			
			if (!iEntity || ExecuteHamB(Ham_IsBSPModel, iEntity))
			{
				FindHullIntersection(vecSrc, iTrace, Float: {-16.0, -16.0, -18.0}, Float: {16.0,  16.0,  18.0}, iPlayer);
			}
		}
	}
	
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		global_get(glb_v_forward, vecSrc);
		
		wpnmod_clear_multi_damage();
		ExecuteHamB(Ham_TraceAttack, (iEntity = INSTANCE(get_tr2(iTrace, TR_pHit))), iPlayer, WEAPON_DAMAGE, vecSrc, iTrace, DMG_CLUB | (bStab ? DMG_NEVERGIB : DMG_ALWAYSGIB));
		wpnmod_apply_multi_damage(iPlayer, iPlayer);
		
		if (ExecuteHamB(Ham_IsPlayer, iEntity))
		{
			emit_sound(iPlayer, CHAN_ITEM, g_szSounds[bStab ? SND_HIT_FLESH_3: random_num(SND_HIT_FLESH_1, SND_HIT_FLESH_2)], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		else
		{
			if (bStab)
			{
				// Mark on the wall.
				wpnmod_decal_trace(iTrace, .szDecalName = "{shot2");
				
				// Hit wall sound.
				emit_sound(iPlayer, CHAN_ITEM, g_szSounds[SND_HIT_WALL_3], 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				wpnmod_decal_trace(iTrace, .szDecalName = random_num(0, 1) ? "{smscorch1" : "{smscorch2");
				
				get_tr2(iTrace, TR_vecEndPos, vecEnd);
				get_tr2(iTrace, TR_vecPlaneNormal, vecSrc);
			
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
				write_byte(TE_STREAK_SPLASH);
				engfunc(EngFunc_WriteCoord, vecEnd[0]);
				engfunc(EngFunc_WriteCoord, vecEnd[1]);
				engfunc(EngFunc_WriteCoord, vecEnd[2]);
				engfunc(EngFunc_WriteCoord, vecSrc[0]);
				engfunc(EngFunc_WriteCoord, vecSrc[1]);
				engfunc(EngFunc_WriteCoord, vecSrc[2]);
				write_byte(5);
				write_short(22);
				write_short(25);
				write_short(65);
				message_end();
				
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
				write_byte(TE_DLIGHT);
				engfunc(EngFunc_WriteCoord, vecEnd[0]);	// X
				engfunc(EngFunc_WriteCoord, vecEnd[1]);	// Y
				engfunc(EngFunc_WriteCoord, vecEnd[2]);	// Z
				write_byte(7);		// radius * 0.1
				write_byte(255);		// r
				write_byte(255);		// g
				write_byte(224);		// b
				write_byte(1);		// time * 10
				write_byte(0);		// decay * 0.1
				message_end();
				
				emit_sound(iPlayer, CHAN_ITEM, g_szSounds[random_num(SND_HIT_WALL_1, SND_HIT_WALL_2)], 1.0, ATTN_NORM, 0, PITCH_NORM);
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
	new iTempTrace;
	
	new Float: flFraction;
	new Float: flThisDistance;
	
	new Float: vecEnd[3];
	new Float: vecEndPos[3];
	new Float: vecHullEnd[3];
	new Float: vecMinMaxs[2][3];
	
	new Float: flDistance = 999999.0;
	
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
	
	for (new j, k, i = 0; i < 2; i++)
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

PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);

		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
				
				// server_print(" * Sound: %s", szSoundPath);
			}
		}
	}
	
	fclose(iFile);
}
