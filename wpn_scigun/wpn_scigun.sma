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

// Grenade explosion flags
#define SF_EXPLOSION_NODAMAGE			( 1 << 0 ) // When set, explosion will not actually inflict damage
#define SF_EXPLOSION_NOFIREBALL			( 1 << 1 ) // Don't draw the fireball
#define SF_EXPLOSION_NOSMOKE			( 1 << 2 ) // Don't draw the smoke
#define SF_EXPLOSION_NODECAL			( 1 << 3 ) // Don't make a scorch mark
#define SF_EXPLOSION_NOSPARKS			( 1 << 4 ) // Don't make a sparks
#define SF_EXPLOSION_NODEBRIS			( 1 << 5 ) // Don't make a debris sound

#define CLASS_NONE					0
#define VECTOR_CONE_10DEGREES			Float:{ 0.08716, 0.08716, 0.08716 }

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
native wpnmod_fire_bullets(const iPlayer, const iAttacker, const iShotsCount, const Float: vecSpread[3], const Float: flDistance, const Float: flDamage, const bitsDamageType, const iTracerFreq);
native wpnmod_get_gun_position(const iPlayer, Float: vecResult[3], const Float: flForwardScale = 1.0, const Float: flRightScale = 1.0, const Float: flUpScale = 1.0);
native wpnmod_fire_contact_grenade(const iPlayer, const Float: vecStart[3], const Float: vecVelocity[3], const szCallBack[] = "");
native wpnmod_set_think(const iItem, const szCallBack[]);
				
//==================================================================================================

// Plugin settings
#define PLUGIN 			"scigun (scientist launcher)"
#define VERSION 			"1.0"
#define AUTHOR 			"NiHiLaNTh (basic explosive wpn code) and BG Rampo (Optimized code for using scigun)"

// Weapon settings
#define WEAPON_NAME 			"weapon_scigun"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"scientist"
#define WEAPON_PRIMARY_AMMO_MAX	80
#define WEAPON_SECONDARY_AMMO	"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP		8
#define WEAPON_DEFAULT_AMMO		8
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			15
#define WEAPON_DAMAGE			105.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_scigun.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_scigun"

// Grenade
#define GRENADE_CLASSNAME		"scigun"

// Models
#define MODEL_WORLD			"models/w_scigun.mdl"
#define MODEL_VIEW			"models/v_scigun.mdl"
#define MODEL_PLAYER			"models/p_scigun.mdl"
#define MODEL_CLIP			"models/w_scigunclip.mdl"
#define MODEL_SCI			"models/scientist.mdl"
#define MODEL_ROCKET			"models/hev_rocket.mdl"

// Sounds
#define SOUND_FIRE			"weapons/scigun_fire1.wav"
#define SOUND_FIRE2			"weapons/scigun_fire2.wav"
#define SOUND_RELOAD			"weapons/scigun_reload.wav"
#define SOUND_ROCKET_FLY		"weapons/hev_fly.wav"

// Sprites
#define SPRITE_TRAIL			"sprites/smoke.spr"
#define SPRITE_EXPLODE			"sprites/zerogxplode.spr"
#define SPRITE_EXPLODE_WATER		"sprites/WXplo1.spr"

// Grenade velocity
#define GRENADE_VELOCITY		700
#define GRENADE_RADIUS			350.0
#define ROCKET_VELOCITY			2000

#define ROCKET_CLASSNAME		"hev_rocket"

// Animation
#define ANIM_EXTENSION		"shotgun"

// Animation Sequence
enum _:escigun
{
	scigun_IDLE = 0,
	scigun_SHOOT,
	scigun_SHOOT2,
	scigun_RELOAD2,
	scigun_RELOAD3,	
	scigun_RELOAD1,
	scigun_DRAW,
	scigun_HOLSTER	
};

enum _: eSounds
{
	SND_SCI_1,
	SND_SCI_2,
	SND_SCI_3,
	SND_SCI_4,
	SND_SCI_5,
	SND_SCI_6,
	SND_SCI_7,
	SND_SCI_8,
	SND_SCI_9,
	SND_SCI_10,
	SND_SCI_11,
	SND_SCI_12,
	SND_END
}

