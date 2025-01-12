/*
*	Photon Gun
*
*				      by GordonFreeman
*			   	   http://gf.hldm.org/
*/

#include <amxmodx>
#include <hl_wpnmod>
#include <beams>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>

#define Offset_ChargeLevel	Offset_iuser1

enum _:PHONTONGUN_ANIAMTION{
	PHOTONGUN_IDLE1,
	PHOTONGUN_FIRE_ALL,
	PHOTONGUN_FIRE_ALL_SOLID,
	PHOTONGUN_FIRE_BARREL1,
	PHOTONGUN_FIRE_BARREL2,
	PHOTONGUN_FIRE_BARREL3,
	PHOTONGUN_FIRE_BARREL4,
	PHOTONGUN_FIRE_BARREL1_SOLID,
	PHOTONGUN_FIRE_BARREL2_SOLID,
	PHOTONGUN_FIRE_BARREL3_SOLID,
	PHOTONGUN_FIRE_BARREL4_SOLID,
	PHOTONGUN_RELOAD,
	PHOTONGUN_DRAW,
	PHOTONGUN_HOLSTER
}

public plugin_precache(){
	PRECACHE_MODEL("models/v_photongun.mdl")
	PRECACHE_MODEL("models/p_photongun.mdl")
	PRECACHE_MODEL("models/w_photongun.mdl")
	
	PRECACHE_MODEL("models/w_uranium235.mdl")
	
	PRECACHE_MODEL("sprites/photon_echo.spr")
	PRECACHE_MODEL("sprites/photon_beam.spr")
	PRECACHE_MODEL("sprites/anim_spr6.spr")
	
	PRECACHE_SOUND("weapons/photongun_fire2.wav")
	PRECACHE_SOUND("weapons/m249_boxin.wav")
	PRECACHE_SOUND("weapons/m249_boxout.wav")
	PRECACHE_SOUND("weapons/m249_coverdown.wav")
	PRECACHE_SOUND("weapons/m249_coverup.wav")
	PRECACHE_SOUND("weapons/lightsaber_hit.wav")
	PRECACHE_SOUND("weapons/lightsaber_hit2.wav")
	
	PRECACHE_GENERIC("sprites/weapon_photongun.spr")
	PRECACHE_GENERIC("sprites/weapon_photongun.txt")
}

public plugin_init(){
	register_plugin("Photon Gun","0.1c","GordonFreeman")
	
	new pg = wpnmod_register_weapon("weapon_photongun",4,5,"uranium235",240,"",-1,18,0,62)
	
	wpnmod_register_weapon_forward(pg,Fwd_Wpn_Spawn,"photongun_spawn")
	wpnmod_register_weapon_forward(pg,Fwd_Wpn_Deploy,"photongun_deploy")
	wpnmod_register_weapon_forward(pg,Fwd_Wpn_Idle,"photongun_idle")
	wpnmod_register_weapon_forward(pg,Fwd_Wpn_PrimaryAttack,"photongun_fire")
	wpnmod_register_weapon_forward(pg,Fwd_Wpn_Reload,"photongun_reload")
	
	new u235 = wpnmod_register_ammobox("ammo_uranium235")
	
	wpnmod_register_ammobox_forward(u235,Fwd_Ammo_Spawn,"uranium235_spawn")
	wpnmod_register_ammobox_forward(u235,Fwd_Ammo_AddAmmo,"uranium235_addammo")
	
	register_think("photon_blastout","blastout_render")
	register_think("photon_beam","beam_render")
	register_think("photon_feedback","feedback_render")
}

public photongun_spawn(ent){
	SET_MODEL(ent,"models/w_photongun.mdl")
	
	wpnmod_set_offset_int(ent,Offset_iDefaultAmmo,120)
	wpnmod_set_offset_int(ent,Offset_ChargeLevel,0)
}

public photongun_deploy(ent,player){
	return wpnmod_default_deploy(ent,"models/v_photongun.mdl","models/p_photongun.mdl",PHOTONGUN_DRAW,"gauss")
}

