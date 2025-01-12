#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>

#define PLUGIN "blockar"
#define VERSION "1.0"
#define AUTHOR "dima_mark7 (Basic Code) and BG Rampo (Optimized for using blockar and V2 Rocket mode)"

// Weapon settings
#define WEAPON_NAME 			"weapon_blockar"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			4
#define WEAPON_PRIMARY_AMMO		"blockclip"
#define WEAPON_PRIMARY_AMMO_MAX		250
#define WEAPON_SECONDARY_AMMO		"ARgrenades"
#define WEAPON_SECONDARY_AMMO_MAX	10
#define WEAPON_MAX_CLIP			40
#define WEAPON_DEFAULT_AMMO		40
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			10
#define WEAPON_DAMAGE			20.0
#define WEAPON_DAMAGE2			200.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_blockar.txt"

// Models
#define MODEL_WORLD			"models/w_blockar.mdl"
#define MODEL_VIEW			"models/v_blockar1.mdl"
#define MODEL_VIEW_MISSILE		"models/v_blockar2.mdl"
#define MODEL_PLAYER			"models/p_blockar1.mdl"
#define MODEL_PLAYER_MISSILE		"models/p_blockar2.mdl"
#define MODEL_CLIP			"models/w_blockarclip.mdl"
#define MODEL_CHANGING			"models/v_blockchange.mdl"
#define MODEL_MISSILE			"models/block_rocket.mdl"

// Sprites
#define SPRITE_TRAIL			"sprites/smoke.spr"
#define SPRITE_EXPLODE			"sprites/fexplo.spr"
#define SPRITE_EXPLODE_WATER		"sprites/WXplo1.spr"

// Sounds
#define SOUND_FIRE1			"weapons/blockar1-1.wav"
#define SOUND_FIRE2			"weapons/blockar2-1.wav"
#define SOUND_READY			"weapons/blockar2_shoot_start.wav"
#define SOUND_CHANGING			"weapons/block_change.wav"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_blockarclip"

// Rocket
#define MISSILE_VELOCITY		2000
#define MISSILE_CLASSNAME		"blockar"

// Animation
#define ANIM_EXTENSION			"mp5"

enum _:blockarmode1
{
	blockar1_IDLE,
	blockar1_SHOOT_1,
	blockar1_SHOOT_2,
	blockar1_SHOOT_3,	
	blockar1_STARTCHANGE,
	blockar1_ENDCHANGE,
	blockar1_RELOAD,
	blockar1_DRAW
}

enum _:blockarmode2
{
	blockar2_IDLE,
	blockar2_IDLE_NO,
	blockar2_SHOOT_READY,
	blockar2_SHOOT,
	blockar2_STARTCHANGE,
	blockar2_STARTCHANGE_NO,
	blockar2_ENDCHANGE,
	blockar2_ENDCHANGE_NO,
	blockar2_RELOAD,
	blockar2_DRAW,
	blockar2_DRAW_NO
}

enum _:blockarchanging
{
	blockar_CHANGING
}

enum _:eFireMode
{
	MODE_NORMAL = 0,
	MODE_MISSILE
};

new g_iModelIndexTrail;
new g_iModelIndexFireball;
new g_iModelIndexWExplosion;

new g_mode[33];

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_VIEW_MISSILE);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(MODEL_PLAYER_MISSILE);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_CHANGING);
	PRECACHE_MODEL(MODEL_MISSILE);

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
	
	new iblockar = wpnmod_register_weapon
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
	new iClip = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);

	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_Spawn, "blockar_spawn");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_Deploy, "blockar_deploy");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_Idle, "blockar_idle");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_PrimaryAttack, "blockar_primaryattack");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_SecondaryAttack,"blockar_secondaryattack");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_Reload, "blockar_reload");
	wpnmod_register_weapon_forward(iblockar, Fwd_Wpn_Holster, "blockar_holster");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_Spawn, "Clip_Spawn");
	wpnmod_register_ammobox_forward(iClip, Fwd_Ammo_AddAmmo, "Clip_AddAmmo");

	RegisterHam( Ham_Killed, "player", "player_dead");
}

public blockar_spawn(const iItem, iPlayer)
{
	SET_MODEL(iItem, MODEL_WORLD);
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public Clip_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
	
	// Setting sub-model
	set_pev(iItem, pev_body, 1);
}

public Clip_AddAmmo(const iItem, const iPlayer)
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