new const g_szSounds[SND_END][] =
{
	"scientist/scream01.wav",
	"scientist/scream02.wav",
	"scientist/scream3.wav",
	"scientist/scream04.wav",
	"scientist/scream4.wav",
	"scientist/scream05.wav",
	"scientist/scream06.wav",
	"scientist/scream6.wav",
	"scientist/scream07.wav",
	"scientist/scream7.wav",
	"scientist/scream08.wav",
	"scientist/scream09.wav"
};

enum ( <<=1 )
{
	v_angle = 1,
	punchangle
};

new g_iModelIndexTrail;
new g_iModelIndexFireball;
new g_iModelIndexWExplosion;

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
	PRECACHE_MODEL(MODEL_SCI);
	PRECACHE_MODEL(MODEL_ROCKET);

	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE2);
	PRECACHE_SOUND(SOUND_RELOAD);
	for (new i = 0; i < SND_END; i++)
	{
		PRECACHE_SOUND(g_szSounds[i]);
	}
	PRECACHE_SOUND(SOUND_ROCKET_FLY);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);

	g_iModelIndexTrail = PRECACHE_MODEL(SPRITE_TRAIL);
	g_iModelIndexFireball = PRECACHE_MODEL(SPRITE_EXPLODE);
	g_iModelIndexWExplosion = PRECACHE_MODEL(SPRITE_EXPLODE_WATER);
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new iscigun = wpnmod_register_weapon
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
	
	new iAmmoscigun = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_Spawn, 		"Scigun_Spawn" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_Deploy, 		"Scigun_Deploy" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_Idle, 		"Scigun_WeaponIdle" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_PrimaryAttack,	"Scigun_PrimaryAttack" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_SecondaryAttack, 	"Scigun_SecondaryAttack" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_Reload, 		"Scigun_Reload" );
	wpnmod_register_weapon_forward(iscigun, Fwd_Wpn_Holster, 		"Scigun_Holster" );
	
	wpnmod_register_ammobox_forward(iAmmoscigun, Fwd_Ammo_Spawn, 	"ScigunAmmo_Spawn" );
	wpnmod_register_ammobox_forward(iAmmoscigun, Fwd_Ammo_AddAmmo,	"ScigunAmmo_AddAmmo" );
}

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public Scigun_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public Scigun_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, scigun_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public Scigun_Holster(const iItem, const iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public Scigun_PrimaryAttack(const iItem, const iPlayer, iClip)
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

	LaunchScientist(iPlayer);
	
	wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
	wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
	
	if( iClip != 0 )
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
	else
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.75 );
		
	wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
	
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM );
	wpnmod_send_weapon_anim( iItem, scigun_SHOOT );
	set_pev( iPlayer, pev_punchangle, Float:{ -6.0, 0.0, 6.0 } );
}

//**********************************************
//* Secondary attack of a weapon is triggered. *
//**********************************************

