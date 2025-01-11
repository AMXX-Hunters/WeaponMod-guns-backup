/*
*	WeaponMod Spawn Config Editor
*
*				        by GordonFreeman
*			    http://www.lambda-force.org/
*/

#include <amxmodx>
#include <amxmisc>
#include <hl_wpnmod>
#include <fakemeta>

new editor,bool:handled,bool:loaded

new Array:g_addname
new Array:g_name
new Array:g_coords
new Array:g_config

new sent,fwd

new bool:cfgloaded,bool:cfgtype

new ammoedited[32]
new ammoeditor[4]

public plugin_precache()
	precache_sound("buttons/bell1.wav")

public plugin_init(){
	register_plugin("WeaponMod Spawn Config Editor","0.5","GordonFreeman")
	
	register_clcmd("wpnmod_spawn","fw_StartEdit",ADMIN_RCON," - start weaponmod spawn editor")
	
	register_clcmd("set_ammo","SetAmmoData",ADMIN_RCON)
}

public fw_ConfigMenu(id){
	if(!cfgloaded)
		fw_CfgLoader()
	
	new menu = menu_create("WeaponMod Config Editor","fw_CfgEditorHandler")
	
	new text[256]
	
	menu_additem(menu,"Equipment Config","equipment")
	menu_additem(menu,"Block Config","block")
	menu_additem(menu,"Ammo Config^n^nConfiguration:","ammo")
	
	new map[32]
	get_mapname(map,31)
	
	get_localinfo("amxx_configsdir",text,255)
	formatex(text,255,"%s/weaponmod/weaponmod%s%s.ini",text,cfgtype?"":"-",cfgtype?"":map)
	
	new existscfg = file_exists(text)
	
	formatex(text,255,"%s%s^n",cfgtype?"[ WeaponMod ]":"[ MapConfig ]",existscfg?"":"^n--> Config file will be created")
	
	menu_additem(menu,text,"cfgtype")
	
	menu_additem(menu,"Save Config","save")
	
	menu_display(id,menu)
}

public fw_ConfigEditorMenu(id,configtype,page){
	new menu,stripped[62],info[6]
	new string[62],classname[32],style[2][5]
	
	switch(configtype){
		case 1:{
			menu = menu_create("WeaponMod Equipment Editor","fw_ProMenuHandler")
	
			for(new i;i<ArraySize(g_config);++i){
				ArrayGetString(g_config,i,string,62)
				
				parse(string,classname,31,style[0],4,style[1],4)
				
				if(str_to_num(style[0])!=1)
					continue
					
				formatex(stripped,61,"%s [ %d ]",classname,str_to_num(style[1]))
				
				formatex(info,5,"e%d",i)
				
				menu_additem(menu,stripped,info)
			}
			
			menu_display(id,menu,page)
		}
		case 2:{
			menu = menu_create("WeaponMod Block Editor","fw_ProMenuHandler")
	
			for(new i;i<ArraySize(g_config);++i){
				ArrayGetString(g_config,i,string,62)
				
				parse(string,classname,31,style[0],4,style[1],4)
				
				if(str_to_num(style[0])!=2)
					continue
					
				formatex(stripped,61,"%s [ %s ]",classname,str_to_num(style[1])?"ON":"OFF")
				
				formatex(info,5,"b%d",i)
				
				menu_additem(menu,stripped,info)
			}
			
			menu_display(id,menu,page)
		}
		case 3:{
			menu = menu_create("WeaponMod Ammo Editor","fw_ProMenuHandler")
	
			for(new i;i<ArraySize(g_config);++i){
				ArrayGetString(g_config,i,string,62)
				
				parse(string,classname,31,style[0],4,style[1],4)
				
				if(str_to_num(style[0])!=3)
					continue
					
				formatex(stripped,61,"%s [ %d ]",classname,str_to_num(style[1]))
				
				formatex(info,5,"a%d",i)
				
				menu_additem(menu,stripped,info)
			}
			
			menu_display(id,menu,page)
		}
	}
	
	return PLUGIN_HANDLED
}

