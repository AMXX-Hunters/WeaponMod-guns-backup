#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <hl_wpnmod>

// Weapon settings
#define WEAPON_NAME 			"weapon_shockroach"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"shock"
#define WEAPON_PRIMARY_AMMO_MAX		10
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		10
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			34.0

// Models
#define MODEL_WORLD			"models/w_shock.mdl"
#define MODEL_VIEW			"models/v_shock.mdl"
#define MODEL_PLAYER			"models/p_shock.mdl"
#define MODEL_SHOCK			"models/shock_effect.mdl"

#define SHOCK_BEAM_PARTICLE		"sprites/flare3.spr"

#define SOUND_FIRE			"weapons/shock_fire.wav"
#define SOUND_DRAW			"weapons/shock_draw.wav"
#define SOUND_IMPACT			"weapons/shock_impact.wav"
#define SOUND_RECHARGE			"weapons/shock_recharge.wav"

#define SPRITE_LIGHTNING		"sprites/lgtning.spr"


enum _:anims{
	IDLE1,
	FIRE,
	DRAW,
	HOLSTER,
	IDLE3
}

new g_LigtningIndex

public plugin_precache(){
	PRECACHE_MODEL(MODEL_VIEW)
	PRECACHE_MODEL(MODEL_WORLD)
	PRECACHE_MODEL(MODEL_PLAYER)
	PRECACHE_MODEL(MODEL_SHOCK)
	
	PRECACHE_MODEL(SHOCK_BEAM_PARTICLE)
	
	PRECACHE_SOUND(SOUND_FIRE)
	PRECACHE_SOUND(SOUND_DRAW)
	PRECACHE_SOUND(SOUND_IMPACT)
	PRECACHE_SOUND(SOUND_RECHARGE)
	
	PRECACHE_GENERIC("sprites/weapon_shockroach.txt")
	PRECACHE_GENERIC("sprites/weapon_shockroach.spr")
	
	g_LigtningIndex = PRECACHE_MODEL(SPRITE_LIGHTNING)
}

public plugin_init(){
	register_plugin("Shockroach","0.2","[LF] | Dr.Freeman & KORD_12.7")
	
	new shockroach = wpnmod_register_weapon(
		WEAPON_NAME,
		WEAPON_SLOT,
		WEAPON_POSITION,
		WEAPON_PRIMARY_AMMO,
		WEAPON_PRIMARY_AMMO_MAX,
		WEAPON_SECONDARY_AMMO,
		WEAPON_SECONDARY_AMMO_MAX,
		WEAPON_MAX_CLIP,
		ITEM_FLAG_SELECTONEMPTY|ITEM_FLAG_NOAUTOSWITCHEMPTY,
		WEAPON_WEIGHT
	)
	
	
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_Spawn,"fw_RoachSpawn")
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_AddToPlayer,"fw_RoachAddToPlayer")
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_Deploy,"fw_RoachDeploy")
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_Holster,"fw_RoachHolster")
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_Idle,"fw_RoachIdle")
	
	wpnmod_register_weapon_forward(shockroach,Fwd_Wpn_PrimaryAttack,"fw_RoachPrimaryAttack")
	
	register_touch("shock_beam","*","fw_ShockBeamTouch")
	register_think("shock_beam","fw_ShockBeamThink")
}

public fw_RoachSpawn(const ent){
	SET_MODEL(ent,MODEL_WORLD)
	wpnmod_set_offset_int(ent,Offset_iDefaultAmmo,WEAPON_DEFAULT_AMMO)
}

public fw_RoachAddToPlayer(const ent,const player){
	wpnmod_set_player_ammo(player,WEAPON_PRIMARY_AMMO,WEAPON_PRIMARY_AMMO_MAX)
}

public fw_RoachHolster(const ent,const player,const clip,const ammo){
	if(!ammo){
		wpnmod_set_player_ammo(player,WEAPON_PRIMARY_AMMO,1)
	}
}

