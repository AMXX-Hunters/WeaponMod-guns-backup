#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>

#define PLUGIN "SPAS-12ex [Beta]"
#define VERSION "1.0"
#define AUTHOR "DOK_BATCOH"

// Weapon settings
#define WEAPON_NAME 			"weapon_spas12ex"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			3
#define WEAPON_PRIMARY_AMMO		"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX		64
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			8
#define WEAPON_DEFAULT_AMMO		32
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			40.0
#define WEAPON_DAMAGE_EX		30.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_spas12ex.txt"
#define WEAPON_HUD_SPR			"sprites/640hud66.spr"

// Models
#define MODEL_WORLD			"models/weapon/w_spas12ex.mdl"
#define MODEL_VIEW			"models/weapon/v_spas12ex.mdl"
#define MODEL_PLAYER			"models/weapon/p_spas12ex.mdl"

// Sounds
#define SOUND_FIRE			"weapons/spas12.wav"
#define SOUND_DRAW			"weapons/spas12_draw.wav"
#define SOUND_RELOAD			"weapons/spas12_reload.wav"
#define SOUND_INSERT			"weapons/spas12_insert.wav"

#define MODEL_SHELL			"models/shotgunshell.mdl"

// Animation
#define ANIM_EXTENSION			"shotgun"

#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
#define Offset_Mod Offset_iuser1

enum _:spas12ex
{
	SPAS12_IDLE,
	SPAS12_INSERT,
	SPAS12_DRAW,
	SPAS12_INSERT_2,
	SPAS12_END_RELOAD,
	SPAS12_START_RELOAD,
        SPAS12_SHOOT_1,
        SPAS12_SHOOT_2,
        SPAS12_MOD_EX_START,
        SPAS12_IDLE_EX,
	SPAS12_INSERT_EX,
	SPAS12_DRAW_EX,
	SPAS12_INSERT_2_EX,
	SPAS12_END_RELOAD_EX,
	SPAS12_START_RELOAD_EX,
        SPAS12_SHOOT_1_EX,
        SPAS12_SHOOT_2_EX,
        SPAS12_MOD_EX_END
}

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
        PRECACHE_MODEL(MODEL_SHELL);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DRAW);
	PRECACHE_SOUND(SOUND_RELOAD);
        PRECACHE_SOUND(SOUND_INSERT);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new ispas12ex = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_Spawn, "spas12ex_spawn");
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_Deploy, "spas12ex_deploy");
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_Idle, "spas12ex_idle");
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_PrimaryAttack, "spas12ex_primaryattack");
        wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_SecondaryAttack, "spas12ex_SecondaryAttack");
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_Reload, "spas12ex_reload");
	wpnmod_register_weapon_forward(ispas12ex, Fwd_Wpn_Holster, "spas12ex_holster");
}

public spas12ex_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public spas12ex_deploy(const iItem, const iPlayer, const iClip)
{ 
        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, SPAS12_DRAW, ANIM_EXTENSION);
        }
        else
        {
        wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, SPAS12_DRAW_EX, ANIM_EXTENSION);
        }
        return
}

public spas12ex_holster(const iItem)
{
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}

public spas12ex_idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound(iItem);
	
	
	wpnmod_reset_empty_sound( iItem );
	
	if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
	{
		return;
	}
	
	new fInSpecialReload = wpnmod_get_offset_int( iItem, Offset_iInSpecialReload );
	
	if( !iClip && !fInSpecialReload && iAmmo )
	{
		spas12ex_reload( iItem, iPlayer, iClip, iAmmo );
	}
	else if( fInSpecialReload != 0 )
	{
		if( iClip != WEAPON_MAX_CLIP && iAmmo )
		{
			spas12ex_reload( iItem, iPlayer, iClip, iAmmo );
		}
		else
		{
                        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	                {
			wpnmod_send_weapon_anim( iItem, SPAS12_END_RELOAD );
                        }
                        else
                        {
                        wpnmod_send_weapon_anim( iItem, SPAS12_END_RELOAD_EX );
                        }
			
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
		}
	}
}

