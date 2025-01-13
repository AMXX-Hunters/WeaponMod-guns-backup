#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>

#pragma semicolon 1
#pragma ctrlchar  '\'


#define PLUGIN "Weapon : Destroyer"
#define VERSION "2.0.3"
#define AUTHOR "BIGs"

//Configs
#define WEAPON_NAME "weapon_destroyer"
#define WEAPON_SLOT	4
#define WEAPON_POSITION	5
#define WEAPON_PRIMARY_AMMO	"50BMG"
#define WEAPON_PRIMARY_AMMO_MAX	30
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	0
#define WEAPON_MAX_CLIP	10
#define WEAPON_DEFAULT_AMMO	 30
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	35
#define WEAPON_DAMAGE	200.0

// Models
#define MODEL_WORLD	"models/w_destroyer.mdl"
#define MODEL_VIEW	"models/v_destroyer_hev.mdl"
#define MODEL_PLAYER	"models/p_destroyer.mdl"

// Hud
#define WEAPON_HUD_TXT	"sprites/weapon_destroyer.txt"
#define WEAPON_HUD_BAR	"sprites/640hud141.spr"
#define WEAPON_HUD_AMMO	"sprites/weapon_destroyer_scp.txt"
#define WEAPON_HUD_SCP	"sprites/destroyer_scope.spr"


// Sounds
#define SOUND_FIRE	"weapons/destroyer-1.wav"
#define SOUND_RELOAD	"weapons/destroyer_clipout.wav"
#define SOUND_DEPLOY "weapons/destroyer_draw.wav"
#define SOUND_CHANGE "weapons/sfsniper_insight1.wav"
#define SOUND_1 "weapons/destroyer_clipin.wav"


// Animation
#define ANIM_EXTENSION	"crossbow"
new aOrigin[3];
new sTrail;

new g_iSpiteExlplosion;

enum _:cz_VUL
{
	idle1,
	shoot1,
	shoot2,
	reload,
	draw
}; 

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new dest50 = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_Spawn, 		"D50_Spawn" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_Deploy, 		"D50_Deploy" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_Idle, 		"D50_Idle" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_PrimaryAttack,	"D50_PrimaryAttack" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_SecondaryAttack,	"D50_SecondaryAttack" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_Reload, 		"D50_Reload" );
	wpnmod_register_weapon_forward(dest50, Fwd_Wpn_Holster, 		"D50_Holster" );
	
}
public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_RELOAD);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_CHANGE);
	PRECACHE_SOUND(SOUND_DEPLOY);
	PRECACHE_SOUND(SOUND_1);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_BAR);
	PRECACHE_GENERIC(WEAPON_HUD_SCP);
	PRECACHE_GENERIC(WEAPON_HUD_AMMO);
	sTrail = precache_model("sprites/zbeam5.spr");
	g_iSpiteExlplosion = precache_model("sprites/dexplo.spr");
}
public D50_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
public D50_Deploy(const iItem, const iPlayer, const iClip)
{
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.0);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);

	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, draw, ANIM_EXTENSION);
}
public D50_Holster(const iItem , iPlayer)
{
	// Cancel any reload in progress.
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
	new Float: flFov;
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		D50_SecondaryAttack(iItem, iPlayer);
	}
}

public D50_Idle(const iItem)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}

	wpnmod_send_weapon_anim(iItem, idle1);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 4.0);
}

public D50_Reload(const iItem, const iPlayer, const iClip, const iAmmo)
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	wpnmod_default_reload(iItem, WEAPON_MAX_CLIP, reload, 3.2);
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, ATTN_NORM, 0, PITCH_NORM);
}
public D50_PrimaryAttack(const iItem, const iPlayer, iClip)
{
		if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
		{
			wpnmod_play_empty_sound(iItem);
			wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
			return;
		}
		
		wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
		wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
		
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.83);
		wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 1.0);
		
		wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
		wpnmod_send_weapon_anim(iItem, random_num(shoot1 , shoot2));
		
		wpnmod_fire_bullets
		(
			iPlayer, 
			iPlayer, 
			1, 
			Float: {0.0001, 0.0001, 0.0001},
			8192.0, 
			WEAPON_DAMAGE, 
			DMG_BULLET, 
			1
		);
				
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
		
		set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
		set_pev(iPlayer, pev_punchangle, Float: {-4.0, 0.0, 0.0});
		
		get_user_origin(iPlayer,aOrigin ,3);
		
		buff_special(iPlayer);
		
		new Float:AimOr[3];
		fm_get_aim_origin(iPlayer , AimOr);
		
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		write_coord(AimOr[0]);
		write_coord(AimOr[1]);
		write_coord(AimOr[2]);
		write_short(g_iSpiteExlplosion);
		write_byte(10);
		write_byte(10);
		write_byte(0);
		message_end();
}
public D50_SecondaryAttack(const iItem, const iPlayer)
{
	new Float: flFov;
	
	if (pev(iPlayer, pev_fov, flFov) && flFov != 0.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_destroyer", 0.0);
		
	}
	else if (flFov != 20.0)
	{
		MakeZoom(iItem, iPlayer, "weapon_destroyer_scp", 20.0);
	}
	
	emit_sound(iPlayer, CHAN_ITEM, SOUND_CHANGE, random_float(0.95, 1.0), ATTN_NORM, 0, PITCH_NORM);
	
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.1);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.8);
}
MakeZoom(const iItem, const iPlayer, const szWeaponName[], const Float: flFov)
{
	static msgWeaponList;
	
	set_pev(iPlayer, pev_fov, flFov);
	wpnmod_set_offset_int(iPlayer, Offset_iFOV, _:flFov);
		
	if (msgWeaponList || (msgWeaponList = get_user_msgid("WeaponList")))		
	{
		message_begin(MSG_ONE, msgWeaponList, .player = iPlayer);
		write_string(szWeaponName);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iPrimaryAmmoType));
		write_byte(WEAPON_PRIMARY_AMMO_MAX);
		write_byte(wpnmod_get_offset_int(iItem, Offset_iSecondaryAmmoType));
		write_byte(WEAPON_SECONDARY_AMMO_MAX);
		write_byte(WEAPON_SLOT - 1);
		write_byte(WEAPON_POSITION - 1);
		write_byte(get_user_weapon(iPlayer));
		write_byte(WEAPON_FLAGS);
		message_end();
	}
}
public buff_special(id)
{
	new Float:flAim[3];
	fm_get_aim_origin(id, flAim);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMENTPOINT);
	write_short(id | 0x1000);
	engfunc(EngFunc_WriteCoord, flAim[0]);
	engfunc(EngFunc_WriteCoord, flAim[1]);
	engfunc(EngFunc_WriteCoord, flAim[2]);
	write_short(sTrail);
	write_byte(0); // framerate
	write_byte(0); // framerate
	write_byte(2); // life
	write_byte(10);  // width
	write_byte(0);// noise
	write_byte(255);// r, g, b
	write_byte(255);// r, g, b
	write_byte(255);// r, g, b
	write_byte(255);	// brightness
	write_byte(200);	// speed
	message_end();
}