public fw_RoachIdle(const ent){
	if(wpnmod_get_offset_float(ent,Offset_flTimeWeaponIdle)>0.0)
		return
	
	new anim,Float:nextidle
	
	if(random_float(0.0,1.0)<=0.50){
		anim = IDLE1
		nextidle = 7.0
	}
	else {
		anim = IDLE3
		nextidle = 5.0
	}
	
	wpnmod_send_weapon_anim(ent,anim)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,nextidle)
}

public fw_RoachDeploy(const ent,const player,const clip,const ammo){
	emit_sound(player,CHAN_WEAPON,SOUND_DRAW,0.9,ATTN_NORM,0,PITCH_NORM)
	
	if(ammo<WEAPON_DEFAULT_AMMO){
		wpnmod_set_think(ent,"fw_RoachThink")
		set_pev(ent,pev_nextthink,get_gametime()+0.5)
	}
	
	return wpnmod_default_deploy(ent,MODEL_VIEW,MODEL_PLAYER,DRAW,"hive")
}

public fw_RoachPrimaryAttack(const ent,const player,const clip,const ammo){
	if(ammo<=0)
		return
	
	ShockRifle_Fire(player)
	
	wpnmod_set_player_ammo(player,WEAPON_PRIMARY_AMMO,ammo - 1)
	
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.1)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,5.0)
	
	emit_sound(player,CHAN_WEAPON,SOUND_FIRE,0.9,ATTN_NORM,0,PITCH_NORM)
	
	wpnmod_set_player_anim(player,PLAYER_ATTACK1)
	wpnmod_send_weapon_anim(ent,FIRE)
	
	wpnmod_set_think(ent,"fw_RoachThink")
	set_pev(ent,pev_nextthink,get_gametime()+0.5)
}

public fw_RoachThink(const ent,const player,const clip,const ammo){
	if(ammo<WEAPON_DEFAULT_AMMO){
		wpnmod_set_player_ammo(player,WEAPON_PRIMARY_AMMO,ammo+1)
		set_pev(ent,pev_nextthink,get_gametime()+0.4)
		emit_sound(player,CHAN_WEAPON,SOUND_RECHARGE,1.0,ATTN_NORM,0,PITCH_NORM)
	}
	
}

public render(id){
	if(ExecuteHamB(Ham_IsPlayer,id)){
		set_rendering(id,kRenderFxGlowShell,0,130,255,kRenderNormal,128)
		set_task(0.8,"derender",id)
	}
}

public derender(id)
	set_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,0)

public fw_ShockBeamThink(ent){
	if(pev(ent,pev_waterlevel)==3){
		static id,owner
		static Float: origin[3]
		
		owner = pev(ent,pev_owner)
		
		pev(ent, pev_origin, origin)
		
		while ((id = engfunc(EngFunc_FindEntityInSphere, id, origin,1200.0)))
		{
			if (pev(id, pev_takedamage) && is_visible(id, ent) && pev(id,pev_waterlevel)==3)
			{
				static Float: target_origin[3]; pev(id, pev_origin, target_origin)
				static Float: beam_dist; beam_dist = get_distance_f(target_origin, origin)
				static Float: beam_dmg; beam_dmg = 500.0 - ( 500.0 / 1200.0 ) * beam_dist
				
				if (beam_dmg < 1.0) continue
				ExecuteHamB(Ham_TakeDamage, id, ent, owner, beam_dmg, DMG_SHOCK )
				UTIL_MakeBeam(id, origin, g_LigtningIndex, life:1, width:65, noise:45, 0, 128, 255, brightness:255, scroll:35);
			}
		}
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord,origin[0])
		engfunc(EngFunc_WriteCoord,origin[1])
		engfunc(EngFunc_WriteCoord,origin[2])
		message_end()
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
		write_byte(TE_DLIGHT)
		engfunc(EngFunc_WriteCoord,origin[0])
		engfunc(EngFunc_WriteCoord,origin[1])
		engfunc(EngFunc_WriteCoord,origin[2])
		write_byte(10)
		write_byte(0)
		write_byte(128)
		write_byte(255)
		write_byte(255)
		write_byte(25)
		write_byte(1)
		message_end()
		
		emit_sound(ent,CHAN_WEAPON,SOUND_IMPACT,0.9,ATTN_NORM,0,PITCH_NORM)
		
		engfunc(EngFunc_RemoveEntity,ent)
		
		return
	}
	
	set_pev(ent,pev_nextthink,get_gametime()+0.02)
}

