/*
*	Chrone Cannon
*
*				      by GordonFreeman
*			   http://www.lambda-force.org/
*/

#include <amxmodx>
#include <hl_wpnmod>
#include <hamsandwich>
#include <fakemeta_util>
#include <beams>
#include <xs>

new particle,shock,Float:maxspeed
new screenfade

#define REFLUX_DIST		500.0

#define Offset_Qwant		Offset_iuser1
#define Offset_Refluxing	Offset_iuser2
#define Offset_PowerUpTime	Offset_fuser1
#define Offset_ZAxisCheckFail	Offset_fuser2

#define MDL_INHANDS 		"models/v_chronecannon.mdl"
#define MDL_ATHANDS 		"models/p_chronecannon.mdl"
#define MDL_ATWORLD 		"models/w_chronecannon.mdl"

#define REFLUX_BEAM		"sprites/xbeam1.spr"

#define REFLUX_FAIL		"debris/beamstart9.wav"
#define REFLUX_READY		"buttons/blip2.wav"
#define REFLUX_GONE		"weapons/egon_windup2.wav"
#define REFLUX_STOP		"weapons/egon_off1.wav"
#define REFLUX_TAKEOUT		"debris/beamstart8.wav"
#define REFLUX_TAKEIN		"debris/beamstart14.wav"

new bool:g_frozen[33]
new maxpl

enum _:{
	IDLE1,
	FIDGET1,
	ALTON,
	ALTCYCLE,
	ALTCYCLEWTF,
	FIRE1,
	FIRE2,
	FIRE3,
	FIRE4,
	DRAW,
	FIDGET2
}

public plugin_precache(){
	PRECACHE_MODEL(MDL_INHANDS)
	PRECACHE_MODEL(MDL_ATHANDS)
	PRECACHE_MODEL(MDL_ATWORLD)
	
	PRECACHE_MODEL(REFLUX_BEAM)
	
	PRECACHE_SOUND(REFLUX_FAIL)
	PRECACHE_SOUND(REFLUX_READY)
	PRECACHE_SOUND(REFLUX_GONE)
	PRECACHE_SOUND(REFLUX_STOP)
	PRECACHE_SOUND(REFLUX_TAKEOUT)
	PRECACHE_SOUND(REFLUX_TAKEIN)
	
	PRECACHE_GENERIC("sprites/weapon_chronecannon.txt")
	
	shock = precache_model("sprites/shockwave.spr")
	particle = precache_model("sprites/blueflare2.spr")
}

public plugin_init(){
	register_plugin("Chrone Cannon","0.2","GordonFreeman")
	
	new cc = wpnmod_register_weapon("weapon_chronecannon",1,5,"",-1,"",-1,-1,ITEM_FLAG_SELECTONEMPTY,14)
	
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_Spawn,"fw_RelictInWorld")
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_Deploy,"fw_TakeToUse")
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_PrimaryAttack,"fw_TimeShift")
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_SecondaryAttack,"fw_DimensionShift")
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_Idle,"fw_Easy")
	wpnmod_register_weapon_forward(cc,Fwd_Wpn_Holster,"fw_TakeOut")
	
	RegisterHam(Ham_TakeDamage,"player","fw_PlayerDamage")	// refluxing subjects cant be damaged
	
	screenfade = get_user_msgid("ScreenFade")
	maxpl = get_maxplayers()
}

public plugin_cfg()
	maxspeed = get_cvar_float("sv_maxspeed")

public fw_RelictInWorld(ent)
	SET_MODEL(ent,MDL_ATWORLD)
	
public fw_TakeToUse(ent,player)
	return wpnmod_default_deploy(ent,MDL_INHANDS,MDL_ATHANDS,DRAW,"egon")
	
