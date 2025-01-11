/*
	v0.1 [3.10.2012] - first release
	
	v0.2 [12.02.2013]
		1)Added Reflect To Another Entities By -> Shock Beam && Shock Sphere && Shock Combo (example - Tripmine / Weaponbox ...)
		2)Fixed - Unlimited Touches With Shock Sphere & Owner (at first - owner may appear in many shock combo spheres area, and no touch received)
		3)Fixed - Shock Combo Ignores Entities In Water
		4)Added Screen Shake On First & Second Attack
		5)Fixed - Client Spawn Init
		6)Fixed - ShockRifle Deploy Sound
		7)Fixed - "HotGlow" unexpected points(from 1-st attack), on Shock Combo o_O
		8)Code Refactoring

	v0.2a [04.04.2013]
		1) Critical Fix
		
	To Do - Water Refraction Fix (this changes position Shock Sphere & made it difficult to do Shock Combo)
	
	Weapon Info -> http://unreal.standardof.net/unreal-tournament-2004/weapons-and-tactics/
	
	http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>
#include <beams>

#pragma semicolon 1
#pragma tabsize 0

/*

	<<<<<	Plugin Data		>>>>>

*/

enum {
	BUG_IGNORE_WATER = 0x1,
	BUG_IGNORE_OWNER = 0x2
};

enum {
	MAKE_DEFAULT_POINT = 0x1,
	MAKE_AIMING_POINT = 0x2
};

#define DATA_ORIGIN 0x0
#define DATA_VIEW_OFS 0x1
#define DATA_ANGLES 0x2
#define DATA_PUNCH_ANGLES 0x3
#define DATA_ANGLES_RESULT 0x4
#define DATA_ORIGIN_RESULT 0x5
#define DATA_GLOBAL_FORWARD 0x6
#define DATA_GLOBAL_RIGHT 0x7
#define DATA_GLOBAL_UP 0x8
#define DATA_SPHERE_ORIGIN 0x9
#define DATA_AIMING_POINT 0xA
#define DATA_ANGLES_RESULT_MULTIPLIED 0xB
#define DATA_GLOBAL_FORWARD_MULTIPLIED 0xC
#define DATA_AIMING_ORIGIN_FULL 0xD
#define DATA_TOTAL 0xE

#define DATA_BEAM_ORIGIN DATA_AIMING_POINT

enum {
	ENTITY_WORLD_BRUSH = 0x1,
	ENTITY_PLAYER = 0x2,
	ENTITY_MONSTER = 0x4,
	ENTITY_OBJECT = 0x8,
	ENTITY_TARGET = 0x10
};
	
enum {
	P_MODEL = 0,
	V_MODEL,
	W_MODEL
};

#define SPRITE_HOT_GLOW 1
#define SPRITE_TERMINATE 2
#define ENTITY_INFO_TARGET 1
#define ENTITY_ENV_SPRITE 0
#define EVENT_EXPLOSION 1
#define EVENT_THINK 0

new const g_9mmClipSound[] = "items/9mmclip1.wav";

/*

	<<<<<	Beam Data	>>>>>

*/

new const g_ShockRifleBeamSprite[] = "sprites/shockrifle/ShockRifleBeam.spr";
new const BEAM_CLASSNAME[] = "weapon_UT_shockrifle_beam";

#define BEAM_LIFE 0.085
#define BEAM_BRIGHTNESS 255.0
#define BEAM_SCROLLRATE 10.0
		
#define Beam_SetLife(%0,%1) set_pev(%0, pev_nextthink, (get_gametime() + %1))

/*

	<<<<<	ShockRifle Data		>>>>>

*/

enum {
	ANIM_IDLE = 0,
	ANIM_FIRE,
	ANIM_ALT_FIRE,
	ANIM_HOLSTER,
	ANIM_DEPLOY
};

#define SHOCK_RIFLE_DEPLOY_SOUND_VOLUME 0.35
#define SHOCK_RIFLE_PUNCHANGLE 1.75
#define SHOCK_RIFLE_BEAM_DAMAGE_TYPE (DMG_RADIATION)
#define SHOCK_RIFLE_BEAM_AREA_RADIUS 1.0

//new const g_const_ShockRifleAmmoBoxClass[] = "AmmoBox_UT_Plazma";
new const g_ShockRifleHotGlowSprite[] = "sprites/shockrifle/ShockRifleHotGlow.spr";
new const WEAPON_NAME[] = "weapon_UT_shockrifle";
new const WEAPON_PRIMARY_AMMO[] = "ammo_UT_plazma";
new const g_TouchSound[] = "shockrifle/touch.wav";
new const g_ExplosionSound[] = "shockrifle/explosion.wav";
new const g_FireSound[] = "shockrifle/fire.wav";
new const g_AltFireSound[] = "shockrifle/alt_fire.wav";
new const g_SwitchSound[] = "shockrifle/switch.wav";

new const g_ShockRifleAmmoBoxModel[] = "models/shockrifle/w_ammo.mdl";

new const g_AvailiableModels[][] = {
	"models/shockrifle/p_shockrifle.mdl",
	"models/shockrifle/v_shockrifle.mdl",
	"models/shockrifle/w_shockrifle.mdl"
};

#define SHOCK_RIFLE_DAMAGE_MONSTERS 45.0
#define SHOCK_RIFLE_DAMAGE_OBJECTS 40.0
#define SHOCK_SPHERE_DAMAGE_MONSTERS 40.0
#define SHOCK_SPHERE_DAMAGE_OBJECTS 45.0

#define PRIMARY_FIRE_RATE 0.5 // 0.5 = 2 attacks in 1 sek
#define SECONDARY_FIRE_RATE 0.5 // 0.5 = 2 attacks in 1 sek

