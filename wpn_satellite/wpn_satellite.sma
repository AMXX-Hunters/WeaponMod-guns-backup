#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < hl_wpnmod >
#include < xs >

// Weapon parameters
#define WEAPON_NAME 			"weapon_satellite"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			2
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_FLAGS			ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY
#define WEAPON_WEIGHT			15

// Models
#define MODEL_P				"models/p_satellite.mdl"
#define MODEL_V				"models/v_satellite.mdl"

// Sounds
#define SOUND_IDLE			"weapons/satellite_idle.wav"
#define SOUND_DENY			"buttons/button2.wav"
#define SOUND_DENY2			"buttons/button10.wav"
#define SOUND_ATTACK			"weapons/satellite_activate.wav"

// V_ model sequence indexes
#define SEQ_IDLE			0
#define SEQ_FIDGET			1
#define SEQ_DEPLOY			3
#define SEQ_FIRE			4

// Ammo	
#define AMMO_DEFAULT			200
#define AMMO_MAX			200
#define AMMO_NAME			"power"
#define AMMO_RTIME			18.0	// time in seconds when ammo should START recharging after we did a shot

// Air Strike
#define STRIKE_TIME			15.0	// Delay to explosion
#define STRIKE_DAMAGE			"200"	// One strike damage(total damage STRIKE_DAMAGE * STRIKE_COUNT)
#define STRIKE_SPREAD			"64"	// Accuracy
#define STRIKE_COUNT			"10"	// How many strikes totally

// For correct Weapon HUD
new const SPRITE_HUD[ ][ ]		=
{
	"sprites/weapon_satellite.txt",
	"sprites/hud_weapons11.spr",
	"sprites/hud_interface.spr"
}
//=====================================================================
new g_pTriggerMultiple;
new g_iMaxClients;

// Some default vector
new const Float:gVecSky[ ]		= { 0.0, 0.0, 16000.0 };
new const Float:gVecZero[ ]		= { 0.0, 0.0, 0.0 };

enum ( <<=1 )
{
	v_angle = 1,
	punchangle
};