public fw_TimeShift(ent,player){	// primary attack - back to future our victim
	new qwant = wpnmod_get_offset_int(ent,Offset_Qwant)	// current refluxing ent
	new reflux = get_aiment(player)				// ent at aim pos
	
	if(pev_valid(qwant)){		// continue reflux current refluxing ent
		new Float:dist = fm_entity_range(player,qwant)
		
		if(dist>REFLUX_DIST){
			RefluxFailed(ent,player,0)
			
			return
		}
		
		set_pev(player,pev_maxspeed,-1.0)	// player cant move while refluxing process is going
		
		if(0<qwant<=maxpl){	// despeed refluxing player, make him in stazis
			g_frozen[qwant] = true
			set_pev(qwant,pev_maxspeed,-1.0)
		}
		
		// effects
		set_pev(qwant,pev_renderfx,kRenderFxDistort)
		set_pev(qwant,pev_rendermode,kRenderTransAdd)
		set_pev(qwant,pev_renderamt,128.0)
		
		// we are in refluxing
		wpnmod_set_offset_int(ent,Offset_Refluxing,1)
		
		if(!wpnmod_get_offset_float(ent,Offset_PowerUpTime)){	// play sound
			wpnmod_send_weapon_anim(ent,ALTON)
			emit_sound(ent,CHAN_WEAPON,REFLUX_GONE,1.0,ATTN_NONE,0,PITCH_HIGH)
		}
		
		// refluxing think
		wpnmod_set_think(ent,"fw_Refluxing")
		set_pev(ent,pev_nextthink,get_gametime())
		
		
		wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.00)
		wpnmod_set_offset_float(ent,Offset_flNextSecondaryAttack,0.8)
		wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,0.1)	// for reflux reset
		
		// reflxuing beams
		
		new beams
		
		// remove olds
		while((beams = fm_find_ent_by_owner(beams,"beam",player))){
			engfunc(EngFunc_RemoveEntity,beams)
		}
		
		new Float:origin[3]
		wpnmod_get_projective_pos(player,4.0,2.0,-2.0,origin)
		
		// and create news
		for(new i;i<5;++i){
			beams = Beam_Create(REFLUX_BEAM,10.0)
			Beam_Init(beams,REFLUX_BEAM,10.0)
			Beam_PointEntInit(beams,origin,qwant)
			Beam_SetColor(beams,{255.0,255.0,255.0})
			Beam_SetNoise(beams,50)
			set_pev(beams,pev_owner,player)
		}
		
		return
	}else if(pev_valid(reflux)){	// if current refluxing ent is invalid, then try to catch another
		wpnmod_set_offset_int(ent,Offset_Qwant,reflux)
		
		return
	}
	
	RefluxFailed(ent,player,0)	// failed too do something, lets screenshake player!
}

public fw_DimensionShift(ent,player){		// teleport player to the aimpoint
	new Float:oldloc[3],Float:newloc[3]
	
	pev(player,pev_origin,oldloc)		// get player origin
	fm_get_aim_origin(player,newloc)	// get player aim origin, teleport where
	
	// some effects
	wpnmod_play_snd(ent,REFLUX_TAKEOUT)
	particle_shower(player)
	shockwave(oldloc,330,0,255,255)
	create_screen_fade(player,(1<<10)*2,(1<<10),(1<<12),0,255,255,210)
	
	// change coordinates to make sure player won't get stuck in the ground/wall
	newloc[0] += ((newloc[0]-oldloc[0]>0.0)?-30.0:30.0)
	newloc[1] += ((newloc[1]-oldloc[1]>0.0)?-30.0:30.0)
	newloc[2] += 40.0
	
	shockwave(newloc,330,0,255,255)
	set_pev(player,pev_origin,newloc)	// teleport the player
	particle_shower(player)
	wpnmod_play_snd(player,REFLUX_TAKEIN)
	
	wpnmod_set_offset_float(ent,Offset_ZAxisCheckFail,newloc[2])
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,0.5)
	wpnmod_set_offset_float(ent,Offset_flNextSecondaryAttack,1.5)
	
	wpnmod_set_think(ent,"fw_TeleportCheckFail")
	set_pev(ent,pev_nextthink,get_gametime()+0.5)
}

public fw_TeleportCheckFail(ent,player){	// check teleport correctly
	new Float:origin[3],Float:zaxis = wpnmod_get_offset_float(ent,Offset_ZAxisCheckFail)
	pev(player,pev_origin,origin)
	
	if(origin[2]==zaxis){		// if teleporting is failed, then kill the player
		wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,3.0)
		wpnmod_set_offset_float(ent,Offset_flNextSecondaryAttack,3.0)
		
		RefluxFailed(ent,player,0)
		RefluxDone(player,player,ent)
	}
}

