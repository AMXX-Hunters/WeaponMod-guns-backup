/*
	Credits: HLSDK, Arkshine, Valve(HUD sprites)
*/

#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < hl_wpnmod >
#include < xs >

// Change this to your server max slots
#define MAX_CLIENTS			32

// Weapon parameters
#define WEAPON_NAME 			"weapon_flamethrower"
#define WEAPON_SLOT			4
#define WEAPON_POSITION			5
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_CLIP			75
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15

// Ammo parameters
#define AMMO_NAME			"fuel"
#define AMMO_MAX			200
#define AMMO_DEFAULT			75

// Models
#define MODEL_P				"models/p_flame.mdl"
#define MODEL_V				"models/v_flame.mdl"
#define MODEL_W				"models/w_flame.mdl"
#define MODEL_FUEL			"models/w_flamefuel.mdl"

// Sounds
#define SOUND_STARTUP			"weapons/flamethrower/flameburst.wav"
#define SOUND_RUN			"weapons/flamethrower/flamerun.wav"
#define SOUND_OFF			"weapons/flamethrower/end.wav"

// Sprites
#define SPRITE_FLAME			"sprites/flame_puff01.spr"

// v_ model Sequence indexes
#define SEQ_IDLE			0
#define SEQ_RELOAD			1
#define SEQ_DEPLOY			3
#define SEQ_SHOOT 			2

// Some other stuff
#define WEAPON_RELOADTIME		3.6
#define WEAPON_DAMAGE			10.0
#define WEAPON_RADIUS			75.0

// Afterburn
#define BURN_DAMAGE			5.0
#define BURN_MAX_TIME			10	// how many seconds max. player can burn after hit
#define BURN_GIVE_ON_HIT		2	// how many seconds are added on hit

// HUD sprites
new const HUD_SPRITES[ ][ ]		=
{
	"sprites/weapon_flamethrower.spr",
	"sprites/weapon_flamethrower.txt"	// name MUST MATCH with WEAPON_NAME
};

// Reload sounds built into model
new const SOUND_RELOAD[ ][ ]		=
{
	"weapons/v_flame_in.wav",
	"weapons/v_flame_out.wav",
	"weapons/v_flame_pshh.wav"
};
//=============================================================
// Burn struct
enum _:eBurnData
{
	__BurnTime,
	Float:__NextBurn,
	__Attacker
};

// Vars
new any:g_aBurnData[ MAX_CLIENTS + 1 ][ eBurnData ];
new g_sModelIndexFlameBurst;
new g_cFrameCount;
new g_iMaxClients;

// Ents
#define CLASS_FUEL			"ammo_fueltank"
#define CLASS_FLAME			"monster_flamethrower"

new const Float:gVecZero[ ]		= { 0.0, 0.0, 0.0 };

// Fire states
enum
{
	FIRE_OFF = 0,
	FIRE_CHARGE
};

enum ( <<=1 )
{
	v_angle = 1,
	punchangle
};

