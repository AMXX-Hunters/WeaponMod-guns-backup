/*
	v0.1 [08.03.2013] - first release
	v0.11 [08.03.2013] - added weapon pickup emit sound :D
	
	Weapon Info -> http://unreal.standardof.net/unreal-tournament-2004/weapons-and-tactics/
	
	http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
	By - "Turanga_Leela"
	
	Thanks to KOSHAK - for great models & sprites
*/

// Compile Options

#define HALF_LIFE

#define SEED_HOTGLOW_POINTS
#define SEED_TRAILS
#define SEED_RICOCHET_SOUNDS
#define SEED_RICOCHET_SPARKS

// End

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>

#pragma semicolon 1
#pragma tabsize 0

#define WORLD_CONTENT(%1) (1 << (-(%1)))

#define GROUND_TYPE_VERTICAL_X  (1 << 0)
#define GROUND_TYPE_AXIS_X      (1 << 1)
#define GROUND_TYPE_VERTICAL_Y  (1 << 2)
#define GROUND_TYPE_AXIS_Y      (1 << 3)
#define GROUND_TYPE_VERTICAL_XY (1 << 4)
#define GROUND_TYPE_AXIS_XY     (1 << 5)
#define GROUND_TYPE_HORIZONTAL  (1 << 6)
#define GROUND_TYPE_NEGATIVE    (1 << 7)
#define GROUND_TYPE_REVERSE     (1 << 8)

enum
{
	MaxSides = 6
};

enum
{
	SUMMON_CORE = 0,
	SUMMON_SEED
};

enum
{
	P_MODEL = 0,
	V_MODEL,
	W_MODEL
};

enum
{
	MAKE_DEFAULT_POINT = 0x1,
	MAKE_AIMING_POINT = 0x2
};

enum
{
	ANIM_IDLE = 0,
	ANIM_FIRE,
	ANIM_ALT_FIRE,
	ANIM_HOLSTER,
	ANIM_DEPLOY
};

enum
{
	DATA_ORIGIN = 0,
	DATA_VIEW_OFS,
	DATA_ANGLES,
	DATA_PUNCH_ANGLES,
	DATA_ANGLES_RESULT,
	DATA_ORIGIN_RESULT,
	DATA_GLOBAL_FORWARD,
	DATA_GLOBAL_RIGHT,
	DATA_GLOBAL_UP,
	DATA_AIMING_POINT,
	DATA_ANGLES_RESULT_MULTIPLIED,
	DATA_GLOBAL_FORWARD_MULTIPLIED,
	DATA_AIMING_ORIGIN_FULL,
	DATA_TOTAL
};

#define DATA_BEAM_ORIGIN DATA_AIMING_POINT

enum
{
	ENTITY_WORLD_BRUSH = 0x1,
	ENTITY_PLAYER = 0x2,
	ENTITY_MONSTER = 0x4,
	ENTITY_OBJECT = 0x8,
	ENTITY_TARGET = 0x10
};

#define BIT_VALID(%1,%2) ((%1) & (1 << ((%2) - 1)))
#define BIT_ADD(%1,%2) ((%1) |= (1 << ((%2) - 1)))
#define BIT_SUB(%1,%2) ((%1) &= ~(1 << ((%2) - 1)))
#define BIT_NOT_VALID(%1,%2) (~(%1) & (1 << ((%2) - 1)))

#define _BIT_VALID(%1,%2) ((%1) & (1 << (%2)))
#define _BIT_ADD(%1,%2) ((%1) |= (1 << (%2)))
#define _BIT_SUB(%1,%2) ((%1) &= ~(1 << (%2)))
#define _BIT_NOT_VALID(%1,%2) (~(%1) & (1 << (%2)))

#define write_coord_f(%0) engfunc(EngFunc_WriteCoord, Float:%0)

//////////////////
// # Velocity # //
//////////////////

#define g_const_FC_iCoreVelocity 1250 // change here
#define g_const_FC_iSeedVelocity 1500 // change here

const Float:g_const_FC_fCoreVelocity = Float:_:g_const_FC_iCoreVelocity.0; // do not modify
const Float:g_const_FC_fSeedVelocity = Float:_:g_const_FC_iSeedVelocity.0; // do not modify

///////////////////////////
// # [END] -> Velocity # //
///////////////////////////

////////////////
// # Damage # //
////////////////

const g_const_FC_iCoreDmg_Type = (DMG_BLAST);
const g_const_FC_iSeedDmg_Type = (DMG_BULLET | DMG_BLAST);

const Float:g_const_FC_fCoreDmg_Monsters = 110.0; // + Seeds
const Float:g_const_FC_fCoreDmg_Objects = 145.0; // + Seeds
const Float:g_const_FC_fSeedDmg_Monsters = 13.0; // 9x
const Float:g_const_FC_fSeedDmg_Objects = 13.0; // 9x

/////////////////////////
// # [END] -> Damage # //
/////////////////////////

/////////////////////
// # Punch Angle # //
/////////////////////

const Float:g_const_FC_fPuchAngle = 1.75;

//////////////////////////////
// # [END] -> Punch Angle # //
//////////////////////////////

///////////////////
// # Fire Rate # //
///////////////////

const Float:g_const_FC_fFireRate = 0.666666;
const Float:g_const_FC_fAltFireRate = 1.0;

////////////////////////////
// # [END] -> Fire Rate # //
////////////////////////////

//////////////
// # Size # //
//////////////

const Float:g_const_FC_fCoreSize = 12.0;
const Float:g_const_FC_fSeedSize = 4.0;

///////////////////////
// # [END] -> Size # //
///////////////////////

////////////////
// # Sounds # //
////////////////

const Float:g_const_FC_fAltFire_SndVol = 0.5;
const Float:g_const_FC_fFire_SndVol = 0.5;
const Float:g_const_FC_fDeploy_SndVol = 0.5;
const Float:g_const_FC_fCore_TouchSndVol = 0.5;
const Float:g_const_FC_fSeed_TouchSndVol = 0.25;

new const g_const_FC_sAttackSnd[2][] =
{
	"flakcannon/flakcannon_altfire.wav",
	"flakcannon/flakcannon_fire.wav"
};

new const g_const_FC_sSwitchSnd[] = "flakcannon/flakcannon_switch.wav";
new const g_const_FC_sAmmo_PickUpSnd[] = "flakcannon/flakcannon_ammo_pickup.wav";
new const g_const_FC_sWeapon_PickUpSnd[] = "flakcannon/flakcannon_weapon_pickup.wav";
new const g_const_FC_sSeed_HitSnd[] = "flakcannon/flakcannon_bullet_hit.wav";
new const g_const_FC_sCoreExplosionSnd[] = "flakcannon/flakcannon_core_explosion.wav";

