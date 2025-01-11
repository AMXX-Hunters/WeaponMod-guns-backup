#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta_util>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#pragma semicolon 1
#pragma ctrlchar  '\'

#define PLUGIN "TNT"
#define VERSION "9.11"
#define AUTHOR "POLIGON RPG hldm server"

//Configs
#define WEAPON_NAME "weapon_TNT"
#define WEAPON_SLOT	5
#define WEAPON_POSITION	1
#define WEAPON_PRIMARY_AMMO	"TNT"
#define WEAPON_PRIMARY_AMMO_MAX	3
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP	1
#define WEAPON_DEFAULT_AMMO	 1
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	20
#define WEAPON_RADIUS   450
#define WEAPON_RADIUS2   800
#define WEAPON_DAMAGE	450.0

// Models
#define MODEL_WORLD	"models/w_bomb.mdl"
#define MODEL_VIEW	"models/v_bomb.mdl"
#define MODEL_PLAYER	"models/p_bomb.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_TNT.txt"
#define WEAPON_HUD_SPR  "sprites/weapon_TNT.spr"
#define SPRITE_SMO     "sprites/ballsmoke.spr"
#define SPRITE_EXPLO     "sprites/redeemer_explo.spr"
#define SPRITE_TOR     "sprites/zbeam4.spr"

// Sounds
#define SOUND_FIRE	"fvox/activated.wav"
#define SOUND_IDLE 	"bomb/explosion.wav"
#define SOUND_HALP 	"hgrunt/gr_pain5.wav"

#define SOUND_DEPLOY "common/menu3.wav"

new all_num;
new decal;
new all[32];
new Killer;
new g_iModelIndexExplo;
new g_iModelIndexSmoke;
new g_iModelIndexWave;
// Animation
#define ANIM_EXTENSION	"crossbow"
enum _:cz_VUL
{
	idle1,
	idle1,
	draw,
	drop
}; 
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_IDLE);
	PRECACHE_SOUND(SOUND_DEPLOY);
        PRECACHE_SOUND(SOUND_HALP);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	g_iModelIndexExplo = PRECACHE_MODEL(SPRITE_EXPLO);
        g_iModelIndexSmoke = PRECACHE_MODEL(SPRITE_SMO);
        g_iModelIndexWave = PRECACHE_MODEL(SPRITE_TOR);
}
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new TNT = wpnmod_register_weapon
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
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_Spawn, 		"TNT_Spawn" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_Deploy, 		"TNT_Deploy" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_Idle, 		"TNT_Idle" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_PrimaryAttack,	"TNT_PrimaryAttack" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_SecondaryAttack,	"TNT_SecondaryAttack" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_Reload, 		"TNT_Reload" );
	wpnmod_register_weapon_forward(TNT, Fwd_Wpn_Holster, 		"TNT_Holster" );
	
}

public TNT_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public TNT_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.2);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.2);	
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public TNT_Holster(const iItem ,iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
public TNT_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	wpnmod_send_weapon_anim(iItem, idle1 );
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 6.0);
}
public TNT_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	emit_sound(0, CHAN_WEAPON, SOUND_DEPLOY, 0.9, ATTN_NORM, 0, PITCH_NORM);
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, draw, 1.0);
	
}

public TNT_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	new fOrigin[3];
	get_user_origin(iPlayer ,fOrigin ,3);
	new PlOrg[3];
	get_user_origin(iPlayer ,PlOrg);
	if(get_distance(PlOrg ,fOrigin) < 150)
	{
			if ( iClip <= 0)
			{
				wpnmod_play_empty_sound(iItem);
				wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
				return;
			}
			wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
			wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
			
			wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
						
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, 1.5, 0, PITCH_NORM);
                        wpnmod_send_weapon_anim(iItem, drop );
			
			new iBomb = create_entity("info_target");
			new Float:fOrigiN[3];
			fm_get_aim_origin(iPlayer ,fOrigiN);
			set_pev(iBomb, pev_origin, fOrigiN); 
			set_pev(iBomb, pev_classname, "bomb"); 
			set_pev(iBomb, pev_solid, SOLID_NOT);
			set_pev(iBomb, pev_movetype, MOVETYPE_NONE); 
			//set_pev(iBomb, pev_sequence, 0); 
			//set_pev(iBomb, pev_framerate, 1.0); 
		 
			engfunc(EngFunc_SetModel, iBomb, MODEL_WORLD);//Присваиваем модель
			engfunc(EngFunc_SetSize, iBomb, Float:{-24.0, -24.0, -24.0}, Float:{24.0, 24.0, 24.0});
				
			drop_to_floor(iBomb);
				
				
			Killer = iPlayer;
			set_task(13.0, "BOOM" ,iBomb);
			

	
	}
}