#define WEAPON_SLOT 4
#define WEAPON_POSITION 5
#define WEAPON_PRIMARY_AMMO_MAX 50
#define WEAPON_SECONDARY_AMMO ""
#define WEAPON_SECONDARY_AMMO_MAX -1
#define WEAPON_FLAGS 0
#define WEAPON_MAX_CLIP -1
#define WEAPON_DEFAULT_AMMO 10 // ammo in spawned weapon
#define WEAPON_WEIGHT 15
#define AMMOBOX_AMMO 10

/*

	<<<<<	Hud Data		>>>>>

*/

new const WEAPON_HUD_TXT[] = "sprites/weapon_UT_shockrifle.txt";
new const WEAPON_HUD_SPR[] = "sprites/weapon_UT_shockrifle.spr";
new const ANIM_EXTENSION[] = "gauss";

/*

	<<<<<	Shock Sphere Data	>>>>>

*/

new const g_ShockSphereExplosionSprite[] = "sprites/shockrifle/ShockSphereExplosion.spr";
new const g_ShockSphereSprite[] = "sprites/shockrifle/ShockSphere.spr";
new const g_ShockSphereClass[] = "UT_ShockSphere";
new const g_ShockSphereTerminateSprite[] = "sprites/shockrifle/ShockSphereTerminate.spr";

#define SHOCK_SPHERE_EXPLODE_DAMAGE 200
#define SHOCK_SPHERE_EXPLODE_RADIUS 300
#define SHOCK_SPHERE_VELOCITY_MULTIPLE 850
const Float:DETONATE_RADIUS_MULTIPLE = 7.5; // for greater value -> less aiming needed to explode shock sphere
const Float:SHOCK_SPHERE_SIZE = 2.5;

#define SHOCK_SPHERE_TRANSPARENCY 192.0
#define SHOCK_SPHERE_SPRITE_SIZE 0.75
#define SHOCK_SPHERE_TOUCH_DAMAGE 0.625
#define SPRITE_ANIMATION_SPEED 21.0
#define SHOCK_SPHERE_AREA_RADIUS 1.0

#define SPHERE_SOLID SOLID_TRIGGER
#define MAX_SPHERE_EXPLOSION_DAMAGE 200.0
#define SHOCK_SPHERE_DAMAGE_TYPE (DMG_RADIATION | DMG_BLAST)

#if (_:SHOCK_SPHERE_EXPLODE_DAMAGE > _:SHOCK_SPHERE_EXPLODE_RADIUS)
	#define SHOCK_SPHERE_EXPLODE_RESULT SHOCK_SPHERE_EXPLODE_DAMAGE
#else
	#define SHOCK_SPHERE_EXPLODE_RESULT SHOCK_SPHERE_EXPLODE_RADIUS
#endif
	
/*

	<<<<<	Stocks	>>>>>

*/

#define WORLD_CONTENT(%1) (1 << (-(%1)))
#define write_coord_f(%0) engfunc(EngFunc_WriteCoord, Float:%0)
#define BOOL_FLAGS(%1,%2) bool:((pev((%1), pev_flags) & (%2)) == (%2))

#define BIT_VALID(%1,%2) ((%1) & (1 << ((%2) - 1)))
#define BIT_ADD(%1,%2) ((%1) |= (1 << ((%2) - 1)))
#define BIT_SUB(%1,%2) ((%1) &= ~(1 << ((%2) - 1)))
#define BIT_NOT_VALID(%1,%2) (~(%1) & (1 << ((%2) - 1)))

#define _BIT_VALID(%1,%2) ((%1) & (1 << (%2)))
#define _BIT_ADD(%1,%2) ((%1) |= (1 << (%2)))
#define _BIT_SUB(%1,%2) ((%1) &= ~(1 << (%2)))
#define _BIT_NOT_VALID(%1,%2) (~(%1) & (1 << (%2)))

#define PlayerEntity(%1) (0 < %1 <= g_iMaxPlayers)
#define PlayerEntityAlive(%1) ((0 < %1 <= g_iMaxPlayers) && BIT_ALIVE(%1))

#define _PlayerEntity(%1) (-1 < %1 < g_iMaxPlayers)
#define _PlayerEntityAlive(%1) ((-1 < %1 < g_iMaxPlayers) && _BIT_ALIVE(%1))

new

Float:g_vec_fGlobalData[DATA_TOTAL][3],
Array:g_ArrayHandle,
g_iMaxPlayers,
g_iOwnerData,
// g_iShockSphereIndex, FIXME -> Index Of Exploded Sphere
g_iShockSphereOwner,
g_iPlayerInAttack,
g_iBitAlive = 0,
g_iBitFirstSpawn = 0,
g_iTerminateDecalSpriteIndex,
g_iHotGlowDecalSpriteIndex,
Float:g_fClientTimeData[32],
g_TraceResultData,
bool:g_bIsPlayer,
bool:g_bShockSphereInWater,
g_iShockSphereCalledBy,
g_const_iDetonateRadius, // const
Float:g_fShockRifleBeamAreaDamage, // const!
Float:g_fShockSphereAreaDamage; // const!

