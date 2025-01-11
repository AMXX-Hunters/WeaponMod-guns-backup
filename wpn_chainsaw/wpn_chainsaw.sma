/*
	Credits:	
		KORD_12.7 - knife plugin
		Koshak - model
		
		fixed by ET-NiK
*/
#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < hl_wpnmod >
#include < xs >

// Weapon settings
#define WEAPON_NAME 			"weapon_chainsaw"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			2
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_CLIP			100
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			19

// Damage
#define CHAINSAW_DAMAGE			50.0
#define CHAINSAW_DAMAGE2		30.0

// Attack distance
#define CHAINSAW_DISTANCE		80.0
#define CHAINSAW_DISTANCE2		80.0

// Attack speed
#define CHAINSAW_REFIRE_RATE2		0.7

// Weapon models
#define MODEL_WORLD			"models/w_chainsaw.mdl"
#define MODEL_VIEW			"models/v_chainsaw.mdl"
#define MODEL_PLAYER			"models/p_chainsaw.mdl"

// v_ model animation sequence indexes
#define SEQ_DEPLOY			1
#define SEQ_DEPLOY_EMPTY		2	
#define SEQ_LOOP_START			3
#define SEQ_LOOP			4
#define SEQ_LOOP_END			5
#define SEQ_SLASH			7
#define SEQ_IDLE			0
#define SEQ_IDLE_EMPTY			11
#define SEQ_RELOAD			6

// Fire sound
#define SOUND_START			"weapons/chainsaw_attack1_start.wav"
#define SOUND_FIRE			"weapons/chainsaw_attack1_loop.wav"
#define SOUND_END			"weapons/chainsaw_attack1_end.wav"
#define SOUND_HIT_WALL			"weapons/chainsaw_hit1.wav"
#define SOUND_HIT_FLESH			"weapons/chainsaw_hit3.wav"
#define SOUND_MISS			"weapons/chainsaw_miss.wav"

// Ammo
#define AMMO_NAME			"petrol"
#define AMMO_MAX			200
#define AMMO_DEFAULT			50
#define FUEL_REMOVE_SPEED		0.25 // how fast ammo is depleting

// Playermodel animation extension
#define ANIM_EXTENSION			"bow"

// Other sounds, built into model
new const SOUND_SAW[ ][ ]		=
{
	"weapons/chainsaw_draw1.wav",
	"weapons/chainsaw_draw.wav",
	"weapons/chainsaw_idle.wav",
	"weapons/chainsaw_reload.wav"
};

// HUD sprites
new const HUD_SPRITES[ ][ ]		=
{
	"sprites/weapon_chainsaw.txt",	// should match with WEAPON_NAME
	"sprites/640hud84.spr",
	"sprites/640hud21.spr"
}
//=======================================================
//=======================================================

// Hit volume
#define	CHAINSAW_BODYHIT_VOLUME		128
#define	CHAINSAW_WALLHIT_VOLUME		512

#define Instance(%0) 			( ( %0 == -1 ) ? 0 : %0 )
//
// Precache the resources
//
public plugin_precache( )
{
	new i;
	
	//models
	PRECACHE_MODEL( MODEL_PLAYER );
	PRECACHE_MODEL( MODEL_VIEW );
	PRECACHE_MODEL( MODEL_WORLD );
	
	//sounds
	PRECACHE_SOUND( SOUND_START );
	PRECACHE_SOUND( SOUND_FIRE );
	PRECACHE_SOUND( SOUND_END );
	PRECACHE_SOUND( SOUND_HIT_FLESH );
	PRECACHE_SOUND( SOUND_HIT_WALL );
	
	PRECACHE_SOUND( SOUND_MISS );
	
	//built into model
	for( i = 0; i < sizeof( SOUND_SAW ); i++ )
		PRECACHE_SOUND( SOUND_SAW[ i ] );
	
	//sprites
	for( i = 0; i < sizeof( HUD_SPRITES ); i++ )
		PRECACHE_GENERIC( HUD_SPRITES[ i ] );
}
// 
// Register the weapon & co
//
public plugin_init( )
{
	register_plugin( "[HL] Chainsaw", "1.1", "NiHiLaNTh" );
	//
	//weapon
	//
	new pChainsaw = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_Spawn, 		"CChainsaw__Spawn" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_Deploy, 		"CChainsaw__Deploy" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_Holster, 		"CChainsaw__Holster" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_PrimaryAttack, 	"CChainsaw__PrimaryAttack" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_SecondaryAttack,	"CChainsaw__SecondaryAttack" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_Reload, 		"CChainsaw__Reload" );
	wpnmod_register_weapon_forward( pChainsaw, Fwd_Wpn_Idle, 		"CChainsaw__WeaponIdle" );
}