public spas12ex_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
        if (wpnmod_get_offset_float(iItem, Offset_flNextPrimaryAttack) > 0.0)
	{
		return;
	}

        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	switch (wpnmod_get_offset_int(iItem, Offset_iInSpecialReload))
	{
		case 0:
		{
			wpnmod_send_weapon_anim( iItem, SPAS12_START_RELOAD );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
			wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
		}
		case 1:
		{
			if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
				return;
				
			// was waiting for gun to move to side
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 2 );
			
			wpnmod_send_weapon_anim( iItem, SPAS12_INSERT );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
		}
		default:
		{
			wpnmod_set_offset_int( iItem, Offset_iClip, iClip + 1 );
			wpnmod_set_player_ammo( iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - 1 );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
		}
	}
        }
        else
        {
        switch (wpnmod_get_offset_int(iItem, Offset_iInSpecialReload))
	{
		case 0:
		{
			wpnmod_send_weapon_anim( iItem, SPAS12_START_RELOAD_EX );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
			wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
		}
		case 1:
		{
			if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
				return;
				
			// was waiting for gun to move to side
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 2 );
			
			wpnmod_send_weapon_anim( iItem, SPAS12_INSERT_EX );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
		}
		default:
		{
			wpnmod_set_offset_int( iItem, Offset_iClip, iClip + 1 );
			wpnmod_set_player_ammo( iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - 1 );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
		}
	}
        }
}

public spas12ex_primaryattack(const iItem, const iPlayer, iClip)
{
	static Float: flZVel;
	static Float: vecAngle[3];
	static Float: vecForward[3];
	static Float: vecVelocity[3];
	static Float: vecPunchangle[3];
	
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.7);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);

        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_fire_bullets(iPlayer,iPlayer,8,VECTOR_CONE_8DEGREES,3048.0,WEAPON_DAMAGE,DMG_BULLET,8)
        wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
        }
        else
        {
        wpnmod_fire_bullets(iPlayer,iPlayer,8,VECTOR_CONE_15DEGREES,3048.0,WEAPON_DAMAGE_EX,DMG_BULLET,8)
        wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.5);
        }
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 7.0);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);

        if (!wpnmod_get_offset_int(iItem, Offset_Mod))
	{
	wpnmod_send_weapon_anim(iItem, random_num(SPAS12_SHOOT_1, SPAS12_SHOOT_2));
        }
        else
        {
        wpnmod_send_weapon_anim(iItem, random_num( SPAS12_SHOOT_1_EX,  SPAS12_SHOOT_2_EX));
        }

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
        static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHOTSHELL, 16.0, -20.0, 6.0);
	}

	global_get(glb_v_forward, vecForward);
	
	pev(iPlayer, pev_v_angle, vecAngle);
	pev(iPlayer, pev_velocity, vecVelocity);
	pev(iPlayer, pev_punchangle, vecPunchangle);
	
	xs_vec_add(vecAngle, vecPunchangle, vecPunchangle);
	engfunc(EngFunc_MakeVectors, vecPunchangle);
	
	flZVel = vecVelocity[2];
	
	xs_vec_mul_scalar(vecForward, 35.0, vecPunchangle);
	xs_vec_sub(vecVelocity, vecPunchangle, vecVelocity);
	
	vecPunchangle[2] = 0.0;
	vecVelocity[2] = flZVel;
	
	vecPunchangle[0] = random_float(-2.0, 2.0);
	vecPunchangle[1] = random_float(-2.0, 2.0);
	 
	set_pev(iPlayer, pev_velocity, vecVelocity);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
}

public spas12ex_SecondaryAttack(const iItem, const iPlayer)
{
	new iMod = wpnmod_get_offset_int(iItem, Offset_Mod);
	
	if (!iMod)
	{
		SetThink(iItem, "spas12ex_SightThink", 0.3);
	}
	else
	{
	        MakeMod(iItem, iPlayer, WEAPON_NAME, 0.0);
        }	

	wpnmod_set_offset_int(iItem, Offset_Mod, !iMod);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.9);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 2.9);
	wpnmod_send_weapon_anim(iItem, iMod ? SPAS12_MOD_EX_END : SPAS12_MOD_EX_START );
}

public spas12ex_SightThink(const iItem, const iPlayer)
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