public fw_ProMenuHandler(id,menu,item){
	if(item==MENU_EXIT){
		menu_destroy(menu)
		
		fw_ConfigMenu(id)
		
		return PLUGIN_HANDLED
	}
	
	new data[38],name[64]
	new access,callback,page
	
	menu_item_getinfo(menu,item,access,data,37,name,63,callback)
	player_menu_info(id,menu,menu,page)
	
	new string[62],classname[32],style[3][5]
	
	switch(data[0]){
		case 'e':{
			replace(data,4,"e","")
			
			ArrayGetString(g_config,str_to_num(data),string,62)
			
			parse(string,classname,31,style[0],4,style[1],4)
			
			formatex(string,61,"^"%s^" ^"%d^" ^"%d^"",classname,str_to_num(style[0]),str_to_num(style[1])<10?str_to_num(style[1])+1:0)
			
			ArraySetString(g_config,str_to_num(data),string)
			
			fw_ConfigEditorMenu(id,1,page)
		}
		case 'b':{
			replace(data,4,"b","")
			
			ArrayGetString(g_config,str_to_num(data),string,62)
			
			parse(string,classname,31,style[0],4,style[1],4)
			
			formatex(string,61,"^"%s^" ^"%d^" ^"%d^"",classname,str_to_num(style[0]),str_to_num(style[1])?0:1)
			
			ArraySetString(g_config,str_to_num(data),string)
			
			fw_ConfigEditorMenu(id,2,page)
		}
		case 'a':{
			replace(data,4,"a","")
			
			ArrayGetString(g_config,str_to_num(data),string,62)
			
			parse(string,classname,31,style[0],4,style[1],4,style[2],4)
			
			AttemptSetAmmoData(id,classname,str_to_num(data),str_to_num(style[1]),str_to_num(style[2]),page)
		}
	}
	
	return PLUGIN_HANDLED
}

public AttemptSetAmmoData(id,ammoname[],cfgid,current,maxammo,page){
	ammoeditor[0] = menu_create("Set Ammo Value","AmmoMenuHandler")
	ammoeditor[1] = maxammo
	ammoeditor[2] = page
	ammoeditor[3] = cfgid
	
	formatex(ammoedited,31,ammoname)
	
	menu_setprop(ammoeditor[0],MPROP_EXIT,MEXIT_NEVER)
	
	new text[102]
	formatex(text,101,"by GordonFreeman")
	
	menu_additem(ammoeditor[0],text)
	
	formatex(text,101,"Set startup ammo value for:^n   [ %s ] [ %d/%d ]",ammoname,current,maxammo)
	menu_addtext(ammoeditor[0],text)
	
	menu_display(id,ammoeditor[0])
	
	client_cmd(id,"messagemode set_ammo")
}

public AmmoMenuHandler(id,menu,item){
	if(item==MENU_EXIT)
		return PLUGIN_HANDLED
	
	menu_display(id,menu)
	
	return PLUGIN_HANDLED
}

public SetAmmoData(id){
	if(ammoeditor[0]<=0)
		return PLUGIN_HANDLED
		
	new string[128]
	read_args(string,127)
	remove_quotes(string)
	
	new ammo = str_to_num(string)
	
	if(ammo<=ammoeditor[1]&&ammo!=0&&ammo>0){
		formatex(string,127,"^"%s^" ^"3^" ^"%d^" ^"%d^"",ammoedited,str_to_num(string),ammoeditor[1])
		ArraySetString(g_config,ammoeditor[3],string)
	}else{
		client_print(id,print_chat,"[WEAPONMOD] Max ammo value for %s is %d",ammoedited,ammoeditor[1])
	}
	
	fw_ConfigEditorMenu(id,3,ammoeditor[2])
	
	ammoedited[0] = 0
	
	menu_destroy(ammoeditor[0])
	
	ammoeditor[0] = 0
	ammoeditor[1] = 0
	ammoeditor[2] = 0
	ammoeditor[3] = 0
	
	return PLUGIN_HANDLED
}

