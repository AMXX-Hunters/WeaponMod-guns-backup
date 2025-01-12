#include <amxmodx>
#include <fakemeta_util>
#include <hl_wpnmod>

// Weapon settings
#define WEAPON_NAME 			"weapon_ac"
#define WEAPON_SLOT			5
#define WEAPON_POSITION			5
#define WEAPON_PRIMARY_AMMO		"9mm"
#define WEAPON_PRIMARY_AMMO_MAX		250
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		50
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			34
#define WEAPON_DAMAGE			10.0

// Models
#define MODEL_WORLD			"models/w_tfac.mdl"
#define MODEL_VIEW			"models/v_tfac.mdl"
#define MODEL_PLAYER			"models/p_tfac.mdl"
#define MODEL_SHELL			"models/shell.mdl"

// Sounds
#define SOUND_SPINUP			"weapons/asscan1.wav"
#define SOUND_FIRE			"weapons/asscan2.wav"
#define SOUND_SPINDOWN			"weapons/asscan3.wav"
#define SOUND_SPIN			"weapons/asscan4.wav"

// Animation
#define ANIM_EXTENSION			"egon"

new Float:ms,shell

enum _:anima{
	IDLE,
	IDLE2,
	SPINUP,
	SPINDOWN,
	FIRE,
	DRAW,
	HOLSTER
}

public plugin_precache(){
	PRECACHE_MODEL(MODEL_WORLD)
	PRECACHE_MODEL(MODEL_VIEW)
	PRECACHE_MODEL(MODEL_PLAYER)
	
	PRECACHE_SOUND(SOUND_SPINUP)
	PRECACHE_SOUND(SOUND_FIRE)
	PRECACHE_SOUND(SOUND_SPINDOWN)
	PRECACHE_SOUND(SOUND_SPIN)
	
	shell = PRECACHE_MODEL(MODEL_SHELL)
	
	PRECACHE_GENERIC("sprites/weapon_ac.spr")
	PRECACHE_GENERIC("sprites/weapon_ac.txt")
}


public plugin_init() {
	register_plugin("Assault Cannon","0.1","[LF] | Dr.Freeman")
	
	new ac = wpnmod_register_weapon(
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
	)
	
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_Deploy,"fw_AcDeploy")
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_Holster,"fw_AcHolster")
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_PrimaryAttack,"fw_AcPrimary")
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_SecondaryAttack,"fw_AcSecondary")
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_Idle,"fw_AcIdle")
	wpnmod_register_weapon_forward(ac,Fwd_Wpn_Spawn,"fw_AcSpawn")
}

public plugin_cfg(){
	ms = get_cvar_float("sv_maxspeed")
}

public fw_AcDeploy(ent,player){
	return wpnmod_default_deploy(ent,MODEL_VIEW,MODEL_PLAYER,DRAW,ANIM_EXTENSION)
}

public fw_AcPrimary(ent,player,clip,ammo){
	new Float:spintime = wpnmod_get_offset_float(ent,Offset_flStartThrow)
	
	if(ammo<=0){
		if(spintime){
			emit_sound(player,CHAN_WEAPON,SOUND_SPINDOWN,0.9,ATTN_NORM,0,PITCH_NORM)
			fm_set_user_maxspeed(player,ms)
			wpnmod_send_weapon_anim(ent,SPINDOWN)
		
			spintime=0.0
		
			wpnmod_set_offset_float(ent,Offset_flStartThrow,spintime)
		}
			
		wpnmod_play_empty_sound(ent)
		wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.15)
		
		return
	}
	
	fm_set_user_maxspeed(player,115.0)
	
	if(!spintime)
		emit_sound(player,CHAN_WEAPON,SOUND_SPINUP,0.9,ATTN_NORM,0,PITCH_NORM)
	
	if(spintime<=0.0){
		wpnmod_send_weapon_anim(ent,SPINUP)
		spintime+=0.1
	}else if(spintime<=0.4){
		spintime+=0.1
	}else if(spintime>0.4){
		fm_set_user_maxspeed(player,54.0)
		emit_sound(player,CHAN_WEAPON,SOUND_FIRE,0.9,ATTN_NORM,0,PITCH_NORM)
		
		wpnmod_send_weapon_anim(ent,FIRE)
		wpnmod_set_player_anim(player,PLAYER_ATTACK1)
		
		wpnmod_set_offset_int(player,Offset_iWeaponVolume,LOUD_GUN_VOLUME)
		wpnmod_set_offset_int(player,Offset_iWeaponFlash,BRIGHT_GUN_FLASH)
		
		wpnmod_eject_brass(player,shell,TE_BOUNCE_SHELL,16.0,-18.0,6.0)
		wpnmod_eject_brass(player,shell,TE_BOUNCE_SHELL,16.0,-18.0,6.0)
		wpnmod_fire_bullets(player,player,7,VECTOR_CONE_15DEGREES,4096.0,WEAPON_DAMAGE,DMG_BULLET,7)
		
		wpnmod_set_player_ammo(player,WEAPON_PRIMARY_AMMO,ammo-2)
	}
	
	wpnmod_set_offset_float(ent,Offset_flStartThrow,spintime)
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.1)
	wpnmod_set_offset_float(ent,Offset_flNextSecondaryAttack,0.2)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,0.1)
}