const g_const_iSeedRicochet_SndCount = 14;

#if defined SEED_RICOCHET_SOUNDS
new const g_sSeedRicochet_Snd[g_const_iSeedRicochet_SndCount][] =
{
	"bullet/bullet_impact1.wav",
	"bullet/bullet_impact2.wav",
	"bullet/bullet_impact3.wav",
	"bullet/bullet_impact4.wav",
	"bullet/bullet_impact5.wav",
	"bullet/bullet_impact6.wav",
	"bullet/bullet_impact7.wav",
	"bullet/bullet_impact8.wav",
	"bullet/bullet_impact9.wav",
	"bullet/bullet_impact10.wav",
	"bullet/bullet_impact11.wav",
	"bullet/bullet_impact12.wav",
	"bullet/bullet_impact13.wav",
	"bullet/bullet_impact14.wav"
};
#endif

/////////////////////////
// # [END] -> Sounds # //
/////////////////////////

/////////////////////
// # Weapon Info # //
/////////////////////

const g_const_FC_iWeaponSlot = 4;
const g_const_FC_iWeaponPos = 3;
const g_const_FC_iPrimaryAmmo_Max = 35;
const g_const_FC_iSecondaryAmmo_Max = -1;
const g_const_FC_iWeaponFlags = 0;
const g_const_FC_iWeapon_MaxClip = -1;
const g_const_FC_iDefaultAmmo = 10; // ammo in spawned weapon
const g_const_FC_iAmmoBox_Ammo = 10;
const g_const_FC_iWeaponWeight = 20;

//////////////////////////////
// # [END] -> Weapon Info # //
//////////////////////////////

/////////////////
// # Classes # //
/////////////////

new const g_const_FC_sSecondaryAmmoClass[] = "";
new const g_const_FC_sWeaponClass[] = "weapon_UT_flakcannon";
new const g_const_FC_sAmmoClass[] = "ammo_UT_flakcannon";

new const g_const_FC_sSummonClasses[2][] =
{
	"UT_FlakCannon_Core",
	"UT_FlakCannon_Seed"
};

//////////////////////////
// # [END] -> Classes # //
//////////////////////////

////////////////
// # Models # //
////////////////

new const g_const_FC_sModels[][] =
{
	"models/flakcannon/p_flakcannon.mdl",
	"models/flakcannon/v_flakcannon.mdl",
	"models/flakcannon/w_flakcannon.mdl"
};

new const g_const_FC_sAB_Mdl[] = "models/flakcannon/w_flakcannon_ammo.mdl";

/////////////////////////
// # [END] -> Models # //
/////////////////////////

/////////////////
// # Sprites # //
/////////////////

const g_const_FC_iExplodeSpr_Frames = 12;
const Float:g_const_FC_fExplodeSpr_Transper = 255.0;

const Float:g_const_FC_fCoreSpr_AnimFrames = 0.0;
const Float:g_const_FC_fSeedSpr_AnimFrames = 0.0; // by default - static picture

const Float:g_const_FC_fExplodeSpr_Speed = 0.0325; // frames per sec

const Float:g_const_FC_fCoreExplodeSprScale = 0.55;
const Float:g_const_FC_fCoreSpr_Scale = 0.15;
const Float:g_const_FC_fSeedSpr_Scale = 0.08;

new const g_const_FC_sCoreExplosion_Spr[] = "sprites/flakcannon/flakcannon_core_explode.spr";

#define SEED_SPRITE "sprites/flakcannon/flakcannon_seed_end_point.spr"
#define IUSER_DATA2 pev_iuser3 // core explode sprite frames

new const g_const_FC_sSphere_Spr[][] =
{
	"sprites/flakcannon/flakcannon_core.spr",
	SEED_SPRITE
};

new const g_const_FC_sHudSprCfg[] = "sprites/weapon_UT_flakcannon.txt";
new const g_const_FC_sHudSpr[] = "sprites/weapon_UT_flakcannon.spr";

//////////////////////////
// # [END] -> Sprites # //
//////////////////////////

///////////////
// # Other # //
///////////////

new const g_const_FC_sAnimExtension[] = "gauss";

const Float:g_const_FC_fShootScattering = 0.064; // 0.1 == 10% from seed speed
const Float:g_const_FC_fSeedRicochet = 1.0; // 1.0 == 100% from seed speed

#define IUSER_DATA pev_iuser3 // num of seed touches

const Float:g_const_FC_fSeedGravity_I = 2.5; // all new seeds, summoned on shoot(after 1st touch) -> gets this gravity
const Float:g_const_FC_fSeedGravity_II = 5.0; // all new seeds, summoned on core explode -> gets this gravity

////////////////////////
// # [END] -> Other # //
////////////////////////

//////////////////////
// # Transparency # //
//////////////////////

const Float:g_const_FC_fCoreTransparency = 256.0;
const Float:g_const_FC_fSeedTransparency = 128.0;

///////////////////////////////
// # [END] -> Transparency # //
///////////////////////////////

new g_iSummonedOwner = -1;

#if defined SEED_TRAILS
new g_iSeedTrail_Spr = -1;
#endif

#if defined SEED_HOTGLOW_POINTS
new g_iSeedEndPoint_SprPtr;
#endif

#if defined HALF_LIFE
new g_iBitFirstSpawn = 0;
#endif

new g_iBitAlive = 0;
new Float:g_vec_fGlobalData[DATA_TOTAL][3];
new Float:g_fPointOriginResult[3];
new Float:g_fPointResult[3];
new g_iMaxPlayers = 0;
new Float:g_vec_fCoreOrigin[3];
new Float:g_vec_fRicochetResult[3];
new Float:g_vec_fCorePlanePoint[3];
new Float:g_vec_fGroundNormal[3];
new Array:g_ArrayHandle;
new Float:g_FC_fSeedScattering_Min;
new Float:g_FC_fSeedScattering_Max;
new Float:g_FC_fSeedRicochet_Min;
new Float:g_FC_fSeedRicochet_Max;
//new Float:g_fClientAttackTime[32];
new g_FC_iTouchedFlags;

new Float:g_fCore_CheckPoints[MaxSides][3] =
{
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0},
	{0.0, 0.0, 0.0}
};

// Stocks

stock Core_FixBrain(iCore)
{
	GetSeed_RicochetAngles(iCore);
	UTIL_FixSpritePos(iCore);
	Core_Action(iCore);
}

stock UTIL_FixSpritePos(iCore)
{
	static Float:vec_fSpriteOrigin[3];
		
	xs_vec_mul_scalar(g_vec_fGroundNormal, g_const_FC_fCoreSize * 1.5, vec_fSpriteOrigin);
	xs_vec_add(g_vec_fCoreOrigin, vec_fSpriteOrigin, vec_fSpriteOrigin);
	xs_vec_copy(vec_fSpriteOrigin, g_vec_fCoreOrigin);
		
	set_pev(iCore, pev_origin, g_vec_fCoreOrigin);
}

