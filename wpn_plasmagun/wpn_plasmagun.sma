/*
	Credits:
		KORD_12.7 - code improvements
		222202939 - model port from CSO
		Koshak	  - model&sprite
*/

#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < hl_wpnmod >
#include < xs >

// Weapon parameters
#define WEAPON_NAME 			"weapon_plasmagun"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			5
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_CLIP			45
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_RELOADTIME		3.36
#define WEAPON_REFIRE_RATE		0.15
#define WEAPON_DAMAGE			50.0
#define WEAPON_RADIUS			125.0

// Ammo parameters
#define AMMO_MODEL			"models/w_plasmabox.mdl"
#define AMMO_NAME			"plasma"
#define AMMO_MAX			200
#define AMMO_DEFAULT			90

// Models
#define MODEL_P				"models/p_plasmagun.mdl"
#define MODEL_V				"models/v_plasmagun.mdl"
#define MODEL_W				"models/w_plasmagun.mdl"

// Sounds
#define SOUND_FIRE			"weapons/plasmagun-1.wav"
#define SOUND_EXPLODE			"weapons/plasmagun_exp.wav"

// Ball sprite
#define PLASMA_MODEL			"sprites/plasmaball.spr"
#define PLASMA_EXPLODE			"sprites/plasmabomb.spr"
#define PLASMA_VELOCITY			1200

// V_ model sequences
#define SEQ_IDLE			0
#define SEQ_DEPLOY			2
#define SEQ_RELOAD			1
#define SEQ_FIRE			3

// Playermodel anim group
#define ANIM_EXTENSION			"gauss"

// HUD sprites
new const HUD_SPRITES[ ][ ]		=
{
	"sprites/weapon_plasmagun.txt",
	"sprites/weapon_plasmagun.spr"
};

new const SOUND_OTHER[ ][ ]		=
{
	"weapons/plasmagun_clipin1.wav",
	"weapons/plasmagun_clipin2.wav",
	"weapons/plasmagun_clipout.wav",
	"weapons/plasmagun_draw.wav",
	"weapons/plasmagun_idle.wav"
};
//===================================================================
new g_sModelIndexExplode;

#define CLASS_PLASMABOX			"ammo_plasmabox"
#define CLASS_PLASMA			"monster_plasma"