public Scigun_SecondaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 1)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}

	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 2);

	hev_Fire(iPlayer);

	emit_sound( iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM );
	wpnmod_send_weapon_anim( iItem, scigun_SHOOT2 );

	wpnmod_set_player_anim( iPlayer, PLAYER_ATTACK1 );
	
	wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.35 );
	wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.35 );
		
	wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );

	set_pev( iPlayer, pev_punchangle, Float:{ -8.0, 0.0, 8.0 } );
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public Scigun_WeaponIdle(const iItem, const iPlayer, const iClip, const iAmmo)
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
		Scigun_Reload( iItem, iPlayer, iClip, iAmmo );
	}
	else if( fInSpecialReload != 0 )
	{
		if( iClip != WEAPON_MAX_CLIP && iAmmo )
		{
			Scigun_Reload( iItem, iPlayer, iClip, iAmmo );
		}
		else
		{
			// reload debounce has timed out
			wpnmod_send_weapon_anim( iItem, scigun_RELOAD3 );
			
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
		}
	}
	else
	{
		wpnmod_send_weapon_anim( iItem, scigun_IDLE );
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
	}
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public Scigun_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
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
			wpnmod_send_weapon_anim( iItem, scigun_RELOAD1 );
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
			
			emit_sound( iPlayer, CHAN_ITEM, SOUND_RELOAD, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			wpnmod_send_weapon_anim( iItem, scigun_RELOAD2 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.52 );
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

public ScigunAmmo_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public ScigunAmmo_AddAmmo(const iItem, const iPlayer)
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

public LaunchScientist(const iPlayer)
{
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	velocity_by_aim(iPlayer, GRENADE_VELOCITY, vecVelocity);
	wpnmod_get_gun_position(iPlayer, vecOrigin, .flUpScale = 16.0);
	
	new iScientist = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity,"Scientist_Explode");
		
	if (iScientist != FM_NULLENT)
	{
		new Float: flGameTime = get_gametime();
		
		// Dont draw default fireball on explode and do not inflict damage
		set_pev(iScientist, pev_spawnflags, SF_EXPLOSION_NODAMAGE | SF_EXPLOSION_NOFIREBALL);

		new Float: vecAngles[3];
		
		pev(iScientist, pev_angles, vecAngles);
		vecAngles[0] = -120.0;
		set_pev(iScientist, pev_angles, vecAngles);
		
		#define SET_SIZE(%0,%1,%2) engfunc(EngFunc_SetSize,%0,%1,%2)
		
		set_pev(iScientist, pev_dmg, WEAPON_DAMAGE);
		set_pev(iScientist, pev_avelocity, Float: {-20.0, 0.0, 0.0});
		//set_pev_string(iGrenade, pev_classname, g_iszGrenadeClassName);
		set_pev( iScientist, pev_classname,	GRENADE_CLASSNAME );
			
		SET_MODEL(iScientist, MODEL_SCI);
		SET_SIZE(iScientist, Float: {-16.0, -16.0, -16.0}, Float: {16.0, 16.0, 16.0});

		emit_sound(iScientist, CHAN_AUTO, g_szSounds[random_num(SND_SCI_1, SND_SCI_12)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		set_pev(iScientist, pev_frame, 0.0);
		set_pev(iScientist, pev_sequence, 97);
		set_pev(iScientist, pev_animtime, get_gametime());
		set_pev(iScientist, pev_framerate, 1.0);
		set_pev(iScientist, pev_owner, iPlayer);

		// Set rocket fly think callback
		wpnmod_set_think(iScientist, "Scientist_FlyThink");
		
		// set next think time
		set_pev(iScientist, pev_nextthink, flGameTime + 0.1);
		
		// Set max fly time
		set_pev(iScientist, pev_dmgtime, flGameTime + 3.0);
	}
}

public Scientist_FlyThink(const iScientist)
{
	static Float: flDmgTime;
	
	pev(iScientist, pev_dmgtime, flDmgTime);

	if (pev(iScientist, pev_waterlevel) != 0)
	{
		new Float: vecVelocity[3];
		
		pev(iScientist, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iScientist, pev_velocity, vecVelocity);
	}
}

public Scientist_Explode(const iScientist)
{	
	new iOwner;
	
	new Float: flDamage;
	new Float: vecOrigin[3];
	
	iOwner = pev(iScientist, pev_owner);
	
	pev(iScientist, pev_dmg, flDamage);
	pev(iScientist, pev_origin, vecOrigin);

	engfunc(EngFunc_MessageBegin,MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_WATER ? g_iModelIndexFireball : g_iModelIndexWExplosion);
	write_byte(25);
	write_byte(15); 
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_KILLBEAM); 
	write_short(iScientist);
	message_end(); 
	
	// Reset to attack owner too
	set_pev(iScientist, pev_owner, 0);
	
	// Lets damage
	wpnmod_radius_damage(vecOrigin, iScientist, iOwner, flDamage, GRENADE_RADIUS, CLASS_NONE, DMG_BLAST);
	
	emit_sound(iScientist, CHAN_AUTO, g_szSounds[random_num(SND_SCI_1, SND_SCI_12)], 0.0, 0.0, SND_STOP, PITCH_NORM);
}

hev_Fire(const iPlayer)
{
	new iRocket;
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 6.0, 0.0);
	velocity_by_aim(iPlayer, ROCKET_VELOCITY, vecVelocity);
		
	// Create default contact grenade with module
	iRocket = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity, "Rocket_Explode");

	if (pev_valid(iRocket))
	{
		new Float: flGameTime = get_gametime();
		
		// Dont draw default fireball on explode and do not inflict damage
		set_pev(iRocket, pev_spawnflags, SF_EXPLOSION_NODAMAGE | SF_EXPLOSION_NOFIREBALL);
		
		// Set custom classname
		set_pev(iRocket, pev_classname, ROCKET_CLASSNAME);
		
		// Set movetype.
		set_pev(iRocket, pev_movetype, MOVETYPE_FLY);
		
		// Set custom damage, because default is 100
		set_pev(iRocket, pev_dmg, WEAPON_DAMAGE * 1.5);
			
		// Set avelocity
		set_pev(iRocket, pev_avelocity, Float: {0.0, 0.0, 1000.0});
		
		// Set custom grenade model
		SET_MODEL(iRocket, MODEL_ROCKET);
		
		// Set rocket fly think callback
		wpnmod_set_think(iRocket, "Rocket_FlyThink");
		
		// set next think time
		set_pev(iRocket, pev_nextthink, flGameTime + 0.1);
		
		// Set max fly time
		set_pev(iRocket, pev_dmgtime, flGameTime + 3.0);
		
		// rocket trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(iRocket); // entity
		write_short(g_iModelIndexTrail); // model
		write_byte(10); // life
		write_byte(4); // width
		write_byte(224); // r, g, b
		write_byte(224); // r, g, b
		write_byte(255); // r, g, b
		write_byte(255); // brightness
		message_end();
		
		emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 1.0, 0.5, 0, PITCH_NORM);
	}
}