stock Core_Action(iCore)
{
	engfunc(EngFunc_EmitSound, iCore, CHAN_AUTO, g_const_FC_sCoreExplosionSnd, 0.5, ATTN_NORM, 0, PITCH_NORM);
	Core_SwitchType(iCore);
	SeedGroupInit_ByCore();
}

stock UTIL_RicochetRandomize()
{
	g_vec_fRicochetResult[0] = random_float(-0.999999, 1.000001);
	g_vec_fRicochetResult[1] = random_float(-1.0, 1.0);
	g_vec_fRicochetResult[2] = random_float(-1.000001, 0.999999);
		
	xs_vec_mul_scalar(g_vec_fRicochetResult, g_const_FC_fSeedVelocity, g_vec_fRicochetResult);
}

stock Core_SwitchType(iCore)
{
	set_pev(iCore, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(iCore, pev_solid, SOLID_NOT);
	set_pev(iCore, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(iCore, pev_scale, g_const_FC_fCoreExplodeSprScale);
	set_pev(iCore, IUSER_DATA2, g_const_FC_iExplodeSpr_Frames);
	set_pev(iCore, pev_nextthink, get_gametime());
	set_pev(iCore, pev_renderamt, g_const_FC_fExplodeSpr_Transper);
	
	engfunc(EngFunc_SetModel, iCore, g_const_FC_sCoreExplosion_Spr);
	
	entity_set_float(iCore, EV_FL_frame, 0.0);
	wpnmod_set_think(iCore, "CoreExplode_Spr");	
}

stock bool:UTIL_DoDamage(iAgressor, iEntity, iMode, bool:bGetFlags = true)
{
	if(bGetFlags)
	{
		UTIL_GetEntityFlags(iEntity);
	}
	
	static bool:bDamage;
	bDamage = false;
	
	static const Float:const_fDamageMonsters[2] = {g_const_FC_fCoreDmg_Monsters, g_const_FC_fSeedDmg_Monsters};
	static const Float:const_fDamageObjects[2] = {g_const_FC_fCoreDmg_Objects, g_const_FC_fSeedDmg_Objects};
	static const const_iDamageType[2] = {g_const_FC_iCoreDmg_Type, g_const_FC_iSeedDmg_Type};
		
	if(g_FC_iTouchedFlags & ENTITY_TARGET)
	{
		bDamage = true;
		
		static iOwner;
		iOwner = pev(iAgressor, pev_owner);
		
		if((iOwner == iEntity) && (g_FC_iTouchedFlags & ENTITY_PLAYER))
		{
			if(get_gametime() < pev(iAgressor, pev_armorvalue))
			{
				bDamage = false;
			}
		}
		
		if(bDamage)
		{
			ExecuteHamB
			(
				Ham_TakeDamage, 
				iEntity, 
				iAgressor, 
				iOwner, 
				((g_FC_iTouchedFlags & (ENTITY_MONSTER | ENTITY_PLAYER)) ? const_fDamageMonsters[iMode] : const_fDamageObjects[iMode]),
				const_iDamageType[iMode]
			);
		}
	}
	
	return bDamage;
}

stock bool:UTIL_WorldPointAnalyze(const Float:vec_fOrigin[3], iFlags)
{
 	return bool:((WORLD_CONTENT(engfunc(EngFunc_PointContents, vec_fOrigin)) & iFlags) == iFlags);
}

stock bool:Core_PlanePointAnalyze()
{
	static iPlane;
	static iResult;
	static iArrayCell;
	
	static bool:bReturn;
	bReturn = false;
	
	ArrayClear(g_ArrayHandle);
	
	for(iPlane = 0; iPlane < MaxSides; iPlane++)
	{
		ArrayPushCell(g_ArrayHandle, iPlane);
	}
	
	for(iPlane = 0; iPlane < MaxSides; iPlane++)
	{
		xs_vec_copy(g_vec_fCoreOrigin, g_vec_fCorePlanePoint);
		
		iArrayCell = random(ArraySize(g_ArrayHandle));
		iResult = ArrayGetCell(g_ArrayHandle, iArrayCell);
		
		ArrayDeleteItem(g_ArrayHandle, iArrayCell);
		xs_vec_add(g_vec_fCorePlanePoint, g_fCore_CheckPoints[iResult], g_vec_fCorePlanePoint);
		
		if(UTIL_WorldPointAnalyze(g_vec_fCorePlanePoint, WORLD_CONTENT(CONTENTS_SOLID)))
		{
			bReturn = true;
			
			break;
		}
	}
	
	return bReturn;
}

stock bool:GetSeed_RicochetAngles(iCore)
{
	static TResult;
	static iBitGroundType;
	static iBitGroundOffSet;
	static bool:bNegativeType;
	static bool:bReturn;
	
	if((bReturn = Core_PlanePointAnalyze()))
	{
		g_vec_fRicochetResult = Float:{0.0, 0.0, 0.0};
	
		engfunc(EngFunc_TraceLine, g_vec_fCoreOrigin, g_vec_fCorePlanePoint, (IGNORE_MONSTERS | IGNORE_MISSILE), iCore, TResult);
	
		iBitGroundType = UTIL_GetGroundType(TResult);
		iBitGroundOffSet = (iBitGroundType & (~(GROUND_TYPE_NEGATIVE | GROUND_TYPE_REVERSE)));
		bNegativeType = bool:(iBitGroundType & GROUND_TYPE_NEGATIVE);
	
		switch(iBitGroundOffSet)
		{
			case GROUND_TYPE_HORIZONTAL: {if(bNegativeType) {g_vec_fRicochetResult[2] = -180.0;}}

			case GROUND_TYPE_VERTICAL_X:
			{
				g_vec_fRicochetResult[1] = -90.0;
				g_vec_fRicochetResult[2] = bNegativeType ? 90.0 : -90.0; // + "GROUND_TYPE_VERTICAL_Y" -> Case
			}

			case GROUND_TYPE_VERTICAL_Y: {g_vec_fRicochetResult[2] = bNegativeType ? 90.0 : -90.0;}

			default:
			{
				xs_vec_mul_scalar(g_vec_fGroundNormal, -1.0, g_vec_fRicochetResult);
				vector_to_angle(g_vec_fRicochetResult, g_vec_fRicochetResult);
			
				g_vec_fRicochetResult[0] += 90.0;
			}
		}
	
		engfunc(EngFunc_MakeVectors, g_vec_fRicochetResult);
		global_get(glb_v_up, g_vec_fRicochetResult);
	
		if(iBitGroundOffSet & ~(GROUND_TYPE_VERTICAL_X | GROUND_TYPE_VERTICAL_Y))
		{
			g_vec_fRicochetResult[0] *= -1;
			g_vec_fRicochetResult[1] *= -1;
		}
	
		xs_vec_mul_scalar(g_vec_fRicochetResult, g_const_FC_fSeedVelocity, g_vec_fRicochetResult);
	}
	
	else
	{
		g_vec_fGroundNormal = Float:{0.0, 0.0, 0.0}; // ??? FIXME
		UTIL_RicochetRandomize();
	}
	
	return bReturn;
}

stock UTIL_GetGroundType(TR)
{
	static iReturn;
	static iCell;
	static iOffSet;
	static iBitReverse;
	
	iReturn = 0;
	iCell = 0;
	iOffSet = 0;
	iBitReverse = 0;
	
	get_tr2(TR, TR_vecPlaneNormal, g_vec_fGroundNormal);
	
	if(g_vec_fGroundNormal[2] == 1.0) // Ground -> Horizontal (floor)
	{
		iReturn = GROUND_TYPE_HORIZONTAL;
	}

	else if(g_vec_fGroundNormal[2] == 0.0) // Ground -> Vertical
	{
		iReturn = GROUND_TYPE_VERTICAL_XY;
	}

	else if(g_vec_fGroundNormal[2] == -1.0) // Ground -> Horizontal (ceiling)
	{
		iReturn = (GROUND_TYPE_HORIZONTAL | GROUND_TYPE_NEGATIVE | GROUND_TYPE_REVERSE);
	}

	else // Ground -> Has Angles
	{
		if(g_vec_fGroundNormal[2] < 0.0)
		{
			iBitReverse = GROUND_TYPE_REVERSE;
		}

		iReturn = GROUND_TYPE_AXIS_XY;
		iOffSet = 1;
	}

	if(iReturn & (GROUND_TYPE_AXIS_XY | GROUND_TYPE_VERTICAL_XY))
	{
		static bool:bGroundInitialized;
		bGroundInitialized = true;

		if(g_vec_fGroundNormal[0] == 0.0)
		{
			iReturn = GROUND_TYPE_VERTICAL_Y;
			iCell = 1;
		}

		else if(g_vec_fGroundNormal[1] == 0.0)
		{
			iReturn = GROUND_TYPE_VERTICAL_X;
		}

		else
		{
			iReturn = GROUND_TYPE_VERTICAL_XY;
			bGroundInitialized = false;
		}

		iReturn <<= iOffSet; // If - "iOffSet" :: Convert Flags From "VERTICAL" To "AXIS"

		if((bGroundInitialized ? (g_vec_fGroundNormal[iCell] < 0.0) : ((g_vec_fGroundNormal[0] < 0.0) || (g_vec_fGroundNormal[1] < 0.0))))
		{
			iReturn |= GROUND_TYPE_NEGATIVE;
		}
	}

	return (iReturn | iBitReverse);
}

stock FlakCannon_InAttack(iEntity, id, iAmmo, iMode)
{
	static const Float:const_fIdleTime[2] = {1.0, 1.0};
	static const Float:const_fFireRate[2] = {g_const_FC_fAltFireRate, g_const_FC_fFireRate};
	static const Float:const_fSndVolume[2] = {g_const_FC_fAltFire_SndVol, g_const_FC_fFire_SndVol};
	static const const_iWeaponAmin[2] = {ANIM_ALT_FIRE, ANIM_FIRE};
	static const Float:const_fSpeed[2] = {g_const_FC_fCoreVelocity, g_const_FC_fSeedVelocity};
	
	g_iSummonedOwner = id;
	
	wpnmod_set_offset_float(iEntity, Offset_flNextPrimaryAttack, const_fFireRate[iMode]);
	wpnmod_set_offset_float(iEntity, Offset_flNextSecondaryAttack, const_fFireRate[iMode]);			
	wpnmod_set_offset_float(iEntity, Offset_flTimeWeaponIdle, const_fIdleTime[iMode]);
	
	UTIL_MakeVectors(id, MAKE_AIMING_POINT);
		
	wpnmod_send_weapon_anim(iEntity, const_iWeaponAmin[iMode]);
	wpnmod_set_player_ammo(id, g_const_FC_sAmmoClass, (iAmmo - 1));	
	wpnmod_set_player_anim(id, PLAYER_ATTACK1);
		
	UTIL_GetVectorPointOrigin(g_fPointOriginResult, Float:((get_distance_f(g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_AIMING_POINT]) > 64.0) ? {16.0, 1.0, 2.5} : {1.0, 1.0, 2.5}));
	
	xs_vec_copy(g_vec_fGlobalData[DATA_GLOBAL_FORWARD], g_fPointResult);
	xs_vec_mul_scalar(g_fPointResult, const_fSpeed[iMode], g_fPointResult);
	
	UTIL_CrosshairJump(id);
	engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_const_FC_sAttackSnd[iMode], const_fSndVolume[iMode], ATTN_NORM, 0, PITCH_NORM);
}