public fw_Refluxing(ent,player){	// refluxing think
	new qwant = wpnmod_get_offset_int(ent,Offset_Qwant)
	new refluxing = wpnmod_get_offset_int(ent,Offset_Refluxing)
	
	if(!pev_valid(qwant)){
		RefluxFailed(ent,player,0)
		
		return
	}
	
	if(0<qwant<=maxpl)
		create_screen_fade(qwant,(1<<10)*2,(1<<10),(1<<12),255,255,255,230)
	
	//new Float:reftime = wpnmod_get_offset_float(ent,Offset_RefluxingTime)	// dont use anymore
	new Float:powerup = wpnmod_get_offset_float(ent,Offset_PowerUpTime)
	
	if(powerup>55.0){	// refluxing is finished, lets back to future our ent
		RefluxDone(qwant,player,ent)
		RefluxFailed(ent,player,1)
		wpnmod_set_offset_float(ent,Offset_PowerUpTime,0.0)
	}else // otherwise just continue
		wpnmod_set_offset_float(ent,Offset_PowerUpTime,powerup+1.0)
	
	if(refluxing){
		wpnmod_set_think(ent,"fw_Refluxing")
		set_pev(ent,pev_nextthink,get_gametime())
	}
}

public fw_Easy(ent,player){ 		// weapon idle, reset goes here
	if(wpnmod_get_offset_int(ent,Offset_Refluxing))
		RefluxFailed(ent,player,0)
	
	if(wpnmod_get_offset_float(ent,Offset_flTimeWeaponIdle)>0.0)
		return
	
	new anim
	new Float:nextidle
	
	if(random_float(0.0,1.0)<=0.75){
		anim = IDLE1
		nextidle = 8.0
	}else{
		anim = FIDGET1
		nextidle = 12.0
	}
	
	wpnmod_send_weapon_anim(ent,anim)
	wpnmod_set_offset_float(ent,Offset_flTimeWeaponIdle,nextidle)
}

public fw_TakeOut(ent,player){		// holster, reset goes here
	set_pev(player,pev_maxspeed,maxspeed)
	
	new beams
	
	while((beams = fm_find_ent_by_owner(beams,"beam",player))){
		engfunc(EngFunc_RemoveEntity,beams)
	}
	
	RefluxReset(wpnmod_get_offset_int(ent,Offset_Qwant))
	
	wpnmod_set_offset_int(ent,Offset_Qwant,0)
	wpnmod_set_offset_int(ent,Offset_Refluxing,0)
	wpnmod_set_offset_float(ent,Offset_PowerUpTime,0.0)
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,1.0)
}

public fw_RefluxReady(ent)		// beep sound
	wpnmod_play_snd(ent,REFLUX_READY)
	
public RefluxDone(ent,player,wpn){	// we did it
	RefluxEffect(ent)
	
	if(!(0<ent<=maxpl))
		set_pev(ent,pev_solid,SOLID_NOT)	//	SOLID_NOT for players can crash the game
		
	set_pev(ent,pev_movetype,MOVETYPE_FLY)
	set_pev(ent,pev_rendermode,kRenderTransAlpha)
	set_pev(ent,pev_renderfx,kRenderFxGlowShell)
	set_pev(ent,pev_renderamt,255.0)
	set_pev(ent,pev_rendercolor,{255.0,255.0,255.0})
	set_pev(ent,pev_velocity,Float:{0.0,0.0,20.0})
	
	wpnmod_set_offset_int(ent,Offset_Qwant,0)
	
	new data[4]
	data[0] = ent
	data[1] = 255
	data[2] = player
	data[3] = wpn
		
	set_task(0.1,"BackToFuture",_,data,4)
}

public fw_PlayerDamage(ent,ct,atc){	// subjects in refluxing cant take damage or be damaged
	if(!(0<ent<=maxpl)||!(0<atc<=maxpl))
		return HAM_IGNORED
	
	if(g_frozen[ent])
		return HAM_SUPERCEDE
		
	if(g_frozen[atc])
		return HAM_SUPERCEDE
		
	return HAM_IGNORED
}