public fw_CfgLoader(){
	new Trie:g_repeated
	
	g_repeated = TrieCreate()
	g_config = ArrayCreate(42)
	
	new classname[32],temp[42]
	
	for(new i=1;i<=wpnmod_get_weapon_count();++i){
		wpnmod_get_weapon_info(i,ItemInfo_szName,classname,31)
		
		if(!TrieKeyExists(g_repeated,classname)){
			formatex(temp,41,"^"%s^" ^"1^" ^"0^"",classname)
			ArrayPushString(g_config,temp)
			TrieSetCell(g_repeated,classname,1)
			formatex(temp,41,"^"%s^" ^"2^" ^"0^"",classname)
			ArrayPushString(g_config,temp)
		}else
			continue
			
		wpnmod_get_weapon_info(i,ItemInfo_szAmmo1,classname,31)
		
		if(!classname[0])
			continue
		
		if(!TrieKeyExists(g_repeated,classname)){
			formatex(temp,41,"^"%s^" ^"3^" ^"0^" ^"%d^"",classname,wpnmod_get_weapon_info(i,ItemInfo_iMaxAmmo1))
			ArrayPushString(g_config,temp)
			TrieSetCell(g_repeated,classname,1)
		}else
			continue
		
		wpnmod_get_weapon_info(i,ItemInfo_szAmmo2,classname,31)
		
		if(!classname[0])
			continue
		
		if(!TrieKeyExists(g_repeated,classname)){
			formatex(temp,41,"^"%s^" ^"3^" ^"0^" ^"%d^"",classname,wpnmod_get_weapon_info(i,ItemInfo_iMaxAmmo1))
			ArrayPushString(g_config,temp)
			TrieSetCell(g_repeated,classname,1)
		}else
			continue
	}
	
	for(new i=1;i<=wpnmod_get_ammobox_count();++i){
		wpnmod_get_ammobox_info(i,AmmoInfo_szName,classname,31)
		
		if(!TrieKeyExists(g_repeated,classname)){
			formatex(temp,41,"^"%s^" ^"1^" ^"0^"",classname)
			ArrayPushString(g_config,temp)
			TrieSetCell(g_repeated,classname,1)
			formatex(temp,41,"^"%s^" ^"2^" ^"0^"",classname)
			ArrayPushString(g_config,temp)
		}else
			continue
	}
	
	TrieDestroy(g_repeated)
	
	cfgloaded = true
	
	new text[256],map[32]
	
	get_mapname(map,31)
	
	get_localinfo("amxx_configsdir",text,255)
	formatex(text,255,"%s/weaponmod/weaponmod%s%s.ini",text,cfgtype?"":"-",cfgtype?"":map)
	
	new file = fopen(text,"rt")
	
	if(!file)
		return
		
	new wtf[1],valuev[16],cuprev
	
	while(!feof(file)){
		fgets(file,text,255)
		trim(text)
			
		if(text[0]&&text[0]!=';'){
			parse(text,classname,31,wtf,0,valuev,15)
			
			if(!strcmp(classname,"[equipment]")){
				cuprev = 1
				
				continue
			}
			else if(!strcmp(classname,"[block]")){
				cuprev = 2
				
				continue
			}
			else if(!strcmp(classname,"[ammo]")){
				cuprev = 3
				
				continue
			}
				
			SetConfigValue(classname,cuprev,cuprev!=2?str_to_num(valuev):1)
		}
	}
	
	fclose(file)
}