stock UTIL_MakeBeam(const ent,  const Float:endposition[3], const m_Sprite, const life, 
	const with, const noise, const red, const green, const blue, const brightness, const scroll) 
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(ent); // start entity
	engfunc(EngFunc_WriteCoord, endposition[0]);
	engfunc(EngFunc_WriteCoord, endposition[1]);
	engfunc(EngFunc_WriteCoord, endposition[2]);
	write_short(m_Sprite); // sprite index
	write_byte(0); // starting frame
	write_byte(0); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(with); // line wdith in 0.1's
	write_byte(noise); // noise amplitude in 0.01's
	write_byte(red); // red
	write_byte(green); // green
	write_byte(blue); // blue
	write_byte(brightness); // brightness
	write_byte(scroll); // scroll speed in 0.1's
	message_end();
}

public fw_ShockBeamTouch(ent,toucher){
	new Float:origin[3]
	pev(ent,pev_origin,origin)
	
	new isplayer = ExecuteHamB(Ham_IsPlayer,toucher)
	
	if(!isplayer){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord,origin[0])
		engfunc(EngFunc_WriteCoord,origin[1])
		engfunc(EngFunc_WriteCoord,origin[2])
		write_byte(194)
		message_end()
	}else
		render(toucher)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)	// ну зачем? чем BRODACAST непонравился? :(
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord,origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	message_end()
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord,origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	write_byte(10)
	write_byte(0)
	write_byte(128)
	write_byte(255)
	write_byte(255)
	write_byte(25)
	write_byte(1)
	message_end()
	
	wpnmod_radius_damage(origin,ent,pev(ent,pev_owner),WEAPON_DAMAGE,64.0,0,DMG_SHOCK)
	emit_sound(ent,CHAN_WEAPON,SOUND_IMPACT,0.9,ATTN_NORM,0,PITCH_NORM)
	
	
	#define Offset_iBeam Offset_iuser1
	#define Offset_iGlow Offset_iuser2
	
	#define REMOVE_ENTITY(%0) engfunc(EngFunc_RemoveEntity,%0)
	
	REMOVE_ENTITY(wpnmod_get_offset_int(ent, Offset_iBeam))
	REMOVE_ENTITY(wpnmod_get_offset_int(ent, Offset_iGlow))
	REMOVE_ENTITY(ent)
}



// Here starts code by KORD_12.7

#pragma semicolon 1
#pragma ctrlchar '\'

//*************************************
//* Future beam.inc  :D               *
//*************************************

// These functions are here to show the way beams are encoded as entities.
// Encoding beams as entities simplifies their management in the client/server architecture.

// Beam types
enum _:Beam_Types
{
	BEAM_POINTS,
	BEAM_ENTPOINT,
	BEAM_ENTS,
	BEAM_HOSE
};

#define Beam_SetType(%0,%1) set_pev(%0, pev_rendermode, (pev(%0, pev_rendermode) & 0xF0) | %1 & 0x0F)
/* stock Beam_SetType(const iBeamEntity, const iType)
	return set_pev(iBeamEntity, pev_rendermode, (pev(iBeamEntity, pev_rendermode) & 0xF0) | iType & 0x0F) */