public blockar_deploy(const iItem, const iPlayer, const iClip)
{
	if (g_mode[iPlayer] == MODE_NORMAL)
	{
		wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, blockar1_DRAW, ANIM_EXTENSION);
	}
	else
	{
		if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
		{
			wpnmod_default_deploy(iItem, MODEL_VIEW_MISSILE, MODEL_PLAYER_MISSILE, blockar2_DRAW, ANIM_EXTENSION);
		}
		else
		{
			wpnmod_default_deploy(iItem, MODEL_VIEW_MISSILE, MODEL_PLAYER_MISSILE, blockar2_DRAW_NO, ANIM_EXTENSION);
		}
	}

	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.05);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.05);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.55 );
}

public blockar_holster(const iItem, const iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}

public blockar_idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound( iItem );
	
	if( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
	{
		return;
	}
	
	if (g_mode[iPlayer] == MODE_NORMAL)
	{
		wpnmod_send_weapon_anim( iItem, blockar1_IDLE );
	}
	else
	{
		if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
		{
			wpnmod_send_weapon_anim( iItem, blockar2_IDLE );
		}
		else
		{
			wpnmod_send_weapon_anim( iItem, blockar2_IDLE_NO );
		}
	}
	wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 7.5 );	
}

public blockar_reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if( iAmmo <= 0 || iClip == WEAPON_MAX_CLIP || g_mode[iPlayer] != MODE_NORMAL )
		return;

	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, blockar1_RELOAD, 4.25);
}

public blockar_primaryattack(const iItem, const iPlayer, iClip)
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

		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			1, 
			VECTOR_CONE_2DEGREES,
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_BULLET | DMG_NEVERGIB, 
			2
		);
	
		wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 0.11 );
		wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
	
		if( iClip != 0 )
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 5.0 );
		else
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.75 );
		
		wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
	
		emit_sound( iPlayer, CHAN_WEAPON, SOUND_FIRE1, 0.9, ATTN_NORM, 0, PITCH_NORM );
		wpnmod_send_weapon_anim( iItem, blockar1_SHOOT_1 );
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
				client_print( iPlayer, print_center, "Out of Missiles" );
				blockar_secondaryattack(iItem, iPlayer);
			}
			return;
		}
	
		wpnmod_send_weapon_anim( iItem, blockar2_SHOOT_READY );

		emit_sound( iPlayer, CHAN_WEAPON, SOUND_READY, 0.9, ATTN_NORM, 0, PITCH_NORM );

		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 4.95);
		wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 4.95);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 5.05 );

		wpnmod_set_think(iItem, "Missile_Fire");
		set_pev(iItem, pev_nextthink, get_gametime() + 1.15);
	}
}

public Missile_Fire(const iItem, const iPlayer)
{
	new Float: vecOrigin[3];
	
	wpnmod_send_weapon_anim(iItem, blockar2_SHOOT);

	wpnmod_set_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO, wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) - 1);

	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	set_pev(iPlayer, pev_punchangle, Float:{ -4.0, 0.0, 4.0 });
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, .flUpScale = -2.0);
	
	Missile_Launch( iPlayer );

	if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) != 0)
	{
		wpnmod_set_think(iItem, "Missile_Reload");
		set_pev(iItem, pev_nextthink, get_gametime() + 1.15);
	}
}

public Missile_Reload(const iItem)
{
	wpnmod_send_weapon_anim(iItem, blockar2_RELOAD);
}

