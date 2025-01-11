/* AMX Mod X
*	Stealth Box.
*
* This plugin is licenced under the AGPLv3 Licence
* 
* The AGPL license differs from the other GNU licenses in 
* that it was built for network software. You can distribute 
* modified versions if you keep track of the changes and the 
* date you made them. As per usual with GNU licenses, you must 
* license derivatives under AGPL. 
* It provides the same restrictions and freedoms as the GPLv3 
* but with an additional clause which makes it so that source code 
* must be distributed along with web publication. 
* Since web sites and services are never distributed in the 
* traditional sense, the AGPL is the GPL of the web.
*
* This file is provided as is (no warranties)
*/

#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <hl_wpnmod>
#include <hlstocks>

#define PLUGIN "Stealth Box"
#define VERSION "1.0"
#define AUTHOR "Gabe Iggy"

// Weapon settings
#define WEAPON_NAME 			"weapon_box"
#define WEAPON_SLOT			1
#define WEAPON_POSITION			3 // NULL
#define WEAPON_PRIMARY_AMMO		""
#define WEAPON_PRIMARY_AMMO_MAX		-1
#define WEAPON_SECONDARY_AMMO		"" // NULL
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP			-1
#define WEAPON_DEFAULT_AMMO		-1
#define WEAPON_FLAGS			0
#define WEAPON_WEIGHT			0

// Hud
#define WEAPON_HUD_TXT			"sprites/weapon_box.txt"
#define WEAPON_HUD_SPR			"sprites/weapon_box.spr"

// Models
#define MODEL_WORLD				"models/svm/w_stealthbox.mdl"
#define MODEL_VIEW				"models/svm/v_stealthbox.mdl"
#define MODEL_PLAYER			"models/svm/p_stealthbox.mdl"

// Sounds
#define SOUND_PHIL_1			"BoxPhilosophy/box1.wav"
#define SOUND_PHIL_2			"BoxPhilosophy/box2.wav"
#define SOUND_PHIL_3			"BoxPhilosophy/box3.wav"
#define SOUND_PHIL_4			"BoxPhilosophy/box4.wav"
#define SOUND_PHIL_5			"BoxPhilosophy/box5.wav"
#define SOUND_PHIL_6			"BoxPhilosophy/box6.wav"

// Animation
#define ANIM_EXTENSION			"trip"

new g_iBoxHandle;
const g_aButtonBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

enum _:Animation 
{
	ANIM_IDLE = 0,
};

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_PHIL_1);
	PRECACHE_SOUND(SOUND_PHIL_2);
	PRECACHE_SOUND(SOUND_PHIL_3);
	PRECACHE_SOUND(SOUND_PHIL_4);
	PRECACHE_SOUND(SOUND_PHIL_5);
	PRECACHE_SOUND(SOUND_PHIL_6);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_iBoxHandle = wpnmod_register_weapon
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
	
	wpnmod_register_weapon_forward(g_iBoxHandle, Fwd_Wpn_Spawn, "box_spawn");
	wpnmod_register_weapon_forward(g_iBoxHandle, Fwd_Wpn_Deploy, "box_deploy");
	//wpnmod_register_weapon_forward(g_iBoxHandle, Fwd_Wpn_Holster, "box_holster");
	wpnmod_register_weapon_forward(g_iBoxHandle, Fwd_Wpn_SecondaryAttack, "box_speech");
	
	register_message(get_user_msgid("StatusValue"), "message_statusvalue");
	register_forward(FM_AddToFullPack, "fullpack_pre", 0);
}


public message_statusvalue()
{
	if(1 <= get_msg_arg_int(2) <= get_maxplayers())
	{
		if (get_user_weapon(get_msg_arg_int(2)) == g_iBoxHandle)
		{
			// Pretend the previous message never arrived
			set_msg_arg_int(1, get_msg_argtype(1), 1);
			set_msg_arg_int(2, get_msg_argtype(2), 0);
		}
	}
}

/*
AddToFullPack
Return 1 if the entity state has been filled in for the ent and the entity 
will be propagated to the client, 0 otherwise

· "ent_state" is the server maintained copy of the state info that is transmitted 
	to the client a MOD could alter values copied into state to send the "host" a 
	different look for a particular entity update, etc.
· "e" and "edict_t_ent" are the entity that is being added to the update, if 1 is returned
· "edict_t_host" is the player's edict of the player whom we are sending the update to
· "player" is 1 if the ent/e is a player and 0 otherwise
· "pSet" is either the PAS or PVS that we previous set up.  
	We can use it to ask the engine to filter the entity against the PAS or PVS.
	we could also use the pas/ pvs that we set in SetupVisibility, if we wanted to.  Caching the value is valid in that case, but still only for the current frame
*/
public fullpack_pre(ent_state,e,edict_t_ent,edict_t_host,hostflags,player,pSet) 
{	
	if(player)
	{
		if((is_user_alive(edict_t_host)) && (edict_t_host != edict_t_ent) && (get_user_weapon(edict_t_ent) == g_iBoxHandle))
		{
			new buttons = get_user_button(edict_t_ent);
			if (!(buttons & g_aButtonBits) && (buttons & IN_DUCK))
				return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}


public box_spawn(const iItem)
{
	// Setting world model
	SET_MODEL(iItem, MODEL_WORLD);
}


public box_deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_IDLE, ANIM_EXTENSION);
}

public box_speech(const iItem, const iPlayer)
{
	switch (random_num(0, 5))
	{
		case 0: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_1, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 1: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_2, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 2: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_3, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 3: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_4, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 4: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_5, 1.0, ATTN_NORM, 0, PITCH_NORM);
		case 5: emit_sound(iPlayer, CHAN_VOICE, SOUND_PHIL_6, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}

	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 7.0);
}