#define STOP_SOUND(%0,%1,%2)		emit_sound( %0, %1, %2, VOL_NORM, 0.0, SND_STOP, 0 )
#define CLASS_STRIKE			"func_SatelliteStrike"
//
// Precache all the resources
//
public plugin_precache( )
{
	PRECACHE_MODEL( MODEL_P );
	PRECACHE_MODEL( MODEL_V );
	
	PRECACHE_SOUND( SOUND_IDLE );
	PRECACHE_SOUND( SOUND_DENY );
	PRECACHE_SOUND( SOUND_DENY2 )
	PRECACHE_SOUND( SOUND_ATTACK );
	PRECACHE_SOUND( "weapons/mortar.wav" );
	PRECACHE_SOUND( "weapons/mortarhit.wav" );
	
	PRECACHE_MODEL( "sprites/lgtning.spr" );
	
	for( new pSprite = 0; pSprite < sizeof( SPRITE_HUD ); pSprite++ )
		PRECACHE_GENERIC( SPRITE_HUD[ pSprite ] );
		
	// This activates air strike
	g_pTriggerMultiple = create_entity( "trigger_multiple" );
	
	if( g_pTriggerMultiple )
	{
		DispatchKeyValue( g_pTriggerMultiple, "target", "satellite_mortar" );
		DispatchKeyValue( g_pTriggerMultiple, "delay", "0.5" );
		DispatchKeyValue( g_pTriggerMultiple, "wait", "0.5" );
		DispatchSpawn( g_pTriggerMultiple );
	}
}
//
// Create the weapon & ammo box
//
public plugin_init( )
{
	register_plugin( "[HL] Satellite Strike", "1.0", "NiHiLaNTh" );
	
	// New weapon
	new pWeapon = wpnmod_register_weapon
	(
		WEAPON_NAME,
		WEAPON_SLOT,
		WEAPON_POSITION,
		AMMO_NAME,
		AMMO_MAX,
		WEAPON_SECONDARY_AMMO,
		WEAPON_SECONDARY_AMMO_MAX,
		WEAPON_MAX_CLIP,
		WEAPON_FLAGS,
		WEAPON_WEIGHT
	);
	
	// TODO. Block weapon giving if player already have the Satellite
	// Strike(no matter with ammo or no!)
	//wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_AddToPlayer, "CSatellite__AddToPlayer" );;
	
	// Events
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Spawn,		"CSatellite__Spawn" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Deploy,	"CSatellite__Deploy" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_IsUseable,	"CSatellite__IsUseable" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Holster,	"CSatellite__Holster" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_PrimaryAttack,	"CSatellite__PrimaryAttack" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Reload,	"CSatellite__Reload" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Idle,		"CSatellite__WeaponIdle" );
		
	// Satellite Strike entity
	register_think( CLASS_STRIKE, 		"CSStrike__Think" );
	
	// This is used to set a proper killer on mortar kill
	RegisterHam( Ham_Killed, "player", "fw_PlayerKilled", .Post = 0 );
	
	// Store maxplayers
	g_iMaxClients = get_maxplayers( );
}
//
// Spawn the weapon ent
//
public CSatellite__Spawn( pItem )
{
	// Apply new w_ model
	SET_MODEL( pItem, MODEL_P );
	
	// Force it to be on the ground
	entity_set_int( pItem, EV_INT_sequence, 1 );
	
	// Give some default ammo
	wpnmod_set_offset_int( pItem, Offset_iDefaultAmmo, AMMO_DEFAULT );
}
//
// Deploy the weapon
//
public CSatellite__Deploy( pItem )
{
	// Set models, player deploy anim and set correct anim extension for the
	// player model.
	return wpnmod_default_deploy( pItem, MODEL_V, MODEL_P, SEQ_DEPLOY, "hive" );
}
//
// Mark this weapon as useable all the time
//
public CSatellite__IsUseable( pItem )
{
	return true;
}
//
// Hide the weapon
//
public CSatellite__Holster( pItem )
{
	// Stop the idle sound
	STOP_SOUND( pItem, CHAN_ITEM, SOUND_IDLE );
}
//
// Fire the satellite 
//
public CSatellite__PrimaryAttack( pItem, pPlayer, iClip )
{
	// Don't launch it underwater
	if( entity_get_int( pPlayer, EV_INT_waterlevel ) == 3 )
		return;
		
	// Damn, we need just one more ammo to launch!
	if( wpnmod_get_player_ammo( pPlayer, AMMO_NAME ) <= AMMO_MAX - 1 )
	{
		client_print( pPlayer, print_center, "Not enough power to call Air Mortar!" );
		emit_sound( pItem, CHAN_ITEM, SOUND_DENY, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 1.5 );
		return;
	}
	
	UTIL_MakeVectors( pPlayer, v_angle + punchangle );
	
	static tr, Float:vecSrc[ 3 ], Float:vecRet[ 3 ];
	
	entity_get_vector( pPlayer, EV_VEC_origin, vecSrc );
	engfunc( EngFunc_TraceLine, vecSrc, gVecSky, IGNORE_MONSTERS, pPlayer, tr );
	get_tr2( tr, TR_vecEndPos, vecRet );
	
	// WHAT THE HELL ARE YOU DOING?
	if( point_contents( vecRet ) != CONTENTS_SKY )
	{
		client_print( pPlayer, print_center, "Satellite could not reach the target" );
		emit_sound( pItem, CHAN_ITEM, SOUND_DENY2, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 1.5 );
		return;
	}
	
	// Reset all the ammo
	wpnmod_set_player_ammo( pPlayer, AMMO_NAME, 0 );
	
	// Warn the owner
	client_print( pPlayer, print_center, "Target locked! %d Seconds to leave area!", floatround( STRIKE_TIME ) );
	
	// Animations
	wpnmod_send_weapon_anim( pItem, SEQ_FIRE );
	wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
	
	// Calculate start/dest origin
	static Float:vecStart[ 3 ], Float:vecViewOfs[ 3 ], Float:vecThrow[ 3 ], Float:vecUp[ 3 ];
	entity_get_vector( pPlayer, EV_VEC_view_ofs, vecViewOfs )
	global_get( glb_v_forward, vecThrow );
	global_get( glb_v_up, vecUp );
	vecStart[ 0 ] = vecSrc[ 0 ] + vecViewOfs[ 0 ] + vecThrow[ 0 ] * 16.0 + vecUp[ 0 ] * -15.0;
	vecStart[ 1 ] = vecSrc[ 1 ] + vecViewOfs[ 1 ] + vecThrow[ 1 ] * 16.0 + vecUp[ 1 ] * -15.0;
	vecStart[ 2 ] = vecSrc[ 2 ] + vecViewOfs[ 2 ] + vecThrow[ 2 ] * 16.0 + vecUp[ 2 ] * -15.0;
	
	// Do the attack
	if( CSStrike__ShootStrike( pPlayer, vecStart, STRIKE_TIME ) )
	{
		emit_sound( pItem, CHAN_AUTO, SOUND_ATTACK, 1.0, ATTN_NORM, 0, PITCH_NORM );
	
		// Set the next attack time
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 5.0 );
		wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, 1.0 );
		wpnmod_set_offset_float( pItem, Offset_fuser1, get_gametime( ) + AMMO_RTIME ); // dont recharge ammo for a while
	}
}
//
// Restore the ammo
//
public CSatellite__Reload( pItem, pPlayer, iClip, iAmmo )
{
	// Enough ammo
	if( iAmmo >= AMMO_MAX )
		return;
		
	static Float:tTime;
	tTime = get_gametime( );
		
	// Recharge the ammo ASAP
	while( iAmmo < AMMO_MAX && wpnmod_get_offset_float( pItem, Offset_fuser1 ) < tTime )
	{
		wpnmod_set_player_ammo( pPlayer, AMMO_NAME, iAmmo + 1 );
		wpnmod_set_offset_float( pItem, Offset_fuser1, tTime + 1.0 );
	}
}
//
// Idle
//
public CSatellite__WeaponIdle( pItem, pPlayer, iClip, iAmmo )
{
	// Force reload each frame
	CSatellite__Reload( pItem, pPlayer, iClip, iAmmo );
	
	static Float:tTime;
	tTime = get_gametime( );
	
	// Are we ready for the idle sound?
	if( tTime >= wpnmod_get_offset_float( pItem, Offset_fuser2 ) )
	{
		emit_sound( pItem, CHAN_ITEM, SOUND_IDLE, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_set_offset_float( pItem, Offset_fuser2, tTime + 2.45 );
	}
	
	if( wpnmod_get_offset_float( pItem, Offset_flTimeWeaponIdle ) > 0.0 )
	{
		return;
	}
	
	// Do some randomization
	switch( random_num( 0, 1 ) )
	{
		case 0:	wpnmod_send_weapon_anim( pItem, SEQ_IDLE );
		case 1:	wpnmod_send_weapon_anim( pItem, SEQ_FIDGET );
	}
	
	// Call for idle pretty soon
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, random_float( 10.0, 15.0 ) );
}
//
// Create the strike itself
//
CSStrike__ShootStrike( pevOwner, Float:vecStart[ 3 ], Float:time )
{
	new pStrike = create_entity( "info_target" );
	
	if( pStrike <= 0 )
		return 0;
		
	entity_set_int( pStrike, EV_INT_movetype, MOVETYPE_NONE );
	entity_set_string( pStrike, EV_SZ_classname, CLASS_STRIKE );
	entity_set_int( pStrike, EV_INT_solid, SOLID_BBOX );
	entity_set_int( pStrike, EV_INT_effects, entity_get_int( pStrike, EV_INT_effects ) | EF_NODRAW );
	
	// Set any generic model, we dont care since target isn't drawn anyway
	entity_set_model( pStrike, "models/crossbow_bolt.mdl" );
	
	entity_set_size( pStrike, gVecZero, gVecZero );
	engfunc( EngFunc_SetOrigin, pStrike, vecStart );
	entity_set_edict( pStrike, EV_ENT_owner, pevOwner );
	
	// Do we need this?
	drop_to_floor( pStrike );
	
	entity_set_float( pStrike, EV_FL_nextthink, get_gametime( ) + time );

	return pStrike;
}
//
// Satellite strike is thinking
//
public CSStrike__Think( pStrike )
{
	if( !is_valid_ent( pStrike ) )
		return;
		
	if( !IsInWorld( pStrike ) )
	{
		remove_entity( pStrike );
		return;
	}
	
	CSStrike__Explode( pStrike );
}
//
// Satellite strike should explode now
//
CSStrike__Explode( pStrike )
{
	static pMortar, pevOwner;
	pevOwner = entity_get_edict( pStrike, EV_ENT_owner );
	pMortar = 0;
	
	pMortar = create_entity( "func_mortar_field" );
	
	if( pMortar <= 0 )
		return

	DispatchKeyValue( pMortar, "m_iDamage", STRIKE_DAMAGE );
	DispatchKeyValue( pMortar, "m_fControl", "1" ); // 1 mean depending on activator origin
	DispatchKeyValue( pMortar, "m_flSpread", STRIKE_SPREAD );
	DispatchKeyValue( pMortar, "m_iCount", STRIKE_COUNT );
	DispatchSpawn( pMortar );	
	
	entity_set_edict( pMortar, EV_ENT_owner, pevOwner );
	entity_set_string( pMortar, EV_SZ_targetname, "satellite_mortar" );
	
	ExecuteHam( Ham_Use, pMortar, pStrike, g_pTriggerMultiple, 1, 0.5 );
}
//
// HACK! Make a valid killer for airstrike kills
//
public fw_PlayerKilled( pevVictim, pevKiller, fShouldGib )
{
	if( 1 <= pevKiller <= g_iMaxClients )
		return HAM_IGNORED;
	
	static strClass[ 32 ];
	entity_get_string( pevKiller, EV_SZ_classname, strClass, charsmax( strClass ) );
	
	if( equal( strClass, CLASS_STRIKE ) )
	{
		static pevOwner;
		pevOwner = entity_get_edict( pevKiller, EV_ENT_owner );
		
		ExecuteHamB( Ham_Killed, pevVictim, pevOwner, fShouldGib );
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
//
// Credit Arkshine
//
UTIL_MakeVectors( pPlayer, bsType )
{
	static Float:vPunchAngle[ 3 ], Float:vAngle[ 3 ];

	if( bsType & v_angle )    
		pev( pPlayer, pev_v_angle, vAngle );
	if( bsType & punchangle ) 
		pev( pPlayer, pev_punchangle, vPunchAngle );

	xs_vec_add( vAngle, vPunchAngle, vAngle );
	engfunc( EngFunc_MakeVectors, vAngle );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