#define Beam_SetStartPos(%0,%1) set_pev(%0, pev_origin, %1)
/* stock Beam_SetStartPos(const iBeamEntity, const Float: flVecStart[3])
	return set_pev(iBeamEntity, pev_origin, flVecStart) */

#define Beam_SetEndPos(%0,%1) set_pev(%0, pev_angles, %1)
/* stock Beam_SetEndPos(const iBeamEntity, const Float: flVecEnd[3]) 
	return set_pev(iBeamEntity, pev_angles, flVecEnd) */

#define Beam_SetStartEntity(%0,%1) \
	set_pev(%0, pev_sequence, (%1 & 0x0FFF) | ((pev(%0, pev_sequence) & 0xF000) << 12)); \
	set_pev(%0, pev_owner, %1) \
/* stock Beam_SetStartEntity(const iBeamEntity, const iEntityIndex) */

#define Beam_SetEndEntity(%0,%1) \
	set_pev(%0, pev_skin, (%1 & 0x0FFF) | ((pev(%0, pev_skin) & 0xF000) << 12)); \
	set_pev(%0, pev_aiment, %1) \
/* stock Beam_SetEndEntity(const iBeamEntity, const iEntityIndex) */

#define Beam_SetStartAttachment(%0,%1) set_pev(%0, pev_sequence, (pev(%0, pev_sequence) & 0x0FFF) | ((%1 & 0xF) << 12))
/* stock Beam_SetStartAttachment(const iBeamEntity, const iAttachment)
	return set_pev(iBeamEntity, pev_sequence, (pev(iBeamEntity, pev_sequence) & 0x0FFF) | ((iAttachment & 0xF) << 12)) */

#define Beam_SetEndAttachment(%0,%1) set_pev(%0, pev_skin, (pev(%0, pev_skin) & 0x0FFF) | ((%1 & 0xF) << 12))
/* stock Beam_SetEndAttachment(const iBeamEntity, const iAttachment)
	return set_pev(iBeamEntity, pev_skin, (pev(iBeamEntity, pev_skin) & 0x0FFF) | ((iAttachment & 0xF) << 12)) */

#define Beam_SetTexture(%0,%1) set_pev(%0, pev_modelindex, %1)
/* stock Beam_SetTexture(const iBeamEntity, const iSpriteIndex)
	return set_pev(iBeamEntity, pev_modelindex, iSpriteIndex) */

#define Beam_SetWidth(%0,%1) set_pev(%0, pev_scale, %1)
/* stock Beam_SetWidth(const iBeamEntity, const Float: flWidth)
	return set_pev(iBeamEntity, pev_scale, flWidth) */

#define Beam_SetNoise(%0,%1) set_pev(%0, pev_body, %1)
/* stock Beam_SetNoise(const iBeamEntity, const iNoise)
	return set_pev(iBeamEntity, pev_body, iNoise) */	
	
#define Beam_SetColor(%0,%1) set_pev(%0, pev_rendercolor, %1)
/* stock Beam_SetColor(const iBeamEntity, const Float: flColor[3])
	return set_pev(iBeamEntity, pev_rendercolor, flColor) */	
		
#define Beam_SetBrightness(%0,%1) set_pev(%0, pev_renderamt, %1)
/* stock Beam_SetBrightness(const iBeamEntity, const Float: flBrightness)
	return set_pev(iBeamEntity, pev_renderamt, flBrightness) */

#define Beam_SetFrame(%0,%1) set_pev(%0, pev_frame, %1)
/* stock Beam_SetFrame(const iBeamEntity, const Float: flFrame)
	return set_pev(iBeamEntity, pev_frame, flFrame) */

#define Beam_SetScrollRate(%0,%1) set_pev(%0, pev_animtime, %1)
/* stock Beam_SetScrollRate(const iBeamEntity, const Float: flSpeed)
	return set_pev(iBeamEntity, pev_animtime, flSpeed) */