public Missile_Launch(const iPlayer)
{
	new iMissile;
	
	new Float: vecOrigin[3];
	new Float: vecVelocity[3];
	
	wpnmod_get_gun_position(iPlayer, vecOrigin, 16.0, 6.0, 0.0);
	velocity_by_aim(iPlayer, MISSILE_VELOCITY, vecVelocity);
		
	// Create default contact grenade with module
	iMissile = wpnmod_fire_contact_grenade(iPlayer, vecOrigin, vecVelocity, "Rocket_Explode");

	if (pev_valid(iMissile))
	{
		new Float: flGameTime = get_gametime();
		
		// Dont draw default fireball on explode and do not inflict damage
		set_pev(iMissile, pev_spawnflags, SF_EXPLOSION_NODAMAGE | SF_EXPLOSION_NOFIREBALL);
		
		// Set custom classname
		set_pev(iMissile, pev_classname, MISSILE_CLASSNAME);
		
		// Set movetype.
		set_pev(iMissile, pev_movetype, MOVETYPE_FLY);
		
		// Set custom damage, because default is 100
		set_pev(iMissile, pev_dmg, WEAPON_DAMAGE2);
		
		// Set avelocity
		set_pev(iMissile, pev_avelocity, Float: {0.0, 0.0, 1000.0});
		
		// Set custom grenade model
		SET_MODEL(iMissile, MODEL_MISSILE);
		
		// Set rocket fly think callback
		wpnmod_set_think(iMissile, "Rocket_FlyThink");
		
		// set next think time
		set_pev(iMissile, pev_nextthink, flGameTime + 0.1);
		
		// Set max fly time
		set_pev(iMissile, pev_dmgtime, flGameTime + 3.0);
		
		// rocket trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(iMissile); // entity
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

public Rocket_FlyThink(const iMissile)
{
	static Float: flDmgTime;
	
	pev(iMissile, pev_dmgtime, flDmgTime);

	if (pev(iMissile, pev_waterlevel) != 0)
	{
		new Float: vecVelocity[3];
		
		pev(iMissile, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
		set_pev(iMissile, pev_velocity, vecVelocity);
	}
}

//**********************************************
//* Rocket explode.          		       *
//**********************************************

public Rocket_Explode(const iMissile)
{	
	new iOwner;
	
	new Float: flDamage;
	new Float: vecOrigin[3];
	
	iOwner = pev(iMissile, pev_owner);
	
	pev(iMissile, pev_dmg, flDamage);
	pev(iMissile, pev_origin, vecOrigin);

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
	write_short(iMissile);
	message_end(); 
	
	// Reset to attack owner too
	set_pev(iMissile, pev_owner, 0);
	
	// Lets damage
	wpnmod_radius_damage(vecOrigin, iMissile, iOwner, flDamage, flDamage * 2.0, CLASS_NONE, DMG_BLAST);
}

public blockar_secondaryattack(const iItem, const iPlayer)
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
			wpnmod_send_weapon_anim(iItem, blockar1_STARTCHANGE);
			wpnmod_set_think(iItem, "Missile_Changing");
			set_pev(iItem, pev_nextthink, get_gametime() + 1.65);
		}
		case MODE_MISSILE:
		{
			if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
			{
				wpnmod_send_weapon_anim(iItem, blockar2_STARTCHANGE);
			}
			else
			{
				wpnmod_send_weapon_anim(iItem, blockar2_STARTCHANGE_NO);
			}
			wpnmod_set_think(iItem, "Normal_Changing");
			set_pev(iItem, pev_nextthink, get_gametime() + 1.65);
		}
	}

	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 6.20);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 6.20);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.20);
}

public Missile_Changing(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_CHANGING);
	wpnmod_send_weapon_anim(iItem, blockar_CHANGING);
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_CHANGING, 0.9, ATTN_NORM, 0, PITCH_NORM );	
	wpnmod_set_think(iItem, "Missile_Mode");
	set_pev(iItem, pev_nextthink, get_gametime() + 2.65);
}

public Normal_Changing(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_CHANGING);
	wpnmod_send_weapon_anim(iItem, blockar_CHANGING);
	emit_sound( iPlayer, CHAN_WEAPON, SOUND_CHANGING, 0.9, ATTN_NORM, 0, PITCH_NORM );
	wpnmod_set_think(iItem, "Normal_Mode");
	set_pev(iItem, pev_nextthink, get_gametime() + 2.65);	
}

public Missile_Mode(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_VIEW_MISSILE);
	set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER_MISSILE);
	g_mode[iPlayer] = MODE_MISSILE;
	if (wpnmod_get_player_ammo(iPlayer, WEAPON_SECONDARY_AMMO) > 0)
	{
		wpnmod_send_weapon_anim(iItem, blockar2_ENDCHANGE);
	}
	else
	{
		wpnmod_send_weapon_anim(iItem, blockar2_ENDCHANGE_NO);
	}
}

public Normal_Mode(const iItem, const iPlayer)
{
	set_pev(iPlayer, pev_viewmodel2, MODEL_VIEW);
	set_pev(iPlayer, pev_weaponmodel2, MODEL_PLAYER);
	g_mode[iPlayer] = MODE_NORMAL;
	wpnmod_send_weapon_anim(iItem, blockar1_ENDCHANGE);	
}

public player_dead(id)
{
	if( g_mode[ id ] == MODE_MISSILE )
	{
		g_mode[ id ] = MODE_NORMAL;
	}
}