public fw_CfgSaver(id){
	new text[256],map[32]
	
	get_mapname(map,31)
	
	get_localinfo("amxx_configsdir",text,255)
	formatex(text,255,"%s/weaponmod/weaponmod%s%s.ini",text,cfgtype?"":"-",cfgtype?"":map)
	
	new file = fopen(text,"w+")
	
	fprintf(file,"; Weapon Mod Addon: Config Editor ^n")
	fprintf(file,"; %s - map configuration file^n",map)
	fprintf(file,"^n")
	
	new bool:passed
	
	new Array:datasaver = ArrayCreate(42)
	
	new classname[32],style[2][5]
	
	for(new i;i<ArraySize(g_config);++i){
		ArrayGetString(g_config,i,text,255)
		
		parse(text,classname,31,style[0],4,style[1],4)
		
		if(str_to_num(style[0])!=1)
			continue
			
		if(!str_to_num(style[1]))
			continue
			
		if(!passed)
			passed = true
			
		formatex(text,255,"%s %s",classname,style[1])
		ArrayPushString(datasaver,text)
	}
	
	if(passed){
		fprintf(file,"; Set start weapons and items for player on spawn.^n")
		fprintf(file,"[equipment]^n")
	}
	
	for(new i;i<ArraySize(datasaver);++i){
		ArrayGetString(datasaver,i,text,255)
		
		parse(text,classname,31,style[0],4)
		
		fprintf(file,"%s : %s^n",classname,style[0])
	}
	
	ArrayClear(datasaver)
	passed = false
	
	for(new i;i<ArraySize(g_config);++i){
		ArrayGetString(g_config,i,text,255)
		
		parse(text,classname,31,style[0],4,style[1],4)
		
		if(str_to_num(style[0])!=2)
			continue
			
		if(!str_to_num(style[1]))
			continue
			
		if(!passed)
			passed = true
		
		ArrayPushString(datasaver,classname)
	}
	
	if(passed){
		fprintf(file,"^n; Set block for default weapons and ammoboxes.^n")
		fprintf(file,"[block]^n")
	}
	
	for(new i;i<ArraySize(datasaver);++i){
		ArrayGetString(datasaver,i,text,255)
		
		fprintf(file,"%s^n",text)
	}
	
	ArrayClear(datasaver)
	passed = false
	
	for(new i;i<ArraySize(g_config);++i){
		ArrayGetString(g_config,i,text,255)
		
		parse(text,classname,31,style[0],4,style[1],4)
		
		if(str_to_num(style[0])!=3)
			continue
			
		if(!str_to_num(style[1]))
			continue
			
		if(!passed)
			passed = true
			
		formatex(text,255,"%s %s",classname,style[1])
		ArrayPushString(datasaver,text)
	}
	
	if(passed){
		fprintf(file,"^n; Set start ammo for player on spawn.^n")
		fprintf(file,"[ammo]^n")
	}
	
	for(new i;i<ArraySize(datasaver);++i){
		ArrayGetString(datasaver,i,text,255)
		
		parse(text,classname,31,style[0],4)
		
		fprintf(file,"%s : %s^n",classname,style[0])
	}
	
	ArrayDestroy(datasaver)
	
	fprintf(file,"^n")
	fprintf(file,";^n")
	fprintf(file,"; by GordonFreeman^n")
	fprintf(file,"; http://aghl.ru/forum/")
	
	fclose(file)
	
	fw_ConfigMenu(id)
	client_print(id,print_chat,"[WEAPONMOD] Configuration file for %s map saved!",map)
}

SetConfigValue(classname[],type,value){
	new string[62]
	
	new classnamepro[32],style[2][5]
	
	if(type==2){
		formatex(string,61,"^"%s^" ^"%d^" ^"%d^"",classname,type,value)
		ArrayPushString(g_config,string)
		
		return
	}
	
	for(new i;i<ArraySize(g_config);++i){
		ArrayGetString(g_config,i,string,61)
		
		parse(string,classnamepro,31,style[0],4,style[1],4)
		
		if(strcmp(classnamepro,classname))
			continue
			
		if(str_to_num(style[0])!=type)
			continue
			
		formatex(string,61,"^"%s^" ^"%d^" ^"%d^"",classname,type,value)
		ArraySetString(g_config,i,string)
		
		break
	}
}

public fw_CfgEditorHandler(id,menu,item){
	if(item==MENU_EXIT){
		ArrayDestroy(g_config)
		cfgloaded = false
		
		menu_destroy(menu)
		
		fw_EditorMenu(id)
		
		return PLUGIN_HANDLED
	}
	
	new data[38],name[64]
	new access,callback
	
	menu_item_getinfo(menu,item,access,data,37,name,63,callback)
	
	if(!strcmp(data,"equipment")){
		fw_ConfigEditorMenu(id,1,0)
			
		return PLUGIN_HANDLED
	}else if(!strcmp(data,"block")){
		fw_ConfigEditorMenu(id,2,0)
			
		return PLUGIN_HANDLED
	}else if(!strcmp(data,"ammo")){
		fw_ConfigEditorMenu(id,3,0)
			
		return PLUGIN_HANDLED
	}else if(!strcmp(data,"cfgtype")){
		ArrayDestroy(g_config)
		cfgloaded = false
		cfgtype = cfgtype?false:true
			
		fw_ConfigMenu(id)
			
		return PLUGIN_HANDLED
	}else if(!strcmp(data,"save")){
		fw_CfgSaver(id)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}

public fw_StartEdit(id,level,cid){
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(!loaded){
		new menu = menu_create("Start Editor?","fw_MenuHandler")
		menu_additem(menu,"Yes","y1")
		menu_additem(menu,"No","y2")
		
		menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER)
		
		menu_display(id,menu)
	}else{
		fw_EditorMenu(id)
	}
	
	return PLUGIN_HANDLED
}

