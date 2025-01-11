#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < fakemeta_util >
#include < hamsandwich >
#include < hl_wpnmod >
#include < fun>
#include < xs >

// Change this to your server max slots
#define MAX_CLIENTS			32

// Weapon parameters
#define WEAPON_NAME 			"weapon_cyclone"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			5
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_CLIP			35
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15

// Ammo parameters
#define AMMO_NAME			"uranium"
#define AMMO_MAX			200
#define AMMO_DEFAULT			35

// Models
#define MODEL_P				"models/p_cyclon.mdl"
#define MODEL_V				"models/v_cyclon.mdl"
#define MODEL_W				"models/w_cyclon.mdl"

// Sounds
#define SOUND_STARTUP			"weapons/sfpistol_shoot_start.wav"
#define SOUND_RUN			"weapons/sfpistol_shoot1.wav"
#define SOUND_OFF			"weapons/sfpistol_shoot_end.wav"

// v_ model Sequence indexes
#define SEQ_IDLE			0
#define SEQ_RELOAD			3
#define SEQ_DEPLOY			4
#define SEQ_SHOOT 			1
#define SEQ_SHOOTEND			2

// Some other stuff
#define WEAPON_RELOADTIME		2.75
#define WEAPON_DAMAGE			24.0


#define WEAPON_HUD_SPARK	"sprites/ef_smoke_poison.spr"

// HUD sprites
new const HUD_SPRITES[ ][ ]		=
{
	"sprites/640hud104_2.spr",
	"sprites/640hud12_2.spr",
	"sprites/weapon_cyclon.txt"	// name MUST MATCH with WEAPON_NAME
};

// Reload sounds built into model
new const SOUND_RELOAD[ ][ ]		=
{
	"weapons/sfpistol_clipin.wav",
	"weapons/sfpistol_clipout.wav"
};

new sTrail;
new sSpark;

enum
{
	LASER_OFF = 0,
	LASER_CHARGE
};

enum ( <<=1 )
{
	v_angle = 1,
	punchangle
};

// Macro
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

	// Sounds
	PRECACHE_SOUND( SOUND_STARTUP );
	PRECACHE_SOUND( SOUND_RUN );
	PRECACHE_SOUND( SOUND_OFF );
	
	sTrail = precache_model("sprites/zbeam4.spr");
	sSpark =  precache_model(WEAPON_HUD_SPARK);
	
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
	register_plugin( "[CSO] Cyclone", "1.5", "Dr.Hunter;BIGs" );

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
	
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Spawn, 		"CYC__Spawn" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Deploy, 	"CYC__Deploy" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Idle, 		"CYC__WeaponIdle" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_PrimaryAttack,	"CYC__PrimaryAttack" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Reload, 	"CYC__Reload" );
	wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Holster, 	"CYC__Holster" );
}

public CYC__Spawn( pItem )
{
	// Set the model
	SET_MODEL( pItem, MODEL_W );
	
	// Give some default ammo
	wpnmod_set_offset_int( pItem, Offset_iDefaultAmmo, AMMO_DEFAULT );
}

public CYC__Deploy( pItem )
{
	// Reset fire state
	wpnmod_set_offset_int( pItem, Offset_iFireState, LASER_OFF );
	
	wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.65 );

	// Set models, player deploy anim and set correct anim extension for the
	// player model.
	return wpnmod_default_deploy( pItem, MODEL_V, MODEL_P, SEQ_DEPLOY, "python" );
}

public CYC__Holster( pItem, pPlayer )
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int( pItem, Offset_iInReload, 0 );
	
	// Stop the attack
	CYC__EndAttack( pItem, pPlayer );
}