#define Beam_GetType(%0) pev(%0, pev_rendermode) & 0x0F
/* stock Beam_GetType(const iBeamEntity)
	return pev(iBeamEntity, pev_rendermode) & 0x0F */

#define Beam_GetStartEntity(%0) pev(%0, pev_sequence) & 0xFFF
/* stock Beam_GetStartEntity(const iBeamEntity)
	return pev(iBeamEntity, pev_sequence) & 0xFFF */

#define Beam_GetEndEntity(%0) pev(%0, pev_skin) & 0xFFF
/* stock Beam_GetEndEntity(const iBeamEntity)
	return pev(iBeamEntity, pev_skin) & 0xFFF */

stock Beam_GetStartPos(const iBeamEntity, Float: flStartPos[3])
{
	if (Beam_GetType(iBeamEntity) == BEAM_ENTS)
	{
		new iEntity = Beam_GetStartEntity(iBeamEntity);
		
		if (pev_valid(iEntity))
		{
			pev(iEntity, pev_origin, flStartPos);
			return;
		}
	}
	
	pev(iBeamEntity, pev_origin, flStartPos);
}

stock Beam_GetEndPos(const iBeamEntity, Float: flEndPos[3])
{
	new iType = Beam_GetType(iBeamEntity);
	
	if (iType == BEAM_POINTS || iType == BEAM_HOSE)
	{
		pev(iBeamEntity, pev_angles, flEndPos);
		return;
	}
	
	new iEntity = Beam_GetEndEntity(iBeamEntity);
	
	if (pev_valid(iEntity))
	{
		pev(iEntity, pev_origin, flEndPos);
		return;
	}
	
	pev(iBeamEntity, pev_angles, flEndPos);
}

#define Beam_GetTexture(%0) pev(%0, pev_modelindex)
/* stock Beam_GetTexture(const iBeamEntity)
	return pev(iBeamEntity, pev_modelindex) */
	
stock Float: Beam_GetWidth(const iBeamEntity)
{
	new Float: flScale;
	pev(iBeamEntity, pev_scale, flScale);
	
	return flScale;
}

stock Beam_Create(const szSpriteName[], const iSpriteIndex, const Float: flWidth)
{
	new iBeamEntity;
	static iszAllocStringCached;
	
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "beam")))
	{
		iBeamEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (pev_valid(iBeamEntity))
	{
		set_pev(iBeamEntity, pev_classname, "beam");
		Beam_Init(iBeamEntity, szSpriteName, iSpriteIndex, flWidth);
		
		return iBeamEntity;
	}
	
	return FM_NULLENT;
}

stock Beam_Init(const iBeamEntity, const szSpriteName[], const iSpriteIndex, const Float: flWidth)
{
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY);
	
	Beam_SetColor(iBeamEntity, Float: {255.0, 255.0, 255.0});
	Beam_SetBrightness(iBeamEntity, 255.0);
	Beam_SetNoise(iBeamEntity, 0);
	Beam_SetFrame(iBeamEntity, 0.0);
	Beam_SetScrollRate(iBeamEntity, 0.0);
	
	set_pev(iBeamEntity, pev_model, szSpriteName);
	
	Beam_SetTexture(iBeamEntity, iSpriteIndex);
	Beam_SetWidth(iBeamEntity, flWidth);
	
	set_pev(iBeamEntity, pev_skin, 0);
	set_pev(iBeamEntity, pev_sequence, 0);
	set_pev(iBeamEntity, pev_rendermode, 0);
}

stock Beam_PointEntInit(const iBeamEntity, const Float: flVecStart[3], const iEndIndex)
{
	Beam_SetType(iBeamEntity, BEAM_ENTPOINT);
	Beam_SetStartPos(iBeamEntity, flVecStart);
	Beam_SetEndEntity(iBeamEntity, iEndIndex);
	Beam_SetStartAttachment(iBeamEntity, 0);
	Beam_SetEndAttachment(iBeamEntity, 0);
	Beam_RelinkBeam(iBeamEntity);
}

