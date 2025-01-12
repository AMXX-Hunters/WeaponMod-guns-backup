![WeaponMod Gun Plugins Logo](https://github.com/user-attachments/assets/7422beef-a99e-4460-8fae-7dbc919817f9)
# Half-Life Weaponmod Plugins Backup 

## Description 

Over the years, these plugins have been published on various forums, websites, and other resources dedicated to Half-Life modding. However, over time, these resources may or are already shut down for various reasons: lack of interest from administrators, financial difficulties, absence of support or just a death of the host hard drive. When this happens, the plugins hosted on these platforms are often lost forever, becoming unavailable to server developers.

The goal of this repository is to preserve all plugins using the Weaponmod module in one place, preventing their loss. This not only simplifies the search for necessary content but also allows modders and enthusiasts to focus on development rather than the exhausting task of looking for materials across numerous resources.

The repository creators do not claim authorship of the plugins collected here. On the contrary, wherever possible, information about the authors and the original sources of publication is provided in the descriptions or comments. We deeply respect the work of all developers and aim to preserve their legacy by making their work accessible to new generations of players and modders.

This repository is intended solely for archival and educational purposes, bringing together and preserving an important part of Half-Life modding history.

## Installing a Gun Plugin for the Half-Life WeaponMod

This guide will walk you through the steps to install a custom gun plugin for the Half-Life WeaponMod. Ensure you have the WeaponMod on your Half-Life server installed.

- ![Half-Life WeaponMod](https://github.com/tmp64/weaponmod)
---

### Prerequisites

Before starting, ensure you have:
1. **Server using ![ReHLDS](https://github.com/rehlds/ReHLDS) (on Linux) or ![BugfixedHL-Rebased](https://github.com/tmp64/BugfixedHL-Rebased) (on Windows)**
1. **WeaponMod installed**.
2. **AMX Mod X 1.10+ installed and working**.
3. **The plugin resources**:
   - `.sma` file (plugin source code).
   - Additional files (models, sounds, or configs, if provided).

---

### Installation Steps

#### 1. Compile the `.sma` File
1. Navigate to your AMX Mod X installation directory.
   - Look for the `scripting` folder.
2. Place the `.sma` file in the `scripting` folder.
3. Use the `compile.exe` tool in the `scripting` folder to compile the `.sma` file:
   - Run `compile.exe` (double-click it on Windows).
   - After compiling, the `.amxx` file will be generated in the `scripting/compiled` folder.

#### 2. Copy the Compiled Plugin
- Move the newly created `.amxx` file to the following directory: `addons/amxmodx/plugins`
- Add the name of the compiled `.amxx` file to the end of the `plugins.ini` file located in: `addons/amxmodx/configs/plugins.ini`. Example:

```plaintext
my_new_gun.amxx
```
#### 3. Add Additional Resources (if provided)

    Place additional files in their corresponding directories:
        Models (.mdl): Place in the models folder.
        Sounds (.wav, .mp3): Place in the sound folder.
        Sprites (.spr , .txt) : Place in the sprites folder.

#### 4. Restart Your Server

    Restart your Half-Life server to load the plugin.


## List of contents 

### Weapons

* Half-life Opposing Force
  - ![M249: Squad Automatic Weapon](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_m249)
  - ![M40A1: Sniper Rifle](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_sniperrifle)
  - ![Spore Launcher](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_sporelauncher)
  - ![Shock Roach](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_shockroach)
  - ![Barnacle Grapple](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_grapple)
  - ![Combat Knife](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_knife)
  - ![Displacer cannon (by Glaster)](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_displacer)

* Counter-Strike Online
  - ![Ethereal](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ethereal)
  - ![TAR-21: Tavor Assault Rifle](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_tar21)
  - ![Plasma Gun](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_plasmagun)
  - ![Lightning Bazzi-1](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_cart)
  - ![CSO Crossbow](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_cbowex)
  - ![Chainsaw](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_chainsaw)
  - ![Crow-7](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_crow7)
  - ![Light saber](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_cso_lightsaber)
  - ![Cyclone](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_cyclone)
  - ![Double-barreled shotgun](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_dbarrel)
  - ![Infinity single pistol](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_infinity)
  - ![Python desperado](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_desperado)
  - ![Janus 9](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_emace)
  - ![Ethereal](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ethereal)
  - ![SVDEx](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_svdex)
  - ![Paladin](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_paladin)
  - ![Skull 11](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_skull11)
  - ![Skull 4](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_skull4)
  - ![Gilboa](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_gilboa)
  - ![Guitar](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_guitar)
  - ![KSG-12](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ksg12)
  - ![SPAS-12](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_spas12)

* Half-Life 2
  - ![Overwatch_Standard_Issue_Pulse_Rifle(AR2)](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ar2)

* The Specialists
  - ![USAS-12](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_usas12)
  - ![UZI Akimbo](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_uzi_akimbo)

* Unreal Tournament
  - ![Shock Rifle](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_UT_ShockRifle)
  - ![Flak Cannon](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_UT_FlakCannon)

* Team Fortress Classic
  - ![Assault Cannon](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ac)
  - ![Nailgun](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_tfcnailgun)

* Counter Strike 1.6
  - ![Famas](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_famas)
  - [SG550](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_sg550)

* Gunman Chronicles
  - ![Shotgunman](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_shotgunman)

* Poke646
  - ![Xen Shooter](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_xen_shooter)

* Day of Defeat
  - ![MG42](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_mg42)

* Others
  - ![MP5 Scope](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_9mmarS)
  - ![AK-47: Avtomat Kalashnikova](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ak47)
  - ![Armor piercing rifle](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_armorpiercingrifle)
  - ![BFG](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_bfg)
  - ![BlockAR](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_blockar)
  - ![BlockAS](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_blockas)
  - ![C4 Bomb](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_c4_bomb)
  - ![Camera](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_camera)
  - ![Chrone Cannon](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_chronecannon)
  - ![Double Deagle](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_ddeagle)
  - ![Double Kriss](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_dkirss)
  - ![FN Minipara](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_fn_minipara)
  - ![M1 Garand](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_garand)
  - ![M4A1 Scope](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_m4a1scope)
  - ![Medic Kit](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_medkit)
  - ![Mossin Nagant](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_mossin)
  - ![Photongun](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_photongun)
  - ![Railgun](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_railgun)
  - ![RG6 Buldog Grenade Launcher](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_rg6)
  - ![RPG-7](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_rpg7)
  - ![Saiga](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_saiga)
  - ![Satellite Cannon](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_satellite)
  - ![Sciencists Launcher](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_scigun)
  - ![Stealth Box](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/wpn_stealth_box)

  ### Util

* Utilitary plugins
  - ![Wpnmod spawn editor](https://github.com/andreiseverin/WeaponMod-guns-backup/tree/main/util/weaponmod_spawn_editor)

