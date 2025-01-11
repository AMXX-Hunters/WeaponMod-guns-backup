/*
	Weapon RG6 Buldog Grenade Launcher by NiHiLaNTh.
	Two fire modes swithable by right mouse button - instant explosion and bouncing!
	
	Credits: KORD_12.7, Shapirlic, Arkshine, GordonFreeman(RU)
	
	Only for HL and only under WeaponMod module!!!
	
	Have Fun!
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

//=========================== Some stuff from hl_wpnmod.inc ========================================

#define SET_MODEL(%0,%1) 			engfunc(EngFunc_SetModel, %0, %1)
#define PRECACHE_MODEL(%0) 			engfunc(EngFunc_PrecacheModel,%0)
#define PRECACHE_SOUND(%0) 			engfunc(EngFunc_PrecacheSound,%0)
#define PRECACHE_GENERIC(%0) 		engfunc(EngFunc_PrecacheGeneric,%0)

#define LOUD_GUN_VOLUME				1000
#define NORMAL_GUN_VOLUME				600
#define QUIET_GUN_VOLUME				200

#define BRIGHT_GUN_FLASH				512
#define NORMAL_GUN_FLASH				256
#define DIM_GUN_FLASH					128

#define CLASS_NONE					0

enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1,
};

enum e_AmmoFwds
{
	Fwd_Ammo_Spawn,
	Fwd_Ammo_AddAmmo,

	Fwd_Ammo_End
};

enum e_WpnFwds
{
	Fwd_Wpn_Spawn,
	Fwd_Wpn_CanDeploy,
	Fwd_Wpn_Deploy,
	Fwd_Wpn_Idle,
	Fwd_Wpn_PrimaryAttack,
	Fwd_Wpn_SecondaryAttack,
	Fwd_Wpn_Reload,
	Fwd_Wpn_CanHolster,
	Fwd_Wpn_Holster,
	Fwd_Wpn_IsUseable,

	Fwd_Wpn_End
};

enum e_Offsets
{
	// Weapon
	Offset_flStartThrow,
	Offset_flReleaseThrow,
	Offset_iChargeReady,
	Offset_iInAttack,
	Offset_iFireState,
	Offset_iFireOnEmpty,				// True when the gun is empty and the player is still holding down the attack key(s)
	Offset_flPumpTime,
	Offset_iInSpecialReload,			// Are we in the middle of a reload for the shotguns
	Offset_flNextPrimaryAttack,			// Soonest time ItemPostFrame will call PrimaryAttack
	Offset_flNextSecondaryAttack,		// Soonest time ItemPostFrame will call SecondaryAttack
	Offset_flTimeWeaponIdle,			// Soonest time ItemPostFrame will call WeaponIdle
	Offset_iPrimaryAmmoType,			// "Primary" ammo index into players m_rgAmmo[]
	Offset_iSecondaryAmmoType,			// "Secondary" ammo index into players m_rgAmmo[]
	Offset_iClip,						// Number of shots left in the primary weapon clip, -1 it not used
	Offset_iInReload,					// Are we in the middle of a reload;
	Offset_iDefaultAmmo,				// How much ammo you get when you pick up this weapon as placed by a level designer.
	
	// Player
	Offset_flNextAttack,				// Cannot attack again until this time
	Offset_iWeaponVolume,				// How loud the player's weapon is right now
	Offset_iWeaponFlash,				// Brightness of the weapon flash
	
	Offset_End
};

native wpnmod_register_weapon(const szName[], const iSlot, const iPosition, const szAmmo1[], const iMaxAmmo1, const szAmmo2[], const iMaxAmmo2, const iMaxClip, const iFlags, const iWeight);
native wpnmod_register_weapon_forward(const iWeaponID, const e_WpnFwds: iForward, const szCallBack[]);
native wpnmod_register_ammobox(const szClassname[]);				
native wpnmod_register_ammobox_forward(const iWeaponID, const e_AmmoFwds: iForward, const szCallBack[]);	
native wpnmod_set_offset_int(const iEntity, const e_Offsets: iOffset, const iValue);
native wpnmod_set_offset_float(const iEntity, const e_Offsets: iOffset, const Float: flValue);
native wpnmod_get_offset_int(const iEntity, const e_Offsets: iOffset);
native Float: wpnmod_get_offset_float(const iEntity, const e_Offsets: iOffset);
native wpnmod_default_deploy(const iItem, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[]);
native wpnmod_default_reload(const iItem, const iClipSize, const iAnim, const Float: flDelay);
native wpnmod_reset_empty_sound(const iItem);
native wpnmod_play_empty_sound(const iItem);
native wpnmod_send_weapon_anim(const iItem, const iAnim);
native wpnmod_set_player_anim(const iPlayer, const PLAYER_ANIM: iPlayerAnim);	
native wpnmod_radius_damage(const Float: vecSrc[3], const iInflictor, const iAttacker, const Float: flDamage, const Float: flRadius, const iClassIgnore, const bitsDamageType);
				
//==================================================================================================

// Plugin settings
#define PLUGIN 			"RG6 Buldog"
#define VERSION 			"1.1"
#define AUTHOR 			"NiHiLaNTh"

// Weapon settings
#define WEAPON_NAME 			"weapon_rg6"
#define WEAPON_SLOT			3
#define WEAPON_POSITION		5
#define WEAPON_PRIMARY_AMMO		"gp25_nade"
#define WEAPON_PRIMARY_AMMO_MAX	20
#define WEAPON_SECONDARY_AMMO	"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP		4
#define WEAPON_DEFAULT_AMMO		4
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			90.0

// Hud
#define WEAPON_HUD_TXT		"sprites/weapon_rg6.txt"
#define WEAPON_HUD_SPR		"sprites/weapon_rg6.spr"
#define WEAPON_HUD_WPN		"sprites/rg6_flame.spr"
#define WEAPON_CROSSHAIR		"sprites/rgcross.spr"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_gp25"

// Grenade
#define GRENADE_CLASSNAME		"gp25_grenade"

// Models
#define MODEL_WORLD			"models/w_rg6.mdl"
#define MODEL_VIEW			"models/v_rg6.mdl"
#define MODEL_PLAYER			"models/p_rg6.mdl"
#define MODEL_CLIP			"models/w_rg6_grenade.mdl"

// Sounds
#define SOUND_FIRE			"weapons/rg6/fire1.wav"
#define SOUND_RELOAD_0		"weapons/rg6/start.wav"
#define SOUND_RELOAD_1		"weapons/rg6/reload.wav"
#define SOUND_RELOAD_2		"weapons/rg6/next.wav"
#define SOUND_RELOAD_3		"weapons/rg6/end.wav"
#define SOUND_BOUNCE			"weapons/grenade_hit1.wav"

// Sprites
#define SPRITE_TRAIL			"sprites/laserbeam.spr"
#define SPRITE_EXPLODE		"sprites/zerogxplode.spr"

// Grenade velocity
#define GRENADE_VELOCITY		1500
#define GRENADE_RADIUS		300.0

// Animation
#define ANIM_EXTENSION		"gauss"

// Animation Sequence
enum _:eRG6
{
	RG6_IDLE = 0,
	RG6_HOLSTER,
	RG6_DRAW,
	RG6_SHOOT,
	RG6_RELOAD1,
	RG6_RELOAD2,
	RG6_RELOAD3
};

enum ( <<=1 )
{
	v_angle = 1,
	punchangle
};

enum _:eFireMode
{
	MODE_BOUNCE = 0,
	MODE_INSTANT
};

new g_iCurrentMode[ 33 ];
new g_sModelIndexTrail;
new g_sModelIndexExplode;

// Null size
new const Float:gVecZero[ 3 ]		= { 0.0, 0.0, 0.0 };
//==================================================================================================

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_CLIP);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_RELOAD_0);
	PRECACHE_SOUND(SOUND_RELOAD_1);
	PRECACHE_SOUND(SOUND_RELOAD_2);
	PRECACHE_SOUND(SOUND_RELOAD_3);
	PRECACHE_SOUND(SOUND_BOUNCE);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_WPN);
	PRECACHE_GENERIC(WEAPON_CROSSHAIR);
	
	g_sModelIndexTrail = PRECACHE_MODEL(SPRITE_TRAIL);
	g_sModelIndexExplode = PRECACHE_MODEL(SPRITE_EXPLODE);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iRG6 = wpnmod_register_weapon
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
	
	new iAmmoRG6 = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_Spawn, 		"CRG6__Spawn" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_Deploy, 		"CRG6__Deploy" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_Idle, 		"CRG6__WeaponIdle" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_PrimaryAttack,	"CRG6__PrimaryAttack" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_SecondaryAttack, 	"CRG6__SecondaryAttack" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_Reload, 		"CRG6__Reload" );
	wpnmod_register_weapon_forward(iRG6, Fwd_Wpn_Holster, 		"CRG6__Holster" );
	
	wpnmod_register_ammobox_forward(iAmmoRG6, Fwd_Ammo_Spawn, 	"CRG6Ammo__Spawn" );
	wpnmod_register_ammobox_forward(iAmmoRG6, Fwd_Ammo_AddAmmo,	"CRG6Ammo__AddAmmo" );

	register_think( GRENADE_CLASSNAME, "CGP25Grenade__Think" );
	register_touch( GRENADE_CLASSNAME, "*", "CGP25Grenade__Touch" );
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public CRG6__Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public CRG6__Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, RG6_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public CRG6__Holster(const iItem, const iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public CRG6__PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}
	
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	
	set_pev( iPlayer, pev_effects, pev( iPlayer, pev_effects ) | EF_MUZZLEFLASH );
	wpnmod_set_player_anim( iPlayer, PLAYER_ATTACK1 );

	CGrenade__Launch( iPlayer );
	
	wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
	wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
	
	if( iClip != 0 )
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
	else
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.75 );
		
	wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
	
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM );
	wpnmod_send_weapon_anim( iItem, RG6_SHOOT );
	set_pev( iPlayer, pev_punchangle, Float:{ -7.0, 0.0, 0.0 } );
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public CRG6__SecondaryAttack(const iItem, const iPlayer)
{
	switch( g_iCurrentMode[ iPlayer ] )
	{
		case MODE_INSTANT:
		{
			g_iCurrentMode[ iPlayer ] = MODE_BOUNCE;
			client_print( iPlayer, print_center, "--> Switched to Grenade Bounce Mode <--" );
		}
		case MODE_BOUNCE:
		{
			g_iCurrentMode[ iPlayer ] = MODE_INSTANT;
			client_print( iPlayer, print_center, "--> Switched to Instant Explosion Mode <--" );
		}
	}
	
	emit_sound( iPlayer, CHAN_ITEM,  "weapons/scock1.wav", 0.7, ATTN_NORM, 0, 92 );
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.2);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public CRG6__WeaponIdle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound( iItem );
	
	if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
	{
		return;
	}
	
	static fInSpecialReload;
	fInSpecialReload = wpnmod_get_offset_int( iItem, Offset_iInSpecialReload );
	
	if( !iClip && !fInSpecialReload && iAmmo )
	{
		CRG6__Reload( iItem, iPlayer, iClip, iAmmo );
	}
	else if( fInSpecialReload != 0 )
	{
		if( iClip != WEAPON_MAX_CLIP && iAmmo )
		{
			CRG6__Reload( iItem, iPlayer, iClip, iAmmo );
		}
		else
		{
			// reload debounce has timed out
			wpnmod_send_weapon_anim( iItem, RG6_RELOAD3 );
			
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
		}
	}
	else
	{
		wpnmod_send_weapon_anim( iItem, RG6_IDLE );
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
	}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public CRG6__Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if( iAmmo <= 0 || iClip == WEAPON_MAX_CLIP )
		return;
	
	// don't reload until recoil is done
	if( wpnmod_get_offset_float( iItem, Offset_flNextPrimaryAttack ) > 0.0 )
		return;
	
	//static Float:tTime;
	//tTime = get_gametime( );
	
	const m_rgAmmo = 310;
	
	static iAmmoIndex, iAmmo2;
		
	// check to see if we're ready to reload
	switch( wpnmod_get_offset_int( iItem, Offset_iInSpecialReload ) )
	{
		case 0:
		{
			wpnmod_send_weapon_anim( iItem, RG6_RELOAD1 );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
			wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
			return;
		}
		case 1:
		{
			if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
				return;
				
			// was waiting for gun to move to side
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 2 );
			
			emit_sound( iPlayer, CHAN_ITEM, SOUND_RELOAD_1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_send_weapon_anim( iItem, RG6_RELOAD2 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.25 );
		}
		default:
		{
			wpnmod_set_offset_int( iItem, Offset_iClip, iClip + 1 );
			
			//Remove bpammo
			iAmmoIndex = wpnmod_get_offset_int( iItem, Offset_iPrimaryAmmoType );
			iAmmo2 = get_pdata_int( iPlayer, m_rgAmmo + iAmmoIndex - 1 );
			set_pdata_int( iPlayer, m_rgAmmo + iAmmoIndex - 1, iAmmo2 - 1 );
			
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
		}
	}
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public CRG6Ammo__Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public CRG6Ammo__AddAmmo(const iItem, const iPlayer)
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

//**********************************************
//* Launch a contact grenade.           	 *
//**********************************************

CGrenade__Launch( iPlayer )
{
	new pGrenade = create_entity( "info_target" );
	
	if( pGrenade <= 0 )
		return;
		
	// classname
	set_pev( pGrenade, pev_classname,	GRENADE_CLASSNAME );
	
	// model
	engfunc( EngFunc_SetModel, pGrenade,	MODEL_CLIP );
	
	// origin
	static Float:vecSrc[ 3 ];
	UTIL_MakeVectors( iPlayer, v_angle + punchangle );
	GetGunPosition( iPlayer, vecSrc );
	engfunc( EngFunc_SetOrigin, pGrenade,	vecSrc );
	
	// fly in the air
	set_pev( pGrenade, pev_gravity,		0.5 );
	
	// movetype
	set_pev( pGrenade, pev_movetype,	g_iCurrentMode[ iPlayer ] == MODE_BOUNCE ? MOVETYPE_BOUNCE : MOVETYPE_TOSS );
	
	// interaction
	set_pev( pGrenade, pev_solid,		SOLID_BBOX );
	
	// size
	engfunc( EngFunc_SetSize, pGrenade,	gVecZero, gVecZero );
	
	// owner
	set_pev( pGrenade, pev_owner,		iPlayer );
	
	// store grenade mode
	set_pev( pGrenade, pev_iuser1,		g_iCurrentMode[ iPlayer ] );
	
	// damage
	set_pev( pGrenade, pev_dmg,		WEAPON_DAMAGE );
	
	// next think
	set_pev( pGrenade, pev_nextthink,	get_gametime( ) + 0.6 );
	
	// Velocity
	static Float:vecVelocity[ 3 ];
	velocity_by_aim( iPlayer, GRENADE_VELOCITY, vecVelocity );
	set_pev( pGrenade, pev_velocity,	vecVelocity );
	
	// angles
	static Float:vecAngles[ 3 ];
	engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );
	set_pev( pGrenade, pev_angles, 		vecAngles );
	
	// trail
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( pGrenade );
	write_short( g_sModelIndexTrail );
	write_byte( 25 );
	write_byte( 5 );
	write_byte( 250 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 250 );
	message_end( );
}

//**********************************************
//* Grenade is ticking away.          	 *
//**********************************************

public CGP25Grenade__Think( pGrenade )
{
	if( !pev_valid( pGrenade ) )
		return;
		
	switch( pev( pGrenade, pev_iuser1 ) )
	{
		case MODE_BOUNCE:
		{
			static Float:vecVelocity[ 3 ];
			pev( pGrenade, pev_velocity, vecVelocity );
			
			if( xs_vec_len( vecVelocity ) <= 10.0 )
			{
				CGP25__Explode( pGrenade );
			}
		}
	}
}

//**********************************************
//* Grenade hit something.          		 *
//**********************************************

public CGP25Grenade__Touch( pGrenade, pOther )
{
	if( !pev_valid( pGrenade ) )
		return;
		
	switch( pev( pGrenade, pev_iuser1 ) )
	{
		case MODE_BOUNCE:
		{
			static Float:vecVelocity[ 3 ];
			pev( pGrenade, pev_velocity, vecVelocity );
			
			xs_vec_mul_scalar( vecVelocity, 0.4, vecVelocity );
			set_pev( pGrenade, pev_velocity, vecVelocity );
			
			if( pev( pGrenade, pev_fuser1 ) <= 0.0 )
			{
				emit_sound( pGrenade, CHAN_ITEM, SOUND_BOUNCE, VOL_NORM, ATTN_NORM, 0, 97 );
				set_pev( pGrenade, pev_fuser1, random_float( 0.5, 0.9 ) );
			}
			
			set_pev( pGrenade, pev_nextthink, get_gametime( ) + 0.16 );
		}
		case MODE_INSTANT:
		{
			CGP25__Explode( pGrenade );
		}
	}
}

//**********************************************
//* Grenade explode.          		 *
//**********************************************

CGP25__Explode( pGrenade )
{
	if( !pev_valid( pGrenade ) )
		return;
		
	static Float:vecSrc[ 3 ], Float:flDmg;
	pev( pGrenade, pev_origin, vecSrc );
	pev( pGrenade, pev_dmg, flDmg );
	
	// sprite
	engfunc( EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecSrc, 0 );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
	write_short( g_sModelIndexExplode );
	write_byte( floatround( ( flDmg - 50.0 ) * 0.6 ) );
	write_byte( 15 );
	write_byte( TE_EXPLFLAG_NONE );
	message_end( );
	
	static pevOwner;
	pevOwner = pev( pGrenade, pev_owner );
	
	// damage
	wpnmod_radius_damage( vecSrc, pGrenade, pevOwner, flDmg, GRENADE_RADIUS, CLASS_NONE, DMG_BLAST | DMG_ALWAYSGIB );
		
	engfunc( EngFunc_RemoveEntity, pGrenade );	
}

//**********************************************
//* Get Gun Position.          		 *
//**********************************************

GetGunPosition( pPlayer, Float:vecRet[ 3 ] )
{
	static Float:vecSrc[ 3 ], Float:vForward[ 3 ], Float:vRight[ 3 ], Float:vUp[ 3 ];
	pev( pPlayer, pev_origin, vecSrc );
	global_get( glb_v_forward, vForward );
	global_get( glb_v_right, vRight );
	global_get( glb_v_up, vUp );
	
	vecRet[ 0 ] = vecSrc[ 0 ] + vForward[ 0 ] * 25.0 + vRight[ 0 ] * 20.0 + vUp[ 0 ] * 10.0;
	vecRet[ 1 ] = vecSrc[ 1 ] + vForward[ 1 ] * 25.0 + vRight[ 1 ] * 20.0 + vUp[ 1 ] * 10.0;
	vecRet[ 2 ] = vecSrc[ 2 ] + vForward[ 2 ] * 25.0 + vRight[ 2 ] * 20.0 + vUp[ 2 ] * 10.0;
}

//**********************************************
//* Credit to Arkshine.          		 *
//**********************************************

UTIL_MakeVectors( Player, bsType )
{
	static Float:vPunchAngle[ 3 ], Float:vAngle[ 3 ];

	if( bsType & v_angle )    
		pev( Player, pev_v_angle, vAngle );
	if( bsType & punchangle ) 
		pev( Player, pev_punchangle, vPunchAngle );

	xs_vec_add( vAngle, vPunchAngle, vAngle );
	engfunc( EngFunc_MakeVectors, vAngle );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
