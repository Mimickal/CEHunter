clua_version = 2.042

set_callback("pretick", "PreTick")
set_callback("tick", "OnTick")
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")

weapon_hud_tag_name = "mimickal\\ui\\hunter_weapon\\master"

function OnMapLoad()
	new_map = true
	HudMeterColorInit()
end

function PreTick()
	--SuspendCommandTarget()
end

function OnTick()
	--PlayerUpdateKeysHeld()
	HudMeterColor()
	PartnerHealth()
	FireCommandTrace()
	CatchCommandTrace()
	SuspendCommandTarget()
end

function PlayerUpdateKeysHeld()
	player_ptr = get_dynamic_player()
	
	ConsoleClear()
	console_out(read_u32(0x7FC6A0)) --+ 0x42C)
	--console_out(read_byte(player_ptr+0x206))
	--console_out(read_bit(player_ptr+0x208,14))
	--write_byte(player_ptr+0x208, 0)
	--write_bit(player_ptr+0x208, 19, 1)
	player_ptr = get_player()
	console_out(player_ptr)
	--console_out(read_bit(player_ptr+0x11C, 1))
	--console_out(read_bit(player_ptr+0x11C, 3))
	console_out(read_bit(player_ptr+0x11C, 13))
	
end



----hud meter color values
min_a = 0
min_r = 0
min_g = 0
min_b = 0

max_a = 0
max_r = 0
max_g = 0
max_b = 0

dif_a = 0
dif_r = 0
dif_g = 0
dif_b = 0

heat_cutoff = 0
heat_offset = 0
heat_bound = 0
color_address = 0

function HudMeterColorInit()
	color_address = read_u32(read_u32(get_tag("weapon_hud_interface",weapon_hud_tag_name) + 0x14) + 0x68 + 8) + 0x58
	heat_cutoff = read_u16(read_u32(get_tag("weapon_hud_interface",weapon_hud_tag_name) + 0x14) + 0x18)/100
	heat_offset = 1 - heat_cutoff + 0.01 --+0.01 is to avoid the max value appearing at the end of the first segment
	heat_bound = heat_cutoff - heat_offset
	
	min_a = read_u8(color_address+3)
	min_r = read_u8(color_address+2)
	min_g = read_u8(color_address+1)
	min_b = read_u8(color_address)
	max_a = read_u8(color_address+4+3)
	max_r = read_u8(color_address+4+2)
	max_g = read_u8(color_address+4+1)
	max_b = read_u8(color_address+4)

	dif_a = 0-1*(min_a - max_a)
	dif_r = 0-1*(min_r - max_r)
	dif_g = 0-1*(min_g - max_g)
	dif_b = 0-1*(min_b - max_b)

end

function HudMeterColor()
	local player = get_dynamic_player()
	if player ~= nil and read_float(player + 0xE0) ~= 0 then
		
		local currWeapSlot = read_i16(player + 0x2F2)
		local weapId = read_i16(player+0x2F8+currWeapSlot*4)
		local weapHeat = 0
		if weapId > -1 then
			weapHeat = read_f32(get_object(weapId)+0x23C)
		end
		if weapHeat > 0 then
			if weapHeat < heat_offset then
			write_u8(color_address+3, min_a)
			write_u8(color_address+4+3, min_a)
			write_u8(color_address+2, min_r)
			write_u8(color_address+4+2, min_r)
			write_u8(color_address+1, min_g)
			write_u8(color_address+4+1, min_g)
			write_u8(color_address, min_b)
			write_u8(color_address+4, min_b)
			
			elseif weapHeat > heat_offset and weapHeat < heat_cutoff then
			write_u8(color_address+3, min_a + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_a))
			write_u8(color_address+4+3, min_a + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_a))
			write_u8(color_address+2, min_r + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_r))
			write_u8(color_address+4+2, min_r + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_r))
			write_u8(color_address+1, min_g + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_g))
			write_u8(color_address+4+1, min_g + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_g))
			write_u8(color_address, min_b + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_b))
			write_u8(color_address+4, min_b + math.floor((weapHeat-heat_offset)*(1/heat_bound) * dif_b))
			
			else
			write_u8(color_address+3, max_a)
			write_u8(color_address+4+3, max_a)
			write_u8(color_address+2, max_r)
			write_u8(color_address+4+2, max_r)
			write_u8(color_address+1, max_g)
			write_u8(color_address+4+1, max_g)
			write_u8(color_address, max_b)
			write_u8(color_address+4, max_b)
			end
		end

	end
end