stock Beam_EntsInit(const iBeamEntity, const iStartIndex, const iEndIndex)
{
	Beam_SetType(iBeamEntity, BEAM_ENTS);
	Beam_SetStartEntity(iBeamEntity, iStartIndex);
	Beam_SetEndEntity(iBeamEntity, iEndIndex);
	Beam_SetStartAttachment(iBeamEntity, 0);
	Beam_SetEndAttachment(iBeamEntity, 0);
	Beam_RelinkBeam(iBeamEntity);
}

stock Beam_RelinkBeam(const iBeamEntity)
{
	new Float: flOrigin[3];
	new Float: flStartPos[3];
	new Float: flEndPos[3];
	new Float: flMins[3];
	new Float: flMaxs[3];
	
	pev(iBeamEntity, pev_origin, flOrigin);
	
	Beam_GetStartPos(iBeamEntity, flStartPos);
	Beam_GetEndPos(iBeamEntity, flEndPos);
	
	flMins[0] = floatmin(flStartPos[0], flEndPos[0]);
	flMins[1] = floatmin(flStartPos[1], flEndPos[1]);
	flMins[2] = floatmin(flStartPos[2], flEndPos[2]);
	
	flMaxs[0] = floatmax(flStartPos[0], flEndPos[0]);
	flMaxs[1] = floatmax(flStartPos[1], flEndPos[1]);
	flMaxs[2] = floatmax(flStartPos[2], flEndPos[2]);
	
	xs_vec_sub(flMins, flOrigin, flMins);
	xs_vec_sub(flMaxs, flOrigin, flMaxs);
	
	set_pev(iBeamEntity, pev_mins, flMins);
	set_pev(iBeamEntity, pev_maxs, flMaxs);
	
	engfunc(EngFunc_SetSize, iBeamEntity, flMins, flMaxs);
	engfunc(EngFunc_SetOrigin, iBeamEntity, flOrigin);
}

//**********************************************
//* Shock Rifle fire function.                 *
//**********************************************

ShockRifle_Fire(const iPlayer)
{
	static iShockBeam;
	
	static Float: vecOrigin[3];
	static Float: vecAngles[3];
	static Float: vecVelocity[3];
	
	GetGunPosition(iPlayer, vecOrigin,8.0, 12.0, -10.0);
	UTIL_MakeVector(iPlayer, vecAngles);
	
	vecAngles[0] = -vecAngles[0];
	
	if ((iShockBeam = ShockBeam_Create(vecOrigin, vecAngles, iPlayer)))
	{
		velocity_by_aim(iPlayer, 2000, vecVelocity);
		set_pev(iShockBeam, pev_velocity, vecVelocity );
	}
}

//**********************************************
//* Create and spawn shock beam.               *
//**********************************************

ShockBeam_Create(const Float: vecOrigin[3], const Float: vecAngles[3], const iOwner)
{
	new iShock;
	static iszAllocStringCached;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		iShock = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!pev_valid(iShock))
	{
		return 0;
	}
	
	set_pev(iShock, pev_classname, "shock_beam");
	set_pev(iShock, pev_origin, vecOrigin);
	set_pev(iShock, pev_angles, vecAngles);
	set_pev(iShock, pev_owner, iOwner);
	
	ShockBeam_Spawn(iShock);
		
	return iShock;
}