public fw_AcSecondary(ent,player,clip,ammo){
	new Float:spintime = wpnmod_get_offset_float(ent,Offset_flStartThrow)
	
	if(ammo<=0){
		if(spintime)
			wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,0.1)
			
		wpnmod_play_empty_sound(ent)
		wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.15)
		
		return
	}
	
	fm_set_user_maxspeed(player,115.0)
	
	if(spintime==0.4)
		wpnmod_send_weapon_anim(ent,FIRE)
	
	
	if(!spintime)
		emit_sound(player,CHAN_WEAPON,SOUND_SPINUP,0.9,ATTN_NORM,0,PITCH_NORM)
	
	if(spintime<=0.0){
		wpnmod_send_weapon_anim(ent,SPINUP)
		spintime+=0.1
	}else if(spintime<=0.4){
		spintime+=0.1
	}else if(spintime>0.4){
		emit_sound(player,CHAN_WEAPON,SOUND_SPIN,0.9,ATTN_NORM,0,PITCH_NORM)
	}
	
	wpnmod_set_offset_float(ent,Offset_flStartThrow,spintime)
	wpnmod_set_offset_float(ent,Offset_flNextSecondaryAttack,0.1)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,0.1)
}

public fw_AcIdle(ent,player,clip,ammo){
	wpnmod_reset_empty_sound(ent)
	
	if (wpnmod_get_offset_float(ent,Offset_flTimeWeaponIdle)>0.0)
		return
		
	if(wpnmod_get_offset_float(ent,Offset_flStartThrow)){
		emit_sound(player,CHAN_WEAPON,SOUND_SPINDOWN,0.9,ATTN_NORM,0,PITCH_NORM)
		fm_set_user_maxspeed(player,ms)
		wpnmod_send_weapon_anim(ent,SPINDOWN)
		
		wpnmod_set_offset_float(ent,Offset_flStartThrow,0.0)
		wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,3.0)
		
		return
	}
	
	new anim,Float:next
	
	if (random_float(0.0, 1.0) <= 0.75){
		anim = IDLE2
		next = 5.0
	}
	else{
		anim = IDLE
		next = 6.2
	}
	
	wpnmod_send_weapon_anim(ent,anim)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,next)
}

public fw_AcHolster(ent,player,clip,ammo){
	if(wpnmod_get_offset_float(ent,Offset_flStartThrow)){
		emit_sound(player,CHAN_WEAPON,SOUND_SPINDOWN,0.9,ATTN_NORM,0,PITCH_NORM)
		fm_set_user_maxspeed(player,ms)
		wpnmod_send_weapon_anim(ent,SPINDOWN)
		
		wpnmod_set_offset_float(ent,Offset_flStartThrow,0.0)
	}
}

public fw_AcSpawn(ent){
	SET_MODEL(ent,MODEL_WORLD)
	
	wpnmod_set_offset_int(ent,Offset_iDefaultAmmo,WEAPON_DEFAULT_AMMO)
}