public photongun_idle(ent){
	wpnmod_reset_empty_sound(ent)

	if(wpnmod_get_offset_float(ent,Offset_flTimeWeaponIdle)>0.0)
		return
	
	wpnmod_send_weapon_anim(ent,PHOTONGUN_IDLE1)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,7.0)
}

public photongun_fire(ent,player,clip,ammo){
	if(pev(player,pev_waterlevel)==3||clip<=0){
		wpnmod_play_empty_sound(ent)
		wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.5)
		
		return
	}
	
	wpnmod_set_player_anim(player,PLAYER_ATTACK1)
	new charge = chargesec(ent)
	
	wpnmod_set_offset_int(ent,Offset_iClip,clip-=1)
	
	engfunc(EngFunc_EmitSound,player,CHAN_AUTO,"weapons/photongun_fire2.wav",0.6,ATTN_NORM,0,PITCH_NORM)
	
	new Float:angles[3],Float:aimvector[3]
	
	new blastout = fm_create_entity("env_sprite")
			
	set_pev(blastout,pev_classname,"photon_blastout")
	engfunc(EngFunc_SetModel,blastout,"sprites/photon_echo.spr")
	fm_set_rendering(blastout,kRenderFxNone,255,255,255, kRenderTransAdd,255)
	set_pev(blastout,pev_scale,0.06)
	
	pev(player,pev_origin,aimvector)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,aimvector,0)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord,aimvector[0])
	engfunc(EngFunc_WriteCoord,aimvector[1])
	engfunc(EngFunc_WriteCoord,aimvector[2])
	write_byte(20)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(45)
	write_byte(1)
	message_end()
	
	fm_get_aim_origin(player,aimvector)
	
	switch(charge){
		case 1: wpnmod_projectile_startpos(player,10.0,2.9,-2.0,angles)
		case 2: wpnmod_projectile_startpos(player,10.0,2.9,-3.2,angles)
		case 3: wpnmod_projectile_startpos(player,9.0,1.15,-2.95,angles)
		case 4: wpnmod_projectile_startpos(player,9.0,1.15,-2.0,angles)
	}
	
	engfunc(EngFunc_SetOrigin,blastout,angles)
	set_pev(blastout,pev_nextthink,get_gametime()+0.01)
	
	blastout = Beam_Create("sprites/photon_beam.spr",8.0)
	Beam_Init(blastout,"sprites/photon_beam.spr",8.0)
	Beam_SetScrollRate(blastout,10.0)
	Beam_PointsInit(blastout,angles,aimvector)
	Beam_RelinkBeam(blastout)
	
	set_pev(blastout,pev_classname,"photon_beam")
	set_pev(blastout,pev_nextthink,get_gametime()+0.01)
	
	blastout = fm_create_entity("env_sprite")
		
	set_pev(blastout,pev_classname,"photon_feedback")
	engfunc(EngFunc_SetModel,blastout,"sprites/anim_spr6.spr")
	fm_set_rendering(blastout,kRenderFxNone,255,255,255, kRenderTransAdd,200)
	set_pev(blastout,pev_scale,0.7)
	set_pev(blastout,pev_animtime,5.0)
	engfunc(EngFunc_SetOrigin,blastout,aimvector)
	set_pev(blastout,pev_nextthink,get_gametime()+0.01)
	
	if(random_num(0,1)){
		engfunc(EngFunc_EmitSound,blastout,CHAN_AUTO,"weapons/lightsaber_hit.wav",0.5,ATTN_NORM,0,PITCH_NORM)
	}else{
		engfunc(EngFunc_EmitSound,blastout,CHAN_AUTO,"weapons/lightsaber_hit2.wav",0.5,ATTN_NORM,0,PITCH_NORM)
	}
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,aimvector,0)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord,aimvector[0])
	engfunc(EngFunc_WriteCoord,aimvector[1])
	engfunc(EngFunc_WriteCoord,aimvector[2])
	message_end()
	
	engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,aimvector,0)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord,aimvector[0])
	engfunc(EngFunc_WriteCoord,aimvector[1])
	engfunc(EngFunc_WriteCoord,aimvector[2])
	write_byte(10)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(25)
	write_byte(1)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord,aimvector[0])
	engfunc(EngFunc_WriteCoord,aimvector[1])
	engfunc(EngFunc_WriteCoord,aimvector[2])
	write_byte(194)
	message_end()
	
	wpnmod_radius_damage(aimvector,player,player,30.0,112.0,0,DMG_ENERGYBEAM|DMG_ALWAYSGIB)
	
	angles[0] = random_float(0.5,1.5)
	angles[1] = 0.0
	angles[2] = 0.0
	
	set_pev(player,pev_punchangle,angles)
	
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.1)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,5.0)
}

