#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>

#define PLUGIN "Skull-4"
#define VERSION "1.0"
#define AUTHOR "DOK_BATCOH"

// Weapon settings
#define WEAPON_NAME 			"weapon_skull4"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			1
#define WEAPON_PRIMARY_AMMO		"skull"
#define WEAPON_PRIMARY_AMMO_MAX		200
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			48
#define WEAPON_DEFAULT_AMMO		48
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			20.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_skull4.txt"
#define WEAPON_HUD_SPR		        "sprites/640hud87.spr"
#define WEAPON_HUD_SPR2			"sprites/640hud7_cso.spr"

// Models
#define MODEL_WORLD			"models/weapon/w_skull4.mdl"
#define MODEL_VIEW			"models/weapon/v_skull4.mdl"
#define MODEL_PLAYER			"models/weapon/p_skull4.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/skull4_shoot1.wav"
#define SOUND_CLIP_IN			"weapons/skull4_clipin.wav"
#define SOUND_CLIP_OUT			"weapons/skull4_clipout.wav"
#define SOUND_BOLT_PULL			"weapons/skull_boltpull.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

#define MODEL_SHELL			"models/shell_tar21.mdl"

enum _:skull4
{
	SKULL4_IDLE,
        SKULL4_RELOAD,
        SKULL4_DRAW,
	SKULL4_SHOOT_1,
	SKULL4_SHOOT_2,
	SKULL4_SHOOT_3
}

#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
#define Offset_iInZoom Offset_iuser1

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
        PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_CLIP_IN);
	PRECACHE_SOUND(SOUND_CLIP_OUT);
	PRECACHE_SOUND(SOUND_BOLT_PULL);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_SPR2);
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new iskull4 = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_Spawn, "skull4_spawn");
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_Deploy, "skull4_deploy");
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_Idle, "skull4_idle");
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_PrimaryAttack, "skull4_primaryattack");
        wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_SecondaryAttack, "skull4_SecondaryAttack");
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_Reload, "skull4_reload");
	wpnmod_register_weapon_forward(iskull4, Fwd_Wpn_Holster, "skull4_holster");
}

public skull4_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public skull4_deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, SKULL4_DRAW, ANIM_EXTENSION);
}

public skull4_holster(const iItem, const iPlayer)
{
        if (wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
		skull4_SecondaryAttack(iItem, iPlayer);
	}

	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public skull4_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, SKULL4_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public skull4_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}	
        
        if (!wpnmod_get_offset_int(iItem, Offset_iInZoom))
	{
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, SKULL4_RELOAD, 3.80);
        }
        else
	{
	skull4_SecondaryAttack(iItem, iPlayer);
        wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, SKULL4_RELOAD, 3.80);
	}
}

public skull4_primaryattack(const iItem, const iPlayer, iClip)
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
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.2);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, random_num(SKULL4_SHOOT_1, SKULL4_SHOOT_3));
	
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
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 8.0);
                wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, -18.0);
	}
	
	vecPunchangle[0] = random_float(-1.0, 2.0);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

public skull4_SecondaryAttack(const iItem, const iPlayer)
{
	new iInZoom = wpnmod_get_offset_int(iItem, Offset_iInZoom);
	
	if (!iInZoom)
	{
		SetThink(iItem, "skull4_SightThink", 0.3);
	}
	else
	{
		MakeZoom(iItem, iPlayer, WEAPON_NAME, 0.0);
	}
	
	wpnmod_set_offset_int(iItem, Offset_iInZoom, !iInZoom);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.35);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
}

//**********************************************
//* Enable sight.                              *
//**********************************************

public skull4_SightThink(const iItem, const iPlayer)
{
	MakeZoom(iItem, iPlayer, WEAPON_NAME, 60.0);
}


MakeZoom(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	
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