#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>

#define PLUGIN "Buff M4"
#define VERSION "1.0"
#define AUTHOR "Dr.Hunter" //Fix model and sprites BIGs

// Weapon settings
#define WEAPON_NAME 			"weapon_buffm4"
#define WEAPON_SLOT			4
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		".75"
#define WEAPON_PRIMARY_AMMO_MAX		125
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			40
#define WEAPON_DEFAULT_AMMO		40
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			45.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_buffm4.txt"
#define WEAPON_HUD_TXT_2		"sprites/weapon_buffm4_scp.txt"
#define WEAPON_HUD_SPR		        "sprites/wpn/640hud132.spr"
#define WEAPON_HUD_SPR2			"sprites/wpn/640hud7.spr"
#define WEAPON_HUD_SPR_2		"sprites/wpn/zg_hit.spr"

// Models
#define MODEL_WORLD			"models/w_buffm4.mdl"
#define MODEL_VIEW			"models/v_buffm4.mdl"
#define MODEL_PLAYER			"models/p_buffm4.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/m4a1buff-1.wav"
#define SOUND_SHOOT_SPECIAL		"weapons/m4a1buff-2.wav"
#define SOUND_RELOAD1			"weapons/m4a1buff_clipin1.wav"
#define SOUND_RELOAD2			"weapons/m4a1buff_clipin2.wav"
#define SOUND_RELOAD3			"weapons/m4a1buff_clipout.wav"
#define SOUND_IDLE			"weapons/m4a1buff_idle.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

#define MODEL_SHELL			"models/shell_tar21.mdl"

enum _:buff
{
	BUFF_IDLE,
        BUFF_RELOAD,
        BUFF_DRAW,
	BUFF_SHOOT_1,
	BUFF_SHOOT_2,
	BUFF_SHOOT_3
}

#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
new Float: flFov;
new sTrail, g_MF1, g_MF2, g_MF3;

new const MuzzleFlash1[] = "sprites/wpn/muzzleflash43.spr"
new const MuzzleFlash2[] = "sprites/wpn/muzzleflash44.spr"
new const MuzzleFlash3[] = "sprites/wpn/muzzleflash45.spr"

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
        PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_SHOOT_SPECIAL);
	PRECACHE_SOUND(SOUND_RELOAD1);
	PRECACHE_SOUND(SOUND_RELOAD2);
	PRECACHE_SOUND(SOUND_RELOAD3);
	PRECACHE_SOUND(SOUND_IDLE);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_TXT_2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_SPR2);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);

	sTrail = precache_model("sprites/zbeam2.spr")
	g_MF1 = engfunc(EngFunc_PrecacheModel, MuzzleFlash1)
	g_MF2 = engfunc(EngFunc_PrecacheModel, MuzzleFlash2)
	g_MF3 = engfunc(EngFunc_PrecacheModel, MuzzleFlash3)
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new iBUFF = wpnmod_register_weapon
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

	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_Spawn, "buff_spawn");
	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_Deploy, "buff_deploy");
	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_Idle, "buff_idle");
	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_PrimaryAttack, "buff_primaryattack");
        wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_SecondaryAttack, "buff_SecondaryAttack");
	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_Reload, "buff_reload");
	wpnmod_register_weapon_forward(iBUFF, Fwd_Wpn_Holster, "buff_holster");
}

public buff_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public buff_deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.7);

	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, BUFF_DRAW, ANIM_EXTENSION);
}

public buff_holster(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		buff_SecondaryAttack(iItem, iPlayer);
	}

	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public buff_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, BUFF_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public buff_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}	
        
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		buff_SecondaryAttack(iItem, iPlayer);
	}

	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, BUFF_RELOAD, 2.0);
}

public buff_primaryattack(const iItem, const iPlayer, iClip)
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
	
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(BUFF_SHOOT_1, BUFF_SHOOT_3));
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
	buff_special(iPlayer);
	special_attack(iItem, iPlayer);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT_SPECIAL, 1.0, ATTN_NORM, 0, PITCH_NORM);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.4);
	}
	else if (flFov != 80.0)
	{
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_2DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);

	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);

	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
                wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, -18.0);
	}
	}
	
	vecPunchangle[0] = random_float(-1.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	Make_Muzzleflash(iPlayer);
}

public buff_SecondaryAttack(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		MakeZoom(iItem, iPlayer, WEAPON_NAME, 0.0);
		
	}
	else if (flFov != 80.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_buffm4_scp", 80.0);
	}
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.35);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
}

MakeZoom(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(WEAPON_PRIMARY_AMMO_MAX);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(WEAPON_SECONDARY_AMMO_MAX);
		write_byte(WEAPON_SLOT - 1);
		write_byte(WEAPON_POSITION - 1);
		write_byte(get_user_weapon(iPlayer));
		write_byte(WEAPON_FLAGS);
		message_end();
	}
}

public buff_special(id)
{
	new Float:flAim[3]
	fm_get_aim_origin(id, flAim)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMENTPOINT)
	write_short(id | 0x1000)
	engfunc(EngFunc_WriteCoord, flAim[0])
	engfunc(EngFunc_WriteCoord, flAim[1])
	engfunc(EngFunc_WriteCoord, flAim[2])
	write_short(sTrail)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(4)  // width
	write_byte(0)// noise
	write_byte(255)// r, g, b
	write_byte(255)// r, g, b
	write_byte(255)// r, g, b
	write_byte(150)	// brightness
	write_byte(0)	// speed
	message_end()
}

public Make_Muzzleflash(id)
{
	static Float:Origin[3], TE_FLAG
	get_position(id, 40.0, -6.0, -16.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	new rand = random_num(1,3)
	switch(rand)
	{
		case 1:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(g_MF1)
			write_byte(1)
			write_byte(20)
			write_byte(TE_FLAG)
			message_end()
		}
		case 2:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(g_MF2)
			write_byte(1)
			write_byte(20)
			write_byte(TE_FLAG)
			message_end()
		}
		case 3:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, Origin[0])
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2])
			write_short(g_MF3)
			write_byte(1)
			write_byte(20)
			write_byte(TE_FLAG)
			message_end()
		}
	}
}

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

public special_attack(const iItem, const iPlayer)
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

	xs_vec_mul_scalar(vecUp, 1.0, vecUp);
	xs_vec_mul_scalar(vecRight, 6.0, vecRight);
	xs_vec_mul_scalar(vecForward, 9999999.0, vecForward);
		
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
	}
	
	if (flFraction < 1.0)
	{
		iHitWorld = true;
		iEntity = Instance(get_tr2(iTrace, TR_pHit));
		
		wpnmod_clear_multi_damage();
		
		pev(iPlayer, pev_v_angle, vecAngle);
		engfunc(EngFunc_MakeVectors, vecAngle);	
		
		global_get(glb_v_forward, vecForward);
		ExecuteHamB(Ham_TraceAttack, iEntity, iPlayer, 355.0 * 1.0, vecForward, iTrace, DMG_BLAST | DMG_NEVERGIB);
		
		wpnmod_apply_multi_damage(iPlayer, iPlayer);
			
		if (iEntity && (iClass = ExecuteHamB(Ham_Classify, iEntity)) != CLASS_NONE && iClass != CLASS_MACHINE)
		{	
			if (!ExecuteHamB(Ham_IsAlive, iEntity))
			{
				return;
			}
				
			iHitWorld = false;
		}
			
		if (iHitWorld)
		{
		}
	}
}

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

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}