public BackToFuture(data[4]){		// back to future our victim
	new ent = data[0]
	new player = data[2]
	new wpn = data[3]
	new Float:amt = float(data[1])
	
	if(!pev_valid(ent))
		return
	
	amt -= 25.5

	if(amt>0.0){
		set_pev(ent,pev_renderamt,amt)
		new data[4]
		
		data[0] = ent
		data[1] = floatround(amt)
		data[2] = player
		data[3] = wpn
		
		if(0<ent<=maxpl)
			create_screen_fade(ent,(1<<10)*2,(1<<10),(1<<12),255,255,255,200)
		
		RefluxEffect(ent)
		
		set_task(0.1,"BackToFuture",_,data,4)
	}
	else{
		particle_shower(ent)
		emit_sound(ent,CHAN_STATIC,REFLUX_FAIL,1.0,ATTN_NONE,0,PITCH_NORM)
		
		if(0<ent<=maxpl){
			if(pev_valid(ent))			
				RefluxReset(ent)
			else
				return
			
			if(pev_valid(wpn)&&pev_valid(wpn))
				ExecuteHamB(Ham_TakeDamage,ent,wpn,player,500.0,DMG_ALWAYSGIB|DMG_TIMEBASED)
		}
		else{
			engfunc(EngFunc_RemoveEntity,ent)
		}
	}
}

public RefluxEffect(ent){	// shock wave effect
	new Float:org[3]
	
	pev(ent,pev_origin,org)
	shockwave(org,128,255,255,255)
}
	
public RefluxFailed(ent,player,no){	// reflux failed, screenfade + snd and reset
	new Float:org[3]
	wpnmod_get_projective_pos(player,6.0,0.0,-2.0,org)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY,org,0)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord,org[0])
	engfunc(EngFunc_WriteCoord,org[1])
	engfunc(EngFunc_WriteCoord,org[2])
	engfunc(EngFunc_WriteCoord,org[0])
	engfunc(EngFunc_WriteCoord,org[1])
	engfunc(EngFunc_WriteCoord,org[2]+10)
	write_short(particle)
	write_byte(5)
	write_byte(5)
	write_byte(2)
	write_byte(random_num(5,10))
	write_byte(5)
	message_end()
		
	create_screen_fade(player,(1<<10)*2,(1<<10),(1<<12),255,255,255,128)
	wpnmod_play_snd(ent,REFLUX_FAIL)
	emit_sound(ent,CHAN_WEAPON,REFLUX_STOP,1.0,ATTN_NONE,0,PITCH_HIGH)
	set_pev(player,pev_maxspeed,maxspeed)
	
	new beams
	
	while((beams = fm_find_ent_by_owner(beams,"beam",player))){
		engfunc(EngFunc_RemoveEntity,beams)
	}
	
	if(pev_valid(wpnmod_get_offset_int(ent,Offset_Qwant))&&!no)
		RefluxReset(wpnmod_get_offset_int(ent,Offset_Qwant))
	
	wpnmod_set_offset_int(ent,Offset_Qwant,0)
	wpnmod_set_offset_int(ent,Offset_Refluxing,0)
	wpnmod_set_offset_float(ent,Offset_PowerUpTime,0.0)
	wpnmod_set_offset_float(ent,Offset_flNextPrimaryAttack,1.0)

	wpnmod_set_think(ent,"fw_RefluxReady")
	set_pev(ent,pev_nextthink,get_gametime()+1.0)
}

public RefluxReset(ent){	// become ent to normal
	if(!pev_valid(ent))
		return
	
	if(0<ent<=get_maxplayers()){
		g_frozen[ent] = false
		set_pev(ent,pev_maxspeed,maxspeed)
	}
	
	set_pev(ent,pev_flags,0)
	set_pev(ent,pev_renderfx,kRenderFxNone)
	set_pev(ent,pev_rendermode,kRenderNormal)
	set_pev(ent,pev_renderamt,0.0)
}