//
// Weapon appeared on the world
//
public CChainsaw__Spawn( pWeapon )
{
	SET_MODEL( pWeapon, MODEL_WORLD );
	wpnmod_set_offset_int( pWeapon, Offset_iDefaultAmmo, AMMO_DEFAULT );
}
//
// Weapon deploy
//
public CChainsaw__Deploy( pWeapon, pPlayer, iClip )
{
	wpnmod_set_offset_int( pWeapon, Offset_iChargeReady, 0 );
	
	return wpnmod_default_deploy( pWeapon, MODEL_VIEW, MODEL_PLAYER, !iClip ? SEQ_DEPLOY_EMPTY : SEQ_DEPLOY, ANIM_EXTENSION );
}
//
// Weapon hide
//
public CChainsaw__Holster( pWeapon, pPlayer )
{
	// cancel any reload in progress
	wpnmod_set_offset_int( pWeapon, Offset_iInReload, 0 );
	
	// stop attacking
	CChainsaw__EndAttack( pWeapon, pPlayer, 0 );
}
//
// Weapon fire
//
public CChainsaw__PrimaryAttack( pWeapon, pPlayer, iClip )
{
	static iChargeReady;
	iChargeReady = wpnmod_get_offset_int( pWeapon, Offset_iChargeReady );
	
	if( entity_get_int( pPlayer, EV_INT_waterlevel ) == 3 )
	{
		if( iChargeReady > 0 )
		{
			CChainsaw__EndAttack( pWeapon, pPlayer );
		}
		else
		{
			CChainsaw__EmptyAttack( pWeapon, pPlayer );
		}
		return;
	}
	
	if( iClip <= 0 )
	{
		if( iChargeReady > 0 )
		{
			CChainsaw__EndAttack( pWeapon, pPlayer );
		}
		else
		{
			CChainsaw__EmptyAttack( pWeapon, pPlayer );
		}
		return;
	}
	
	static Float:tTime;
	tTime = get_gametime( );
		
	switch( iChargeReady )
	{
		case 0:
		{
			emit_sound( pPlayer, CHAN_WEAPON, SOUND_START, 1.0, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_send_weapon_anim( pWeapon, SEQ_LOOP_START );
			
			wpnmod_set_offset_int( pWeapon, Offset_iChargeReady, 1 );
			wpnmod_set_offset_float( pWeapon, Offset_flTimeWeaponIdle, 0.3 );
			return;
		}
		case 1:
		{
			if( wpnmod_get_offset_float( pWeapon, Offset_flTimeWeaponIdle ) > 0.0 )
				return;
			
			wpnmod_send_weapon_anim( pWeapon, SEQ_LOOP );
			emit_sound( pPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_set_offset_float( pWeapon, Offset_flNextPrimaryAttack, 0.1 );
			
			//dont try to use secondary attack until we end this one!
			wpnmod_set_offset_float( pWeapon, Offset_flNextSecondaryAttack, 9999.0 ); 
			
			wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
			
			if( tTime >= wpnmod_get_offset_float( pWeapon, Offset_flReleaseThrow ) )
			{
				wpnmod_set_offset_int( pWeapon, Offset_iClip, iClip - 1 );
				wpnmod_set_offset_float( pWeapon, Offset_flReleaseThrow, tTime + FUEL_REMOVE_SPEED ); //1.0
			}
			
			wpnmod_fire_bullets( pPlayer, pPlayer, 1, VECTOR_CONE_20DEGREES, CHAINSAW_DISTANCE, CHAINSAW_DAMAGE, DMG_CLUB | DMG_ALWAYSGIB, 6 );
		}
	}		
}
//
// Secondary attack: slow, low damage, bigger attack distance, no ammo required
//
public CChainsaw__SecondaryAttack( pWeapon, pPlayer )
{
	if( wpnmod_get_offset_int( pWeapon, Offset_iChargeReady ) > 0 )
	{
		CChainsaw__EndAttack( pWeapon, pPlayer );
	}
	
	CChainsaw__EmptyAttack( pWeapon, pPlayer );
}
//
// Weapon reload
//
public CChainsaw__Reload( pWeapon, pPlayer, iClip, rgAmmo )
{
	if( iClip >= WEAPON_CLIP || rgAmmo <= 0 )
		return;
			
	if( wpnmod_get_offset_int( pWeapon, Offset_iChargeReady ) )	
		CChainsaw__EndAttack( pWeapon, pPlayer );
			
	wpnmod_default_reload( pWeapon, WEAPON_CLIP, SEQ_RELOAD, 3.0 );
}
// 
// Weapon idle
//
public CChainsaw__WeaponIdle( pWeapon, pPlayer, iClip )
{
	wpnmod_reset_empty_sound( pWeapon );
	
	if( wpnmod_get_offset_float( pWeapon, Offset_flTimeWeaponIdle ) > 0.0 )
		return;
	
	if( wpnmod_get_offset_int( pWeapon, Offset_iChargeReady ) )
	{
		CChainsaw__EndAttack( pWeapon, pPlayer );
		return;
	}
	
	wpnmod_send_weapon_anim( pWeapon, !iClip ? SEQ_IDLE_EMPTY : SEQ_IDLE );
	wpnmod_set_offset_float( pWeapon, Offset_flTimeWeaponIdle, random_float( 5.0, 15.0 ) );
}
//
// Secondary attack
//
CChainsaw__EmptyAttack( pWeapon, pPlayer )
{
	//wpnmod_set_think( pWeapon, "CChainsaw__Slash" );
	emit_sound( pPlayer, CHAN_WEAPON, SOUND_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM );
	CChainsaw__Slash( pWeapon, pPlayer );
	wpnmod_send_weapon_anim( pWeapon, SEQ_SLASH );

	wpnmod_set_offset_float( pWeapon, Offset_flNextPrimaryAttack, CHAINSAW_REFIRE_RATE2 );
	wpnmod_set_offset_float( pWeapon, Offset_flNextSecondaryAttack, CHAINSAW_REFIRE_RATE2 );
	wpnmod_set_offset_float( pWeapon, Offset_flTimeWeaponIdle, 5.0 );
}
//
// Make the attack itself
//
public CChainsaw__Slash( pWeapon, pPlayer )
{	
	new iClass;
	new iTrace;
	new iDidHit;
	new iEntity;
	new iHitWorld;
	
	new Float:vecSrc[ 3 ];
	new Float:vecEnd[ 3 ];
	new Float:vecAngle[ 3 ];
	new Float:vecRight[ 3 ];
	new Float:vecForward[ 3 ];
	
	new Float: flFraction;
	
	iTrace = create_tr2( );
	
	entity_get_vector( pPlayer, EV_VEC_v_angle, vecAngle );
	engfunc( EngFunc_MakeVectors, vecAngle );
	
	wpnmod_get_gun_position( pPlayer, vecSrc );
	
	global_get( glb_v_right, vecRight );
	global_get( glb_v_forward, vecForward );
	
	xs_vec_mul_scalar( vecRight, 6.0, vecRight );
	xs_vec_mul_scalar( vecForward, 42.0, vecForward );
		
	xs_vec_add( vecRight, vecForward, vecForward );
	xs_vec_add( vecForward, vecSrc, vecEnd );
	
	engfunc( EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, iTrace );
	get_tr2( iTrace, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 )
	{ 
		engfunc( EngFunc_TraceHull, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, pPlayer, iTrace );
		get_tr2( iTrace, TR_flFraction, flFraction );
		
		if( flFraction < 1.0 )
		{
			new iHit = Instance( get_tr2( iTrace, TR_pHit ) );
			
			if( !iHit || ExecuteHamB( Ham_IsBSPModel, iHit ) )
			{
				FindHullIntersection( vecSrc, iTrace, Float:{ -16.0, -16.0, -18.0 }, Float:{16.0,  16.0,  18.0 }, pPlayer );
			}
			
			get_tr2( iTrace, TR_vecEndPos, vecEnd );
		}
	}
	
	get_tr2( iTrace, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 )
	{	
		wpnmod_set_offset_float( pWeapon, Offset_flNextPrimaryAttack, 0.5 );
		wpnmod_set_offset_float( pWeapon, Offset_flNextSecondaryAttack, 0.5 );
			
		wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
	}
	else
	{
		iDidHit = true;
		iEntity = Instance( get_tr2( iTrace, TR_pHit ) );
		 
		wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
		wpnmod_clear_multi_damage( );
		
		entity_get_vector( pPlayer, EV_VEC_v_angle, vecAngle );
		engfunc( EngFunc_MakeVectors, vecAngle );	
		
		global_get( glb_v_forward, vecForward );
		ExecuteHamB( Ham_TraceAttack, iEntity, pPlayer, CHAINSAW_DAMAGE2, vecForward, iTrace, DMG_CLUB | DMG_NEVERGIB );
		
		wpnmod_apply_multi_damage( pPlayer, pPlayer );
		
		iHitWorld = true;
			
		if( iEntity && ( iClass = ExecuteHamB( Ham_Classify, iEntity ) ) != CLASS_NONE && iClass != CLASS_MACHINE )
		{
			/*switch (random_num(0, 1))
			{
				case 0: emit_sound(pPlayer, CHAN_ITEM, SOUND_HIT_FLESH_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 1: emit_sound(pPlayer, CHAN_ITEM, SOUND_HIT_FLESH_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}*/
				
			emit_sound( iEntity, CHAN_VOICE, SOUND_HIT_FLESH, 1.0, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, CHAINSAW_BODYHIT_VOLUME );
				
			if( !ExecuteHamB( Ham_IsAlive, iEntity ) )
			{
				return true;
			}
				
			iHitWorld = false;
		}
			
		if( iHitWorld )
		{
			emit_sound( iEntity, CHAN_VOICE, SOUND_HIT_WALL, 1.0, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_set_offset_int( pWeapon, Offset_iuser4, iTrace )
		}
			
		wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, CHAINSAW_WALLHIT_VOLUME );
		
		//CChainsaw__Smack( pWeapon );
		wpnmod_set_think( pWeapon, "CChainsaw__Smack");
		entity_set_float( pWeapon, EV_FL_nextthink, get_gametime( ) + 0.1 );
	}

	free_tr2( iTrace );
	return iDidHit;
}
//
// Paint decals
//
public CChainsaw__Smack( pWeapon )
{
	new iTrace = wpnmod_get_offset_int( pWeapon, Offset_iuser4 );
	
	//sparks
	new Float:vecEnd[ 3 ];
	get_tr2( iTrace, TR_vecEndPos, vecEnd );
	
	engfunc( EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0 );
	write_byte( TE_SPARKS );
	engfunc( EngFunc_WriteCoord, vecEnd[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecEnd[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecEnd[ 2 ] );
	message_end( );
	
	free_tr2( iTrace );
}
//
// Stop attacking
//
CChainsaw__EndAttack( pWeapon, pPlayer, iPlaySound = 0 )
{
	if( iPlaySound > 0 ){
		emit_sound( pPlayer, CHAN_WEAPON, SOUND_END, 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
	
	wpnmod_send_weapon_anim( pWeapon, SEQ_LOOP_END );
	
	wpnmod_set_offset_float( pWeapon, Offset_flNextPrimaryAttack, 0.2 );
	wpnmod_set_offset_float( pWeapon, Offset_flNextSecondaryAttack, 0.5 );
	wpnmod_set_offset_float( pWeapon, Offset_flTimeWeaponIdle, 2.0 );
	
	wpnmod_set_offset_int( pWeapon, Offset_iChargeReady, 0 );
}
// 
// 
//
FindHullIntersection( const Float:vecSrc[ 3 ], &iTrace, const Float: vecMins[ 3 ], const Float: vecMaxs[ 3 ], const iEntity )
{
	new i, j, k;
	new iTempTrace;
	
	new Float:vecEnd[ 3 ];
	new Float:flDistance;
	new Float:flFraction;
	new Float:vecEndPos[ 3 ];
	new Float:vecHullEnd[ 3 ];
	new Float:flThisDistance;
	new Float:vecMinMaxs[ 2 ][ 3 ];
	
	flDistance = 999999.0;
	
	xs_vec_copy( vecMins, vecMinMaxs[ 0 ] );
	xs_vec_copy( vecMaxs, vecMinMaxs[ 1 ] );
	
	get_tr2( iTrace, TR_vecEndPos, vecHullEnd );
	
	xs_vec_sub( vecHullEnd, vecSrc, vecHullEnd );
	xs_vec_mul_scalar( vecHullEnd, 2.0, vecHullEnd );
	xs_vec_add( vecHullEnd, vecSrc, vecHullEnd );
	
	engfunc( EngFunc_TraceLine, vecSrc, vecHullEnd, DONT_IGNORE_MONSTERS, iEntity, ( iTempTrace = create_tr2( ) ) );
	get_tr2( iTempTrace, TR_flFraction, flFraction );
	
	if( flFraction < 1.0 )
	{
		free_tr2( iTrace );
		
		iTrace = iTempTrace;
		return;
	}
	
	for( i = 0; i < 2; i++ )
	{
		for( j = 0; j < 2; j++ )
		{
			for( k = 0; k < 2; k++ )
			{
				vecEnd[ 0 ] = vecHullEnd[ 0 ] + vecMinMaxs[ i ][ 0 ];
				vecEnd[ 1 ] = vecHullEnd[ 1 ] + vecMinMaxs[ j ][ 1 ];
				vecEnd[ 2 ] = vecHullEnd[ 2 ] + vecMinMaxs[ k ][ 2 ];
				
				engfunc( EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iEntity, iTempTrace );
				get_tr2( iTempTrace, TR_flFraction, flFraction );
				
				if( flFraction < 1.0 )
				{
					get_tr2( iTempTrace, TR_vecEndPos, vecEndPos );
					xs_vec_sub( vecEndPos, vecSrc, vecEndPos );
					
					if( ( flThisDistance = xs_vec_len( vecEndPos ) ) < flDistance )
					{
						free_tr2( iTrace );
						
						iTrace = iTempTrace;
						flDistance = flThisDistance;
					}
				}
			}
		}
	}
}