public photongun_reload(ent,player,clip,ammo){
	if(ammo<=0||clip>=60)
		return
	
	wpnmod_default_reload(ent,60,PHOTONGUN_RELOAD,4.7)
}

public chargesec(ent){
	new chargelevel = wpnmod_get_offset_int(ent,Offset_ChargeLevel)
	
	chargelevel++
	
	if(chargelevel==5)
		chargelevel = 1
	
	switch(chargelevel){
		case 1: wpnmod_send_weapon_anim(ent,PHOTONGUN_FIRE_BARREL1)
		case 2: wpnmod_send_weapon_anim(ent,PHOTONGUN_FIRE_BARREL2)
		case 3: wpnmod_send_weapon_anim(ent,PHOTONGUN_FIRE_BARREL3)
		case 4: wpnmod_send_weapon_anim(ent,PHOTONGUN_FIRE_BARREL4)
	}
	
	wpnmod_set_offset_int(ent,Offset_ChargeLevel,chargelevel)
	
	return chargelevel
}

public blastout_render(ent){
	new Float:scale,Float:amount
	
	pev(ent,pev_scale,scale)
	pev(ent,pev_renderamt,amount)
	
	if(amount==15.0){
		fm_remove_entity(ent)
		
		return
	}
	
	scale -= 0.01
	amount -= 40.0
	
	set_pev(ent,pev_scale,scale)
	set_pev(ent,pev_renderamt,amount)

	set_pev(ent,pev_nextthink,get_gametime()+0.01)
}

public beam_render(ent){
	new Float:scale,Float:amount
	
	scale = Beam_GetWidth(ent)
	
	pev(ent,pev_renderamt,amount)
	
	if(amount==15.0){
		fm_remove_entity(ent)
		
		return
	}
	
	scale += 0.5
	amount -= 40.0
	
	Beam_SetWidth(ent,scale)
	set_pev(ent,pev_renderamt,amount)

	set_pev(ent,pev_nextthink,get_gametime()+0.01)
}

public feedback_render(ent){
	new Float:frame
	pev(ent,pev_frame,frame)
	
	frame += 1.0
	
	if(frame==10){
		fm_remove_entity(ent)
		
		return
	}
	
	set_pev(ent,pev_frame,frame)
	set_pev(ent,pev_nextthink,get_gametime()+0.01)
}

public uranium235_spawn(ent){
	SET_MODEL(ent,"models/w_uranium235.mdl")
}

public uranium235_addammo(ent,player){
	new result = (ExecuteHamB(Ham_GiveAmmo,player,30,"uranium235",240)!= -1)
	
	if(result)
		emit_sound(ent,CHAN_ITEM,"items/9mmclip1.wav",1.0,ATTN_NORM,0,PITCH_NORM)
	
	return result
}

stock wpnmod_projectile_startpos(const player,const Float:forw,const Float:right,const Float:up,Float:vSrc[3]){
	new Float:v_forward[3]
	new Float:v_right[3]
	new Float:v_up[3]
	
	GetGunPosition(player,vSrc)
	
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)
	
	xs_vec_mul_scalar(v_forward,forw, v_forward)
	xs_vec_mul_scalar(v_right,right, v_right)
	xs_vec_mul_scalar(v_up,up, v_up)
	
	xs_vec_add(vSrc,v_forward,vSrc)
	xs_vec_add(vSrc,v_right,vSrc)
	xs_vec_add(vSrc,v_up,vSrc)
}

stock GetGunPosition(const player,Float:origin[3]){
	new Float:viewOfs[3];
	
	pev(player, pev_origin, origin);
	pev(player, pev_view_ofs, viewOfs);
    
	xs_vec_add( origin, viewOfs, origin);
}