// Macro
#define IS_NET_CLIENT(%0)		( 1 <= %0 <= g_iMaxClients )
#define STOP_SOUND(%0,%1,%2)		emit_sound( %0, %1, %2, VOL_NORM, 0.0, SND_STOP, 0 )
#define VectorMA(%0,%1,%2,%3)    	( %3[ 0 ] = %0[ 0 ] + %1 * %2[ 0 ], %3[ 1 ] = %0[ 1 ] + %1 * %2[ 1 ], %3[ 2 ] = %0[ 2 ] + %1 * %2[ 2 ] )
#define VectorScale(%0,%1,%2)    	( %2[ 0 ] = %1 * %0[ 0 ], %2[ 1 ] = %1 * %0[ 1 ], %2[ 2 ] = %1 * %0[ 2 ] )
// 
// Precache resource
//
public plugin_precache( )
{
	// Models
	PRECACHE_MODEL( MODEL_P );
	PRECACHE_MODEL( MODEL_V );
	PRECACHE_MODEL( MODEL_W );
	PRECACHE_MODEL( MODEL_FUEL );
	
	// Sounds
	PRECACHE_SOUND( SOUND_STARTUP );
	PRECACHE_SOUND( SOUND_RUN );
	PRECACHE_SOUND( SOUND_OFF );
	
	// Sprites
	g_sModelIndexFlameBurst = PRECACHE_MODEL( SPRITE_FLAME );
	
	// HUD
	new i;
	for( i = 0; i < sizeof( HUD_SPRITES ); i++ )
		PRECACHE_GENERIC( HUD_SPRITES[ i ] );
		
	// Reload sound
	for( i = 0; i < sizeof( SOUND_RELOAD ); i++ )
		PRECACHE_SOUND( SOUND_RELOAD[ i ] );
}
//
// Create the weapon and the ammo box
//
public plugin_init( )
{
	register_plugin( "[HL] Weapon Flamethrower", "1.2", "NiHiLaNTh" );
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
	
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Spawn, 		"CFlameThrower__Spawn" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Deploy, 	"CFlameThrower__Deploy" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Idle, 		"CFlameThrower__WeaponIdle" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_PrimaryAttack,	"CFlameThrower__PrimaryAttack" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Reload, 	"CFlameThrower__Reload" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Holster, 	"CFlameThrower__Holster" );
	//
	// Burning
	//
	register_event( "ItemPickup", "EV_ItemPickup", "be", "1=item_healthkit" );
	RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn", .Post = 1 );
	RegisterHam( Ham_Player_PreThink, "player", "fw_PlayerPreThink", .Post = 0 );
	RegisterHam( Ham_TakeDamage, "player", "fw_PlayerTakeDamage", .Post = 1 );
	g_iMaxClients = get_maxplayers( );
	//
	// Fuel
	//
	new pFuel = wpnmod_register_ammobox( CLASS_FUEL );
	
	wpnmod_register_ammobox_forward( pFuel, Fwd_Ammo_Spawn, 		"CFuel__Spawn" );
	wpnmod_register_ammobox_forward( pFuel, Fwd_Ammo_AddAmmo,	"CFuel__AddAmmo" );
	//
	// Fire
	//
	register_think( CLASS_FLAME,		"CFlame__Think" );
	register_touch( CLASS_FLAME,	"*",	"CFlame__Touch" );
}
public plugin_cfg( )
	g_cFrameCount = engfunc( EngFunc_ModelFrames, g_sModelIndexFlameBurst );
