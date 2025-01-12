#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <hl_wpnmod>

#define PLUGIN "blockas"
#define VERSION "1.2"
#define AUTHOR "dima_mark7 (Basic code) and BG Rampo (Optimized Code for using blockas and Cannon Firing Mode)"

// Weapon settings
#define WEAPON_NAME 			"weapon_blockas"
#define WEAPON_SLOT			2
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX		125
#define WEAPON_SECONDARY_AMMO		"ARgrenades"
#define WEAPON_SECONDARY_AMMO_MAX	10
#define WEAPON_MAX_CLIP			10
#define WEAPON_DEFAULT_AMMO		10
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			10
#define WEAPON_DAMAGE			20.0
#define WEAPON_DAMAGE2		120.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_blockas.txt"

// Models
#define MODEL_WORLD			"models/w_blockas.mdl"
#define MODEL_VIEW			"models/v_blockas1.mdl"
#define MODEL_VIEW_CANNON		"models/v_blockas2.mdl"
#define MODEL_PLAYER			"models/p_blockas1.mdl"
#define MODEL_PLAYER_CANNON		"models/p_blockas2.mdl"
#define MODEL_CHANGING			"models/v_blockchange.mdl"
#define MODEL_CANNON			"models/block_rocket.mdl"

// Sprites
#define SPRITE_TRAIL			"sprites/smoke.spr"
#define SPRITE_EXPLODE			"sprites/fexplo.spr"
#define SPRITE_EXPLODE_WATER		"sprites/WXplo1.spr"

// Sounds
#define SOUND_FIRE1			"weapons/blockas1-1.wav"
#define SOUND_FIRE2			"weapons/blockas2_shoot_end.wav"
#define SOUND_READY			"weapons/blockas2_shoot_start.wav"
#define SOUND_CHANGING			"weapons/block_change.wav"

// Rocket
#define CANNON_VELOCITY		2000
#define CANNON_CLASSNAME		"blockas"

// Animation
#define ANIM_EXTENSION			"shotgun"

enum _:blockasmode1
{
	blockas1_IDLE,
	blockas1_SHOOT_1,
	blockas1_SHOOT_2,
	blockas1_SHOOT_3,	
	blockas1_STARTCHANGE,
	blockas1_ENDCHANGE,
	blockas1_START,
	blockas1_RELOAD,
	blockas1_END,
	blockas1_DRAW
}

enum _:blockasmode2
{
	blockas2_IDLE,
	blockas2_IDLE_NO,
	blockas2_SHOOT_READY,
	blockas2_SHOOT,
	blockas2_STARTCHANGE,
	blockas2_STARTCHANGE_NO,
	blockas2_ENDCHANGE,
	blockas2_ENDCHANGE_NO,
	blockas2_RELOAD,
	blockas2_DRAW,
	blockas2_DRAW_NO
}

enum _:blockaschanging
{
	blockas_CHANGING
}

enum _:eFireMode
{
	MODE_NORMAL = 0,
	MODE_CANNON
};

new g_iModelIndexTrail;
new g_iModelIndexFireball;
new g_iModelIndexWExplosion;
new gMsgScreenShake;

new g_mode[33];

#define MIN -10.0
#define MAX 10.0

#define IsPlayer(%1) (1 <= %1 <= g_maxplayers)
#define CRAZY_CODE 5646489

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_VIEW_CANNON);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_PLAYER_CANNON);
	PRECACHE_MODEL(MODEL_CHANGING);
	PRECACHE_MODEL(MODEL_CANNON);

	PRECACHE_SOUND(SOUND_FIRE1);
	PRECACHE_SOUND(SOUND_FIRE2);
	PRECACHE_SOUND(SOUND_READY);
	PRECACHE_SOUND(SOUND_CHANGING);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);

	g_iModelIndexTrail = PRECACHE_MODEL(SPRITE_TRAIL);
	g_iModelIndexFireball = PRECACHE_MODEL(SPRITE_EXPLODE);
	g_iModelIndexWExplosion = PRECACHE_MODEL(SPRITE_EXPLODE_WATER);
}	

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new iblockas = wpnmod_register_weapon
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

	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_Spawn, "blockas_spawn");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_Deploy, "blockas_deploy");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_Idle, "blockas_idle");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_PrimaryAttack, "blockas_primaryattack");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_SecondaryAttack,"blockas_secondaryattack");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_Reload, "blockas_reload");
	wpnmod_register_weapon_forward(iblockas, Fwd_Wpn_Holster, "blockas_holster");

	gMsgScreenShake = get_user_msgid("ScreenShake");
	RegisterHam( Ham_Killed, "player", "player_dead");
}