stock HitShockSphere(id) {
	new

	iReturn = 0,
	iSize = ArraySize(g_ArrayHandle);
	
	if(iSize) {
		static
		
		i,
		iSphere,
		sClassName[32],
		
		Float:fVectorMultiple[3] = {1.0, 1.0, 1.0},
		Float:fVector[3] = {0.0, 0.0, 0.0};
		
		new
		
		bool:bFix = false,
		bool:bInLiquid = BOOL_FLAGS(id, FL_INWATER);
		
		for(i = 0; i < (iSize ? iSize : (iSize = ArraySize(g_ArrayHandle))); i++) {
			if(bFix) {
				iSize = 0;
				ArrayDeleteItem(g_ArrayHandle, i--);
				bFix = false;
				
				continue;
			}
			
			if
			(
				pev_valid((iSphere = ArrayGetCell(g_ArrayHandle, i)))
			&& 
				(pev(iSphere, pev_solid) == SPHERE_SOLID) 
			&& 
				(pev(iSphere, pev_movetype) == MOVETYPE_FLY)
			)
			
			{
				pev(iSphere, pev_classname, sClassName, charsmax(sClassName));
					
				if(equal(sClassName, g_ShockSphereClass, sizeof(g_ShockSphereClass))) {
					pev(iSphere, pev_origin, g_vec_fGlobalData[DATA_SPHERE_ORIGIN]);
						
					fVectorMultiple[0] = get_distance_f(g_vec_fGlobalData[DATA_SPHERE_ORIGIN], g_vec_fGlobalData[DATA_ORIGIN_RESULT]);
					g_bShockSphereInWater = WorldPointAnalyze(g_vec_fGlobalData[DATA_SPHERE_ORIGIN], WORLD_CONTENT(CONTENTS_WATER));
					
					GetVectorPointOrigin(fVector, fVectorMultiple);
					
					if(bInLiquid != g_bShockSphereInWater) {
						// Refraction :'(
					}
						
					if(floatround(get_distance_f(fVector, g_vec_fGlobalData[DATA_SPHERE_ORIGIN])) > g_const_iDetonateRadius) {
						continue;
					}
					
					if(GetTraceResult(g_vec_fGlobalData[DATA_SPHERE_ORIGIN], g_vec_fGlobalData[DATA_ORIGIN_RESULT], (DONT_IGNORE_MONSTERS | IGNORE_MISSILE), 0, id, bInLiquid)) {
						// iReturn = g_iShockSphereIndex = iSphere; FIXME -> Index Of Exploded Sphere

						iReturn = iSphere;
						g_iShockSphereOwner = GetOwnerEntityIndex(pev(iSphere, pev_owner), iSphere);
							
						break;
					}
				} else {
					i--;
					bFix = true;
				}
			} else {
				i--;
				bFix = true;
			}
		}
	}

	return iReturn;
}

stock bool:ExecuteAreaDamage(iInflictor, iAttacker, const Float:vec_fOrigin[3], Float:fRadius, Float:fDamage, iDamageBits) {
	new 
	
	iEntity = -1,
	Float:vec_fSource[3],
	bool:bReturn = false;
	
	while((iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, vec_fOrigin, fRadius)) > 0) {
		if(GetEntityFlags(iEntity) & ENTITY_TARGET) {
			(pev(iEntity, pev_movetype) == MOVETYPE_PUSH) ? GetRealOrigin(iEntity, vec_fSource) : pev(iEntity, pev_origin, vec_fSource);
			engfunc(EngFunc_TraceLine, vec_fOrigin, vec_fSource, (IGNORE_MONSTERS | IGNORE_MISSILE), iEntity, g_TraceResultData);
			
			if((get_tr2(g_TraceResultData, TR_pHit) == iEntity) || SolidConditions(iEntity, vec_fSource)) {
				ExecuteHamB(Ham_TakeDamage, iEntity, iInflictor, iAttacker, fDamage, iDamageBits);
				bReturn = true;
				
				break;	
			}
		}
	}
	
	return bReturn;
}

public client_putinserver(id) {
	BIT_ADD(g_iBitFirstSpawn, id);
}

public ShockRiflePrimaryFire(iEntity, id, iClip, iAmmo) {
	wpnmod_set_offset_float(iEntity, Offset_flTimeWeaponIdle, 0.6);
	wpnmod_set_offset_float(iEntity, Offset_flNextPrimaryAttack, Float:PRIMARY_FIRE_RATE);
	wpnmod_set_offset_float(iEntity, Offset_flNextSecondaryAttack, Float:SECONDARY_FIRE_RATE);

	if(iAmmo) {
		new
		
		iBeam,
		iVictim;
		
		if((iBeam = Beam_Create(g_ShockRifleBeamSprite, 25.0))) {
			g_iPlayerInAttack = id;
			
			wpnmod_set_player_ammo(id, WEAPON_PRIMARY_AMMO, (iAmmo - 1));
			wpnmod_send_weapon_anim(iEntity, ANIM_FIRE);
			wpnmod_set_player_anim(id, PLAYER_ATTACK1);

			UTIL_MakeVectors(id, (MAKE_AIMING_POINT | MAKE_DEFAULT_POINT));

			new 
			
			iSphere = HitShockSphere(id),
			iFlags,
			i = _:DATA_BEAM_ORIGIN;

			engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_FireSound, 0.75, ATTN_NORM, 0, PITCH_NORM);

			if(iSphere) {
				i = _:DATA_SPHERE_ORIGIN;
				ExecuteRadiusDamage(id, iSphere);
				ShockSphereChange(iSphere, g_ExplosionSound, g_ShockSphereExplosionSprite, 0.5, 3.0, 9);	
			} else if((iVictim = GetTraceResult(g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_AIMING_ORIGIN_FULL], (IGNORE_MISSILE | DONT_IGNORE_MONSTERS), id)) && ((iFlags = GetEntityFlags(iVictim)) & ENTITY_TARGET)) {
				SummonSparks(g_vec_fGlobalData[DATA_AIMING_POINT]);
				ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, id, Float:((iFlags & ENTITY_OBJECT) ? SHOCK_RIFLE_DAMAGE_OBJECTS : SHOCK_RIFLE_DAMAGE_MONSTERS), _:(SHOCK_RIFLE_BEAM_DAMAGE_TYPE));
			} else {
				SummonGlowingSprite(g_iHotGlowDecalSpriteIndex, g_vec_fGlobalData[DATA_AIMING_POINT], 1, 255);
				ExecuteAreaDamage(id, id, g_vec_fGlobalData[DATA_AIMING_POINT], Float:SHOCK_RIFLE_BEAM_AREA_RADIUS, g_fShockRifleBeamAreaDamage, _:(SHOCK_RIFLE_BEAM_DAMAGE_TYPE));
			}
			
			set_pev(iBeam, pev_classname, BEAM_CLASSNAME);
		
			Beam_PointEntInit(iBeam, g_vec_fGlobalData[i], id);
			Beam_SetEndAttachment(iBeam, 1);
			Beam_SetBrightness(iBeam, Float:BEAM_BRIGHTNESS);
			Beam_SetScrollRate(iBeam, Float:BEAM_SCROLLRATE);
			Beam_SetLife(iBeam, Float:BEAM_LIFE);
			
			CrosshairJump(id);
		}
	} else {
		wpnmod_play_empty_sound(iEntity);
	}
	
	return 0;
}

