#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>


#define PLUGIN "HL: FAMAS"
#define VERSION "1.0"
#define AUTHOR "RAGEDUDE"


// Weapon settings
#define WEAPON_NAME 			"weapon_famas"
#define WEAPON_SLOT			3
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"fClip"
#define WEAPON_PRIMARY_AMMO_MAX		140
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			35
#define WEAPON_DEFAULT_AMMO		35
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			24
#define WEAPON_DAMAGE			22.0

// Hud
#define WEAPON_HUD_SPR		        "sprites/cso/640hud41.spr"
#define WEAPON_HUD_TXT			"sprites/weapon_svdex.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_Famasclip"

// Models
#define MODEL_WORLD			"models/w_famas.mdl"
#define MODEL_VIEW			"models/v_famas.mdl"
#define MODEL_PLAYER			"models/p_famas.mdl"
#define MODEL_CLIP			"models/w_famasclip.mdl"
#define MODEL_SHELL			"models/shell.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/famas-1.wav"
#define SOUND_SHOOT_MOD                 "weapons/famas-burst.wav"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:Animation
{
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_3
};

#define Offset_Mod Offset_iuser1

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_SHELL);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_SHOOT);
	PRECACHE_SOUND(SOUND_SHOOT_MOD);

	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iFamas = wpnmod_register_weapon
	
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
	new iAmmoFamas = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_Spawn, "Famas_Spawn");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_Deploy, "Famas_Deploy");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_Idle, "Famas_Idle");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_PrimaryAttack, "Famas_PrimaryAttack");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_SecondaryAttack, "Famas_SecondaryAttack");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_Reload, "Famas_Reload");
	wpnmod_register_weapon_forward(iFamas, Fwd_Wpn_Holster, "Famas_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoFamas, Fwd_Ammo_Spawn, "AmmoFamas_Spawn");
	wpnmod_register_ammobox_forward(iAmmoFamas, Fwd_Ammo_AddAmmo, "AmmoFamas_AddAmmo");
}


public Famas_Spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}


public Famas_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

public Famas_Holster(const iItem, const iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}


public Famas_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public Famas_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
        if (wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT_1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE-1, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	
	
	set_pev(iPlayer, pev_punchangle, float: {-1.7, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	wpnmod_set_think(iItem,"Next_Attack");
	set_pev(iItem, pev_nextthink, get_gametime() + 0.08);
	set_pev(iItem, pev_body, 0);
        }
	
        else
        {
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.10001);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT_1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
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
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	
	set_pev(iPlayer, pev_punchangle, float: {-2.4, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
        }
}

public Famas_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 2.95);
}

public Famas_SecondaryAttack(const iItem, const iPlayer)
{
	new Mod = wpnmod_get_offset_int(iItem, Offset_Mod);
	
	wpnmod_set_offset_int(iItem, Offset_Mod, !Mod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.03);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.2);
	if(wpnmod_get_offset_int(iItem, Offset_Mod)){
	client_print( iPlayer, print_center, "--> Switched to Burst-Fire Mode <--");
	}
	else{
	client_print( iPlayer, print_center, "--> Switched to Automatic Mode <--" );
	}
}

public Next_Attack(const iItem, iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.6);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT_1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE-3, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	set_pev(iPlayer, pev_punchangle, float: {-1.8, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	wpnmod_set_think(iItem, "Next_2ndAttack");
	set_pev(iItem, pev_nextthink, get_gametime() + 0.08);
	set_pev(iItem, pev_body, 0);
	}
}

public Next_2ndAttack(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	{
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.35);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);


	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT_1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		1, 
		VECTOR_CONE_1DEGREES, 
		8192.0, 
		WEAPON_DAMAGE-2, 
		DMG_BULLET | DMG_NEVERGIB, 
		4
	);
	
	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 6.0);
	}
	set_pev(iPlayer, pev_punchangle, float: {-2.4, 0.0, 0.0});
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	}
}

public AmmoFamas_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoFamas_AddAmmo(const iItem, const iPlayer)
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
