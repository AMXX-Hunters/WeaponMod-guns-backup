/* AMX Mod X
*	RPG-7.
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <hl_wpnmod>
#include <xs>
#include <engine>
#include <fakemeta>
#include <fun>

#define PLUGIN "Specialized Camera"
#define VERSION "1.0"
#define AUTHOR "KORD_12.7, Koshak (Basic Code) and BG Rampo (Special Ability Effect Code)"


// Weapon settings
#define WEAPON_NAME 			"weapon_camera"
#define WEAPON_SLOT			4
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"SUPRISE!!!"
#define WEAPON_PRIMARY_AMMO_MAX		20
#define WEAPON_SECONDARY_AMMO		""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			2
#define WEAPON_DEFAULT_AMMO		2
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			10
#define WEAPON_DAMAGE_POISON		40.0
#define MAX_CONCUSSION_TIME		30

// redeemer Explosion
#define CASCADE_RADIUS			1000.0
#define CASCADE_DAMAGE			1000.0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_camera.txt"

// Ammobox
#define AMMOBOX_CLASSNAME		"ammo_camera"

// Models
#define MODEL_WORLD			"models/w_camera.mdl"
#define MODEL_VIEW			"models/v_camera.mdl"
#define MODEL_PLAYER			"models/p_camera.mdl"
#define MODEL_CLIP			"models/w_cameraclip.mdl"

#define CASCADE_WTF1			"debris/beamstart6.wav"
#define CASCADE_WTF2			"debris/beamstart7.wav"
#define CASCADE_WTF3			"debris/beamstart8.wav"
#define CASCADE_EXPLO			"weapons/bfg_fire.wav"
#define SOUND_RELOAD			"weapons/camera_reload.wav"

#define SPRITE_FLAME			"sprites/smoke_poison.spr"
#define SPRITE_POISON			"sprites/ef_smoke_poison.spr"

// Animation
#define ANIM_EXTENSION			"trip"

enum _:Animation
{
	ANIM_IDLE,
	ANIM_FIRE,
	ANIM_DRAW,
	ANIM_RELOAD
};

#define FBitSet(%0,%1)		( %0 & ( 1 << ( %1 - 1 ) ) )
#define SetBits(%0,%1)		( %0 |= ( 1 << ( %1 - 1 ) ) )
#define ClearBits(%0,%1)	( %0 &= ~( 1 << ( %1 - 1 ) ) )

#define CNAHGE_ANIM_EXT(%0,%1,%2) \
	wpnmod_set_anim_ext(%0, %1); \
	set_pev(%0, pev_weaponmodel2, %2)
	
#define Offset_iInZoom Offset_iuser1	

new spr_explode, cache_spr_line;
new ring,shockwave,flare,explode;
new g_screenfade;
new g_hasWpn[ 33 ], g_fire[ 33 ], g_callstrike[ 33 ];

#define MAX_CLUSTERS			1
#define MIN_FLY_DISTANCE 		1.0
#define MAX_FLY_DISTANCE		1.0
#define UPWARD_FORCE			1.0
#define CLUSTER_EXPLODE_TIME		0.1

new const CLASS_CLUSTER[ ]		= "poison_mist";

const DMG_AFTERBURN		= ( 1 << 28 );

#define MAX_CLIENTS		32

#define BURN_GIVE_ON_HIT	10.0
#define AFTERBURN_TIME		15
#define AFTERBURN_DAMAGE	10.0

enum _:eBurnData
{
	__BurnTime,
	Float:__NextBurn,
	__Attacker,
	__FlameDamage
};

new any:g_aBurnData[ MAX_CLIENTS + 1 ][ eBurnData ];
new g_bsKilledByGrenade, g_sModelIndexFlame, g_sModelIndexPoison;

// Null size
new const Float:gVecZero[ 3 ]		= { 0.0, 0.0, 0.0 };

#define FBitSet(%0,%1)		( %0 & ( 1 << ( %1 - 1 ) ) )
#define SetBits(%0,%1)		( %0 |= ( 1 << ( %1 - 1 ) ) )
#define ClearBits(%0,%1)	( %0 &= ~( 1 << ( %1 - 1 ) ) )	

//**********************************************
//* Precache resources                         *
//**********************************************

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_CLIP);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(CASCADE_WTF1);
	PRECACHE_SOUND(CASCADE_WTF2);
	PRECACHE_SOUND(CASCADE_WTF3);
	PRECACHE_SOUND(CASCADE_EXPLO);
	PRECACHE_SOUND(SOUND_RELOAD);

	PRECACHE_GENERIC(WEAPON_HUD_TXT);

	g_sModelIndexFlame = precache_model( SPRITE_FLAME );
	g_sModelIndexPoison = precache_model( SPRITE_POISON );

	precache_sound("weapons/camera_charge.wav");
	precache_sound("buttons/button11.wav");
 	precache_sound("ambience/jetflyby1.wav");
 	spr_explode = precache_model("sprites/fexplo.spr"); 
 	cache_spr_line = precache_model("sprites/laserbeam.spr");

	ring = 		PRECACHE_MODEL("sprites/smoke.spr");
	shockwave = 	PRECACHE_MODEL("sprites/shockwave.spr");
	flare = 	PRECACHE_MODEL("sprites/blueflare2.spr");
	explode = 	PRECACHE_MODEL("sprites/zerogxplode.spr");
}

//**********************************************
//* Register weapon.                           *
//**********************************************

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	new icamera = wpnmod_register_weapon
	
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
	
	new iAmmoLarge = wpnmod_register_ammobox(AMMOBOX_CLASSNAME);
	
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_Spawn, "camera_Spawn");
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_Deploy, "camera_Deploy");
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_Idle, "camera_Idle");
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_PrimaryAttack, "camera_PrimaryAttack");
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_Reload, "camera_Reload");
	wpnmod_register_weapon_forward(icamera, Fwd_Wpn_Holster, "camera_Holster");
	
	wpnmod_register_ammobox_forward(iAmmoLarge, Fwd_Ammo_Spawn, "AmmoLarge_Spawn");
	wpnmod_register_ammobox_forward(iAmmoLarge, Fwd_Ammo_AddAmmo, "AmmoLarge_AddAmmo");

	g_screenfade = get_user_msgid("ScreenFade");
	RegisterHam( Ham_Killed, "player", "player_dead");

	RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn", .Post = 1 );
	register_event( "ItemPickup", "EV_ItemPickup", "be", "1=item_healthkit" );
	RegisterHam( Ham_Player_PreThink, "player", "fw_PlayerPreThink", .Post = 0 );
	RegisterHam( Ham_TakeDamage, "player", "fw_PlayerTakeDamage", .Post = 0 );

	register_message( get_user_msgid( "DeathMsg" ), "fw_DeathMsg" );
}

public player_dead(id)
{
	if (g_hasWpn[id])
	{
		g_hasWpn[id] = 0;
		g_fire[id] = 0;
		g_callstrike[id] = 0;
	}
}

public client_putinserver( pPlayer )
{
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
}
public client_disconnect( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );
	
public EV_ItemPickup( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );

public fw_PlayerSpawn( pPlayer )
	arrayset( g_aBurnData[ pPlayer ], 0, eBurnData );

//**********************************************
//* Weapon spawn.                              *
//**********************************************

public camera_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

//**********************************************
//* Deploys the weapon.                        *
//**********************************************

public camera_Deploy(const iItem, const iPlayer, const iClip, ammo)
{
	g_hasWpn[iPlayer] = 1;
	if( wpnmod_get_offset_float( iItem, Offset_flNextPrimaryAttack ) > 0.0 && !g_fire[iPlayer] && !g_callstrike[iPlayer] )
	{
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.75);
	}
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

//**********************************************
//* Called when the weapon is holster.         *
//**********************************************

public camera_Holster(const iItem, const iPlayer, iClip)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
	g_hasWpn[iPlayer] = 0;
	if(g_fire[iPlayer])
	{
		g_fire[iPlayer] = 0;
		emit_sound(iPlayer, CHAN_AUTO, "buttons/button11.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		if (iClip < WEAPON_MAX_CLIP)
		{
			wpnmod_set_offset_int(iItem, Offset_iClip, iClip + 1);
		}
	}
}

//**********************************************
//* Displays the idle animation for the weapon.*
//**********************************************

public camera_Idle(const iItem, const iPlayer, const iClip)
{
	wpnmod_reset_empty_sound(iItem);
	
	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, ANIM_IDLE);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 15.0);
}

//**********************************************
//* The main attack of a weapon is triggered.  *
//**********************************************

public camera_PrimaryAttack(const iItem, const iPlayer, const iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 2.75);
		return;
	}
	
	wpnmod_set_offset_int(iItem, Offset_iClip, iClip - 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 20.75);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 20.75);
	
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
	wpnmod_send_weapon_anim(iItem, ANIM_FIRE);

	g_fire[iPlayer] = 1;
	
	wpnmod_set_think(iPlayer, "camera_Ready");
	set_pev(iPlayer, pev_nextthink, get_gametime() + 2.75);
}

public camera_Ready(const iPlayer)
{
	if (!is_user_alive(iPlayer) || !g_hasWpn[iPlayer])
	{
		return;
	}
	call_strike(iPlayer);
}

//**********************************************
//* Called when the weapon is reloaded.        *
//**********************************************

public camera_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, ANIM_RELOAD, 6.85);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, ATTN_NORM, 0, PITCH_NORM);

	wpnmod_set_think(iItem, "camera_CompleteReload");
	
	set_pev(iItem, pev_nextthink, get_gametime() + 4.85);
}

public camera_CompleteReload(const iItem, const iPlayer)
{
	wpnmod_send_weapon_anim(iItem, ANIM_DRAW);
}

//**********************************************
//* Ammobox spawn.                             *
//**********************************************

public AmmoLarge_Spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_CLIP);
}

//**********************************************
//* Extract ammo from box to player.           *
//**********************************************

public AmmoLarge_AddAmmo(const iItem, const iPlayer)
{
	new iResult = 
	(
		ExecuteHamB
		(
			Ham_GiveAmmo, 
			iPlayer, 
			4, 
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
public call_strike(id) 
{
       if (!is_user_alive(id) || !g_hasWpn[id] || !g_fire[id])
       {
	return;
       }

       g_fire[id] = 0;
       g_callstrike[id] = 1;

       static Float:origin[3];

       fm_get_aim_origin(id, origin);

       new bomb = create_entity("info_target")  ; 

       entity_set_string(bomb, EV_SZ_classname, "sunofgod"); // set name
       entity_set_edict(bomb, EV_ENT_owner, id); // set owner
       entity_set_origin(bomb, origin); // start posistion 
        
       line(origin);

       emit_sound(id,CHAN_AUTO, "weapons/camera_charge.wav", 1.0, ATTN_NORM, 0, PITCH_NORM); 

       set_task(5.0, "stop_siren");
       set_task(5.0+1.0, "jet_sound", id);
       set_task(5.0+1.1, "make_bomb", id);
       set_task(5.0+15.75, "reset", id);
}

public make_bomb(id)
{ 
	new ent = engfunc(EngFunc_FindEntityByString, -1, "classname", "sunofgod");
	if( ent <= 0) 
	{
		return;
	}

	new Float:origin[3];
	pev(ent,pev_origin,origin);

	GrenadeCluster( ent, origin, pev(ent,pev_owner), WEAPON_DAMAGE_POISON );
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord,origin[0]);
	engfunc(EngFunc_WriteCoord,origin[1]);
	engfunc(EngFunc_WriteCoord,origin[2]+12.0);
	write_short(explode);
	write_byte(120);
	write_byte(14);
	write_byte(TE_EXPLFLAG_NOSOUND);
	message_end();
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_LARGEFUNNEL);
	engfunc(EngFunc_WriteCoord,origin[0]);
	engfunc(EngFunc_WriteCoord,origin[1]);
	engfunc(EngFunc_WriteCoord,origin[2]);
	write_short(flare);
	write_short(1);
	message_end();

	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord,origin[0]);
	engfunc(EngFunc_WriteCoord,origin[1]);
	engfunc(EngFunc_WriteCoord,origin[2]);
	engfunc(EngFunc_WriteCoord,origin[0]);
	engfunc(EngFunc_WriteCoord,origin[1]);
	engfunc(EngFunc_WriteCoord,origin[2]+2000.0);
	write_short(ring);
	write_byte(0);
	write_byte(10);
	write_byte(3);
	write_byte(20);
	write_byte(2);
	write_byte(255);
	write_byte(255);
	write_byte(0);
	write_byte(255);
	write_byte(0);
	message_end();
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMTORUS);
	engfunc(EngFunc_WriteCoord,origin[0]);
	engfunc(EngFunc_WriteCoord,origin[1]);
	engfunc(EngFunc_WriteCoord,origin[2]-16+20);
	engfunc(EngFunc_WriteCoord,origin[0]+1400/3+400);
	engfunc(EngFunc_WriteCoord,origin[1]+1400/3+400);
	engfunc(EngFunc_WriteCoord,origin[2]+500);
	write_short(shockwave);
	write_byte(0);
	write_byte(0);
	write_byte(10);
	write_byte(120);
	write_byte(2);
	write_byte(255);
	write_byte(255);
	write_byte(0);
	write_byte(255);
	write_byte(0);
	message_end();
	
	wpnmod_radius_damage(origin,ent,pev(ent,pev_owner),CASCADE_DAMAGE,CASCADE_RADIUS,0,DMG_ENERGYBEAM|DMG_ALWAYSGIB);
	
	static id;
	
	static Float: beam_radius; beam_radius = 680.0;
	
	pev(ent,pev_origin,origin);
	
	while ((id = engfunc(EngFunc_FindEntityInSphere, id, origin, beam_radius))){
		if(pev(id,pev_takedamage)&&fm_is_ent_visible(id,ent))
			UTIL_ScreenFade(id,{255,255,0},0.5,0.1,205);
	}
	
	emit_sound(ent,CHAN_STATIC,CASCADE_WTF1,1.0,ATTN_NORM,0,PITCH_NORM);
	emit_sound(ent,CHAN_STATIC,CASCADE_WTF2,1.0,ATTN_NORM,0,PITCH_HIGH);
	emit_sound(ent,CHAN_STATIC,CASCADE_WTF3,1.0,ATTN_NORM,0,PITCH_LOW);
	emit_sound(ent,CHAN_STATIC,CASCADE_EXPLO,1.0,ATTN_NORM,0,PITCH_NORM);
	
	engfunc(EngFunc_RemoveEntity,ent);
}
  
public stop_siren()
{

 client_cmd(0,"stopsound"); // stops sound on all clients 

}

public jet_sound(id)
{

 emit_sound(id,CHAN_AUTO, "ambience/jetflyby1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

}

public removebomb(id)
{

   new ent = find_ent_by_class(-1,"sunofgod");
   remove_entity(ent);

}

public reset(id)
{

   g_callstrike[id] = 0;

}

public line(const Float:origin[3])
{
       engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
       write_byte(TE_BEAMPOINTS);	// temp entity event
       engfunc(EngFunc_WriteCoord, origin[0]); // x
       engfunc(EngFunc_WriteCoord, origin[1]); // y
       engfunc(EngFunc_WriteCoord, origin[2]); // z
       engfunc(EngFunc_WriteCoord, origin[0]); // x axis
       engfunc(EngFunc_WriteCoord, origin[1]); // y axis
       engfunc(EngFunc_WriteCoord, origin[2]+36.0); // z axis
       write_short(cache_spr_line);	// sprite index
       write_byte(0);			// start frame
       write_byte(0);			// framerate
       write_byte(60);			// life in 0.1's
       write_byte(15);			// line width in 0.1's
       write_byte(0);			// noise amplitude in 0.01's
       write_byte(200);		        // color: red
       write_byte(0);		        // color: green
       write_byte(0);		        // color: blue
       write_byte(200);			// brightness
       write_byte(0);			// scroll speed in 0.1's
       message_end(); 
 
}

public CRT_explosion(const Float:origin[3])
{

   new vec1[3];
   vec1[0] = floatround(origin[0]);
   vec1[1] = floatround(origin[1]);
   vec1[2] = floatround(origin[2]); 


   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0]); 
   write_coord(vec1[1]); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end(); 

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0] + 250); 
   write_coord(vec1[1] + 250); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0] -250); 
   write_coord(vec1[1] -250); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0] +250); 
   write_coord(vec1[1]); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0] -250); 
   write_coord(vec1[1]); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 );
   write_coord(vec1[0]); 
   write_coord(vec1[1] +250); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0]); 
   write_coord(vec1[1] - 250); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
   write_byte( 3 ); 
   write_coord(vec1[0] +250); 
   write_coord(vec1[1] -250); 
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 );  
   message_end();

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1);
   write_byte( 3 ); 
   write_coord(vec1[0] -250); 
   write_coord(vec1[1] +250);
   write_coord(vec1[2] + 20);
   write_short( spr_explode ); 
   write_byte( 50 ); 
   write_byte( 10 );
   write_byte( 0 ); 
   message_end();

}
stock shake_screen(id)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, id);
	write_short(255<< 14 ); //ammount 
	write_short(10 << 14); //lasts this long 
	write_short(255<< 14); //frequency 
	message_end();	
}
stock UTIL_ScreenFade(id=0,iColor[3]={0,0,0},Float:flFxTime=-1.0,Float:flHoldTime=0.0,iAlpha=0,iFlags=0x0000,bool:bReliable=false,bool:bExternal=false)
{
	if(id&&!is_user_connected(id))
		return;

	new iFadeTime;
	if(flFxTime==-1.0)
		iFadeTime = 4;
	else
		iFadeTime = FixedUnsigned16(flFxTime,1<<12);


	new MSG_DEST;
	if(bReliable)
		MSG_DEST = id ? MSG_ONE : MSG_ALL;
	else
		MSG_DEST = id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST;

	if(bExternal){
		emessage_begin(MSG_DEST,g_screenfade, _,id);
		ewrite_short(iFadeTime);
		ewrite_short(FixedUnsigned16(flHoldTime,1<<12 ));
		ewrite_short(iFlags);
		ewrite_byte(iColor[0]);
		ewrite_byte(iColor[1]);
		ewrite_byte(iColor[2]);
		ewrite_byte(iAlpha);
		emessage_end();
	}
	else{
		message_begin(MSG_DEST,g_screenfade,_, id);
		write_short(iFadeTime);
		write_short(FixedUnsigned16(flHoldTime,1<<12 ));
		write_short(iFlags);
		write_byte(iColor[0]);
		write_byte(iColor[1]);
		write_byte(iColor[2]);
		write_byte(iAlpha);
		message_end();
	}
}

stock FixedUnsigned16(Float:flValue, iScale)
{
	new iOutput;

	iOutput = floatround(flValue * iScale);

	if ( iOutput < 0 )
		iOutput = 0;

	if ( iOutput > 0xFFFF )
		iOutput = 0xFFFF;

	return iOutput;
}

GrenadeCluster( pGrenade, Float:vecSrc[ 3 ], pevOwner, Float:flDmg )
{
	new pEntity, Float:tTime, Float:vecVelocity[ 3 ], Float:RVelocity[ 3 ], Float:flDistance;
	new Float:actualDistance, Float:flMulti;
	tTime = get_gametime( );
	
	for( new i = 0; i < MAX_CLUSTERS; i++ )
	{
		pEntity = create_entity( "info_target" );
		
		if( !pEntity )
			continue;
			
		vecVelocity[ 0 ] = random_float( MIN_FLY_DISTANCE, MAX_FLY_DISTANCE );
		
		if( random_num( 0, 1 ) )
			vecVelocity[ 0 ] = floatmul( vecVelocity[ 1 ], -1.0 );
		
		vecVelocity[ 1 ] = random_float( MIN_FLY_DISTANCE, MAX_FLY_DISTANCE );
		
		if( random_num( 0, 1 ) )
			vecVelocity[ 1 ] = floatmul( vecVelocity[ 1 ], -1.0 );
		
		vecVelocity[ 2 ] = UPWARD_FORCE;
		
		RVelocity[ 0 ] = vecSrc[ 0 ] + vecVelocity[ 0 ];
		RVelocity[ 1 ] = vecSrc[ 1 ] + vecVelocity[ 1 ];
		RVelocity[ 2 ] = vecSrc[ 2 ] + vecVelocity[ 2 ];
		
		flDistance = random_float( MIN_FLY_DISTANCE, MAX_FLY_DISTANCE );
		actualDistance = get_distance_f( vecSrc, RVelocity );
		flMulti = floatdiv( flDistance, actualDistance );
		
		vecVelocity[ 0 ] = floatmul( vecVelocity[ 0 ], flMulti );
		vecVelocity[ 1 ] = floatmul( vecVelocity[ 1 ], flMulti );
		vecVelocity[ 2 ] = floatmul( vecVelocity[ 2 ], flMulti );
			
		entity_set_string( pEntity, EV_SZ_classname, CLASS_CLUSTER ); 
		entity_set_size( pEntity, gVecZero, gVecZero );
		entity_set_origin( pEntity, vecSrc );
		entity_set_int( pEntity, EV_INT_movetype, MOVETYPE_TOSS );
		entity_set_int( pEntity, EV_INT_solid, SOLID_TRIGGER );
		entity_set_edict( pEntity, EV_ENT_owner, pevOwner );
		entity_set_vector( pEntity, EV_VEC_velocity, vecVelocity );
		entity_set_float( pEntity, EV_FL_dmgtime, tTime + CLUSTER_EXPLODE_TIME );
		entity_set_float( pEntity, EV_FL_nextthink, tTime + 0.1 );
		entity_set_float( pEntity, EV_FL_dmg, flDmg );
		entity_set_float( pEntity, EV_FL_fuser1, entity_get_float( pGrenade, EV_FL_fuser1 ) );
		
		wpnmod_set_think( pEntity, "fw_ClusterThink" );
		wpnmod_set_touch( pEntity, "fw_ClusterTouch" );
	}
}

public fw_ClusterThink( pCluster )
{
	if( !is_valid_ent( pCluster ) )
		return;
		
	if( !IsInWorld( pCluster ) )
	{
		remove_entity( pCluster );
		return;
	}
	
	static Float:tTime;
	tTime = get_gametime( );
	
	if( entity_get_float( pCluster, EV_FL_dmgtime ) <= tTime )
	{
		static Float:vecSrc[ 3 ];
		entity_get_vector( pCluster, EV_VEC_origin, vecSrc );
		
		GT_OnPoisonExplode( pCluster );
		return;
	}
	
	entity_set_float( pCluster, EV_FL_nextthink, tTime + 0.3 );
}

public fw_ClusterTouch( pCluster, pOther )
{
	if( !is_valid_ent( pCluster ) )
		return;
		
	if( is_valid_ent( pOther ) )
	{
		static strClassName[ 32 ];
		entity_get_string( pOther, EV_SZ_classname, strClassName, charsmax( strClassName ) );
		
		if( equal( strClassName, CLASS_CLUSTER ) )
			return;
	}
	
	static Float:vecTestVelocity[ 3 ];
	entity_get_vector( pCluster, EV_VEC_velocity, vecTestVelocity );
	vecTestVelocity[ 2 ] *= 0.45;
	
	if( entity_get_int( pCluster, EV_INT_flags ) & FL_ONGROUND )
	{
		xs_vec_mul_scalar( vecTestVelocity, 0.8, vecTestVelocity );
	}
	
	entity_set_vector( pCluster, EV_VEC_velocity, vecTestVelocity );
	
	static Float:flFrameRate;
	flFrameRate = xs_vec_len( vecTestVelocity ) / 200.0;
	
	if( flFrameRate > 1.0 )
		flFrameRate = 1.0;
	else if( flFrameRate < 0.5 )
		flFrameRate = 0.0;
		
	entity_set_float( pCluster, EV_FL_framerate, flFrameRate );
}

public fw_PlayerPreThink( pPlayer )
{
	if( g_aBurnData[ pPlayer ][ __BurnTime ] <= 0 )
	{
		return;
	}
		
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
	write_short( g_sModelIndexFlame );
	write_byte( 5 );
	write_byte( 200 );
	message_end( );
	
	SetBits( g_bsKilledByGrenade, pPlayer );
	ExecuteHamB( Ham_TakeDamage, pPlayer, g_aBurnData[ pPlayer ][ __Attacker ], g_aBurnData[ pPlayer ][ __Attacker ], AFTERBURN_DAMAGE, DMG_POISON );
	ClearBits( g_bsKilledByGrenade, pPlayer );
	
	g_aBurnData[ pPlayer ][ __BurnTime ]--;
	g_aBurnData[ pPlayer ][ __NextBurn ] = tTime + 1.0;
}

public fw_PlayerTakeDamage( pevVictim, pevInflictor, pevAttacker, Float:flDamage, bitDamageType )
{
	if( !pevAttacker || !is_user_connected( pevAttacker ) )
		return HAM_IGNORED;
	
	static strClass[ 32 ];
	entity_get_string( pevInflictor, EV_SZ_classname, strClass, charsmax( strClass ) );
	
	if( equal( strClass, CLASS_CLUSTER ) )
	{
		if( g_aBurnData[ pevVictim ][ __BurnTime ] >= AFTERBURN_TIME )
			return HAM_IGNORED;
			
		client_print( pevVictim, print_center, "* You are on poison mist *" );	
			
		g_aBurnData[ pevVictim ][ __NextBurn ] = get_gametime( ) + 1.0;
		g_aBurnData[ pevVictim ][ __BurnTime ] += BURN_GIVE_ON_HIT;
		g_aBurnData[ pevVictim ][ __Attacker ] = pevAttacker;
	}
	return HAM_IGNORED;
}

public fw_DeathMsg( msgId, msgDest, iReceiver )
{	
	//fix stupid message like playername killed himself with crowbar.
	//this happens when switch on other weapon while victim is burning.
	//this fix is temporar.Should be find better way!!!
	if( FBitSet( g_bsKilledByGrenade, get_msg_arg_int( 2 ) ) )
		set_msg_arg_string( 3, CLASS_CLUSTER );
}

public GT_OnPoisonExplode( pGrenade )
{
	if( !pev_valid( pGrenade ) )
		return;

	new Float:vecSrc[ 3 ], Float:tTime;
	entity_get_vector( pGrenade, EV_VEC_origin, vecSrc );
	tTime = get_gametime( );
	
	entity_set_int( pGrenade, EV_INT_iuser4, MAX_CONCUSSION_TIME );
	entity_set_float( pGrenade, EV_FL_dmgtime, tTime + 0.1 );
	entity_set_float( pGrenade, EV_FL_nextthink, tTime + 0.5 );
	wpnmod_set_think( pGrenade, "fw_GrenadePoisonThink" );
	wpnmod_radius_damage( vecSrc, pGrenade, pev(pGrenade, pev_owner), BURN_GIVE_ON_HIT, 300.0, CLASS_MACHINE, DMG_POISON );
}

public fw_GrenadePoisonThink( pGrenade )
{
	if( !is_valid_ent( pGrenade ) )
		return;
		
	static Float:tTime, iCount;
	tTime = get_gametime( );
	iCount = entity_get_int( pGrenade, EV_INT_iuser4 );
	
	if( iCount <= 0 )
	{
		remove_entity( pGrenade );
		return;
	}
	
	if( tTime >= entity_get_float( pGrenade, EV_FL_dmgtime ) )
	{
		iCount--;
		entity_set_int( pGrenade, EV_INT_iuser4, iCount );
		
		static Float:vecSrc[ 3 ];
		entity_get_vector( pGrenade, EV_VEC_origin, vecSrc );
	
		engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 );
		write_byte( TE_SPRITE );
		engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
		engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
		engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
		write_short( g_sModelIndexPoison );
		write_byte( 60 );
		write_byte( 50 );
		message_end( );

		wpnmod_radius_damage( vecSrc, pGrenade, entity_get_edict( pGrenade, EV_ENT_owner ), AFTERBURN_DAMAGE, 300.0, CLASS_MACHINE, DMG_POISON );
		
		entity_set_float( pGrenade, EV_FL_dmgtime, tTime + 0.1 );
	}
	
	entity_set_float( pGrenade, EV_FL_nextthink, tTime + 0.80 );	
}