stock UTIL_EnvSpriteInitialize(iEntity, iType)
{
	static const const_iMoveType[2] = {MOVETYPE_BOUNCE, MOVETYPE_BOUNCE};
	static const Float:const_fGravity[2] = {1.0, 0.000001};
	
	static const Float:const_fSize[2][2][3] =
	{
		{
			{-g_const_FC_fCoreSize, -g_const_FC_fCoreSize, -g_const_FC_fCoreSize},
			{g_const_FC_fCoreSize, g_const_FC_fCoreSize, g_const_FC_fCoreSize}
		},
	
		{
			{-g_const_FC_fSeedSize, -g_const_FC_fSeedSize, -g_const_FC_fSeedSize},
			{g_const_FC_fSeedSize, g_const_FC_fSeedSize, g_const_FC_fSeedSize}
		}
	};
	
	static const Float:const_fTransparency[2] = {g_const_FC_fCoreTransparency, g_const_FC_fSeedTransparency};
	static const Float:const_fScale[2] = {g_const_FC_fCoreSpr_Scale, g_const_FC_fSeedSpr_Scale};
	static const Float:const_fAnimFrames[2] = {g_const_FC_fCoreSpr_AnimFrames, g_const_FC_fSeedSpr_AnimFrames};
	static const const_iRenderMode[2] = {kRenderTransAdd, kRenderTransAdd};
	
	static const const_sCallBack[2][] =
	{
		"CoreTouch",
		"SeedTouch"
	};
	
	SET_MODEL(iEntity, g_const_FC_sSphere_Spr[iType]);

	set_pev(iEntity, pev_spawnflags, SF_SPRITE_STARTON);
	set_pev(iEntity, pev_framerate, const_fAnimFrames[iType]);
	set_pev(iEntity, pev_scale, const_fScale[iType]);

	dllfunc(DLLFunc_Spawn, iEntity);

	set_pev(iEntity, pev_owner, g_iSummonedOwner);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, const_iMoveType[iType]);
	set_pev(iEntity, pev_takedamage, DAMAGE_NO);
	set_pev(iEntity, pev_gravity, const_fGravity[iType]);
	
	set_pev(iEntity, pev_renderfx, kRenderFxNone);
	set_pev(iEntity, pev_rendermode, const_iRenderMode[iType]);
	set_pev(iEntity, pev_renderamt, const_fTransparency[iType]);
	
	set_pev(iEntity, pev_mins, const_fSize[iType][0]);
	set_pev(iEntity, pev_maxs, const_fSize[iType][1]);
	
	engfunc(EngFunc_SetSize, iEntity, const_fSize[iType][0], const_fSize[iType][1]);
	set_pev(iEntity, pev_classname, g_const_FC_sSummonClasses[iType]);
	
	set_pev(iEntity, pev_nextthink, (get_gametime() + 10.0));
	set_pev(iEntity, pev_armorvalue, 0.0); // Must Be! -> Init Time
	
	wpnmod_set_think(iEntity, "DeleteEntity");
	wpnmod_set_touch(iEntity, const_sCallBack[iType]);
	
	return iEntity;
}