new const Float:gVecZero[ ]		= { 0.0, 0.0, 0.0 };
//
// Precache resources
//
public plugin_precache( )
{
	new i;
	
	// Models
	PRECACHE_MODEL( MODEL_P );
	PRECACHE_MODEL( MODEL_V );
	PRECACHE_MODEL( MODEL_W );
	PRECACHE_MODEL( AMMO_MODEL );
	// Sounds
	PRECACHE_SOUND( SOUND_FIRE );
	PRECACHE_SOUND( SOUND_EXPLODE );
	for( i = 0; i < sizeof SOUND_OTHER; i++ )
		PRECACHE_SOUND( SOUND_OTHER[ i ] );
	// Sprites
	PRECACHE_MODEL( PLASMA_MODEL );
	g_sModelIndexExplode = PRECACHE_MODEL( PLASMA_EXPLODE );
	// HUD
	for( i = 0; i < sizeof HUD_SPRITES; i++ )
		PRECACHE_GENERIC( HUD_SPRITES[ i ] );
}
//
// Create the weapon and the ammo box
//
public plugin_init( )
{
	register_plugin( "[HL] Weapon Plasmagun", "1.3", "NiHiLaNTh" );
	//
	// Weapon
	//
	new pWeapon = wpnmod_register_weapon
	(
		WEAPON_NAME,
		WEAPON_SLOT,
		WEAPON_POSITION,
		AMMO_NAME,
		AMMO_MAX,
		WEAPON_SECONDARY_AMMO,
		WEAPON_SECONDARY_AMMO_MAX,
		WEAPON_CLIP,
		WEAPON_FLAGS,
		WEAPON_WEIGHT
	);
	
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Spawn, 		"CPlasma__Spawn" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Deploy, 	"CPlasma__Deploy" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Idle, 		"CPlasma__WeaponIdle" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_PrimaryAttack,	"CPlasma__PrimaryAttack" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Reload, 	"CPlasma__Reload" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Holster, 	"CPlasma__Holster" );
	//
	// Ammo
	//
	new pAmmo = wpnmod_register_ammobox( CLASS_PLASMABOX );
	
	wpnmod_register_ammobox_forward( pAmmo, Fwd_Ammo_Spawn, 		"CPlasmaAmmo__Spawn" );
	wpnmod_register_ammobox_forward( pAmmo, Fwd_Ammo_AddAmmo,	"CPlasmaAmmo__AddAmmo" );
}
//
// Spawn
//
public CPlasma__Spawn( pItem )
{
	// Set the model
	SET_MODEL( pItem, MODEL_W );
	
	// Give some default ammo
	wpnmod_set_offset_int( pItem, Offset_iDefaultAmmo, AMMO_DEFAULT );
}
//
// Deploy
//
public CPlasma__Deploy( pItem )
{
	// Set models, player deploy anim and set correct anim extension for the
	// player model.
	return wpnmod_default_deploy( pItem, MODEL_V, MODEL_P, SEQ_DEPLOY, ANIM_EXTENSION );
}
//
// Hide the weapon
//
public CPlasma__Holster( pItem, pPlayer )
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int( pItem, Offset_iInReload, 0 );
}
// 
// Reload the weapon
//
public CPlasma__Reload( pItem, pPlayer, iClip, iAmmo )
{
	if( iAmmo <= 0 || iClip >= WEAPON_CLIP )
		return;
	
	// Call for reloading
	wpnmod_default_reload( pItem, WEAPON_CLIP, SEQ_RELOAD, WEAPON_RELOADTIME );
}
//
// Primary attack
//
public CPlasma__PrimaryAttack( pItem, pPlayer, iClip, rgAmmo )
{
	if( iClip <= 0 || entity_get_int( pPlayer, EV_INT_waterlevel ) == 3 )
	{
		wpnmod_play_empty_sound( pItem );
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.25 );
		return;
	}
	
	if( CPlasmab__Spawn( pPlayer ) )
	{
		//fire effects
		wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME );
		wpnmod_set_offset_int( pPlayer, Offset_iWeaponFlash, DIM_GUN_FLASH );
		
		//remove ammo
		wpnmod_set_offset_int( pItem, Offset_iClip, iClip -= 1 );
		
		entity_set_int( pPlayer, EV_INT_effects, entity_get_int( pPlayer, EV_INT_effects ) | EF_MUZZLEFLASH );
		wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
	
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, WEAPON_REFIRE_RATE );
		wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, WEAPON_REFIRE_RATE + 3.0 );
		
		emit_sound( pPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_send_weapon_anim( pItem, SEQ_FIRE );
		entity_set_vector( pPlayer, EV_VEC_punchangle, Float:{ -5.0, 0.0, 0.0 } );
	}
}
//
// Weapon idle
//
public CPlasma__WeaponIdle( pItem, pPlayer, iClip, iAmmo )
{
	// Reset empty sound
	wpnmod_reset_empty_sound( pItem );
	
	if( wpnmod_get_offset_float( pItem, Offset_flTimeWeaponIdle ) > 0.0 )
		return;
	
	wpnmod_send_weapon_anim( pItem, SEQ_IDLE );
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, random_float( 5.0, 15.0 ) );
}
//
// Plasma ball spawn
//
CPlasmab__Spawn( pPlayer )
{
	new pPlasma = create_entity( "env_sprite" );
	
	if( pPlasma <= 0 )
		return 0;
		
	// Kill any old beams
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM );
	write_short( pPlasma );
	message_end( );
		
	// classname
	entity_set_string( pPlasma, EV_SZ_classname, CLASS_PLASMA );
	
	// model
	entity_set_model( pPlasma, PLASMA_MODEL );
	
	// origin
	static Float:vecSrc[ 3 ];
	wpnmod_get_gun_position( pPlayer, vecSrc, 25.0, 16.0, -7.0 );
	entity_set_origin( pPlasma, vecSrc );

	entity_set_int( pPlasma, EV_INT_movetype, MOVETYPE_FLY );
	entity_set_int( pPlasma, EV_INT_solid, SOLID_BBOX );
	
	// null size
	entity_set_size( pPlasma, gVecZero, gVecZero );
	
	// remove black square around the sprite
	entity_set_float( pPlasma, EV_FL_renderamt, 255.0 );
	entity_set_float( pPlasma, EV_FL_scale, 0.3 );
	entity_set_int( pPlasma, EV_INT_rendermode, kRenderTransAdd );
	entity_set_int( pPlasma, EV_INT_renderfx, kRenderFxGlowShell );
	
	// velocity
	static Float:vecVelocity[ 3 ];
	velocity_by_aim( pPlayer, PLASMA_VELOCITY, vecVelocity );
	entity_set_vector( pPlasma, EV_VEC_velocity, vecVelocity );
	 
	// angles
	static Float:vecAngles[ 3 ];
	engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );
	entity_set_vector( pPlasma, EV_VEC_angles, vecAngles );
	
	// owner
	entity_set_edict( pPlasma, EV_ENT_owner, pPlayer );
	
	wpnmod_set_touch( pPlasma, "CPlasmab__Touch" );
	
	return 1;
}
// 
// Plasma ball hit the world
//
public CPlasmab__Touch( pPlasma, pOther )
{
	if( !is_valid_ent( pPlasma ) )
		return;
	
	static Float:vecSrc[ 3 ];
	entity_get_vector( pPlasma, EV_VEC_origin, vecSrc );
	
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
	write_short( g_sModelIndexExplode );
	write_byte( 5 );
	write_byte( 15 );
	write_byte( TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND );
	message_end( );
	
	emit_sound( pPlasma, CHAN_WEAPON, SOUND_EXPLODE, 1.0, 1.0, 0, 100 );
		
	wpnmod_radius_damage( vecSrc, pPlasma, entity_get_edict( pPlasma, EV_ENT_owner ), WEAPON_DAMAGE, WEAPON_RADIUS, CLASS_NONE, DMG_ACID | DMG_ENERGYBEAM );	
	remove_entity( pPlasma );	
}
//
// Fuel spawn
//
public CPlasmaAmmo__Spawn( pItem )
{
	// Apply new model
	SET_MODEL( pItem, AMMO_MODEL );
}
//
// Give some fuel to the player
//
public CPlasmaAmmo__AddAmmo( pItem, pPlayer )
{
	new iResult = 
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			pPlayer, 
			WEAPON_CLIP, 
			AMMO_NAME,
			AMMO_MAX
		) != -1
	);
	
	if( iResult )
	{
		emit_sound( pItem, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	return iResult;
}