public blockas_spawn(const iItem)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public blockas_deploy(const iItem, const iPlayer, const iClip)
{
	if (g_mode[iPlayer] == MODE_NORMAL)
	{
		wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, blockas1_DRAW, ANIM_EXTENSION);
	}
	else
	{
		if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
		{
			wpnmod_default_deploy(iItem, MODEL_VIEW_CANNON, MODEL_PLAYER_CANNON, blockas2_DRAW, ANIM_EXTENSION);
		}
		else
		{
			wpnmod_default_deploy(iItem, MODEL_VIEW_CANNON, MODEL_PLAYER_CANNON, blockas2_DRAW_NO, ANIM_EXTENSION);
		}
	}
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.05);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.05);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.55 );
}

public blockas_holster(const iItem)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public blockas_idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound( iItem );
	
	if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
	{
		return;
	}
	
	if (g_mode[iPlayer] == MODE_NORMAL)
	{
		static fInSpecialReload;
		fInSpecialReload = wpnmod_get_offset_int( iItem, Offset_iInSpecialReload );
	
		if( !iClip && !fInSpecialReload && iAmmo )
		{
			blockas_reload( iItem, iPlayer, iClip, iAmmo );
		}
		else if( fInSpecialReload != 0 )
		{
			if( iClip != WEAPON_MAX_CLIP && iAmmo )
			{
				blockas_reload( iItem, iPlayer, iClip, iAmmo );
			}
			else
			{
				// reload debounce has timed out
				wpnmod_send_weapon_anim( iItem, blockas1_END );
			
				wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
				wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
			}
		}
		else
		{
		
			wpnmod_send_weapon_anim( iItem, blockas1_IDLE );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
		}
	}
	else
	{
		if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
		{
			wpnmod_send_weapon_anim( iItem, blockas2_IDLE );
		}
		else
		{
			wpnmod_send_weapon_anim( iItem, blockas2_IDLE_NO );
		}
		wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 7.5 );
	}	
}

public blockas_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if( iAmmo <= 0 || iClip == WEAPON_MAX_CLIP || g_mode[iPlayer] != MODE_NORMAL )
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
			wpnmod_send_weapon_anim( iItem, blockas1_START );
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
			
			wpnmod_send_weapon_anim( iItem, blockas1_RELOAD );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.45 );
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

public blockas_primaryattack(const iItem, const iPlayer, iClip)
{
	if (g_mode[iPlayer] == MODE_NORMAL)
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

		wpnmod_fire_bullets(iPlayer,iPlayer,10,VECTOR_CONE_10DEGREES,3048.0,WEAPON_DAMAGE,DMG_BULLET,10)
	
		wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 0.28 );
		wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
	
		if( iClip != 0 )
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
		else
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.75 );
		
		wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
	
		emit_sound( iPlayer, CHAN_WEAPON, SOUND_FIRE1, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_send_weapon_anim( iItem, blockas1_SHOOT_1 );
		set_pev( iPlayer, pev_punchangle, Float:{ -1.0, 0.0, 1.0 } );
	}
	else
	{
		if (pev(iPlayer, pev_waterlevel) == 3 || wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) <= 0)
		{
			wpnmod_play_empty_sound(iItem);
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
			if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) <= 0)
			{
				client_print( iPlayer, print_center, "Out of Cannon Shells" );
				blockas_secondaryattack(iItem, iPlayer);
			}
			return;
		}
	
		wpnmod_send_weapon_anim( iItem, blockas2_SHOOT_READY );

		emit_sound( iPlayer, CHAN_WEAPON, SOUND_READY, 0.9, ATTN_NORM, 0, PITCH_NORM );

		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 4.95);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 4.95);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.05 );

		wpnmod_set_think(iItem, "Cannon_Fire");
		set_pev(iItem, pev_nextthink, get_gametime() + 1.15);
	}
}

