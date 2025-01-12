#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <hl_wpnmod>
#include <xs>
#include <fun>
#include <engine>

#define PLUGIN "Weapon desperado"
#define VERSION "1.0"
#define AUTHOR "X-RaY ; Dr.Hunter (Basic Code) and BG Rampo (Optimized Code for using desperado and secondary mode)"

// Weapon settings
#define WEAPON_NAME 			"weapon_desperado"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		".44 Fast Draw Colt"
#define WEAPON_PRIMARY_AMMO_MAX		240
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			6
#define WEAPON_DEFAULT_AMMO		126
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			10
#define WEAPON_DAMAGE_A			45.0
#define WEAPON_DAMAGE_B			65.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_desperado.txt"

// Models
#define MODEL_WORLD			"models/w_desperado.mdl"
#define MODEL_VIEW			"models/v_desperado.mdl"
#define MODEL_PLAYER_A			"models/p_desperado_m.mdl"
#define MODEL_PLAYER_B			"models/p_desperado_w.mdl"

// Sounds
#define SOUND_SHOOT			"weapons/desperado-1.wav"

// Animation
#define ANIM_EXTENSION			"python"

#define MODEL_SHELL			"models/shell.mdl"

enum _:desperado
{
	desperado_IDLE_A,
	desperado_START_RUN_A,
	desperado_RUN_A,
	desperado_END_RUN_A,
	desperado_DRAW_A,
	desperado_SHOOT_A,
	desperado_RELOAD_A,
	desperado_CHANGE_A,
	desperado_IDLE_B,
	desperado_START_RUN_B,
	desperado_RUN_B,
	desperado_END_RUN_B,
	desperado_DRAW_B,
	desperado_SHOOT_B,
	desperado_RELOAD_B,
	desperado_CHANGE_B
}
 

#define SetThink(%0,%1,%2) \
							\
	wpnmod_set_think(%0, %1);			\
	set_pev(%0, pev_nextthink, get_gametime() + %2)
	
	
#define Offset_Mod Offset_iuser1

enum _:eFireMode
{
	MODE_A = 0,
	MODE_B
};

new g_iCurrentMode[ 33 ];
new g_fastreload[ 33 ];

public plugin_precache()
{

		PRECACHE_MODEL(MODEL_VIEW);
		PRECACHE_MODEL(MODEL_WORLD);
		PRECACHE_MODEL(MODEL_PLAYER_A);
		PRECACHE_MODEL(MODEL_PLAYER_B);
		PRECACHE_MODEL(MODEL_SHELL);
		
		PRECACHE_SOUND(SOUND_SHOOT);

		PRECACHE_GENERIC(WEAPON_HUD_TXT);
		
		PRECACHE_GENERIC ( "sprites/dana.spr" ); 
		PRECACHE_GENERIC ( "sprites/640hud41new.spr" ); 
		PRECACHE_GENERIC ( "sprites/640hud18new.spr" ); 
		PRECACHE_GENERIC ( "sprites/357.spr" ); 

}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new idesperado = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_Spawn, "wpn_spawn");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_Deploy, "wpn_deploy");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_Idle, "wpn_idle");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_PrimaryAttack, "wpn_primaryattack");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_SecondaryAttack, "wpn_secondaryattack");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_Reload, "wpn_reload");
	wpnmod_register_weapon_forward(idesperado, Fwd_Wpn_Holster, "wpn_holster");

	RegisterHam( Ham_Killed, "player", "player_dead");
}

public client_connect(id)
{
	g_iCurrentMode[id] = MODE_A;
	g_fastreload[id] = 0;
}

public client_disconnect(id)
{
	g_iCurrentMode[id] = MODE_A;
	g_fastreload[id] = 0;
}

public player_dead(id)
{
	g_iCurrentMode[id] = MODE_A;
	g_fastreload[id] = 0;
}

public wpn_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public wpn_deploy(const iItem, const iPlayer, const iClip)
{	
	if (g_iCurrentMode[ iPlayer ] == MODE_A)
	{
		wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER_A, desperado_DRAW_A, ANIM_EXTENSION);
	}
	else
	{
		wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER_B, desperado_DRAW_B, ANIM_EXTENSION);
	}
}

public wpn_holster(const iItem, const iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public wpn_idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);

	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}

	if (g_iCurrentMode[ iPlayer ] == MODE_A)
	{
		wpnmod_send_weapon_anim(iItem, desperado_IDLE_A);
			
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, desperado_IDLE_B);
	}

	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);	
}