public particle_shower(ent){	// rain of particles
	new Float:org[3]
	pev(ent,pev_origin,org)
	
	engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY,org,0)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord,org[0])
	engfunc(EngFunc_WriteCoord,org[1])
	engfunc(EngFunc_WriteCoord,org[2])
	engfunc(EngFunc_WriteCoord,org[0])
	engfunc(EngFunc_WriteCoord,org[1])
	engfunc(EngFunc_WriteCoord,org[2]+10)
	write_short(particle)		// sprite index
	write_byte(15)			// count
	write_byte(5)			// life time
	write_byte(3)			// scale
	write_byte(random_num(5,10))	// velocity
	write_byte(5)			// random less velocity
	message_end()
}

public shockwave(Float:origin[3], radius, r, g, b) {	// shockwave effect
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER )
	engfunc(EngFunc_WriteCoord,origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	engfunc(EngFunc_WriteCoord,origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2]+radius)
	write_short(shock)
	write_byte(0) // startframe
	write_byte(0) // framerate in 0.1's
	write_byte(2) // life
	write_byte(64) // width
	write_byte(255) // noise
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(255) //bright
	write_byte(0) //scrollspeed
	message_end()
}

stock create_screen_fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	message_begin(MSG_ONE_UNRELIABLE,screenfade,{0,0,0},id)
	write_short(duration)
	write_short(holdtime)
	write_short(fadetype)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(alpha)
	message_end()
}

wpnmod_play_snd(ent,snd[])
	emit_sound(ent,CHAN_WEAPON,snd,1.0,ATTN_NORM,0,PITCH_NORM)

wpnmod_get_projective_pos(player,Float:foward,Float:right,Float:up,Float:fstart[3]){	// get beams start pos
	new Float:v_forward[3]
	new Float:v_right[3]
	new Float:v_up[3]
	
	GetGunPosition(player,fstart)
	
	global_get(glb_v_forward,v_forward)
	global_get(glb_v_right,v_right)
	global_get(glb_v_up,v_up)
	
	xs_vec_mul_scalar(v_forward,foward,v_forward)
	xs_vec_mul_scalar(v_right,right,v_right)
	xs_vec_mul_scalar(v_up,up,v_up)
	
	xs_vec_add(fstart,v_forward,fstart)
	xs_vec_add(fstart,v_right,fstart)
	xs_vec_add(fstart,v_up,fstart)
}

stock GetGunPosition(const player,Float:origin[3]){
	new Float:viewOfs[3]
	
	pev(player,pev_origin,origin)
	pev(player,pev_view_ofs,viewOfs)
    
	xs_vec_add(origin,viewOfs,origin)
}

stock traceline( const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3] ){
	engfunc( EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0 )
	get_tr2( 0, TR_vecEndPos, vHitPos )
	return get_tr2( 0, TR_pHit )
}

stock get_view_pos( const id, Float:vViewPos[3] ){
	new Float:vOfs[3]
	pev( id, pev_origin, vViewPos )
	pev( id, pev_view_ofs, vOfs )		
	
	vViewPos[0] += vOfs[0]
	vViewPos[1] += vOfs[1]
	vViewPos[2] += vOfs[2]
}

stock Float:vel_by_aim( id, speed = 1 ){
	new Float:v1[3], Float:vBlah[3]
	pev( id, pev_v_angle, v1 )
	engfunc( EngFunc_AngleVectors, v1, v1, vBlah, vBlah )
	
	v1[0] *= speed
	v1[1] *= speed
	v1[2] *= speed
	
	return v1
}

stock get_aiment(id){	// get aiment
	new target
	new Float:orig[3], Float:ret[3]
	get_view_pos( id, orig )
	ret = vel_by_aim( id, 9999 )
	
	ret[0] += orig[0]
	ret[1] += orig[1]
	ret[2] += orig[2]
	
	target = traceline( orig, ret, id, ret )
	
	new movetype
	if( target && pev_valid( target ) )
	{
		movetype = pev( target, pev_movetype )
		if( !( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS ) )
			return 0
	}
	else
	{
		target = 0
		new ent = engfunc( EngFunc_FindEntityInSphere, -1, ret, 10.0 )
		while( !target && ent > 0 )
		{
			movetype = pev( ent, pev_movetype )
			if( ( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS )
			&& ent != id  )
			target = ent
			ent = engfunc( EngFunc_FindEntityInSphere, ent, ret, 10.0 )
		}
	}
	
	return target
}