public Cannon_Fire(const iItem, const iPlayer)
{
	new Float: vecOrigin[3];
	
	wpnmod_send_weapon_anim(iItem, blockas2_SHOOT);

	wpnmod_set_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO, wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) - 1);

	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	set_pev(iPlayer, pev_punchangle, Float:{ -4.0, 0.0, 4.0 });
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, .flUpScale = -2.0);
	
	Cannon_Launch( iPlayer );

	if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) != 0)
	{
		wpnmod_set_think(iItem, "Cannon_Reload");
		set_pev(iItem, pev_nextthink, get_gametime() + 1.15);
	}

}

public Cannon_Reload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, blockas2_RELOAD);
}

public Cannon_Launch(const iPlayer)
{
	new iCannon;
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 6.0, 0.0);
	velocity_by_aim(iPlayer, CANNON_VELOCITY, vecVelocity);
		
	// Create default contact grenade with module
	iCannon = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity, "Rocket_Explode");

	if (pev_valid(iCannon))
	{
		new Float: flGameTime = get_gametime();
		
		// Dont draw default fireball on explode and do not inflict damage
		set_pev(iCannon, pev_spawnflags, SF_EXPLOSION_NODAMAGE | SF_EXPLOSION_NOFIREBALL);
		
		// Set custom classname
		set_pev(iCannon, pev_classname, CANNON_CLASSNAME);
		
		// Set movetype.
		set_pev(iCannon, pev_movetype, MOVETYPE_TOSS);
		
		// Set custom damage, because default is 100
		set_pev(iCannon, pev_dmg, WEAPON_DAMAGE2);
		
		// Set avelocity
		set_pev(iCannon, pev_avelocity, Float: {0.0, 0.0, 1000.0});
		
		// Set custom grenade model
		SET_MODEL(iCannon, MODEL_CANNON);
		
		// Set rocket fly think callback
		wpnmod_set_think(iCannon, "Rocket_FlyThink");
		
		// set next think time
		set_pev(iCannon, pev_nextthink, flGameTime + 0.1);
		
		// Set max fly time
		set_pev(iCannon, pev_dmgtime, flGameTime + 3.0);
		
		// rocket trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(iCannon); // entity
		write_short(g_iModelIndexTrail); // model
		write_byte(10); // life
		write_byte(4); // width
		write_byte(224); // r, g, b
		write_byte(224); // r, g, b
		write_byte(255); // r, g, b
		write_byte(255); // brightness
		message_end();
		
	}
}

//**********************************************
//* Rocket fly think.          		       *
//**********************************************

public Rocket_FlyThink(const iCannon)
{
	static Float: flDmgTime;
	
	pev(iCannon, pev_dmgtime, flDmgTime);

	if (pev(iCannon, pev_waterlevel) != 0)
	{
		new Float: vecVelocity[3];
		
		pev(iCannon, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iCannon, pev_velocity, vecVelocity);
	}
}

//**********************************************
//* Rocket explode.          		       *
//**********************************************

public Rocket_Explode(const iCannon)
{	
	new iOwner;
	
	new Float: flDamage;
	new Float: vecOrigin[3];
	
	iOwner = pev(iCannon, pev_owner);
	
	pev(iCannon, pev_dmg, flDamage);
	pev(iCannon, pev_origin, vecOrigin);

	fire_explode(iCannon);

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
	write_short(iCannon);
	message_end(); 
	
	// Reset to attack owner too
	set_pev(iCannon, pev_owner, 0);
	
	// Lets damage
	wpnmod_radius_damage(vecOrigin, iCannon, iOwner, flDamage, flDamage * 2.0, CLASS_NONE, DMG_BLAST);
}

public blockas_secondaryattack(const iItem, const iPlayer)
{
	if (g_mode[iPlayer] == MODE_NORMAL && wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.15);
		return;
	}
 	switch( g_mode[ iPlayer ] )
	{
		case  MODE_NORMAL:
		{
			wpnmod_send_weapon_anim(iItem, blockas1_STARTCHANGE);
			wpnmod_set_think(iItem, "Cannon_Changing");
			set_pev(iItem, pev_nextthink, get_gametime() + 1.65);
		}
		case MODE_CANNON:
		{
			if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
			{
				wpnmod_send_weapon_anim(iItem, blockas2_STARTCHANGE);
			}
			else
			{
				wpnmod_send_weapon_anim(iItem, blockas2_STARTCHANGE_NO);
			}
			wpnmod_set_think(iItem, "Normal_Changing");
			set_pev(iItem, pev_nextthink, get_gametime() + 1.65);
		}
	}

	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 6.20);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 6.20);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.20);
}