public fw_MenuHandler(id,menu,item){
	if(item==MENU_EXIT){
		menu_destroy(menu)
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
		
		if(sent)
			engfunc(EngFunc_RemoveEntity,sent)
			
		editor = 0
		
		if(handled)
			fw_EditorMenu(id)
		else{
			set_hudmessage(255, 170, 0, -1.0, 0.30, 0, 6.0, 12.0)
			show_hudmessage(id, "Dont forget save your spawnpoints!")
		}
		
		return PLUGIN_HANDLED
	}
	
	new data[38],name[64]
	new access,callback,page
	
	menu_item_getinfo(menu,item,access,data,37,name,63,callback)
	player_menu_info(id,menu,menu,page)
	
	new key = str_to_num(data[1])
	
	switch(data[0]){
		case 'y':{
			switch(key){
				case 1: fw_LoadSpawnPointsCfg(id)
				case 2: menu_destroy(menu)
			}
		}
		case 's':{
			switch(key){
				case 1: fw_SpawnMenu(id,page)
				case 2: fw_DeleteMenu(id)
				case 4: fw_ConfigMenu(id)
			}
		}
		case 'h':{
			switch(key){
				case 1:{
					fw_Spawn(id)
				}
				case 2:{
					new Float:angle[3]
					pev(sent,pev_angles,angle)
	
					angle[1]+=15.0
		
					if(angle[1]>=360.0)
						angle[1]=0.0
	
					set_pev(sent,pev_angles,angle)
				
					fw_PreSpawnMenu(id)
				}
				case 4:{
					new Float:angle[3]
					pev(sent,pev_angles,angle)
	
					angle[0]+=15.0
		
					if(angle[0]>=360.0)
						angle[0]=0.0
	
					set_pev(sent,pev_angles,angle)
				
					fw_PreSpawnMenu(id)
				}
				case 3:{
					if(fwd)
						unregister_forward(FM_PlayerPreThink,fwd)
						
					page = pev(sent,pev_iuser4)
		
					if(sent)
						engfunc(EngFunc_RemoveEntity,sent)
						
					fw_SpawnMenu(id,page)
				}
			}
		}
		case 'x':{
			fw_DeletePost(id)
		}
		case 'q':{
			fw_SaveSpawnPoints(id)
		}
		case 'j':{
			client_cmd(id,"wp_spawn")
		}
		default:{
			// catch marked item
			if(data[strlen(data)-1]=='z'){
				data[strlen(data)-1] = 0
				
				fw_PreSpawn(id,data,page)
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public fw_EditorMenu(id){
	new menu = menu_create("WeaponMod Spawner","fw_MenuHandler")
	
	menu_additem(menu,"Spawn Item","s1")
	menu_additem(menu,"Delete Item^n","s2")
	
	menu_additem(menu,"Config Editor","s4")
	if(is_plugin_loaded("weapon_framework.amxx",true)!=-1)
		menu_additem(menu,"Weapon FrameWork^n","j")
	
	menu_additem(menu,"Save Changes","q")
	
	editor = id
	handled = false
	
	menu_display(id,menu)
}

public fw_SpawnMenu(id,page){
	if(sent){
		sent = 0
	}
	
	new menu = menu_create("Spawn Item","fw_MenuHandler")
	
	new classname[32],info[38]
	
	for(new i;i<ArraySize(g_addname);++i){
		ArrayGetString(g_addname,i,classname,32)
		
		formatex(info,37,"%sz",classname)	// mark them for menu handler
		
		menu_additem(menu,classname,info)
	}
	
	handled = true
	
	menu_display(id,menu,page)
}

public fw_DeleteMenu(id){
	if(!fwd)
		fwd = register_forward(FM_PlayerPreThink,"fw_EditPreThink")
	else{
		unregister_forward(FM_PlayerPreThink,fwd)
		fwd = register_forward(FM_PlayerPreThink,"fw_EditPreThink")
	}
	
	new menu = menu_create("Delte Item","fw_MenuHandler")
	menu_additem(menu,"Delete It^n","x")
	
	handled = true
	
	menu_display(id, menu, 0)
}

public fw_DeletePost(id){
	new target = get_aiment(id)
	
	if(!target){
		fw_DeleteMenu(id)
		
		return PLUGIN_HANDLED
	}
	
	new classname[32],Float:origin[3],wid
	
	pev(target,pev_classname,classname,31)
	pev(target,pev_origin,origin)
	
	if(target)
		wid = find_id_by_origin(classname,origin)
		
	set_pev(target,pev_renderfx,kRenderFxGlowShell)
	set_pev(target,pev_rendermode,kRenderNormal)
	set_pev(target,pev_rendercolor,{255.0,0.0,0.0})
	set_pev(target,pev_renderamt,96.0)
		
	set_pev(target,pev_movetype,MOVETYPE_NONE)
	set_pev(target,pev_nextthink,1.0)
	set_pev(target,pev_solid,SOLID_NOT)
	
	ArraySetString(g_name,wid,"yandex")
	
	fw_DeleteMenu(id)
	
	return PLUGIN_HANDLED
}

public fw_SaveSpawnPoints(id){
	new classname[32],Float:origin[3],Float:angle[3],Float:sorg[6]
	
	new path[256],count
	
	get_localinfo("amxx_configsdir",path,255)
	formatex(path,255,"%s/weaponmod/spawnpoints/",path)
	
	new map[32]
	get_mapname(map,31)
	
	formatex(path,255,"%s%s.ini",path,map)
	
	new file = fopen(path,"w+")
	if(!file) return
	
	fprintf(file,"; Weapon Mod Addon: Item Spawner^n")
	fprintf(file,"; %s - map configuration file^n",map)
	fprintf(file,"^n")
	
	if(ArraySize(g_name)){
		fprintf(file,"^n;Item        origin (xyz)        angles (pyr)^n")
		for(new i;i<ArraySize(g_name);++i){
			ArrayGetString(g_name,i,classname,31)
			
			if(equal(classname,"yandex"))
				continue
				
			fprintf(file,"%s	",classname)
			
			ArrayGetArray(g_coords,i,sorg)
			
			origin[0] = sorg[0]
			origin[1] = sorg[1]
			origin[2] = sorg[2]
			angle[0] = sorg[3]
			angle[1] = sorg[4]
			angle[2] = sorg[5]
			
			fprintf(file,"^"%.0f %.0f %.0f^"	^"%.0f %.0f %.0f^"^n",origin[0],origin[1],origin[2],angle[0],angle[1],angle[2])
			
			count ++
		}
		
		fprintf(file,"^n")
	}
	
	fprintf(file,"^n")
	fprintf(file,";^n")
	fprintf(file,"; by GordonFreeman^n")
	fprintf(file,"; http://aghl.ru/forum/")
	
	fclose(file)
	
	set_hudmessage(255, 170, 0, -1.0, 0.30, 0, 6.0, 12.0)
	show_hudmessage(id, "Saved!")
	
	client_print(id,print_chat,"[WEAPONMOD] Total %d items saved for %s map",count,map)
	
	return
}

public fw_PreSpawn(id,classname[],page){
	if(fwd||sent){
		engfunc(EngFunc_RemoveEntity,sent)
		sent = 0
		unregister_forward(FM_PlayerPreThink,fwd)
	}
	
	new Float:origin[3],org[3]
	
	get_user_origin(id,org,3)
	
	origin[0] = float(org[0])
	origin[1] = float(org[1])
	origin[2] = float(org[2])
	
	sent = wpnmod_create_item(classname,origin)

	if(sent<0)
		return PLUGIN_HANDLED
	
	set_pev(sent,pev_renderfx,kRenderFxDistort)
	set_pev(sent,pev_rendermode,kRenderTransAdd)
	set_pev(sent,pev_renderamt,128.0)
	
	set_pev(sent,pev_movetype,MOVETYPE_FLY)
	set_pev(sent,pev_nextthink,0.0)
	set_pev(sent,pev_solid,SOLID_NOT)
	
	// mark for page handler
	set_pev(sent,pev_iuser4,page)
	
	fwd = register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	
	fw_PreSpawnMenu(id)
	
	return PLUGIN_HANDLED
}

public fw_PreSpawnMenu(id){
	new title[32]
	pev(sent,pev_classname,title,31)
	
	replace_all(title,32,"weapon_","")
	replace_all(title,32,"ammo_","")
	replace_all(title,32,"item_","")
	ucfirst(title)
	
	format(title,31,"Spawn %s",title)
	new menu = menu_create(title,"fw_MenuHandler")
	
	menu_additem(menu,"Spawn It","h1")
	menu_additem(menu,"Change Yaw Angle","h2")
	menu_additem(menu,"Change Pitch Angle^n","h4")
	menu_additem(menu,"Cancel","h3")
	
	menu_display(id,menu)
}

public fw_Spawn(id){
	if(!sent){
		set_hudmessage(255, 0, 0, -1.0, 0.60, 0, 6.0, 12.0)
		show_hudmessage(id, "Adding Failed, no enitity is selected")
		
		if(fwd)
			unregister_forward(FM_PlayerPreThink,fwd)
		
		return
	}
	
	
	new Float:origin[3],Float:angle[3],Float:all[6],classname[32]
	
	pev(sent,pev_origin,origin)
	pev(sent,pev_classname,classname,31)
	pev(sent,pev_angles,angle)
	
	if(!strcmp(classname,"ammo_spore")){
			angle[0] += 90.0
			origin[2] -= 16.0
	}
	
	set_hudmessage(128, 255, 0, -1.0, 0.60, 0, 6.0, 12.0)
	show_hudmessage(id, "Spawn position added^n[%.2f %.2f %.2f]",origin[0],origin[1],origin[2])
	
	set_pev(sent,pev_renderfx,kRenderFxGlowShell)
	set_pev(sent,pev_rendermode,kRenderNormal)
	set_pev(sent,pev_rendercolor,{128.0,255.0,0.0})
	set_pev(sent,pev_renderamt,160.0)
	set_pev(sent,pev_owner,id)
	
	new data[2]
	data[0] = sent
	data[1] = 160
		
	set_task(0.1,"fw_Working",_,data,2)
	
	all[0] = origin[0]
	all[1] = origin[1]
	all[2] = origin[2]
	all[3] = angle[0]
	all[4] = angle[1]
	all[5] = angle[2]
	
	ArrayPushString(g_name,classname)
	ArrayPushArray(g_coords,all)
	
	if(fwd)
		unregister_forward(FM_PlayerPreThink,fwd)
	
	fw_SpawnMenu(id,pev(sent,pev_iuser4))
}

public fw_Working(data[2]){
	new ent = data[0]
	new Float:amt = float(data[1])
	
	amt -= 25.5
	
	new Float:angles[3]
	pev(ent,pev_angles,angles)
	
	if(amt>0.0){
		set_pev(ent,pev_renderamt,amt)
		new data[2]
		
		data[0] = ent
		data[1] = floatround(amt)
		
		emit_sound(pev(ent,pev_owner),CHAN_STATIC,"buttons/bell1.wav",0.3,ATTN_NORM,0,PITCH_NORM)
		
		set_task(0.1,"fw_Working",_,data,2)
	}
	else{
		new classname[32],Float:origin[3],Float:angles[3]
		
		pev(ent,pev_classname,classname,31)
		pev(ent,pev_origin,origin)
		pev(ent,pev_angles,angles)
		
		engfunc(EngFunc_RemoveEntity,ent)
		
		if(!strcmp(classname,"ammo_spore")){
			angles[0] += 90.0
			origin[2] -= 16.0
		}
		
		wpnmod_create_item(classname,origin,angles)
	}
}

public fw_PlayerPreThink(id){
	if(!sent){
		unregister_forward(FM_PlayerPreThink,fwd)
		return FMRES_HANDLED
	}
	
	if(editor!=id)
		return FMRES_HANDLED
	
	new orig[3],Float:origin[3]
	get_user_origin(id,orig,3)
	
	origin[0] = float(orig[0])
	origin[1] = float(orig[1])
	origin[2] = float(orig[2])
	
	set_pev(sent,pev_origin,origin)
	
	return FMRES_IGNORED
}

public fw_EditPreThink(id){
	if(editor!=id)
		return FMRES_IGNORED
	
	new target = get_aiment(id)
	
	new classname[32],Float:origin[3],Float:angle[3]
	new wid
	
	pev(target,pev_classname,classname,31)
	pev(target,pev_origin,origin)
	pev(target,pev_angles,angle)
	
	if(target)
		wid = find_id_by_origin(classname,origin)
	
	set_hudmessage(255, 0, 0, 0.01, 0.14, 0, 6.0, 0.1,_,_,1)
	show_hudmessage(id, "Delete Item^nID: %d [%s]^nOrigin: [%.1f] [%.1f] [%.1f]^nAngles: [%.1f] [%.1f] [%.1f]^nCFG ID: %d",target,classname,origin[0],origin[1],origin[2],angle[0],angle[1],angle[2],wid)
	
	
	return FMRES_IGNORED
}

public fw_LoadSpawnPointsCfg(id){
	g_addname = ArrayCreate(32)
	g_name = ArrayCreate(32)
	g_coords = ArrayCreate(6)
	
	new path[256],fpath[256],temp[128],classname[32],count
	
	get_localinfo("amxx_configsdir",path,255)
	formatex(path,255,"%s/weaponmod/spawnpoints/",path)
	
	if(!dir_exists(path)){
		client_print(id,print_chat,"[WEAPNMOD] ^"%s^" is not found",path)
		
		return PLUGIN_HANDLED
	}
	
	// load registred weapons
	
	for(new i=1;i<=wpnmod_get_weapon_count();++i){
		if(!wpnmod_get_weapon_info(i,ItemInfo_bCustom))
			continue
			
		wpnmod_get_weapon_info(i,ItemInfo_szName,classname,31)		
		ArrayPushString(g_addname,classname)
			
		count++
	}
	
	// load registred ammo
	
	for(new i=1;i<=wpnmod_get_ammobox_count();++i){
		wpnmod_get_ammobox_info(i,AmmoInfo_szName,classname,31)
		
		ArrayPushString(g_addname,classname)
			
		count++
	}
	
	client_print(id,print_chat,"[WEAPONMOD] Loaded %d items to editing",count)
	
	count = 0
	
	new map[96]
	get_mapname(map,31)
	
	formatex(fpath,255,"%s%s.ini",path,map)
	
	new file = fopen(fpath,"rt")
	
	if(!file){
		loaded=true
		client_print(id,print_chat,"[WEAPONMOD] %s configuration file is not found",map)
		fw_EditorMenu(id)
		
		return PLUGIN_HANDLED
	}
	
	new sorig[20],sangle[20]
	new Float:origin[3],Float:angle[3],Float:all[7]
	
	while(!feof(file)){
		fgets(file,temp,255)
		trim(temp)
			
		if(temp[0]&&!equali(temp,";",1)){
			parse(temp,classname,31,sorig,20,sangle,20)
			
			ParseVec(sorig,19,origin)
			ParseVec(sangle,19,angle)
			
			
			all[0] = origin[0]
			all[1] = origin[1]
			all[2] = origin[2]
			all[3] = angle[0]
			all[4] = angle[1]
			all[5] = angle[2]
			
			ArrayPushString(g_name,classname)
			ArrayPushArray(g_coords,all)
			
			count++
		}
	}
	
	client_print(id,print_chat,"[WEAPONMOD] Loaded %d items from %s configuration file",count,map)
		
	fclose(file)
	
	loaded=true

	fw_EditorMenu(id)
	
	return PLUGIN_HANDLED
}

// Parse Vector Function by KORD_12.7
ParseVec(szString[], iStringLen, Float: Vector[3]){
	new i;
	new szTemp[32];
	
	arrayset(_:Vector, 0, 3);
	
	while (szString[0] != 0 && strtok(szString, szTemp, charsmax(szTemp), szString, iStringLen, ' ', 1))
	{
		Vector[i++] = str_to_float(szTemp);
	}
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

stock get_aiment(id){
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

	if(0<target<=get_maxplayers())
		return 0
	
	new classname[32]
	pev(target,pev_classname,classname,31)
	
	if(equal(classname,"weaponbox"))
		return 0
	
	return target
}

stock find_id_by_origin(classname[],Float:origin[3]){
	new Float:all[8],cl[32]
	
	for(new i;i<ArraySize(g_name);++i){
		ArrayGetString(g_name,i,cl,31)
		ArrayGetArray(g_coords,i,all)
		
		if(!equal(cl,classname))
			continue
						
		if(all[0]!=origin[0]||all[1]!=origin[1])
			continue
			
		return i
	}
	
	return 0
}