public BOOM(taskid)
{
        decal = engfunc(EngFunc_DecalIndex, "{SCORCH1");
	static Float: b_ORG[3];
	pev(taskid ,pev_origin ,b_ORG);
	
	wpnmod_radius_damage2(b_ORG, taskid, Killer, WEAPON_DAMAGE, WEAPON_DAMAGE * 2.0, CLASS_NONE, DMG_BLAST);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION); // Temporary entity ID
	engfunc(EngFunc_WriteCoord, b_ORG[0]); // engfunc because float
	engfunc(EngFunc_WriteCoord, b_ORG[1]);
	engfunc(EngFunc_WriteCoord, b_ORG[2]);
	write_short(g_iModelIndexExplo); // Sprite index
	write_byte(40) ;// Scale
	write_byte(40); // Framerate
	write_byte(4); // Flags
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION); // Temporary entity ID
	engfunc(EngFunc_WriteCoord, b_ORG[0]); // engfunc because float
	engfunc(EngFunc_WriteCoord, b_ORG[1]);
	engfunc(EngFunc_WriteCoord, b_ORG[2]);
	write_short(g_iModelIndexSmoke); // Sprite index
	write_byte(130) ;// Scale
	write_byte(2); // Framerate
	write_byte(4); // Flags
	message_end();

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_BEAMCYLINDER);
        engfunc(EngFunc_WriteCoord, b_ORG[0]);
        engfunc(EngFunc_WriteCoord, b_ORG[1]);
        engfunc(EngFunc_WriteCoord, b_ORG[2]);
        engfunc(EngFunc_WriteCoord, b_ORG[0]);
        engfunc(EngFunc_WriteCoord, b_ORG[1]);
        engfunc(EngFunc_WriteCoord, b_ORG[2] + 16.0 + 500 * 2);
        write_short(g_iModelIndexWave); // Индекс спрайта из прекеша (index of precached sprite)
        write_byte(1);
        write_byte(10); // 0.1's
        write_byte(15); // 0.1's
        write_byte(140);
        write_byte(0); // 0.01's
        write_byte(255);
        write_byte(0);
        write_byte(0);
        write_byte(160);
        write_byte(1); // 0.1's
        message_end();

        message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
        write_byte(TE_WORLDDECAL);
        engfunc(EngFunc_WriteCoord, b_ORG[0]);
        engfunc(EngFunc_WriteCoord, b_ORG[1]);
        engfunc(EngFunc_WriteCoord, b_ORG[2]);
        write_byte(decal);
        message_end();

	emit_sound(0, CHAN_WEAPON, SOUND_IDLE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	set_pev(taskid, pev_flags, FL_KILLME);

        get_players(all,all_num,"c"); 
        for (new i=0;i<all_num;i++)
        {
                new gmsgShake = get_user_msgid("ScreenShake");
                message_begin(MSG_ONE, gmsgShake, {0,0,0}, all[i]);
                write_short(255<< 12); //ammount 
                write_short(10 << 9); //lasts this long 
                write_short(255<< 9);//frequency 
                message_end();
        }

}

public TNT_SecondaryAttack(const iItem, const iPlayer)
{
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.5);
	new Float:youOrigin[3];
	pev(iPlayer ,pev_origin ,youOrigin);
	
	wpnmod_radius_damage2(youOrigin, iItem, iPlayer, WEAPON_DAMAGE, WEAPON_DAMAGE * 1.0, CLASS_NONE, DMG_BLAST);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION); // Temporary entity ID
	engfunc(EngFunc_WriteCoord, youOrigin[0]); // engfunc because float
	engfunc(EngFunc_WriteCoord, youOrigin[1]);
	engfunc(EngFunc_WriteCoord, youOrigin[2]);
	write_short(g_iModelIndexExplo); // Sprite index
	write_byte(40) ;// Scale
	write_byte(50); // Framerate
	write_byte(4); // Flags
	message_end();

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_LAVASPLASH);
        engfunc(EngFunc_WriteCoord, youOrigin[0]);
        engfunc(EngFunc_WriteCoord, youOrigin[1]);
        engfunc(EngFunc_WriteCoord, youOrigin[2]);
        message_end();

	emit_sound(0, CHAN_WEAPON, SOUND_IDLE, 0.9, ATTN_NORM, 0, PITCH_NORM);
        emit_sound(iPlayer, CHAN_ITEM, SOUND_HALP, 0.9, 0.6, 0, PITCH_NORM);

        get_players(all,all_num,"c"); 
        for (new i=0;i<all_num;i++)
        {
                new gmsgShake = get_user_msgid("ScreenShake");
                message_begin(MSG_ONE, gmsgShake, {0,0,0}, all[i]);
                write_short(255<< 12); //ammount 
                write_short(10 << 9); //lasts this long 
                write_short(255<< 9);//frequency 
                message_end();
        }

}