stock bool:WorldPointAnalyze(const Float:vec_fOrigin[3], iFlags) {
 	return bool:((WORLD_CONTENT(engfunc(EngFunc_PointContents, vec_fOrigin)) & iFlags) == iFlags);
}

stock CrosshairJump(id) {
	new Float:vec_fPunchAngles[3];
	
	pev(id, pev_punchangle, vec_fPunchAngles);
	
	vec_fPunchAngles[0] += random_float(-Float:SHOCK_RIFLE_PUNCHANGLE, Float:SHOCK_RIFLE_PUNCHANGLE);
	vec_fPunchAngles[1] += random_float(-Float:SHOCK_RIFLE_PUNCHANGLE, Float:SHOCK_RIFLE_PUNCHANGLE);
	vec_fPunchAngles[2] += random_float(-Float:SHOCK_RIFLE_PUNCHANGLE, Float:SHOCK_RIFLE_PUNCHANGLE);
	
	set_pev(id, pev_punchangle, vec_fPunchAngles);
}

public ShockSphereTouch(iSphere, iEntity) {
	static
	
	iReturn,
	iFlags;
	
	iFlags = 0;
	iReturn = HAM_IGNORED;
	
	if(pev_valid(iSphere)) {
		if(!iEntity || (iFlags = GetEntityFlags(iEntity))) {
			static
			
			Float:fSphereOrigin[3],
			bool:bSphereAction,
			iOwner;
			
			pev(iSphere, pev_origin, fSphereOrigin);
			iOwner = GetOwnerEntityIndex(pev(iSphere, pev_owner), iSphere);
			
			if(iFlags & ENTITY_TARGET) {
				static 
				
				bool:bSameEntity,
				bool:bDamageClientOwner,
				iOwnerIndexOffSet;
		
				bSameEntity = bool:(iOwner == iEntity);
					
				if
				(
					bSameEntity
				&&
					(
						(
							bDamageClientOwner =
							(
								g_bIsPlayer
							&&
								((g_fClientTimeData[(iOwnerIndexOffSet = (iOwner - 1))] + (Float:SECONDARY_FIRE_RATE * 2)) > get_gametime())
							)
						)
					||
						(g_bIsPlayer == false)
					)
				)
					
				{
					bSphereAction = false;
					
					if(bDamageClientOwner) {
						g_fClientTimeData[iOwnerIndexOffSet] -= (Float:SECONDARY_FIRE_RATE * 0.025);
					}
				} else {
					bSphereAction = true;
				}
					
				if(bSphereAction) {
					engfunc(EngFunc_EmitSound, iSphere, CHAN_AUTO, g_TouchSound, 0.25, ATTN_NORM, 0, PITCH_NORM);
					
					SummonSparks(fSphereOrigin);
					ExecuteHamB(Ham_TakeDamage, iEntity, iSphere, g_iOwnerData, (iFlags & ENTITY_OBJECT) ? (Float:SHOCK_SPHERE_DAMAGE_OBJECTS) : (Float:SHOCK_SPHERE_DAMAGE_MONSTERS), _:(SHOCK_SPHERE_DAMAGE_TYPE));
					DeleteEntity(iSphere);
					
					iReturn = HAM_HANDLED;
				}
			} else {
				if(iEntity) {
					static sClassName[32];
					pev(iEntity, pev_classname, sClassName, charsmax(sClassName));
				
					bSphereAction = bool:(!equali(sClassName, g_ShockSphereClass, sizeof(g_ShockSphereClass)));
				} else {
					bSphereAction = true;
				}
				
				if(bSphereAction) {
					SummonGlowingSprite(g_iTerminateDecalSpriteIndex, fSphereOrigin);
					ShockSphereChange(iSphere, g_TouchSound, g_ShockSphereTerminateSprite, 0.25, 0.5, 15);
					ExecuteAreaDamage(iSphere, iOwner, fSphereOrigin, Float:SHOCK_SPHERE_AREA_RADIUS, g_fShockSphereAreaDamage, _:(SHOCK_SPHERE_DAMAGE_TYPE));

					iReturn = HAM_HANDLED;
				}
			}
		}
	}
	
	return iReturn;
}

stock GetOwnerEntityIndex(iExpectedOwner, iDuplicateOwner)
{
	new iReturn = iDuplicateOwner;
	
	g_bIsPlayer = bool:(0 < iExpectedOwner <= g_iMaxPlayers);
	
	if
	(
		(
			g_bIsPlayer 
		&& 
			BIT_VALID(g_iBitAlive, iExpectedOwner)
		) 
			
	|| 
		(
			(g_bIsPlayer == false) 
		&& 
			pev_valid(iExpectedOwner)
		)
	)
	
	{
		iReturn = iExpectedOwner;
	}

	return iReturn;
}

stock bool:SolidConditions(iEntity, const Float:vec_fOrigin[3]) {
	return
	(
		((1 << pev(iEntity, pev_solid)) & ((1 << SOLID_NOT) | (1 << SOLID_TRIGGER)))
	&&
		(TraceBugIgnore(vec_fOrigin, -1) == -1)
	);
}