stock UTIL_CreateEntity(bool:bSetData = false, iEntityType = SUMMON_CORE)
{
	static iClassCache;
	
	new 
	
	iReturn = 0,
	iEntity;
	
	if(iClassCache || (iClassCache = engfunc(EngFunc_AllocString, "env_sprite")))
	{
		if(pev_valid((iEntity = engfunc(EngFunc_CreateNamedEntity, iClassCache))))
		{
			iReturn = bSetData ? UTIL_EnvSpriteInitialize(iEntity, iEntityType) : iEntity;
		}
	}
	
	return iReturn;
}

stock UTIL_GetVectorPointOrigin(Float:vec_fSource[3], const Float:vec_fMultiple[3])
{
	vec_fSource[0] = 
	(
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][0]
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][0]
		* 
			vec_fMultiple[0]
		) 
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][0]
		* 
			vec_fMultiple[1]
		) 
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_UP][0]
		* 
			vec_fMultiple[2]
		)
	);
	
	vec_fSource[1] = 
	(
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][1]
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][1]
		* 
			vec_fMultiple[0]
		)
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][1]
		* 
			vec_fMultiple[1]
		) 
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_UP][1] 
		* 
			vec_fMultiple[2]
		)
	);
	
	vec_fSource[2] = 
	(
		g_vec_fGlobalData[DATA_ORIGIN_RESULT][2]
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_FORWARD][2]
		* 
			vec_fMultiple[0]
		)
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_RIGHT][2]
		* 
			vec_fMultiple[1]
		)
	+ 
		(
			g_vec_fGlobalData[DATA_GLOBAL_UP][2]
		* 
			vec_fMultiple[2]
		)
	);
}

stock UTIL_GetEntityFlags(iEntity)
{
	static iFlags;
	iFlags = 0;
	
	if(iEntity > g_iMaxPlayers)
	{
		if(pev_valid(iEntity))
		{
			if(pev(iEntity, pev_solid) & SOLID_BSP)
			{
				iFlags = (ENTITY_WORLD_BRUSH | ENTITY_OBJECT);
			}
			
			if(pev(iEntity, pev_flags) & FL_MONSTER)
			{
				if(!pev(iEntity, pev_deadflag))
				{
					iFlags |= ENTITY_MONSTER;
				}
			}
			
			else
			{
				iFlags |= ENTITY_OBJECT;
			}
		}
	}
	
	else if(BIT_VALID(g_iBitAlive, iEntity))
	{
		iFlags = ENTITY_PLAYER;
	}
	
	if(iFlags && pev(iEntity, pev_takedamage) && pev(iEntity, pev_health) > 0.0)
	{
		iFlags |= ENTITY_TARGET;
	}
	
	g_FC_iTouchedFlags = iFlags;
	
	return iFlags;
}

stock UTIL_MakeVectors(id, iMode = MAKE_DEFAULT_POINT)
{
	static iTraceResult;

	pev(id, pev_origin, g_vec_fGlobalData[DATA_ORIGIN]);
	pev(id, pev_view_ofs, g_vec_fGlobalData[DATA_VIEW_OFS]);
	pev(id, pev_v_angle, g_vec_fGlobalData[DATA_ANGLES]);
	pev(id, pev_punchangle, g_vec_fGlobalData[DATA_PUNCH_ANGLES]);
	
	xs_vec_add(g_vec_fGlobalData[DATA_ANGLES], g_vec_fGlobalData[DATA_PUNCH_ANGLES], g_vec_fGlobalData[DATA_ANGLES_RESULT]);
	xs_vec_add(g_vec_fGlobalData[DATA_ORIGIN], g_vec_fGlobalData[DATA_VIEW_OFS], g_vec_fGlobalData[DATA_ORIGIN_RESULT]);
	
	engfunc(EngFunc_MakeVectors, g_vec_fGlobalData[DATA_ANGLES_RESULT]);
	global_get(glb_v_forward, g_vec_fGlobalData[DATA_GLOBAL_FORWARD]);

	if(iMode & MAKE_AIMING_POINT)
	{
		xs_vec_mul_scalar(g_vec_fGlobalData[DATA_GLOBAL_FORWARD], 4096.0, g_vec_fGlobalData[DATA_GLOBAL_FORWARD_MULTIPLIED]);
		xs_vec_add(g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_GLOBAL_FORWARD_MULTIPLIED], g_vec_fGlobalData[DATA_AIMING_ORIGIN_FULL]);

		engfunc(EngFunc_TraceLine, g_vec_fGlobalData[DATA_ORIGIN_RESULT], g_vec_fGlobalData[DATA_AIMING_ORIGIN_FULL], (DONT_IGNORE_MONSTERS | IGNORE_MISSILE), id, iTraceResult);
		get_tr2(iTraceResult, TR_vecEndPos, g_vec_fGlobalData[DATA_AIMING_POINT]);
	}
	
	if(iMode & MAKE_DEFAULT_POINT)
	{
		global_get(glb_v_right, g_vec_fGlobalData[DATA_GLOBAL_RIGHT]);
		global_get(glb_v_up, g_vec_fGlobalData[DATA_GLOBAL_UP]);
	}
}