public wpn_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP )
	{
		return;
	}

	if (!g_fastreload[iPlayer])
	{
		if (g_iCurrentMode[ iPlayer ] == MODE_A)
		{
			wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_RELOAD_A, 1.05); 
		}
		else
		{
			wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_RELOAD_B, 1.05); 
		}
	}
	else
	{
		if (g_iCurrentMode[ iPlayer ] == MODE_A)
		{
			wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_CHANGE_A, 0.25); 
			g_iCurrentMode[ iPlayer ] = MODE_B;
			set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_B);
			g_fastreload[iPlayer] = 0;
		}
		else
		{
			wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_CHANGE_B, 0.25); 
			g_iCurrentMode[ iPlayer ] = MODE_A;
			set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_A);
			g_fastreload[iPlayer] = 0;
		}
	}	
}

public wpn_reload_ex(const iItem, const iPlayer, iClip, iAmmo)
{
	if (g_iCurrentMode[ iPlayer ] == MODE_A)
	{
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_CHANGE_A, 0.25); 
		g_iCurrentMode[ iPlayer ] = MODE_B;
		set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_B);
		g_fastreload[iPlayer] = 0;
	}
	else
	{
		wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, desperado_CHANGE_B, 0.25); 
		g_iCurrentMode[ iPlayer ] = MODE_A;
		set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_A);
		g_fastreload[iPlayer] = 0;
	}	
}

public wpn_primaryattack(const iItem, const iPlayer, iClip, iAmmo)
{
	static Float: vecPunchangle[3];
	
	if (iClip <= 0)
	{	
		g_fastreload[iPlayer] = 1;
		if (iAmmo != 0)
		{
			wpn_reload(iItem, iPlayer, iClip, iAmmo);
		}
		else
		{
			wpnmod_play_empty_sound(iItem);
		}
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}

	if (iClip == 1)
	{
		g_fastreload[iPlayer] = 1;
	}

	if (g_iCurrentMode[ iPlayer ] == MODE_A)
	{
		wpnmod_send_weapon_anim(iItem, desperado_SHOOT_A);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, desperado_SHOOT_B);
	}
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.12);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.2);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 2.5);

	static iShellModelIndex;
	if (iShellModelIndex || (iShellModelIndex = engfunc(EngFunc_ModelIndex, MODEL_SHELL)))
	{
		if (g_iCurrentMode[ iPlayer ] == MODE_A)
		{
			wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, -18.0);
		}
		else
		{
			wpnmod_eject_brass(iPlayer, iShellModelIndex, TE_BOUNCE_SHELL, 16.0, -20.0, 8.0);
		}
	}

	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_SHOOT, 1.0, ATTN_NORM, 0, PITCH_NORM);

	if (g_iCurrentMode[ iPlayer ] == MODE_A)
	{
		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			1, 
			VECTOR_CONE_2DEGREES, 
			8192.0, 
			WEAPON_DAMAGE_A, 
			DMG_BULLET, 
			3
		);
	}
	else
	{
		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			1, 
			VECTOR_CONE_4DEGREES, 
			8192.0, 
			WEAPON_DAMAGE_B, 
			DMG_BULLET, 
			5
		);
	}
	
	vecPunchangle[0] = random_float(-1.35, 1.35);
	
	set_pev(iPlayer, pev_punchangle, vecPunchangle);
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
}

public wpn_secondaryattack(const iItem, const iPlayer, iClip, iAmmo)
{
	if (iClip != WEAPON_MAX_CLIP)
	{	
		g_fastreload[iPlayer] = 1;
		if (iAmmo != 0)
		{
			wpn_reload_ex(iItem, iPlayer, iClip, iAmmo);
		}
		else
		{
			switch( g_iCurrentMode[ iPlayer ] )
			{
				case MODE_A:
				{
					g_iCurrentMode[ iPlayer ] = MODE_B;
					wpnmod_send_weapon_anim(iItem, desperado_CHANGE_A);
					set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_B);
				}
				case MODE_B:
				{
					g_iCurrentMode[ iPlayer ] = MODE_A;
					wpnmod_send_weapon_anim(iItem, desperado_CHANGE_B);
					set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_A);
				}
			}
		}
	}

	else
	{
		switch( g_iCurrentMode[ iPlayer ] )
		{
			case MODE_A:
			{
				g_iCurrentMode[ iPlayer ] = MODE_B;
				wpnmod_send_weapon_anim(iItem, desperado_CHANGE_A);
				set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_B);
			}
			case MODE_B:
			{
				g_iCurrentMode[ iPlayer ] = MODE_A;
				wpnmod_send_weapon_anim(iItem, desperado_CHANGE_B);
				set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_A);
			}
		}
	}
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.55);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.55);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.55);
}