public CYC__PrimaryAttack( pItem, pPlayer, iClip )
{
	static iFireState;
	iFireState = wpnmod_get_offset_int( pItem, Offset_iFireState );
	
	if( iClip <= 0 || entity_get_int( pPlayer, EV_INT_waterlevel ) == 3 )
	{
		if( iFireState != LASER_OFF )
		{
			CYC__EndAttack( pItem, pPlayer );
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
		case LASER_OFF:
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
			wpnmod_set_offset_float( pItem, Offset_fuser1, get_gametime( ) + 0.1 );
			
			// Update fire state
			wpnmod_set_offset_int( pItem, Offset_iFireState, LASER_CHARGE );
		}
		case LASER_CHARGE:
		{
			CYC__Fire( pItem, pPlayer, iClip );
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

CYC__Fire( pItem, pPlayer, iClip )
{
	static Float:tTime;
	tTime = get_gametime( );
		
	if( tTime >= wpnmod_get_offset_float( pItem, Offset_fuser2 ) )
	{
		wpnmod_set_offset_int( pItem, Offset_iClip, iClip -= 1 );
		wpnmod_set_offset_float( pItem, Offset_fuser2, tTime + 0.08 );

		buff_special( pPlayer );

		wpnmod_fire_bullets
		(
			pPlayer, 
			pPlayer, 
			1, 
			Float: {0.0001,- 0.0001, 0.0001}, 
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_ACID, 
			0
		);
	}
}

public buff_special(pPlayer)
{
	new Float:flAim[3];
	fm_get_aim_origin(pPlayer, flAim);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMENTPOINT);
	write_short(pPlayer | 0x1000);
	engfunc(EngFunc_WriteCoord, flAim[0]);
	engfunc(EngFunc_WriteCoord, flAim[1]);
	engfunc(EngFunc_WriteCoord, flAim[2]);
	write_short(sTrail);
	write_byte(0); // framerate
	write_byte(0); // framerate
	write_byte(1); // life
	write_byte(10);  // width
	write_byte(0);// noise
	write_byte(41);// r, g, b
	write_byte(164);// r, g, b
	write_byte(0);// r, g, b
	write_byte(255);	// brightness
	write_byte(200);	// speed
	message_end();
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, flAim[0]);
	engfunc(EngFunc_WriteCoord, flAim[1]);
	engfunc(EngFunc_WriteCoord, flAim[2]);
	write_short(sSpark);	// sprite index
	write_byte(2);	// scale in 0.1's
	write_byte(30);	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);	// flags
	message_end();
}

CYC__EndAttack( pItem, pPlayer )
{
	new bool:fMakeNoise = false;

	// Checking the button just in case!.
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != LASER_OFF )
		fMakeNoise = true;
	
	// Stop run sound
	STOP_SOUND( pPlayer, CHAN_WEAPON, SOUND_RUN );

	wpnmod_send_weapon_anim( pItem, SEQ_SHOOTEND );
	
	if( fMakeNoise )
		emit_sound( pPlayer, CHAN_WEAPON, SOUND_OFF, 0.98, ATTN_NORM, 0, 100 );
	
	wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.2 );
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, 2.0 );
	
	wpnmod_set_offset_int( pItem, Offset_iFireState, LASER_OFF );
}

public CYC__Reload( pItem, pPlayer, iClip, iAmmo )
{
	if( iAmmo <= 0 || iClip >= WEAPON_CLIP )
		return;
	
	// End the attack now!
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != LASER_OFF )
		CYC__EndAttack( pItem, pPlayer );
	
	// Call for reloading
	wpnmod_default_reload( pItem, WEAPON_CLIP, SEQ_RELOAD, WEAPON_RELOADTIME );
}

public CYC__WeaponIdle( pItem, pPlayer, iClip, iAmmo )
{
	// Reset empty sound
	wpnmod_reset_empty_sound( pItem );
	
	if( wpnmod_get_offset_float( pItem, Offset_flTimeWeaponIdle ) > 0.0 )
		return;
	
	// Reset attack
	if( wpnmod_get_offset_int( pItem, Offset_iFireState ) != LASER_OFF )
		CYC__EndAttack( pItem, pPlayer );
	
	wpnmod_send_weapon_anim( pItem, SEQ_IDLE );
	wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, random_float( 5.0, 15.0 ) );
}