ShockBeam_Spawn(const iShock)
{
	#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)
	
	new iBeam;
	new iSprite;
	
	static iszAllocStringCached;
	
	set_pev(iShock, pev_movetype, MOVETYPE_FLY);
	set_pev(iShock, pev_solid, SOLID_BBOX);
	set_pev(iShock, pev_takedamage, DAMAGE_NO);
	set_pev(iShock, pev_dmg, WEAPON_DAMAGE);
	set_pev(iShock, pev_gravity, 0.5);
	set_pev(iShock, pev_flags, pev(iShock, pev_flags) | FL_MONSTER);
	
	SET_MODEL(iShock, MODEL_SHOCK);
	SET_SIZE(iShock, Float: {-4.0, -4.0, -4.0}, Float: {4.0, 4.0, 4.0});
	
	if (pev_valid((iBeam = Beam_Create(SPRITE_LIGHTNING, g_LigtningIndex, 60.0))))
	{
		Beam_EntsInit(iBeam, iShock, iShock);
		Beam_SetStartAttachment(iBeam, 1);
		Beam_SetEndAttachment(iBeam, 2);
		Beam_SetBrightness(iBeam, 180.0);
		Beam_SetScrollRate(iBeam, 10.0);
		Beam_SetNoise(iBeam, 0);
		Beam_SetColor(iBeam, Float: {0.0, 253.0, 253.0});
		
		wpnmod_set_offset_int(iShock, Offset_iBeam, iBeam);
	}
	
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
	{
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (pev_valid(iSprite))
	{
		set_pev(iSprite, pev_movetype, MOVETYPE_FOLLOW);
		set_pev(iSprite, pev_solid, SOLID_NOT);
		
		set_pev(iSprite, pev_skin, iShock);
		set_pev(iSprite, pev_body, 0);
		set_pev(iSprite, pev_aiment, iShock);
		    
		set_pev(iSprite, pev_scale, 0.35);
		    
		set_pev(iSprite, pev_renderfx, kRenderFxDistort);
		set_pev(iSprite, pev_rendercolor, Float: {255.0, 255.0, 255.0});
		set_pev(iSprite, pev_rendermode, kRenderTransAdd);
		set_pev(iSprite, pev_renderamt, 255.0);
	
		set_pev(iSprite, pev_spawnflags, pev (iSprite, pev_flags) | SF_SPRITE_TEMPORARY);
		set_pev(iSprite, pev_flags, pev(iSprite, pev_flags) | FL_SKIPLOCALHOST);
		
		wpnmod_set_offset_int(iShock, Offset_iGlow, iSprite);
		
		SET_MODEL(iSprite, SHOCK_BEAM_PARTICLE);
	}
}

//**********************************************
//* Some usefull stocks.                       *
//**********************************************

stock GetGunPosition(const iPlayer, Float: vecResult[3], const Float: flForwardScale = 1.0, const Float: flRightScale = 1.0, const Float: flUpScale = 1.0)
{
	static Float: vecUp[3];
	static Float: vecRight[3];
	static Float: vecForward[3];
	static Float: vecViewOfs[3];
	
	UTIL_MakeVector(iPlayer, vecResult);
	
	pev(iPlayer, pev_origin, vecResult);
	pev(iPlayer, pev_view_ofs, vecViewOfs);
	
	xs_vec_add(vecResult, vecViewOfs, vecResult);
	
	global_get(glb_v_forward, vecForward);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_up, vecUp);
	
	vecResult[0] = vecResult[0] + vecForward[0] * flForwardScale + vecRight[0] * flRightScale + vecUp[0] * flUpScale;
	vecResult[1] = vecResult[1] + vecForward[1] * flForwardScale + vecRight[1] * flRightScale + vecUp[1] * flUpScale;
	vecResult[2] = vecResult[2] + vecForward[2] * flForwardScale + vecRight[2] * flRightScale + vecUp[2] * flUpScale;
}

stock UTIL_MakeVector(const iPlayer, Float: vecAngles[3])
{
	static Float: vecVAngles[3];
	static Float: vecPunchAngles[3];

	pev(iPlayer, pev_v_angle, vecVAngles);
	pev(iPlayer, pev_punchangle, vecPunchAngles);

	xs_vec_add(vecVAngles, vecPunchAngles, vecAngles);
	engfunc(EngFunc_MakeVectors, vecAngles);
}