stock GetTraceResult(const Float:vec_fStart[3], const Float:vec_fEnd[3], iTraceFlags, iSkipEntity, iPrototype = 0, bool:bInLiquid = false) {
	static
	
	_:iEntity,
	_:iReturn;
	
	iReturn = 0;
	
	engfunc(EngFunc_TraceLine, vec_fStart, vec_fEnd, iTraceFlags, iSkipEntity, g_TraceResultData);
	iEntity = get_tr2(g_TraceResultData, TR_pHit);
	
	if(iEntity > 0) {
		if((iPrototype == 0) || (iEntity == iPrototype)) {
			iReturn = iEntity;
		}
	} else {
		static 
		
		i,
		iFoundedEntity;
		
		if(bInLiquid) {
			i = BUG_IGNORE_WATER;
		} else if(iPrototype && (iPrototype == g_iShockSphereOwner)) {
			if((i & BUG_IGNORE_WATER) && (iPrototype == iFoundedEntity)) {
				i = 0;
				iReturn = iFoundedEntity;
				iFoundedEntity = 0;
			} else {
				i = BUG_IGNORE_OWNER;
			}				
		} else {
			i = 0;
		}
		
		if(i) {
			if((iFoundedEntity = TraceBugIgnore(vec_fEnd, i))) {
				iReturn = iFoundedEntity;
			}
		}
	}
	
	return iReturn;
}

stock SummonSparks(const Float:vec_fOrigin[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			
	write_byte(TE_SPARKS);
	write_coord_f(vec_fOrigin[0]);
	write_coord_f(vec_fOrigin[1]);
	write_coord_f(vec_fOrigin[2]);
				
	message_end();
}

stock GetEntityFlags(iEntity) {
	static iFlags;
	iFlags = 0;
	
	if(iEntity > g_iMaxPlayers) {
		if(pev_valid(iEntity)) {
			if(pev(iEntity, pev_solid) & SOLID_BSP) {
				iFlags = (ENTITY_WORLD_BRUSH | ENTITY_OBJECT);
			}
			
			if(pev(iEntity, pev_flags) & FL_MONSTER) {
				if(!pev(iEntity, pev_deadflag)) {
					iFlags |= ENTITY_MONSTER;
				}
			} else {
				iFlags |= ENTITY_OBJECT;
			}
		}
	} else if(BIT_VALID(g_iBitAlive, iEntity)) {
		iFlags = ENTITY_PLAYER;
	}
	
	if(iFlags && pev(iEntity, pev_takedamage) && pev(iEntity, pev_health) > 0.0) {
		iFlags |= ENTITY_TARGET;
	}
	
	return iFlags;
}

stock Float:DamageCalculate(const Float:vec_fSource[3]) {
	static Float:fDamage;
	
	if((fDamage = (Float:_:SHOCK_SPHERE_EXPLODE_RESULT.0 - get_distance_f(g_vec_fGlobalData[DATA_SPHERE_ORIGIN], vec_fSource))) < 1.0) {
		fDamage = 1.0;
	} else if(fDamage > Float:_:SHOCK_SPHERE_EXPLODE_DAMAGE.0) {
		fDamage = Float:_:SHOCK_SPHERE_EXPLODE_DAMAGE.0;
	}
	
	return fDamage;
}

stock GetRealOrigin(iEntity, Float:vec_fSource[3]) {
	static
				
	Float:vec_fMins[3],
	Float:vec_fMaxs[3];
				
	pev(iEntity, pev_mins, vec_fMins);
	pev(iEntity, pev_maxs, vec_fMaxs);
				
	xs_vec_add(vec_fMaxs, vec_fMins, vec_fSource);
	xs_vec_mul_scalar(vec_fSource, 0.5, vec_fSource);
}

stock GetVectorPointOrigin(Float:vec_fSource[3], const Float:vec_fMultiple[3]) {
	vec_fSource[0] = (
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][0] + (
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][0] * 
			vec_fMultiple[0]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][0] * 
			vec_fMultiple[1]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_UP][0] * 
			vec_fMultiple[2]
		)
	);
	
	vec_fSource[1] = (
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][1] + (
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][1] * 
			vec_fMultiple[0]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][1] * 
			vec_fMultiple[1]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_UP][1] * 
			vec_fMultiple[2]
		)
	);
	
	vec_fSource[2] = (
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][2] + (
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][2] * 
			vec_fMultiple[0]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][2] * 
			vec_fMultiple[1]
		) + (
			g_vec_fGlobalData[DATA_GLOBAL_UP][2] * 
			vec_fMultiple[2]
		)
	);
}

public ShockRifleSecondaryFire(iEntity, id, iClip, iAmmo) {
	static iSphereSprite;
	
	wpnmod_set_offset_float(iEntity, Offset_flNextPrimaryAttack, Float:PRIMARY_FIRE_RATE);
	wpnmod_set_offset_float(iEntity, Offset_flNextSecondaryAttack, Float:SECONDARY_FIRE_RATE);			
	wpnmod_set_offset_float(iEntity, Offset_flTimeWeaponIdle, 1.0);
	
	g_iShockSphereCalledBy = id;
	
	if(iAmmo && (iSphereSprite = CreateEntity(true))) {
		g_fClientTimeData[id - 1] = get_gametime();
		
		wpnmod_set_player_ammo(id, WEAPON_PRIMARY_AMMO, (iAmmo - 1));
			
		wpnmod_set_player_anim(id, PLAYER_ATTACK1);
		wpnmod_send_weapon_anim(iEntity, ANIM_ALT_FIRE);
			
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_AltFireSound, 0.5, ATTN_NORM, 0, PITCH_NORM);
			
		UTIL_MakeVectors(id, MAKE_AIMING_POINT);

		new Float:vec_fVector[3];
		GetVectorPointOrigin(vec_fVector, Float:((get_distance_f(g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_AIMING_POINT]) > 64.0) ? {32.0, 1.0, 2.5} : {1.0, 1.0, 2.5}));
			
		set_pev(iSphereSprite, pev_owner, id);
		set_pev(iSphereSprite, pev_origin, vec_fVector);
			
		vec_fVector[0] = (g_vec_fGlobalData[DATA_GLOBAL_FORWARD][0] * SHOCK_SPHERE_VELOCITY_MULTIPLE);
		vec_fVector[1] = (g_vec_fGlobalData[DATA_GLOBAL_FORWARD][1] * SHOCK_SPHERE_VELOCITY_MULTIPLE);
		vec_fVector[2] = (g_vec_fGlobalData[DATA_GLOBAL_FORWARD][2] * SHOCK_SPHERE_VELOCITY_MULTIPLE);
		
		set_pev(iSphereSprite, pev_basevelocity, vec_fVector);
		CrosshairJump(id);
	} else {
		wpnmod_play_empty_sound(iEntity);
	}
	
	return 0;
}