public Cannon_Changing(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_CHANGING);
	wpnmod_send_weapon_anim(iItem, blockas_CHANGING);
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_CHANGING, 0.9, ATTN_NORM, 0, PITCH_NORM );	
	wpnmod_set_think(iItem, "Cannon_Mode");
	set_pev(iItem, pev_nextthink, get_gametime() + 2.65);
}

public Normal_Changing(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_CHANGING);
	wpnmod_send_weapon_anim(iItem, blockas_CHANGING);
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_CHANGING, 0.9, ATTN_NORM, 0, PITCH_NORM );
	wpnmod_set_think(iItem, "Normal_Mode");
	set_pev(iItem, pev_nextthink, get_gametime() + 2.65);	
}

public Cannon_Mode(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_VIEW_CANNON);
	set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_CANNON);
	g_mode[iPlayer] = MODE_CANNON;
	if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
	{
		wpnmod_send_weapon_anim(iItem, blockas2_ENDCHANGE);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, blockas2_ENDCHANGE_NO);
	}
}

public Normal_Mode(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_VIEW);
	set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER);
	g_mode[iPlayer] = MODE_NORMAL;
	wpnmod_send_weapon_anim(iItem, blockas1_ENDCHANGE);	
}

public player_dead(id)
{
	if( g_mode[ id ] == MODE_CANNON )
	{
		g_mode[ id ] = MODE_NORMAL;
	}

	if(task_exists(id+231687)) remove_task(id+231687);
	
	remove_task(id);
}

fire_explode(ent)
{
	// Get origin
	static Float:originF[3], Owner;
	pev(ent, pev_origin, originF);
	Owner = pev(ent, pev_owner);
	
	static Float:PlayerOrigin[3];
	static Float:distance;

	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue;
		if(!is_user_connected(Owner))
			continue;
		
		pev(i, pev_origin, PlayerOrigin);
		distance = get_distance_f(originF, PlayerOrigin);
		if(distance > WEAPON_DAMAGE2 * 2)
			continue;

		if(!can_see_fm(ent, i))
			continue;

		crazy2(i);
		set_task(0.5,"crazy",i+231687,"",0,"a",20);
	}
}

public client_putinserver(id)
{	
	new g_Ham_Bot;

	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1;
		set_task(0.1, "Do_RegisterHam_Bot", id);
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "player_dead");
}

public crazy(taskid)
{
	new id = taskid - 231687;
	
	new Float:fVec[3];
	fVec[0] = random_float(MIN , MAX);
	fVec[1] = random_float(MIN , MAX);
	fVec[2] = random_float(MIN , MAX);
	entity_set_vector(id , EV_VEC_punchangle , fVec);
	message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,id);
	write_short( 1<<14 );
	write_short( 1<<14 );
	write_short( 1<<14 );
	message_end();
}

public crazy2(id)
{
	new Float:fVec[3];
	fVec[0] = random_float(MIN , MAX);
	fVec[1] = random_float(MIN , MAX);
	fVec[2] = random_float(MIN , MAX);
	entity_set_vector(id , EV_VEC_punchangle , fVec);
	message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,id);
	write_short( 1<<14 );
	write_short( 1<<14 );
	write_short( 1<<14 );
	message_end();
}

stock bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false;

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags);
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false;
		}

		new Float:lookerOrig[3];
		new Float:targetBaseOrig[3];
		new Float:targetOrig[3];
		new Float:temp[3];

		pev(entindex1, pev_origin, lookerOrig);
		pev(entindex1, pev_view_ofs, temp);
		lookerOrig[0] += temp[0];
		lookerOrig[1] += temp[1];
		lookerOrig[2] += temp[2];

		pev(entindex2, pev_origin, targetBaseOrig);
		pev(entindex2, pev_view_ofs, temp);
		targetOrig[0] = targetBaseOrig [0] + temp[0];
		targetOrig[1] = targetBaseOrig [1] + temp[1];
		targetOrig[2] = targetBaseOrig [2] + temp[2];

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false;
		} 
		else 
		{
			new Float:flFraction;
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true;
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0];
				targetOrig[1] = targetBaseOrig [1];
				targetOrig[2] = targetBaseOrig [2];
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true;
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0];
					targetOrig[1] = targetBaseOrig [1];
					targetOrig[2] = targetBaseOrig [2] - 17.0;
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction);
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}