function PartnerHealth()
	local partner_id = GetObjectIdByTag("biped", "characters\\hunter\\hunter_test", 0)
	if partner_id ~= nil then
		local partner_ptr = get_object(partner_id)
		local partner_health = read_f32(partner_ptr+0xE0)

		local player = get_dynamic_player()
		if player ~= nil and read_float(player + 0xE0) ~= 0 then
			write_bit(partner_ptr+0x10, 16, 1) --make dead partner not deletable by garbage collection
			--write_bit(player+0x204, 19, 1)          ]]
			--write_f32(player+0x340, 1)              ]] -- code for old method that changed the flashlight
			--write_f32(player+0x344, partner_health) ]]
			local currWeapSlot = read_i16(player + 0x2F2)
			local weapId = read_i16(player+0x2F8+currWeapSlot*4)
			if weapId > -1 then
				write_f32(get_object(weapId)+0x240, partner_health*-2.555+1) --Age apparently works with explicit values for the alpha
			end
		end
		
	end
end



lastTickActionWasheld = 0
commandTrace_Projectile = "mimickal\\lua\\buddy_command\\projectile"
commandTrace_biped = "mimickal\\lua\\buddy_command\\target"
commandTrace_replacementBiped = "mimickal\\lua\\buddy_command\\target_replaced"
target_loc_x = 0
target_loc_y = 0
target_loc_z = 0
action_held_for = 0
can_execute_command = 1

function FireCommandTrace()
	local player = get_dynamic_player()
	if player ~= nil then
		local actionHeld = read_bit(player+0x208,14)
		if lastTickActionWasheld == 1 then
			if action_held_for > 14 then
				execute_script("ai_follow_target_disable buddy/hunter")
				execute_script("deactivate_team_nav_point_object player target")
				execute_script("ai_follow_target_players buddy/hunter")
				action_held_for = 0
				can_execute_command = 0
				console_out("regroup", 1, 0, 1)
			elseif actionHeld == 0 and can_execute_command == 1 then
				local player_tag = read_u32(get_tag("biped",GetName(player)) + 0x14)
				local crouch_scale = read_f32(player + 0x50C)
				local stand_height = read_f32(player_tag + 0x178 + 0x174 + 0x114)
				local crouch_height = read_f32(player_tag + 0x178 + 0x174 + 0x114 + 4)
				local actual_height = stand_height -((stand_height - crouch_height)*crouch_scale)
				local cam_x,cam_y,cam_z = read_vec3d(player + 0x5C)
				cam_z = cam_z + actual_height
				local cam_dx,cam_dy,cam_dz = read_vec3d(player + 0x23C)
				local projectile_tag_name = commandTrace_Projectile
				projectile_tag = read_u32(get_tag("projectile", projectile_tag_name) + 0x14)
				local projectile_speed = read_f32(projectile_tag + 0x178 + 0x5C + 0xC)
				local projectile = get_object(spawn_object("projectile", projectile_tag_name, cam_x+0.5*cam_dx,cam_y+0.5*cam_dy,cam_z+0.5*cam_dz))
				write_f32(projectile + 0x68, projectile_speed * cam_dx)
				write_f32(projectile + 0x68+4, projectile_speed * cam_dy)
				write_f32(projectile + 0x68+8, projectile_speed * cam_dz)
				lastTickActionWasheld = 0
				--console_out("fired command")
			end
		end
		if actionHeld == 1 then
			lastTickActionWasheld = 1
			action_held_for = action_held_for + 1
		else
			lastTickActionWasheld = 0
			action_held_for = 0
			can_execute_command = 1
		end
		--ConsoleClear()
		--console_out(flashLightHeld)
		--console_out(lastTickFlashlightWasheld)
		--console_out(flashlight_held_for)
		
	end
end



function CatchCommandTrace()
	local target_id = GetObjectIdByTag("biped", commandTrace_biped, 0)
	if target_id ~= nil then
		write_bit(get_object(GetObjectIdByName("target"))+0x10, 16, 0)
		execute_script("object_destroy target")
		
		target_ptr = get_object(target_id)
		target_loc_x,target_loc_y,target_loc_z = read_vec3d(target_ptr+0x5C)
		
		local new_target_ptr = get_object(ObjectCreateAnew("target"))
		write_vec3d(new_target_ptr+0x5C, target_loc_x,target_loc_y,target_loc_z)
		write_bit(new_target_ptr+0x10, 16, 1)

		Delete_AllObjectsByTag("biped", commandTrace_biped)
		execute_script("activate_team_nav_point_object target_blue player target 0.5")
		execute_script("ai_disregard target 1")
		execute_script("ai_follow_target_unit buddy/hunter target")
		execute_script("sound_impulse_start sound\\sfx\\ui\\countdown_timer_end (unit (list_get (players) 0)) 0")
		
		write_vec3d(0x40440000-0x10, target_loc_x, target_loc_y, target_loc_z) --save these to the savegame
		console_out("move to position", 1, 0, 1)
	end
end