stock ArrayEntityDataClear(iEntity, iSizeDefault = 0) {
	new iSize;
	
	if((iSize = iSizeDefault) || (iSize = ArraySize(g_ArrayHandle))) {
		new i;
		
		for(i = 0; i < iSize; i++) {
			if(ArrayGetCell(g_ArrayHandle, i) == iEntity) {
				ArrayDeleteItem(g_ArrayHandle, i);

				break;
			}
		}
	}
}

stock ArrayErase() {
	new iOffSet;
	
	for(iOffSet = 0; iOffSet < ArraySize(g_ArrayHandle); iOffSet++) {
		ArrayDeleteItem(g_ArrayHandle, iOffSet);
		iOffSet--;
	}
}

stock TraceBugIgnore(const Float:vec_fEnd[3], iMode) {
	static Float:vec_fEndPos[3];
	new iReturn = 0;

	get_tr2(g_TraceResultData, TR_vecEndPos, vec_fEndPos);
	
	if(get_distance_f(vec_fEndPos, vec_fEnd) < 1.0) {
		iReturn = ((iMode == -1) ? -1 : ((iMode & BUG_IGNORE_WATER) ? g_iPlayerInAttack : g_iShockSphereOwner));
	}
	
	return iReturn;
}

stock EnvSpriteInitialize(iEntity) {
	SET_MODEL(iEntity, g_ShockSphereSprite);

	set_pev(iEntity, pev_spawnflags, SF_SPRITE_STARTON);
	set_pev(iEntity, pev_framerate, Float:SPRITE_ANIMATION_SPEED);
	set_pev(iEntity, pev_scale, Float:SHOCK_SPHERE_SPRITE_SIZE);

	dllfunc(DLLFunc_Spawn, iEntity);

	set_pev(iEntity, pev_owner, g_iShockSphereCalledBy);
	set_pev(iEntity, pev_solid, _:SPHERE_SOLID);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_takedamage, DAMAGE_NO);
	
	set_pev(iEntity, pev_renderfx, kRenderFxNone);
	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, Float:SHOCK_SPHERE_TRANSPARENCY);
	
	set_pev(iEntity, pev_mins, Float:{-SHOCK_SPHERE_SIZE, -SHOCK_SPHERE_SIZE, -SHOCK_SPHERE_SIZE});
	set_pev(iEntity, pev_maxs, Float:{SHOCK_SPHERE_SIZE, SHOCK_SPHERE_SIZE, SHOCK_SPHERE_SIZE});
	
	engfunc(EngFunc_SetSize, iEntity, Float:{-SHOCK_SPHERE_SIZE, -SHOCK_SPHERE_SIZE, -SHOCK_SPHERE_SIZE}, Float:{SHOCK_SPHERE_SIZE, SHOCK_SPHERE_SIZE, SHOCK_SPHERE_SIZE});
	set_pev(iEntity, pev_classname, g_ShockSphereClass);
	
	wpnmod_set_touch(iEntity, "ShockSphereTouch");
	ArrayPushCell(g_ArrayHandle, iEntity);
	
	return iEntity;
}

stock CreateEntity(bool:bSetData = false) {
	static iClassCache;
	
	new 
	
	iReturn = 0,
	iEntity;
	
	if(iClassCache || (iClassCache = engfunc(EngFunc_AllocString, "env_sprite"))) {
		if(pev_valid((iEntity = engfunc(EngFunc_CreateNamedEntity, iClassCache)))) {
			iReturn = bSetData ? EnvSpriteInitialize(iEntity) : iEntity;
		}
	}
	
	return iReturn;
}

stock UTIL_MakeVectors(id, iMode = MAKE_DEFAULT_POINT) {
	static iTraceResult;

	pev(id, pev_origin, g_vec_fGlobalData[DATA_ORIGIN]);
	pev(id, pev_view_ofs, g_vec_fGlobalData[DATA_VIEW_OFS]);
	pev(id, pev_v_angle, g_vec_fGlobalData[DATA_ANGLES]);
	pev(id, pev_punchangle, g_vec_fGlobalData[DATA_PUNCH_ANGLES]);
	
	xs_vec_add(g_vec_fGlobalData[DATA_ANGLES], g_vec_fGlobalData[DATA_PUNCH_ANGLES], g_vec_fGlobalData[DATA_ANGLES_RESULT]);
	xs_vec_add(g_vec_fGlobalData[DATA_ORIGIN], g_vec_fGlobalData[DATA_VIEW_OFS], g_vec_fGlobalData[DATA_ORIGIN_RESULT]);
	
	engfunc(EngFunc_MakeVectors, g_vec_fGlobalData[DATA_ANGLES_RESULT]);
	global_get(glb_v_forward, g_vec_fGlobalData[DATA_GLOBAL_FORWARD]);

	if(iMode & MAKE_AIMING_POINT) {
		xs_vec_mul_scalar(g_vec_fGlobalData[DATA_GLOBAL_FORWARD], 4096.0, g_vec_fGlobalData[DATA_GLOBAL_FORWARD_MULTIPLIED]);
		xs_vec_add(g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_GLOBAL_FORWARD_MULTIPLIED], g_vec_fGlobalData[DATA_AIMING_ORIGIN_FULL]);

		engfunc(EngFunc_TraceLine, g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_AIMING_ORIGIN_FULL], (DONT_IGNORE_MONSTERS | IGNORE_MISSILE), id, iTraceResult);
		get_tr2(iTraceResult, TR_vecEndPos, g_vec_fGlobalData[DATA_AIMING_POINT]);
	}
	
	if(iMode & MAKE_DEFAULT_POINT) {
		global_get(glb_v_right, g_vec_fGlobalData[DATA_GLOBAL_RIGHT]);
		global_get(glb_v_up, g_vec_fGlobalData[DATA_GLOBAL_UP]);
	}
}

