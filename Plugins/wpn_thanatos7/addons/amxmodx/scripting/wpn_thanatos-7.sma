#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>
#include <fun>
#include <engine>

#define PLUGIN "Thanatos-7"
#define VERSION "1.0"
#define AUTHOR "Dr.Hunter;Dev!l"

// Weapon settings
#define WEAPON_NAME 			"weapon_thanatos7"
#define WEAPON_SLOT			4
#define WEAPON_POSITION			3
#define WEAPON_PRIMARY_AMMO		"7.62"
#define WEAPON_PRIMARY_AMMO_MAX		400
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			120
#define WEAPON_DEFAULT_AMMO		120
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			34.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_thanatos7.txt"
#define WEAPON_HUD_SPR		        "sprites/640hud117.spr"
#define WEAPON_HUD_SPR2			"sprites/640hud7_cso.spr"

// Models
#define MODEL_WORLD			"models/hzo/w_thanatos7.mdl"
#define MODEL_VIEW			"models/hzo/v_thanatos7.mdl"
#define MODEL_PLAYER			"models/hzo/p_thanatos7.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/thanatos7-1.wav"
#define SOUND_CLIP_1			"weapons/thanatos7_clipin1.wav"
#define SOUND_CLIP_2			"weapons/thanatos7_clipin2.wav"
#define SOUND_CLIP_OUT_1		"weapons/thanatos7_clipout1.wav"
#define SOUND_CLIP_OUT_2		"weapons/thanatos7_clipout2.wav"
#define SOUND_SCYTHESHOOT		"weapons/thanatos7_scytheshoot.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

#define MODEL_SHELL			"models/shell_tar21.mdl"

enum _:efthanatos
{
	EFTHANATOS_IDLE,
	EFTHANATOS_BIDLE1,
	EFTHANATOS_BIDLE2,
	EFTHANATOS_SHOOT1,
	EFTHANATOS_BSHOOT1,
	EFTHANATOS_SHOOT2,
	EFTHANATOS_BSHOOT2,
        EFTHANATOS_RELOAD,
        EFTHANATOS_BRELOAD,
        EFTHANATOS_SCYTHESHOOT,
        EFTHANATOS_SCYTHERELOAD,
        EFTHANATOS_DRAW,
        EFTHANATOS_BDRAW
}

#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
#define Offset_Mod Offset_iuser1

new Ent;

new const SCYTHE_MODEL[] = "models/hzo/thanatos7_scythe.mdl"

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
        PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_CLIP_1);
	PRECACHE_SOUND(SOUND_CLIP_2);
	PRECACHE_SOUND(SOUND_CLIP_OUT_1);
	PRECACHE_SOUND(SOUND_CLIP_OUT_2);
	PRECACHE_SOUND(SOUND_SCYTHESHOOT);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_SPR2);

	precache_model(SCYTHE_MODEL);
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new ithanatos7 = wpnmod_register_weapon
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
	register_touch("scythe", "*", "fw_Touch");
	
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_Spawn, "thanatos7_spawn");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_Deploy, "thanatos7_deploy");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_Idle, "thanatos7_idle");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_PrimaryAttack, "thanatos7_primaryattack");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_SecondaryAttack, "thanatos7_secondaryattack");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_Reload, "thanatos7_reload");
	wpnmod_register_weapon_forward(ithanatos7, Fwd_Wpn_Holster, "thanatos7_holster");
}

public thanatos7_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public thanatos7_deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.0);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 2.0);

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 2.0);

        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, EFTHANATOS_DRAW, ANIM_EXTENSION);
        }
        else
        {
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, EFTHANATOS_BDRAW, ANIM_EXTENSION);
        }
        return
}

public thanatos7_holster(const iItem, const iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public thanatos7_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_send_weapon_anim(iItem, EFTHANATOS_IDLE);

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
	}
	else
	{
	new iAnim;
	new Float: flRand;
	new Float: flNextIdle;
	
	if ((flRand = random_float(0.0, 1.0)) <= 0.8)
	{
		iAnim = EFTHANATOS_BIDLE1;
		flNextIdle = 6.0;
	}
	else if (flRand <= 0.9)
	{
		iAnim = EFTHANATOS_BIDLE2;
		flNextIdle = 6.5;
	}
	else
	{
		iAnim = EFTHANATOS_BIDLE1;
		flNextIdle = 6.0;
	}
	
	wpnmod_send_weapon_anim(iItem, iAnim);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, flNextIdle);
	}
}

