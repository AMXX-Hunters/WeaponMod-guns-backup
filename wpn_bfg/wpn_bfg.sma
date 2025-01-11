
#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < hl_wpnmod >
#include < xs >

// Weapon parameters
#define WEAPON_NAME             "weapon_bigfuckingun" 
#define WEAPON_SLOT            1
#define WEAPON_POSITION            4
#define WEAPON_SECONDARY_AMMO        "" // NULL
#define WEAPON_SECONDARY_AMMO_MAX    -1        
#define WEAPON_CLIP            1
#define WEAPON_FLAGS            0
#define WEAPON_WEIGHT            15
#define WEAPON_RELOADTIME        3.0
#define WEAPON_REFIRE_RATE        3.0
#define WEAPON_DAMAGE            300.0
#define WEAPON_RADIUS            500.0

// Ammo parameters
#define AMMO_MODEL            "models/w_bfgbox.mdl"
#define AMMO_NAME            "bfgammo"
#define AMMO_MAX            3
#define AMMO_DEFAULT            1

// Models
#define MODEL_P                "models/p_bfg.mdl"
#define MODEL_V                "models/v_bfg.mdl"
#define MODEL_W                "models/w_bfg.mdl"

// Sounds
#define SOUND_FIRE            "weapons/bfg-1.wav"
#define SOUND_EXPLODE            "weapons/bfg_exp.wav"
#define SOUND_RELOAD                    "weapons/bfg_rel.wav"
#define SOUND_DEPLOY                    "weapons/bfg_dep.wav"

// Ball sprite
#define BFG_MODEL            "sprites/bfg1.spr"
#define BFG_EXPLODE            "sprites/bfg31.spr"
#define BFG_VELOCITY            1100
#define BFG_EXPLODE2                    "sprites/bfg4.spr"

// V_ model sequences
#define SEQ_IDLE            0
#define SEQ_DEPLOY            1
#define SEQ_RELOAD            1
#define SEQ_FIRE            2              

// Playermodel anim group
#define ANIM_EXTENSION            "gauss"

// HUD sprites
new const HUD_SPRITES[ ][ ]        =
{
    "sprites/weapon_bfg_newest.txt",
    "sprites/weapon_bigfuckingun.spr",
        "sprites/weapon_bfg_ammo.spr"
};

//===================================================================
new g_sModelIndexExplode;
new g_sModelIndexExplode2;

#define CLASS_BFGBOX            "ammo_bfgbox"
#define CLASS_BFGPLASMA            "monster_plasma"