//
// Spawn
//
public CFlameThrower__Spawn( pItem )
{
	// Set the model
	SET_MODEL( pItem, MODEL_W );
	
	// Give some default ammo
	wpnmod_set_offset_int( pItem, Offset_iDefaultAmmo, AMMO_DEFAULT );
}
//
// Deploy
//
public CFlameThrower__Deploy( pItem )
{
	// Reset fire state
	wpnmod_set_offset_int( pItem, Offset_iFireState, FIRE_OFF );
	
	// Set models, player deploy anim and set correct anim extension for the
	// player model.
	return wpnmod_default_deploy( pItem, MODEL_V, MODEL_P, SEQ_DEPLOY, "egon" );
}
//
// Hide the weapon
//
public CFlameThrower__Holster( pItem, pPlayer )
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int( pItem, Offset_iInReload, 0 );
	
	// Stop the attack
	CFlameThrower__EndAttack( pItem, pPlayer );
}
//
// Primary attack
//
public CFlameThrower__PrimaryAttack( pItem, pPlayer, iClip )
{
	static iFireState;
	iFireState = wpnmod_get_offset_int( pItem, Offset_iFireState );
	
	if( iClip <= 0 || entity_get_int( pPlayer, EV_INT_waterlevel ) == 3 )
	{
		if( iFireState != FIRE_OFF )
		{
			CFlameThrower__EndAttack( pItem, pPlayer );
		}
		else
		{
			wpnmod_play_empty_sound( pItem );
		}
	
		wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.25 );
		return;
	}

	switch( iFireState )
	{
		case FIRE_OFF:
		{
			/*if ( !HasAmmo() )
			{
				m_flNextPrimaryAttack = m_flNextSecondaryAttack = UTIL_WeaponTimeBase() + 0.25;
				PlayEmptySound( );
				return;
			}*/
		
			// start using ammo ASAP.
			wpnmod_set_offset_float( pItem, Offset_fuser2, get_gametime( ) );
			
			// Effects
			emit_sound( pPlayer, CHAN_WEAPON, SOUND_STARTUP, 0.98, ATTN_NORM, 0, 125 );
			wpnmod_send_weapon_anim( pItem, SEQ_SHOOT );
			wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
	
			//m_shakeTime = 0;
			
			// Set some basic weapon params
			wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, 450 );
			wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, 0.1 );
			wpnmod_set_offset_float( pItem, Offset_fuser1, get_gametime( ) + 1.0 );
			
			// Update fire state
			wpnmod_set_offset_int( pItem, Offset_iFireState, FIRE_CHARGE );
		}
		case FIRE_CHARGE:
		{
			CFlameThrower__Fire( pItem, pPlayer, iClip );
			wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, 450 );
			
			if( wpnmod_get_offset_float( pItem, Offset_fuser1 ) <= get_gametime( ) )
			{
				// Fire effects
				emit_sound( pPlayer, CHAN_WEAPON, SOUND_RUN, 0.98, ATTN_NORM, 0, 125 );
				wpnmod_send_weapon_anim( pItem, SEQ_SHOOT );
				
				wpnmod_set_offset_float( pItem, Offset_fuser1, get_gametime( ) + 6.0 );
			}
		}
	}

}
//
// Start attacking
//
CFlameThrower__Fire( pItem, pPlayer, iClip )
{
	// Create the flame itself
	new pFire = FireEffect( pPlayer );

	if( pFire )
	{
		static Float:tTime;
		tTime = get_gametime( );
		
		// multiplayer uses 1 ammo every 1/10th second
		if( tTime >= wpnmod_get_offset_float( pItem, Offset_fuser2 ) )
		{
			wpnmod_set_offset_int( pItem, Offset_iClip, iClip -= 1 );
			wpnmod_set_offset_float( pItem, Offset_fuser2, tTime + 0.1 );
		}
	}
}
//
// End flamethrower attack
//
CFlameThrower__EndAttack( pItem, pPlayer )
{
	new bool:fMakeNoise = false;

	// Checking the button just in case!.
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != FIRE_OFF )
		fMakeNoise = true;
	
	// Stop run sound
	STOP_SOUND( pPlayer, CHAN_WEAPON, SOUND_RUN );
	
	if( fMakeNoise )
		emit_sound( pPlayer, CHAN_WEAPON, SOUND_OFF, 0.98, ATTN_NORM, 0, 100 );
	
	wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.2 );
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, 2.0 );
	
	wpnmod_set_offset_int( pItem, Offset_iFireState, FIRE_OFF );
}
// 
// Reload the weapon
//
public CFlameThrower__Reload( pItem, pPlayer, iClip, iAmmo )
{
	if( iAmmo <= 0 || iClip >= WEAPON_CLIP )
		return;
	
	// End the attack now!
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != FIRE_OFF )
		CFlameThrower__EndAttack( pItem, pPlayer );
	
	// Call for reloading
	wpnmod_default_reload( pItem, WEAPON_CLIP, SEQ_RELOAD, WEAPON_RELOADTIME );
}
//
// Weapon idle
//
public CFlameThrower__WeaponIdle( pItem, pPlayer, iClip, iAmmo )
{
	// Reset empty sound
	wpnmod_reset_empty_sound( pItem );
	
	if( wpnmod_get_offset_float( pItem, Offset_flTimeWeaponIdle ) > 0.0 )
		return;
	
	// Reset attack
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != FIRE_OFF )
		CFlameThrower__EndAttack( pItem, pPlayer );
	
	wpnmod_send_weapon_anim( pItem, SEQ_IDLE );
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, random_float( 5.0, 15.0 ) );
}
//
// Reset burning stuff on connect
//
public client_putinserver( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
//
// Reset burning stuff on disconnect
//
public client_disconnect( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
//
//
// Reset burning when pickup a healthkit
//	
public EV_ItemPickup( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
//
// Reset burning on spawn
//
public fw_PlayerSpawn( pPlayer )
{
	if( is_user_alive( pPlayer ) )
		arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
}
//
// Burning itself
//
public fw_PlayerPreThink( pPlayer )
{
	if( g_aBurnData[ pPlayer ][ __BurnTime ] <= 0 )
		return;
		
	if( !is_user_connected( g_aBurnData[ pPlayer ][ __Attacker ] ) || entity_get_int( pPlayer, EV_INT_waterlevel ) > 1 )
	{
		//reset burning stuff when my attacker disconnects
		//otherwise it will sum up when I'll set on fire
		//for the next time.
		arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
		return;
	}
		
	static Float:tTime;
	tTime = get_gametime( );
	
	if( g_aBurnData[ pPlayer ][ __NextBurn ] > tTime )
		return;
		
	static Float:vecSrc[ 3 ];
	entity_get_vector( pPlayer, EV_VEC_origin, vecSrc );
	
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 );
	write_byte( TE_SPRITE );
	engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
	write_short( g_sModelIndexFlameBurst );
	write_byte( 5 );
	write_byte( 200 );
	message_end( );
	
	ExecuteHamB( Ham_TakeDamage, pPlayer, g_aBurnData[ pPlayer ][ __Attacker ], g_aBurnData[ pPlayer ][ __Attacker ], BURN_DAMAGE, DMG_SLOWBURN | DMG_NEVERGIB );
	
	g_aBurnData[ pPlayer ][ __BurnTime ]--;
	g_aBurnData[ pPlayer ][ __NextBurn ] = tTime + 1.0;	
}
//
// Burn it down! (c) Linkin Park
//
public fw_PlayerTakeDamage( pevVictim, pevInflictor, pevAttacker, Float:flDamage, bitDamageType )
{
	if( !pevAttacker || !IS_NET_CLIENT( pevAttacker ) )
		return;
	
	if( bitDamageType & DMG_BURN )
	{
		if( g_aBurnData[ pevVictim ][ __BurnTime ] >= BURN_MAX_TIME )
			return;
			
		// Afterburn
		g_aBurnData[ pevVictim ][ __NextBurn ] = get_gametime( ) + 1.0;
		g_aBurnData[ pevVictim ][ __BurnTime ] += BURN_GIVE_ON_HIT;
		g_aBurnData[ pevVictim ][ __Attacker ] = pevAttacker;
	}
}
//
// Fuel spawn
//
public CFuel__Spawn( pItem )
{
	// Apply new model
	SET_MODEL( pItem, MODEL_FUEL );
}
//
// Give some fuel to the player
//
public CFuel__AddAmmo( pItem, pPlayer )
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
//
// Create the flame cloud
//
FireEffect( pPlayer )
{
	new pFlame = create_entity( "env_sprite" );
	
	if( pFlame <= 0 )
	{
		return 0;
	}
	
	entity_set_string( pFlame, EV_SZ_classname,	CLASS_FLAME );
	engfunc( EngFunc_SetModel, pFlame,		SPRITE_FLAME );
	
	entity_set_int( pFlame, EV_INT_solid, 		SOLID_NOT );

	UTIL_MakeVectors( pPlayer, v_angle + punchangle );
	
	static Float:vecOrigin[ 3 ], Float:vecSrc[ 3 ], Float:vecViewOfs[ 3 ];
	static Float:vecAngle[ 3 ], Float:vForward[ 3 ], Float:vRight[ 3 ], Float:vUp[ 3 ];
	entity_get_vector( pPlayer, EV_VEC_origin, vecOrigin );
	entity_get_vector( pPlayer, EV_VEC_view_ofs, vecViewOfs );
	entity_get_vector( pPlayer, EV_VEC_v_angle, vecAngle );
	engfunc( EngFunc_MakeVectors, vecAngle )
	global_get( glb_v_forward, vForward );
	global_get( glb_v_right, vRight );
	global_get( glb_v_up, vUp );

	vecSrc[ 0 ] = vecOrigin[ 0 ] + vecViewOfs[ 0 ] + vForward[ 0 ] * 35.0 + vRight[ 0 ] * 8.0 + vUp[ 0 ] * -5.0;
	vecSrc[ 1 ] = vecOrigin[ 1 ] + vecViewOfs[ 1 ] + vForward[ 1 ] * 35.0 + vRight[ 1 ] * 8.0 + vUp[ 1 ] * -5.0;
	vecSrc[ 2 ] = vecOrigin[ 2 ] + vecViewOfs[ 2 ] + vForward[ 2 ] * 35.0 + vRight[ 2 ] * 8.0 + vUp[ 2 ] * -5.0
	engfunc( EngFunc_SetOrigin, pFlame, 		vecSrc );
	
	static Float:vecVelocity[ 3 ];
	velocity_by_aim( pPlayer, 900, vecVelocity );
	entity_set_vector( pFlame, EV_VEC_velocity,	vecVelocity );
	
	entity_set_edict( pFlame, EV_ENT_owner, 		pPlayer );
	entity_set_float( pFlame, EV_FL_dmg,		WEAPON_DAMAGE );
	entity_set_float( pFlame, EV_FL_renderamt,	255.0 );
	entity_set_int( pFlame, EV_INT_iuser2,		20 );
	entity_set_float( pFlame, EV_FL_scale,		0.1 );
	entity_set_float( pFlame, EV_FL_frags,		0.05 );
      
	FlameSpawn( pFlame );
	return pFlame;
}
//
// Now create the flame itself
//
FlameSpawn( pFlame )
{
	entity_set_int( pFlame, EV_INT_movetype, MOVETYPE_FLY );
	entity_set_int( pFlame, EV_INT_solid, SOLID_SLIDEBOX );
	entity_set_float( pFlame, EV_FL_takedamage, DAMAGE_NO );
	entity_set_int( pFlame, EV_INT_flags, FL_FLY );
	
	static Float:vecSrc[ 3 ];
	entity_get_vector( pFlame, EV_VEC_origin, vecSrc );
	engfunc( EngFunc_SetOrigin, pFlame, vecSrc );
	entity_set_size( pFlame, gVecZero, gVecZero );
	
	entity_set_int( pFlame, EV_INT_impulse, g_cFrameCount );
	entity_set_float( pFlame, EV_FL_frame, random_num( 0, g_cFrameCount - 1 ) * 1.0 );
	
	entity_set_vector( pFlame, EV_VEC_rendercolor, Float:{ 100.0, 80.0, 255.0 } );
	entity_set_int( pFlame, EV_INT_rendermode, kRenderTransAdd );
	entity_set_float( pFlame, EV_FL_gravity, -1.0 );
	entity_set_int( pFlame, EV_INT_renderfx, kRenderFxPulseFast );
	
	static Float:tTime;
	tTime = get_gametime( );
	
	entity_set_float( pFlame, EV_FL_dmgtime, tTime );
	entity_set_int( pFlame, EV_INT_iuser1, 1 );
	entity_set_float( pFlame, EV_FL_nextthink, tTime + 0.02 );
}
// 
// Flame is thinking
//
public CFlame__Think( pFlame )
{
	if( !is_valid_ent( pFlame ) )
		return;
	
	if( entity_get_int( pFlame, EV_INT_iuser1 ) )
	{
		if( entity_get_int( pFlame, EV_INT_waterlevel ) > 1 )
		{
			remove_entity( pFlame );
			return;
		}
		
		static Float:flFrame, iImpulse;
		flFrame = entity_get_float( pFlame, EV_FL_frame );
		iImpulse = entity_get_int( pFlame, EV_INT_impulse );
		
		if( iImpulse > 1 )
		{
			if( flFrame < iImpulse - 1 )
			{
				entity_set_float( pFlame, EV_FL_frame, flFrame + 1.0 );
			}
			else
			{
				entity_set_float( pFlame, EV_FL_frame, 0.0 );
			}
		}
		
		static Float:vecVelocity[ 3 ];
		entity_get_vector( pFlame, EV_VEC_velocity, vecVelocity );
		VectorScale( vecVelocity, 0.84, vecVelocity );
		entity_set_vector( pFlame, EV_VEC_velocity, vecVelocity );
		
		entity_get_vector( pFlame, EV_VEC_rendercolor, vecVelocity );
		vecVelocity[ 0 ] = floatclamp( vecVelocity[ 0 ] + 50.0, 0.0, 255.0 );
		vecVelocity[ 1 ] = floatclamp( vecVelocity[ 1 ] + 50.0, 0.0, 255.0 );
		entity_set_vector( pFlame, EV_VEC_rendercolor, vecVelocity );
		
		static iUser2;
		iUser2 = entity_get_int( pFlame, EV_INT_iuser2 );
		flFrame = entity_get_float( pFlame, EV_FL_renderamt );
		
		if( flFrame > iUser2 - 1 )
		{
			entity_set_float( pFlame, EV_FL_renderamt, flFrame - iUser2 );
		}
		else
		{
			remove_entity( pFlame );
			return;
		}
		
		static Float:flNextScale;
		flFrame = entity_get_float( pFlame, EV_FL_scale );
		flNextScale = entity_get_float( pFlame, EV_FL_frags );
		
		if( flFrame >= 1.0 )
		{
			entity_set_int( pFlame, EV_INT_rendermode, kRenderTransAdd );
		}
		
		entity_set_float( pFlame, EV_FL_scale, flFrame + flNextScale );
		entity_set_float( pFlame, EV_FL_nextthink, get_gametime( ) + 0.05 );
	}		
}
//
// Flame has hit something solid
//
public CFlame__Touch( pFlame, pOther )
{
	if( !is_valid_ent( pFlame ) )
		return;
	
	if( !entity_get_int( pFlame, EV_INT_iuser1 ) )
		return;
		
	if( entity_get_int( pFlame, EV_INT_modelindex ) == entity_get_int( pOther, EV_INT_modelindex ) )
		return;
	
	static Float:tTime, Float:vecSrc[ 3 ], pevOwner;
	tTime = get_gametime( );
	entity_get_vector( pFlame, EV_VEC_origin, vecSrc );
	pevOwner = entity_get_edict( pFlame, EV_ENT_owner );
	
	if( ExecuteHam( Ham_IsBSPModel, pOther ) )
	{
		entity_set_vector( pFlame, EV_VEC_velocity, gVecZero );
		wpnmod_radius_damage( vecSrc, pFlame, pevOwner, WEAPON_DAMAGE, WEAPON_RADIUS, CLASS_NONE, DMG_BURN | DMG_NEVERGIB );
		EFX_Explosion( pFlame, vecSrc, g_sModelIndexFlameBurst, 3, 35, TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
	}
	else if( entity_get_int( pOther, EV_INT_solid ) > SOLID_TRIGGER )
	{
		static Float:vecVelocity[ 3 ], Float:vecOVelocity[ 3 ];
		entity_get_vector( pFlame, EV_VEC_velocity, vecVelocity );
		entity_get_vector( pOther, EV_VEC_velocity, vecOVelocity );
		
		VectorMA( vecOVelocity, 0.5, vecVelocity, vecVelocity );
		entity_set_vector( pFlame, EV_VEC_velocity, vecVelocity );
		
		static Float:flDmgTime;
		flDmgTime = entity_get_float( pFlame, EV_FL_dmgtime );
		
		if( flDmgTime <= tTime )
		{
			static Float:flScaleAdd;
			flDmgTime = entity_get_float( pFlame, EV_FL_scale );
			flScaleAdd = entity_get_float( pFlame, EV_FL_frags );
			
			entity_set_float( pFlame, EV_FL_scale, flDmgTime + flScaleAdd );
                
			if( entity_get_float( pOther, EV_FL_takedamage ) && entity_get_float( pFlame, EV_FL_dmg ) > 0 )
			{
				entity_set_int( pFlame, EV_INT_movetype, MOVETYPE_NONE );
				entity_set_int( pFlame, EV_INT_solid, SOLID_NOT );
				//entity_set_int( pFlame, EV_INT_modelindex, g_sModelIndexFlameBurst );
				// set_pev ( i_Ent, pev_modelindex, gi_Flame2 );
				wpnmod_radius_damage( vecSrc, pFlame, pevOwner, WEAPON_DAMAGE, WEAPON_RADIUS, CLASS_NONE, DMG_BURN | DMG_NEVERGIB );
				remove_entity( pFlame );
				return;
			}
		}
	}
	
	entity_set_float( pFlame, EV_FL_dmgtime, tTime + 0.2 );
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
//
// Generate flame explosion
//
EFX_Explosion( pFlame, Float:vecOrigin[ ], iSprite, iScale, iFrameRate, iFlags )
{
	// TODO.Add few trace lines and vector calculations
	// for proper explosion end position calculation
	static Float:vecDown[ 3 ], tr;
	
	vecDown[ 0 ] = vecOrigin[ 0 ];
	vecDown[ 1 ] = vecOrigin[ 1 ];
	vecDown[ 2 ] = vecOrigin[ 2 ] - 32.0;
	
	engfunc( EngFunc_TraceLine, vecOrigin, vecDown, IGNORE_MONSTERS, pFlame, tr );
	
	if( get_tr2( tr, TR_flFraction ) != 1.0 )
	{
		static Float:vEndPos[ 3 ], Float:vPlaneNormal[ 3 ];
		get_tr2( tr, TR_vecEndPos, vEndPos );
		get_tr2( tr, TR_vecPlaneNormal, vPlaneNormal );
		
		for( new i = 0; i < 3; i++ )
			vecOrigin[ i ] = vEndPos[ i ] + ( vPlaneNormal[ i ] * ( entity_get_float( pFlame, EV_FL_dmg ) - 24.0 ) * 0.6 );
	}
	
	vecOrigin[ 0 ] += random_float( -7.0, 7.0 );
	vecOrigin[ 1 ] += random_float( -7.0, 7.0 );
	
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0 );
	write_byte( TE_EXPLOSION );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vecOrigin[ 2 ] );
	write_short( iSprite );
	write_byte( iScale );
	write_byte( iFrameRate );
	write_byte( iFlags );
	message_end( );
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