//**********************************************
//* Rocket fly think.          		       *
//**********************************************

public Rocket_FlyThink(const iRocket)
{
	static Float: flDmgTime;
	static Float: flGameTime;
	
	pev(iRocket, pev_dmgtime, flDmgTime);
	set_pev(iRocket, pev_nextthink, (flGameTime = get_gametime()) + 0.2);

	if (pev(iRocket, pev_waterlevel) != 0)
	{
		new Float: vecVelocity[3];
		
		pev(iRocket, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iRocket, pev_velocity, vecVelocity);
	}
	
	if (flDmgTime <= flGameTime)
	{		
		emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 0.0, 0.0, SND_STOP, PITCH_NORM);
	}
}

//**********************************************
//* Rocket explode.          		       *
//**********************************************

public Rocket_Explode(const iRocket)
{	
	new iOwner;
	
	new Float: flDamage;
	new Float: vecOrigin[3];
	
	iOwner = pev(iRocket, pev_owner);
	
	pev(iRocket, pev_dmg, flDamage);
	pev(iRocket, pev_origin, vecOrigin);

	engfunc(EngFunc_MessageBegin,MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(engfunc(EngFunc_PointContents, vecOrigin) != CONTENTS_WATER ? g_iModelIndexFireball : g_iModelIndexWExplosion);
	write_byte(35);
	write_byte(15); 
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_KILLBEAM); 
	write_short(iRocket);
	message_end(); 
	
	// Reset to attack owner too
	set_pev(iRocket, pev_owner, 0);
	
	// Lets damage
	wpnmod_radius_damage(vecOrigin, iRocket, iOwner, flDamage, GRENADE_RADIUS * 1.5, CLASS_NONE, DMG_BLAST);
	
	// Stop fly sound
	emit_sound(iRocket, CHAN_VOICE, SOUND_ROCKET_FLY, 0.0, 0.0, SND_STOP, PITCH_NORM);
}