function SuspendCommandTarget()
	local target_id = GetObjectIdByTag("biped", commandTrace_replacementBiped, 0)
	if target_id ~= nil then
		local target_ptr = get_object(target_id)
		
		if target_loc_x ~= read_f32(0x40440000-0x10) then -- check prevents checkpoint saves from breaking
			target_loc_x, target_loc_y, target_loc_z = read_vec3d(0x40440000-0x10)
		end
		write_bit(target_ptr+0x10, 0, 1) --turn off collision
		write_bit(target_ptr+0x10, 2, 1) --ignore gravity
		write_bit(target_ptr+0x10, 7, 1) --turn off collision
		write_bit(target_ptr+0x10, 24, 0) --turn off collision
		
		write_vec3d(target_ptr+0x5C, target_loc_x, target_loc_y, target_loc_z)
		write_vec3d(target_ptr+0x68, 0, 0, 0)
		write_vec3d(target_ptr+0x484, 0, 0, 0)
		
		write_f32(target_ptr+0xE0, 0)
	
	end
end


function ObjectCreateAnew(name)
	execute_script("object_create_anew " .. name)
	return GetObjectIdByName(name)
end

function GetObjectIdByName(name)
	local name_id = GetObjectNameListId(name)
	local object_table = read_u32(read_u32(0x401192 + 2))
	local object_count = read_u16(object_table + 0x2E)
	local current_obj_ptr
	for i=0,object_count do
		current_obj_ptr = get_object(i)
		if current_obj_ptr ~= nil then
			if name_id == read_u16(current_obj_ptr+0xBA) then
				return i
			end
		end
	end
	return nil
end

function GetObjectNameListId(name)
	local name_count = read_u32(read_u32(0x40440028+0x14) + 0x204) - 1
	local name_list_ptr = read_u32(read_u32(0x40440028+0x14) + 0x204+4)
	for i=0,name_count do
		if name == read_string(name_list_ptr+0x24*i) then
			return i
		end
	end
	return nil
end


function Delete_AllObjectsByTag(tag_type, tag_path)
	local tag_ptr = get_tag(tag_type, tag_path)
	local object_table = read_u32(read_u32(0x401192 + 2))
	local object_count = read_u16(object_table + 0x2E)
	local current_obj_ptr
	for i=0,object_count do
		current_obj_ptr = get_object(i)
		if current_obj_ptr ~= nil then
			local cur_tag_ptr = get_tag(read_u32(current_obj_ptr))
			if cur_tag_ptr == tag_ptr then
				delete_object(i)
				i=i-1
				object_count = read_u16(object_table + 0x2E)
			end
		end
	end
end

function GetObjectIdByTag(tag_type, tag_path, start_i)
	local tag_ptr = get_tag(tag_type, tag_path)
	local object_table = read_u32(read_u32(0x401192 + 2))
	local object_count = read_u16(object_table + 0x2E)
	local current_obj_ptr
	for i=start_i,object_count do
		current_obj_ptr = get_object(i)
		if current_obj_ptr ~= nil then
			local cur_tag_ptr = get_tag(read_u32(current_obj_ptr))
			if cur_tag_ptr == tag_ptr then
				return i
			end
		end
	end
end


function GetName(object)
	if object ~= 0 then
		return read_string8(read_u32(read_u16(object) * 32 + 0x40440038))
	end
end

function DeleteObject(ID)
	local object = get_object(tonumber(ID))
	if object ~= 0 then
		delete_object(tonumber(ID))
	end
	return false
end

function GetDistance(object, object2)
	local x = read_float(object + 0x5C)
	local y = read_float(object + 0x60)
	local z = read_float(object + 0x64)
	local x1 = read_float(object2 + 0x5C)
	local y1 = read_float(object2 + 0x60)
	local z1 = read_float(object2 + 0x64)
	local x_dist = x1 - x
	local y_dist = y1 - y
	local z_dist = z1 - z
	return math.sqrt(x_dist*x_dist + y_dist*y_dist + z_dist*z_dist)
end

function ConsoleClear()
	for i=1,30 do console_out("") end
end

--special functions for reading game data 

function read_vec3d(address)
--	local x = read_f32(address)
--	local y = read_f32(address+4)
--	local z = read_f32(address+8)
	return read_f32(address),read_f32(address+4),read_f32(address+8)
end

function write_vec3d(dest, i, j, k)
	write_f32(dest, i)
	write_f32(dest+4, j)
	write_f32(dest+8, k)
end

function read_point2d(address)
	local x = read_i16(address)
	local y = read_i16(address+4)
	return x,y
end

function write_point2d(dest, x, y)
	write_i16(dest, x)
	write_i16(dest+2, y)
end

function read_argb(address)
	local a = read_u8(address+3)
	local r = read_u8(address+2)
	local g = read_u8(address+1)
	local b = read_u8(address)
	
	return a,r,g,b
end

function write_argb(dest, a, r, g, b)
	write_u8(address+3, a)
	write_u8(address+2, r)
	write_u8(address+1, g)
	write_u8(address,   b)
end