public thanatos7_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}	

        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, EFTHANATOS_RELOAD, 3.0);
	}
	else
	{
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, EFTHANATOS_BRELOAD, 3.0);
	}
}

public thanatos7_primaryattack(const iItem, const iPlayer, iClip)
{
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_send_weapon_anim(iItem, EFTHANATOS_SHOOT1);
	}
	else
	{
	wpnmod_send_weapon_anim(iItem, EFTHANATOS_BSHOOT1);
	}

	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.08);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_6DEGREES, 
		8192.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
                wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, -8.0);
	}
	
	vecPunchangle[0] = random_float(-1.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

public thanatos7_secondaryattack(const iItem, const iPlayer)
{
	new iMod = wpnmod_get_offset_int(iItem, Offset_Mod);
	
	if (!iMod)
	{
		SetThink(iItem, "thanatos7_SightThink", 0.3);
		wpnmod_send_weapon_anim(iItem, EFTHANATOS_SCYTHERELOAD);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 3.0);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 3.0);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 3.0);
	}
	else
	{
	        MakeMod(iItem, iPlayer, WEAPON_NAME, 0.0);
		SetThink(iItem, "thanatos_scytheshoot", 0.0);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 4.0);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 4.0);
        }	

	wpnmod_set_offset_int(iItem, Offset_Mod, !iMod);
}

public thanatos7_SightThink(const iItem, const iPlayer)
{
	MakeMod(iItem, iPlayer, WEAPON_NAME, 60.0);        
}

MakeMod(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	static msgWeaponList;

	wpnmod_set_offset_int(iPlayer, Offset_iFOV, floatround(flFov));
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo1));
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iMaxAmmo2));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iSlot));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iPosition));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iId));
		write_byte(wpnmod_get_weapon_info(iItem, ItemInfo_iFlags));
		message_end();
	}
}

public thanatos_scytheshoot(const iItem, const iPlayer)
{
	wpnmod_send_weapon_anim(iItem, EFTHANATOS_SCYTHESHOOT);

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);

	SetThink(iItem, "thanatos7_idle", 4.2);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SCYTHESHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);

	Scythe_Shoot(iPlayer);
}

public Scythe_Shoot(id)
{
	static Float:StartOrigin[3], Float:TargetOrigin[3], Float:angles[3], Float:angles_fix[3]
	get_position(id, 2.0, 4.0, -1.0, StartOrigin)

	pev(id,pev_v_angle,angles)
	Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	angles_fix[0] = 360.0 - angles[0]
	angles_fix[1] = angles[1]
	angles_fix[2] = angles[2]
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_owner, id)
	
	entity_set_string(Ent, EV_SZ_classname, "scythe")
	engfunc(EngFunc_SetModel, Ent, SCYTHE_MODEL)
	set_pev(Ent, pev_mins,{ -0.1, -0.1, -0.1 })
	set_pev(Ent, pev_maxs,{ 0.1, 0.1, 0.1 })
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, angles_fix)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_frame, 0.0)
	set_entity_anim(Ent, 1)
	entity_set_float(Ent, EV_FL_nextthink, halflife_time() + 0.01)
	
	static Float:Velocity[3]
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(StartOrigin, TargetOrigin, 750.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
}

public fw_Touch(Ent, Id)
{
	// If ent is valid
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
		
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_entity_anim(Ent, 1)
	entity_set_float(Ent, EV_FL_nextthink, halflife_time() + 0.01)
	
	set_task(0.1, "action_scythe", Ent)
	set_task(9.0, "remove", Ent)
}

public remove(Ent)
{
	if(!pev_valid(Ent))
		return
		
	remove_entity(Ent)
}

public action_scythe(Ent)
{
	if(!pev_valid(Ent))
		return
		
	Damage_scythe(Ent)
}

public Damage_scythe(Ent)
{
	if(!pev_valid(Ent))
		return
	
	static id; id = pev(Ent, pev_owner)
	new Float:origin[3]
	pev(Ent, pev_origin, origin)
	
	// Alive...
	new a = FM_NULLENT
	// Get distance between victim and epicenter
	while((a = find_ent_in_sphere(a, origin, 100.0)) != 0)
	{
		if (id == a)
			continue
	
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			ExecuteHamB(Ham_TakeDamage, a, id, id, 500.0, DMG_NEVERGIB)
		}
	}
	set_task(0.1, "action_scythe", Ent)
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_entity_anim(ent, anim)
{
	entity_set_float(ent, EV_FL_animtime, get_gametime())
	entity_set_float(ent, EV_FL_framerate, 1.0)
	entity_set_int(ent, EV_INT_sequence, anim)	
}