stock UTIL_CrosshairJump(id)
{
	new Float:vec_fPunchAngles[3];
	
	pev(id, pev_punchangle, vec_fPunchAngles);
	
	vec_fPunchAngles[0] += random_float(-Float:g_const_FC_fPuchAngle, Float:g_const_FC_fPuchAngle);
	vec_fPunchAngles[1] += random_float(-Float:g_const_FC_fPuchAngle, Float:g_const_FC_fPuchAngle);
	vec_fPunchAngles[2] += random_float(-Float:g_const_FC_fPuchAngle, Float:g_const_FC_fPuchAngle);
	
	set_pev(id, pev_punchangle, vec_fPunchAngles);
}

stock UTIL_GetRealOrigin(iEntity, Float:vec_fSource[3])
{
	static
				
	Float:vec_fMins[3],
	Float:vec_fMaxs[3];
				
	pev(iEntity, pev_mins, vec_fMins);
	pev(iEntity, pev_maxs, vec_fMaxs);
				
	xs_vec_add(vec_fMaxs, vec_fMins, vec_fSource);
	xs_vec_mul_scalar(vec_fSource, 0.5, vec_fSource);
}

#if defined SEED_HOTGLOW_POINTS
stock UTIL_SummonGlowingSprite(iSpriteIndex, const Float:vec_fOrigin[3], iSize = 5, iBrightness = 192)
{
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
#endif

stock UTIL_SummonSparks(const Float:vec_fOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			
	write_byte(TE_SPARKS);
	write_coord_f(vec_fOrigin[0]);
	write_coord_f(vec_fOrigin[1]);
	write_coord_f(vec_fOrigin[2]);
				
	message_end();
}

#if defined SEED_TRAILS
stock UTIL_ColoredTrails(iEntity, iSpr, iLTime, bool:bSeed = false)
{
	static iColors[3];
	
	if(bSeed)
	{
		iColors[0] = 255;
		iColors[1] = random_num(35, 160);
		iColors[2] = 0;
	}
	
	else
	{
		iColors[0] = random(256);
		iColors[1] = random(256);
		iColors[2] = random(256);
	}

	emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			
	ewrite_byte(TE_BEAMFOLLOW);
	ewrite_short(iEntity);
	ewrite_short(iSpr);
	ewrite_byte(iLTime);
	ewrite_byte(1);
	ewrite_byte(iColors[0]);
	ewrite_byte(iColors[1]);
	ewrite_byte(iColors[2]);
	
	ewrite_byte(random_num(128, 255));
				
	emessage_end();
}

#else

stock UTIL_ColoredTrails(iEntity, iSpr, iLTime)
{
	emessage_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			
	ewrite_byte(TE_BEAMFOLLOW);
	ewrite_short(iEntity);
	ewrite_short(iSpr);
	ewrite_byte(iLTime);
	ewrite_byte(1);
	ewrite_byte(random(256));
	ewrite_byte(random(256));
	ewrite_byte(random(256));
	
	ewrite_byte(random_num(128, 255));
				
	emessage_end();
}

#endif

public SeedTouch(iSeed, iEntity)
{
	static bool:bJump;
	bJump = true;
	
	static Float:vec_fOrigin[3];
	
	if(iEntity)
	{
		if(UTIL_DoDamage(iSeed, iEntity, SUMMON_SEED))
		{
			bJump = false;
			
			pev(iSeed, pev_origin, vec_fOrigin);
			UTIL_SummonSparks(vec_fOrigin);
			emit_sound(iSeed, CHAN_AUTO, g_const_FC_sSeed_HitSnd, 0.25, ATTN_NORM, 0, PITCH_NORM);
			engfunc(EngFunc_RemoveEntity, iSeed);
		}
	}
	
	else
	{
		g_FC_iTouchedFlags = 0;
	}
	
	if(bJump)
	{
		static bool:bTouch;
		bTouch = true;
		
		if(g_FC_iTouchedFlags == ENTITY_OBJECT)
		{
			static sClassName[32];
			pev(iEntity, pev_classname, sClassName, charsmax(sClassName));
			
			if(strcmp(sClassName, g_const_FC_sSummonClasses[SUMMON_SEED]) == 0)
			{
				bTouch = false;
			}
		}
		
		if(bTouch)
		{
#if defined SEED_HOTGLOW_POINTS || defined SEED_RICOCHET_SPARKS				
			pev(iSeed, pev_origin, vec_fOrigin);
#endif			
			
#if defined SEED_RICOCHET_SOUNDS			
			emit_sound(iSeed, CHAN_AUTO, g_sSeedRicochet_Snd[random(g_const_iSeedRicochet_SndCount)], 0.25, ATTN_NORM, 0, PITCH_NORM);
#endif
			if(pev(iSeed, pev_gravity) == 0.0) // bug -> default gravity == 0.000001, but only this works :D
			{				
				set_pev(iSeed, IUSER_DATA, 1);
				set_pev(iSeed, pev_gravity, g_const_FC_fSeedGravity_I);
				UTIL_SummonSparks(vec_fOrigin);
			}
			
			else
			{
				static iTouch;
		
				if((iTouch = pev(iSeed, IUSER_DATA)) == 0)
				{
#if defined SEED_HOTGLOW_POINTS
					UTIL_SummonGlowingSprite(g_iSeedEndPoint_SprPtr, vec_fOrigin, 1, 128);
#endif
					engfunc(EngFunc_RemoveEntity, iSeed);
				}
		
				else
				{
#if defined SEED_RICOCHET_SPARKS
					UTIL_SummonSparks(vec_fOrigin);
#endif
					set_pev(iSeed, IUSER_DATA, (iTouch - 1));
				}
			}
		}
	}
}

public plugin_precache()
{
	PRECACHE_MODEL(g_const_FC_sModels[P_MODEL]);
	PRECACHE_MODEL(g_const_FC_sModels[V_MODEL]);
	PRECACHE_MODEL(g_const_FC_sModels[W_MODEL]);
	
	PRECACHE_MODEL(g_const_FC_sAB_Mdl);
	
	PRECACHE_GENERIC(g_const_FC_sHudSprCfg);
	PRECACHE_GENERIC(g_const_FC_sHudSpr);
	
	PRECACHE_SOUND(g_const_FC_sAttackSnd[1]);
	PRECACHE_SOUND(g_const_FC_sAttackSnd[0]);
	PRECACHE_SOUND(g_const_FC_sSwitchSnd);
	PRECACHE_SOUND(g_const_FC_sAmmo_PickUpSnd);
	PRECACHE_SOUND(g_const_FC_sWeapon_PickUpSnd);
	PRECACHE_SOUND(g_const_FC_sSeed_HitSnd);
	PRECACHE_SOUND(g_const_FC_sCoreExplosionSnd);
	
#if defined SEED_RICOCHET_SOUNDS
	new i;
	
	for(i = 0; i < g_const_iSeedRicochet_SndCount; i++)
	{
		precache_sound(g_sSeedRicochet_Snd[i]);
	}
#endif
	
#if defined SEED_HOTGLOW_POINTS	
	g_iSeedEndPoint_SprPtr = PRECACHE_MODEL(g_const_FC_sSphere_Spr[SUMMON_SEED]);
#else	
	PRECACHE_MODEL(g_const_FC_sSphere_Spr[SUMMON_SEED]);
#endif
	PRECACHE_MODEL(g_const_FC_sSphere_Spr[SUMMON_CORE]);
	PRECACHE_MODEL(g_const_FC_sCoreExplosion_Spr);
	
#if defined SEED_TRAILS	
	g_iSeedTrail_Spr = PRECACHE_MODEL("sprites/xenobeam.spr");
#endif	
	
	g_ArrayHandle = ArrayCreate();
	
	static bool:bNeedInit = true;
	
	if(bNeedInit)
	{
		bNeedInit = false;
		
		g_FC_fSeedScattering_Min = (g_const_FC_fSeedVelocity * (-(g_const_FC_fShootScattering)));
		g_FC_fSeedScattering_Max = (g_const_FC_fSeedVelocity * g_const_FC_fShootScattering);
		g_FC_fSeedRicochet_Min = (g_const_FC_fSeedVelocity * (-(g_const_FC_fSeedRicochet)));
		g_FC_fSeedRicochet_Max = (g_const_FC_fSeedVelocity * g_const_FC_fSeedRicochet);
		
		g_fCore_CheckPoints[0][2] = (g_const_FC_fCoreSize * 1.1);
		g_fCore_CheckPoints[1][2] = (g_const_FC_fCoreSize * -1.1);
		g_fCore_CheckPoints[2][1] = (g_const_FC_fCoreSize * 1.1);
		g_fCore_CheckPoints[3][1] = (g_const_FC_fCoreSize * -1.1);
		g_fCore_CheckPoints[4][0] = (g_const_FC_fCoreSize * 1.1);
		g_fCore_CheckPoints[5][0] = (g_const_FC_fCoreSize * -1.1);
	}
}

public FlakCannon_AmmoAdd(iItem, iPlayer)
{
	new iResult =
	(
		ExecuteHamB
		(
			Ham_GiveAmmo,
			iPlayer,
			g_const_FC_iAmmoBox_Ammo,
			g_const_FC_sAmmoClass,
			g_const_FC_iPrimaryAmmo_Max
		) != -1
	);
	
	if(iResult)
	{
		emit_sound(iItem, CHAN_ITEM, g_const_FC_sAmmo_PickUpSnd, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	return iResult;
}

public FlakCannon_AmmoSpawn(iEntity)
{
	SET_MODEL(iEntity, g_const_FC_sAB_Mdl);
}

public FlakCannon_Spawn(iEntity)
{
	SET_MODEL(iEntity, g_const_FC_sModels[W_MODEL]);
	wpnmod_set_offset_int(iEntity, Offset_iDefaultAmmo, g_const_FC_iDefaultAmmo);
}

public FlakCannon_Deploy(iItem, iPlayer)
{
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, g_const_FC_sSwitchSnd, g_const_FC_fDeploy_SndVol, ATTN_NORM, 0, PITCH_NORM);

	return wpnmod_default_deploy(iItem, g_const_FC_sModels[V_MODEL], g_const_FC_sModels[P_MODEL], ANIM_DEPLOY, g_const_FC_sAnimExtension);
}

public FlakCannon_Idle(const iItem, const iPlayer, const iClip)
{
	if(bool:(wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0))
	{
		wpnmod_reset_empty_sound(iItem); // FIXME
	}
	
	else
	{
		wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
	}
	
	return 0;
}

public DeleteEntity(iEntity)
{
	if(pev_valid(iEntity))
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}

public CoreExplode_Spr(iCore)
{
	static iFrame;
	iFrame = pev(iCore, IUSER_DATA2);
	
	if(iFrame)
	{
		set_pev(iCore, IUSER_DATA2, (iFrame - 1));
		set_pev(iCore, pev_nextthink, (get_gametime() + g_const_FC_fExplodeSpr_Speed));
		entity_set_float(iCore, EV_FL_frame, float(g_const_FC_iExplodeSpr_Frames - iFrame));
	}
	
	else
	{
		engfunc(EngFunc_RemoveEntity, iCore);
	}
}

public CoreTouch(iCore, iEntity)
{
	pev(iCore, pev_origin, g_vec_fCoreOrigin);
	
	if(iEntity)
	{
		UTIL_GetEntityFlags(iEntity);
		
		if(g_FC_iTouchedFlags & ENTITY_TARGET)
		{
			if(UTIL_DoDamage(iCore, iEntity, SUMMON_CORE, false))
			{
				if(g_FC_iTouchedFlags & ENTITY_WORLD_BRUSH) 
				{
					Core_FixBrain(iCore);
				}
			
				else 
				{
					UTIL_RicochetRandomize();
					UTIL_FixSpritePos(iCore);
					Core_Action(iCore);
				}
			}
		}
		
		else
		{
			if(g_FC_iTouchedFlags & ENTITY_WORLD_BRUSH)
			{
				Core_FixBrain(iCore);
			}
		}
	}
		
	else
	{
		Core_FixBrain(iCore);
	}
}

public FlakCannon_SecondaryFire(iEntity, id, iClip, iAmmo)
{
	if(iAmmo)
	{
		FlakCannon_InAttack(iEntity, id, iAmmo, SUMMON_CORE);
		
		new iCore = UTIL_CreateEntity(true, SUMMON_CORE);
		
		if(iCore)
		{
			//g_fClientAttackTime[(id - 1)] = (get_gametime() + g_const_FC_fAltFireRate);
			set_pev(iCore, pev_armorvalue, (get_gametime() + (g_const_FC_fAltFireRate * 2))); // record init time :D
			set_pev(iCore, pev_origin, g_fPointOriginResult);
			set_pev(iCore, pev_basevelocity, g_fPointResult);
		}	
	}
}

stock bool:SeedGroupInit_ByCore()
{
	new
		
	iSeed[9] = {0, 0, 0, ...},
	bool:bDelete = false,
	iCell = -1,
	Float:vec_fNewVel[3];
	
	for(iCell = 0; iCell < 9; iCell++)
	{
		if((iSeed[iCell] = UTIL_CreateEntity(true, SUMMON_SEED)))
		{
			set_pev(iSeed[iCell], pev_origin, g_vec_fCoreOrigin);

			vec_fNewVel[0] = (g_vec_fRicochetResult[0] + random_float(g_FC_fSeedRicochet_Min, g_FC_fSeedRicochet_Max));
			vec_fNewVel[1] = (g_vec_fRicochetResult[1] + random_float(g_FC_fSeedRicochet_Min, g_FC_fSeedRicochet_Max));
			vec_fNewVel[2] = (g_vec_fRicochetResult[2] + random_float(g_FC_fSeedRicochet_Min, g_FC_fSeedRicochet_Max));
			
			set_pev(iSeed[iCell], pev_movetype, MOVETYPE_BOUNCE);
			set_pev(iSeed[iCell], pev_gravity, g_const_FC_fSeedGravity_II);
			set_pev(iSeed[iCell], IUSER_DATA, 1);
#if defined SEED_TRAILS			
			UTIL_ColoredTrails(iSeed[iCell], g_iSeedTrail_Spr, 1, true);
#endif				
			set_pev(iSeed[iCell], pev_basevelocity, vec_fNewVel);
		}
		
		else
		{
			bDelete = true;
				
			break;
		}
	}
	
	if(bDelete)
	{
		for(iCell = 0; iCell < 9; iCell++)
		{
			if(iSeed[iCell])
			{
				engfunc(EngFunc_RemoveEntity, iSeed[iCell]);
			}
		}
	}
	
	return (bDelete == false);
}

stock bool:SeedGroupInit_ByShoot()
{
	new 
		
	iSeed[9] = {0, 0, 0, ...},
	bool:bDelete = false,
	iCell = -1,
	Float:vec_fNewVel[3],
	Float:fGameTime = (get_gametime() + 0.1);
	
	for(iCell = 0; iCell < 9; iCell++)
	{
		if((iSeed[iCell] = UTIL_CreateEntity(true, SUMMON_SEED)))
		{
			set_pev(iSeed[iCell], pev_origin, g_fPointOriginResult);
				
			vec_fNewVel[0] = (g_fPointResult[0] + random_float(g_FC_fSeedScattering_Min, g_FC_fSeedScattering_Max));
			vec_fNewVel[1] = (g_fPointResult[1] + random_float(g_FC_fSeedScattering_Min, g_FC_fSeedScattering_Max));
			vec_fNewVel[2] = (g_fPointResult[2] + random_float(g_FC_fSeedScattering_Min, g_FC_fSeedScattering_Max));

#if defined SEED_TRAILS
			UTIL_ColoredTrails(iSeed[iCell], g_iSeedTrail_Spr, 1, true);
#endif			
			set_pev(iSeed[iCell], pev_armorvalue, fGameTime); // record init time :D
			set_pev(iSeed[iCell], pev_basevelocity, vec_fNewVel);
		}
		
		else
		{
			bDelete = true;
				
			break;
		}
	}
	
	if(bDelete)
	{
		for(iCell = 0; iCell < 9; iCell++)
		{
			if(iSeed[iCell])
			{
				engfunc(EngFunc_RemoveEntity, iSeed[iCell]);
			}
		}
	}
	
	return (bDelete == false);
}

public FlakCannon_PrimaryFire(iEntity, id, iClip, iAmmo)
{
	if(iAmmo)
	{
		//g_fClientAttackTime[(id - 1)] = (get_gametime() + g_const_FC_fFireRate);
		FlakCannon_InAttack(iEntity, id, iAmmo, SUMMON_SEED);
		SeedGroupInit_ByShoot();
	}
}


public client_disconnect(id)
{
	new iPlayer = (id - 1);
	
	_BIT_SUB(g_iBitAlive, iPlayer);
#if defined HALF_LIFE
	_BIT_SUB(g_iBitFirstSpawn, iPlayer);
#endif
}

public OnClientDeath_Post(id)
{
	BIT_SUB(g_iBitAlive, id);
}

#if defined HALF_LIFE
public client_putinserver(id)
{
	BIT_ADD(g_iBitFirstSpawn, id);
}
#endif

public OnClientSpawn_Post(id)
{
	if(is_user_alive(id))
	{
		BIT_ADD(g_iBitAlive, id);
	}
}

#if defined HALF_LIFE
public ResetHUD(id)
{
	static iPlayer;
	iPlayer = (id - 1);
	
	if(_BIT_VALID(g_iBitFirstSpawn, iPlayer))
	{
		_BIT_SUB(g_iBitFirstSpawn, iPlayer);
		OnClientSpawn_Post(id);
	}
}
#endif

public FlakCannon_Add(iWeapon, id)
{
	engfunc(EngFunc_EmitSound, iWeapon, CHAN_AUTO, g_const_FC_sWeapon_PickUpSnd, 0.5, ATTN_NORM, 0, PITCH_NORM);
	
	return 1; // add weapon; 0 - block
}

public plugin_cfg()
{
	g_iMaxPlayers = get_maxplayers();
	
	register_plugin("UT_FlakCannon", "0.11", "Turanga_Leela"); // [08.03.2013]
	
	new
	
	iFlakCannon_WpnIndex,
	iFlakCannon_AmmoBox;
	
	iFlakCannon_WpnIndex = wpnmod_register_weapon
	(
		g_const_FC_sWeaponClass,
		g_const_FC_iWeaponSlot,
		g_const_FC_iWeaponPos,
		g_const_FC_sAmmoClass,
		g_const_FC_iPrimaryAmmo_Max,
		g_const_FC_sSecondaryAmmoClass,
		g_const_FC_iSecondaryAmmo_Max,
		g_const_FC_iWeapon_MaxClip,
		g_const_FC_iWeaponFlags,
		g_const_FC_iWeaponWeight
	);
	
	iFlakCannon_AmmoBox = wpnmod_register_ammobox(g_const_FC_sAmmoClass);
	
	wpnmod_register_ammobox_forward(iFlakCannon_AmmoBox, Fwd_Ammo_AddAmmo, "FlakCannon_AmmoAdd");
	wpnmod_register_ammobox_forward(iFlakCannon_AmmoBox, Fwd_Ammo_Spawn, "FlakCannon_AmmoSpawn");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_Spawn, "FlakCannon_Spawn");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_Deploy, "FlakCannon_Deploy");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_Idle, "FlakCannon_Idle");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_SecondaryAttack, "FlakCannon_SecondaryFire");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_PrimaryAttack, "FlakCannon_PrimaryFire");
	wpnmod_register_weapon_forward(iFlakCannon_WpnIndex, Fwd_Wpn_AddToPlayer2, "FlakCannon_Add");
		
	RegisterHam(Ham_Spawn, "player", "OnClientSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "OnClientDeath_Post", 1);
#if defined HALF_LIFE
	register_event("ResetHUD", "ResetHUD", "be");
#endif
	return 0;
}