stock ExecuteRadiusDamage(id, iSphere) {
	new
	
	i = 0,
	iEntity = -1,
	iFlags = 0,
	iType,
	Float:vec_fOrigin[3];

	while((iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, g_vec_fGlobalData[DATA_SPHERE_ORIGIN], Float:SHOCK_SPHERE_EXPLODE_RADIUS.0)) > 0) {
		if((iType = GetEntityFlags(iEntity)) & ENTITY_TARGET) {
			if(pev(iEntity, pev_movetype) == MOVETYPE_PUSH) {
				GetRealOrigin(iEntity, vec_fOrigin);
				iFlags = (IGNORE_MONSTERS | IGNORE_MISSILE);
			} else {
				pev(iEntity, pev_origin, vec_fOrigin);
				iFlags = IGNORE_MISSILE;
				
				if(iType & ENTITY_PLAYER) {
					static Float:vec_fRealOrigin[3];
					
					pev(iEntity, pev_view_ofs, vec_fRealOrigin);
					xs_vec_add(vec_fOrigin, vec_fRealOrigin, vec_fOrigin);
					
					iFlags |= DONT_IGNORE_MONSTERS; // "|= 0" :D
				} else {
					iFlags |= IGNORE_MONSTERS;
				}		
			}

			if
			(
				GetTraceResult(g_vec_fGlobalData[DATA_SPHERE_ORIGIN], vec_fOrigin, iFlags, iSphere, iEntity, BOOL_FLAGS(iEntity, FL_INWATER))
			||
				(
					(iType & ENTITY_OBJECT)
				&&
					SolidConditions(iEntity, vec_fOrigin)
				)
			)
			
			{
				i++;
				ExecuteHamB(Ham_TakeDamage, iEntity, iSphere, id, DamageCalculate(vec_fOrigin), _:(SHOCK_SPHERE_DAMAGE_TYPE));
			}
		}
	}

	return i;
}

stock SummonGlowingSprite(iSpriteIndex, const Float:vec_fOrigin[3], iSize = 5, iBrightness = 192) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		
	write_byte(TE_GLOWSPRITE);
	write_coord_f(vec_fOrigin[0]);
	write_coord_f(vec_fOrigin[1]);
	write_coord_f(vec_fOrigin[2]);
	write_short(iSpriteIndex);
	write_byte(1); // lifetime
	write_byte(iSize);
	write_byte(iBrightness);
		
	message_end();
}

stock ShockSphereChange(iSphere, const sSound[], const sModel[], Float:fVolume, Float:fScale, iFrames = 0) {
	set_pev(iSphere, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(iSphere, pev_solid, SOLID_NOT);
				
	engfunc(EngFunc_EmitSound, iSphere, CHAN_AUTO, sSound, fVolume, ATTN_NORM, 0, PITCH_NORM);
	
	if(iFrames) {
		SET_MODEL(iSphere, sModel);
	
		set_pev(iSphere, pev_scale, fScale);
		set_pev(iSphere, pev_iuser3, iFrames);
				
		entity_set_float(iSphere, EV_FL_frame, 0.0);
		wpnmod_set_think(iSphere, "ShockSphereThink");
	}
}

public ShockSphereThink(iEntity) {
	static
	
	Float:fGameTime = 0.0,
	Float:fFrame = 0.0;
	
	fGameTime = get_gametime();
	fFrame = entity_get_float(iEntity, EV_FL_frame);
	
	if(fFrame < float(pev(iEntity, pev_iuser3))) {
		fGameTime += 0.05;
		entity_set_float(iEntity, EV_FL_frame, (fFrame + 1));
	} else {
		fGameTime += 0.01;
		wpnmod_set_think(iEntity, "DeleteEntity");
	}
	
	set_pev(iEntity, pev_nextthink, fGameTime);
}

public ShockRifleDeploy(iItem, iPlayer) {
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, g_SwitchSound, Float:SHOCK_RIFLE_DEPLOY_SOUND_VOLUME, ATTN_NORM, 0, PITCH_NORM);
	return wpnmod_default_deploy(iItem, g_AvailiableModels[V_MODEL], g_AvailiableModels[P_MODEL], ANIM_DEPLOY, ANIM_EXTENSION);
}

public ShockRifleIdle(const iItem, const iPlayer, const iClip) {
	if(bool:(wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)) {
		wpnmod_reset_empty_sound(iItem); // FIXME
	} else {
		wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	}
	
	return 0;
}

public ResetHUD(id) {
	static iPlayer;
	iPlayer = (id - 1);
	
	if(_BIT_VALID(g_iBitFirstSpawn, iPlayer)) {
		_BIT_SUB(g_iBitFirstSpawn, iPlayer);
		OnClientSpawn_Post(id);
	}
}