new const Float:gVecZero[ ]        = { 0.0, 0.0, 0.0 };
//
// Precache resources
//
public plugin_precache( )
{
    new i;
    
    // Models
    PRECACHE_MODEL( MODEL_P );
    PRECACHE_MODEL( MODEL_V );
    PRECACHE_MODEL( MODEL_W );
    PRECACHE_MODEL( AMMO_MODEL );
    // Sounds
    PRECACHE_SOUND( SOUND_FIRE );
    PRECACHE_SOUND( SOUND_EXPLODE );
        PRECACHE_SOUND( SOUND_RELOAD );
        PRECACHE_SOUND( SOUND_DEPLOY );
    
    // Sprites
    PRECACHE_MODEL( BFG_MODEL );
    g_sModelIndexExplode = PRECACHE_MODEL( BFG_EXPLODE );
        g_sModelIndexExplode2 = PRECACHE_MODEL( BFG_EXPLODE2 );
    // HUD
    for( i = 0; i < sizeof HUD_SPRITES; i++ )
        PRECACHE_GENERIC( HUD_SPRITES[ i ] );
}
//
// Create the weapon and the ammo box
//
public plugin_init( )
{
    register_plugin( "[HL] Weapon BFG", "2", "lastUnit" );
    //
    // Weapon
    //
    new pWeapon = wpnmod_register_weapon
    (
        WEAPON_NAME,
        WEAPON_SLOT,
        WEAPON_POSITION,
        AMMO_NAME,
        AMMO_MAX,
        WEAPON_SECONDARY_AMMO,
        WEAPON_SECONDARY_AMMO_MAX,
        WEAPON_CLIP,
        WEAPON_FLAGS,
        WEAPON_WEIGHT
    );
    
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Spawn,         "CBfg__Spawn" );
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Deploy,     "CBfg__Deploy" );
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Idle,         "CBfg__WeaponIdle" );
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_PrimaryAttack,    "CBfg__PrimaryAttack" );
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Reload,     "CBfg__Reload" );
    wpnmod_register_weapon_forward( pWeapon, Fwd_Wpn_Holster,     "CBfg__Holster" );
    //
    // Ammo
    //
    new pAmmo = wpnmod_register_ammobox( CLASS_BFGBOX );
    
    wpnmod_register_ammobox_forward( pAmmo, Fwd_Ammo_Spawn,         "CBfgAmmo__Spawn" );
    wpnmod_register_ammobox_forward( pAmmo, Fwd_Ammo_AddAmmo,    "CBFGAmmo__AddAmmo" );
}
//
// Spawn
//
public CBfg__Spawn( pItem )
{
    // Set the model
    SET_MODEL( pItem, MODEL_W );
    
    // Give some default ammo
    wpnmod_set_offset_int( pItem, Offset_iDefaultAmmo, AMMO_DEFAULT );
}
//
// Deploy
//
public CBfg__Deploy( pItem, pPlayer )
{
        emit_sound( pPlayer, CHAN_WEAPON, SOUND_DEPLOY, 1.0, 0.7, 0, PITCH_NORM );
    return wpnmod_default_deploy( pItem, MODEL_V, MODEL_P, SEQ_DEPLOY, ANIM_EXTENSION );
}
//
// Hide the weapon
//
public CBfg__Holster( pItem, pPlayer )
{
    // Cancel any reload in progress.
    wpnmod_set_offset_int( pItem, Offset_iInReload, 0 );
}
// 
// Reload the weapon
//
public CBfg__Reload( pItem, pPlayer, iClip, iAmmo )
{
    if( iAmmo <= 0 || iClip >= WEAPON_CLIP )
        return;
    
    emit_sound( pPlayer, CHAN_WEAPON, SOUND_RELOAD, 1.0, 0.7, 0, PITCH_NORM );
    wpnmod_default_reload( pItem, WEAPON_CLIP, SEQ_RELOAD, WEAPON_RELOADTIME );
}
//
// Primary attack
//
public CBfg__PrimaryAttack( pItem, pPlayer, iClip, rgAmmo )
{
    if( iClip <= 0 )
    {
        wpnmod_play_empty_sound( pItem );
        wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, 0.5 );
        return;
    }
    
    if( CBfgb__Spawn( pPlayer ) )
    {
        //fire effects
        wpnmod_set_offset_int( pPlayer, Offset_iWeaponVolume, NORMAL_GUN_VOLUME );
        
        //remove ammo
        wpnmod_set_offset_int( pItem, Offset_iClip, iClip -= 1 );
        
        wpnmod_set_player_anim( pPlayer, PLAYER_ATTACK1 );
    
        wpnmod_set_offset_float( pItem, Offset_flNextPrimaryAttack, WEAPON_REFIRE_RATE );
        wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, WEAPON_REFIRE_RATE + 3.0 );
        
        emit_sound( pPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, 0.7, 0, PITCH_NORM );
        wpnmod_send_weapon_anim( pItem, SEQ_FIRE );
        entity_set_vector( pPlayer, EV_VEC_punchangle, Float:{ 0.0, 0.0, 0.0 } );
    }
}
//
// Weapon idle
//
public CBfg__WeaponIdle( pItem, pPlayer, iClip, iAmmo )
{
    // Reset empty sound
    wpnmod_reset_empty_sound( pItem );
    
    if( wpnmod_get_offset_float( pItem, Offset_flTimeWeaponIdle ) > 0.0 )
        return;
    
    wpnmod_send_weapon_anim( pItem, SEQ_IDLE );
    wpnmod_set_offset_float( pItem, Offset_flTimeWeaponIdle, random_float( 5.0, 15.0 ) );
}
//
// Bfg ball spawn
//
CBfgb__Spawn( pPlayer )
{
    new pBfg = create_entity( "env_sprite" );
    
    if( pBfg <= 0 )
        return 0;
        
    // Kill any old beams
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
    write_byte( TE_KILLBEAM );
    write_short( pBfg );
    message_end( );
        
    // classname
    entity_set_string( pBfg, EV_SZ_classname, CLASS_BFGPLASMA );
    
    // model
    entity_set_model( pBfg, BFG_MODEL );
    
    // origin
    static Float:vecSrc[ 3 ];
    wpnmod_get_gun_position( pPlayer, vecSrc, 0.0, 16.0, -7.0 );
    entity_set_origin( pBfg, vecSrc );

    entity_set_int( pBfg, EV_INT_movetype, MOVETYPE_FLY );
    entity_set_int( pBfg, EV_INT_solid, SOLID_BBOX );
    
    // null size
    entity_set_size( pBfg, gVecZero, gVecZero );
        
        engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 );
    write_byte( TE_EXPLOSION );
    engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
    engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
    engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
    write_short( g_sModelIndexExplode2 );
    write_byte( 20 );
    write_byte( 3 );
    write_byte( TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND );
    message_end( );
    
    // remove black square around the sprite
    entity_set_float( pBfg, EV_FL_renderamt, 255.0 );
    entity_set_float( pBfg, EV_FL_scale, 0.3 );
    entity_set_int( pBfg, EV_INT_rendermode, kRenderTransAdd );
    entity_set_int( pBfg, EV_INT_renderfx, kRenderFxGlowShell );
    
    // velocity
    static Float:vecVelocity[ 3 ];
    velocity_by_aim( pPlayer, BFG_VELOCITY, vecVelocity );
    entity_set_vector( pBfg, EV_VEC_velocity, vecVelocity );
     
    // angles
    static Float:vecAngles[ 3 ];
    engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );
    entity_set_vector( pBfg, EV_VEC_angles, vecAngles );
    
    // owner
    entity_set_edict( pBfg, EV_ENT_owner, pPlayer );
    
    wpnmod_set_touch( pBfg, "CBfgb__Touch" );
    
    return 1;
}
// 
// Bfg ball hit the world
//
public CBfgb__Touch( pBfg, pOther )
{
    if( !is_valid_ent( pBfg ) )
        return;
    
    static Float:vecSrc[ 3 ];
    entity_get_vector( pBfg, EV_VEC_origin, vecSrc );
    
    engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0 );
    write_byte( TE_EXPLOSION );
    engfunc( EngFunc_WriteCoord, vecSrc[ 0 ] );
    engfunc( EngFunc_WriteCoord, vecSrc[ 1 ] );
    engfunc( EngFunc_WriteCoord, vecSrc[ 2 ] );
    write_short( g_sModelIndexExplode );
    write_byte( 30 );
    write_byte( 12 );
    write_byte( TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND );
    message_end( );
    
    emit_sound( 0, CHAN_WEAPON, SOUND_EXPLODE, 1.0, 1.0, 0, PITCH_NORM );
        
    wpnmod_radius_damage( vecSrc, pBfg, entity_get_edict( pBfg, EV_ENT_owner ), WEAPON_DAMAGE, WEAPON_RADIUS, CLASS_NONE, DMG_ACID | DMG_ENERGYBEAM );    
    remove_entity( pBfg );    
}
//
// Fuel spawn
//
public CBfgAmmo__Spawn( pItem )
{
    // Apply new model
    SET_MODEL( pItem, AMMO_MODEL );
}
//
// Give some fuel to the player
//
public CBfgAmmo__AddAmmo( pItem, pPlayer )
{
    new iResult = 
    (
        ExecuteHamB
        (
            Ham_GiveAmmo, 
            pPlayer, 
            WEAPON_CLIP, 
            AMMO_NAME,
            AMMO_MAX
        ) != -1
    );
    
    if( iResult )
    {
        emit_sound( pItem, CHAN_ITEM, SOUND_DEPLOY, 1.0, 0.7, 0, PITCH_NORM );
    }
    
    return iResult;
}
