#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <hl_wpnmod>
 
#define PLUGIN "shotgunman"
#define VERSION "1.0"
#define AUTHOR "dima_mark7"
 
// Weapon settings
#define WEAPON_NAME                     "weapon_shotgunman"
#define WEAPON_SLOT                     2
#define WEAPON_POSITION                 3
#define WEAPON_PRIMARY_AMMO             "buckshot"
#define WEAPON_PRIMARY_AMMO_MAX         125
#define WEAPON_SECONDARY_AMMO           ""
#define WEAPON_SECONDARY_AMMO_MAX       -1
#define WEAPON_MAX_CLIP                 -1
#define WEAPON_DEFAULT_AMMO             32
#define WEAPON_FLAGS                    0
#define WEAPON_WEIGHT                   15
#define WEAPON_DAMAGE                   18.0
 
// Hud
#define WEAPON_HUD_TXT                  "sprites/weapon_shotgunman.txt"
#define WEAPON_HUD_SPR                  "sprites/weapon_shotgunman.spr"
 
// Models
#define MODEL_WORLD                     "models/w_shotgunman.mdl"
#define MODEL_VIEW                      "models/v_shotgunman.mdl"
#define MODEL_PLAYER                    "models/p_shotgunman.mdl"
#define MODEL_SHELL                     "models/shotgunshell.mdl"
 
// Sounds
#define SOUND_FIRE                      "weapons/sbarrel1.wav"
#define SOUND_WEAPON                    "weapons/shotgun_cock_heavy.wav"
 
// Animation
#define ANIM_EXTENSION                  "shotgun"
 
new shell, g_bullet[33] = {2, ...};
 
enum _:shotgunman
{
        GUN_DRAW,
        GUN_IDLE,
        GUN_IDLE2,
        GUN_SHOOT_1,
        GUN_SHOOT_2,
        GUN_SHOOT_3,
        GUN_SHOOT_4,
        GUN_CUSTOMIZE
};
 
public plugin_precache()
{
        PRECACHE_MODEL(MODEL_VIEW);
        PRECACHE_MODEL(MODEL_WORLD);
        PRECACHE_MODEL(MODEL_PLAYER);
        shell = PRECACHE_MODEL(MODEL_SHELL)
       
        PRECACHE_SOUND(SOUND_FIRE);
        PRECACHE_SOUND(SOUND_WEAPON);
 
        PRECACHE_GENERIC(WEAPON_HUD_TXT);
        PRECACHE_GENERIC(WEAPON_HUD_SPR);
}      
 
public plugin_init()
{
        register_plugin(PLUGIN, VERSION, AUTHOR)
       
        new ishotgunman = wpnmod_register_weapon
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
       
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_Spawn, "shotgunman_spawn");
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_Deploy, "shotgunman_deploy");
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_Idle, "shotgunman_idle");
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_PrimaryAttack, "shotgunman_primaryattack");
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_SecondaryAttack,"shotgunman_secondary")
        wpnmod_register_weapon_forward(ishotgunman, Fwd_Wpn_Holster, "shotgunman_holster");
}
 
public client_disconnect(id)
{
        g_bullet[id] = 2;
}
 
public shotgunman_spawn(const iItem)
{
        SET_MODEL(iItem, MODEL_WORLD);
        wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}
 
public shotgunman_deploy(const iItem)
{
        return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, GUN_DRAW, ANIM_EXTENSION);
}
 
public shotgunman_holster(const iItem)
{
        wpnmod_set_offset_int(iItem, Offset_iInReload, 0);
}
 
public shotgunman_idle(const iItem)
{
        wpnmod_reset_empty_sound(iItem);
       
        if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) <= 0.0)
        {
                wpnmod_send_weapon_anim(iItem, random_float(0.0, 1.0) <= 0.8 ? GUN_IDLE : GUN_IDLE2);
                wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 2.06);
        }
}
 
public shotgunman_primaryattack(const iItem, const iPlayer, iClip, iAmmo)
{
        if (pev(iPlayer, pev_waterlevel) == 3 || iAmmo <= 0)
        {
                wpnmod_play_empty_sound(iItem);
                wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
                return;
        }
       
        shotgunman_ShotBullets(iItem, iPlayer, g_bullet[iPlayer], iAmmo);
       
        wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.92);
        wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.92);
        wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 0.92);
       
        wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);
        emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.92, ATTN_NORM, 0, PITCH_NORM);
}
 
public shotgunman_secondary(const iItem, const iPlayer)
{
        if (++g_bullet[iPlayer] > 4)
        {
                g_bullet[iPlayer] = 1
        }
       
        wpnmod_send_weapon_anim(iItem,GUN_CUSTOMIZE);
       
        wpnmod_set_offset_float(iItem,Offset_flNextPrimaryAttack,2.3);
        wpnmod_set_offset_float(iItem,Offset_flNextSecondaryAttack,2.3);
        wpnmod_set_offset_float(iItem,Offset_flTimeWeaponIdle,2.3);
       
        client_print(iPlayer,print_center,"Bullets: %i", g_bullet[iPlayer])
}
 
shotgunman_ShotBullets(const iItem, const iPlayer, iBullets, const iAmmo)
{
        static Float: flMult;
        static Float: flZVel;
        static Float: vecAngle[3];
        static Float: vecForward[3];
        static Float: vecVelocity[3];
        static Float: vecPunchangle[3];
       
        if (iAmmo < iBullets)
        {
                iBullets = iAmmo;
        }
 
        wpnmod_fire_bullets(iPlayer, iPlayer, iBullets * 4, VECTOR_CONE_15DEGREES, 2048.0, WEAPON_DAMAGE, DMG_BULLET, iBullets * 4);
       
        for (new i = 0; i < iBullets; i++)
        {
                wpnmod_eject_brass(iPlayer, shell, TE_BOUNCE_SHOTSHELL, 16.0, -18.0, 6.0);
        }
       
        wpnmod_send_weapon_anim(iItem, GUN_IDLE2 + iBullets);
        wpnmod_set_player_ammo(iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - iBullets);
               
        global_get(glb_v_forward, vecForward);
       
        pev(iPlayer, pev_v_angle, vecAngle);
        pev(iPlayer, pev_velocity, vecVelocity);
        pev(iPlayer, pev_punchangle, vecPunchangle);
               
        xs_vec_add(vecAngle, vecPunchangle, vecPunchangle);
        engfunc(EngFunc_MakeVectors, vecPunchangle);
               
        flZVel = vecVelocity[2];
        flMult = float(iBullets);
               
        xs_vec_mul_scalar(vecForward, 100.0 * flMult, vecPunchangle);
        xs_vec_sub(vecVelocity, vecPunchangle, vecVelocity);
               
        vecPunchangle[2] = 0.0;
        vecVelocity[2] = flZVel;
       
        vecPunchangle[0] = random_float(-1.0 * flMult, 1.0 * flMult);
        vecPunchangle[1] = random_float(-(++flMult), flMult);
               
        set_pev(iPlayer, pev_velocity, vecVelocity);
        set_pev(iPlayer, pev_punchangle, vecPunchangle);
}