public plugin_cfg() {
	register_plugin("UT_ShockRifle", "0.2a", "Turanga_Leela");

	if(g_ArrayHandle) {
		new
	
		iShockRifle_WpnIndex,
		iShockRifle_AmmoBox;
	
		iShockRifle_WpnIndex = wpnmod_register_weapon
		(
			WEAPON_NAME,
			_:WEAPON_SLOT,
			_:WEAPON_POSITION,
			WEAPON_PRIMARY_AMMO,
			_:WEAPON_PRIMARY_AMMO_MAX,
			WEAPON_SECONDARY_AMMO,
			_:WEAPON_SECONDARY_AMMO_MAX,
			_:WEAPON_MAX_CLIP,
			_:WEAPON_FLAGS,
			_:WEAPON_WEIGHT
		);
	
		iShockRifle_AmmoBox = wpnmod_register_ammobox(WEAPON_PRIMARY_AMMO);
	
		wpnmod_register_ammobox_forward(iShockRifle_AmmoBox, Fwd_Ammo_AddAmmo, "ShockRifle_AmmoAdd");
		wpnmod_register_ammobox_forward(iShockRifle_AmmoBox, Fwd_Ammo_Spawn, "ShockRifle_AmmoSpawn");
		
		g_const_iDetonateRadius = floatround(Float:SHOCK_SPHERE_SIZE * Float:DETONATE_RADIUS_MULTIPLE);
		g_iMaxPlayers = get_maxplayers();
		
		RegisterHam(Ham_Spawn, "player", "OnClientSpawn_Post", 1);
		RegisterHam(Ham_Killed, "player", "OnClientDeath_Post", 1);

		register_event("ResetHUD", "ResetHUD", "be");
		register_think(BEAM_CLASSNAME, "DeleteBeamEntity");
		
		wpnmod_register_weapon_forward(iShockRifle_WpnIndex, Fwd_Wpn_Spawn, "ShockRifleSpawn");
		wpnmod_register_weapon_forward(iShockRifle_WpnIndex, Fwd_Wpn_Deploy, "ShockRifleDeploy");
		wpnmod_register_weapon_forward(iShockRifle_WpnIndex, Fwd_Wpn_Idle, "ShockRifleIdle");
	
		wpnmod_register_weapon_forward(iShockRifle_WpnIndex, Fwd_Wpn_SecondaryAttack, "ShockRifleSecondaryFire");
		wpnmod_register_weapon_forward(iShockRifle_WpnIndex, Fwd_Wpn_PrimaryAttack, "ShockRiflePrimaryFire");
		
		ArrayErase();
	} else {
		set_fail_state("^nERROR: WPN_MOD -> Can't initialize array! 'Shock-Rifle'^n");
	}

	return 0;
}

public DeleteBeamEntity(iBeam) {
	if(pev_valid(iBeam)) {
		engfunc(EngFunc_RemoveEntity, iBeam);
	}
}

public DeleteEntity(iEntity) {
	static sClassName[32];
		
	pev(iEntity, pev_classname, sClassName, 31);
	engfunc(EngFunc_RemoveEntity, iEntity);
		
	if(equal(sClassName, g_ShockSphereClass, sizeof(g_ShockSphereClass))) {
		ArrayEntityDataClear(iEntity);
	}
}

public ShockRifle_AmmoAdd(iItem, iPlayer) {
	new iResult =
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			iPlayer, 
			_:AMMOBOX_AMMO,
			WEAPON_PRIMARY_AMMO, 
			WEAPON_PRIMARY_AMMO_MAX
		) != -1
	);
	
	if(iResult) {
		emit_sound(iItem, CHAN_ITEM, g_9mmClipSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	return iResult;
}	

public ShockRifle_AmmoSpawn(iEntity) {
	SET_MODEL(iEntity, g_ShockRifleAmmoBoxModel);
}	
	
public ShockRifleSpawn(iEntity) {
	SET_MODEL(iEntity, g_AvailiableModels[W_MODEL]);
	wpnmod_set_offset_int(iEntity, Offset_iDefaultAmmo, _:WEAPON_DEFAULT_AMMO);
}

public plugin_precache() {
	g_fShockRifleBeamAreaDamage = ((Float:SHOCK_RIFLE_DAMAGE_MONSTERS + Float:SHOCK_RIFLE_DAMAGE_OBJECTS) / 2);
	g_fShockSphereAreaDamage = ((Float:SHOCK_SPHERE_DAMAGE_MONSTERS + Float:SHOCK_SPHERE_DAMAGE_OBJECTS) / 32);
	
	if(g_fShockRifleBeamAreaDamage < 1.0) {
		g_fShockRifleBeamAreaDamage = 1.0;
	}
	
	if(g_fShockSphereAreaDamage < 1.0) {
		g_fShockSphereAreaDamage = 1.0;
	}
	
	g_ArrayHandle = ArrayCreate();
	
	PRECACHE_MODEL(g_AvailiableModels[P_MODEL]);
	PRECACHE_MODEL(g_AvailiableModels[V_MODEL]);
	PRECACHE_MODEL(g_AvailiableModels[W_MODEL]);
	
	PRECACHE_SOUND(g_TouchSound);
	PRECACHE_SOUND(g_ExplosionSound);
	PRECACHE_SOUND(g_FireSound);
	PRECACHE_SOUND(g_AltFireSound);
	PRECACHE_SOUND(g_SwitchSound);
	
	PRECACHE_MODEL(g_ShockSphereExplosionSprite);
	PRECACHE_MODEL(g_ShockSphereSprite);
	g_iTerminateDecalSpriteIndex = PRECACHE_MODEL(g_ShockSphereTerminateSprite);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	
	PRECACHE_MODEL(g_ShockRifleBeamSprite);
	PRECACHE_MODEL(g_ShockRifleAmmoBoxModel);
	g_iHotGlowDecalSpriteIndex = PRECACHE_MODEL(g_ShockRifleHotGlowSprite);
	
	PRECACHE_SOUND(g_9mmClipSound);
}

public client_disconnect(id) {
	new iPlayer = (id - 1);
	
	_BIT_SUB(g_iBitAlive, iPlayer);
	_BIT_SUB(g_iBitFirstSpawn, iPlayer);
}

public OnClientDeath_Post(id, iKiller, iShouldGib) {
	BIT_SUB(g_iBitAlive, id);
}

public OnClientSpawn_Post(id) {
	if(is_user_alive(id)) {
		BIT_ADD(g_iBitAlive, id);
	}
}
