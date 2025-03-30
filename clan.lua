local http = require("gamesense/http")

local key_url = "https://raw.githubusercontent.com/24124s1/dsw/refs/heads/main/key.txt" 

http.get(key_url, function(success, response)
    if not success then
        print("Failed to fetch key from server")
        return
    end

    local key = response.body:match("%S+")
    print("Your key is: " .. key)
end)


local clan_tag_toggle = ui.new_checkbox("Misc", "Miscellaneous", "Enable Clan Tag Selector")
local clan_tag_combo
local tag_sequence = {}

local clan_tag_combo = ui.new_combobox("Misc", "Miscellaneous", "Select Clan Tag", "None", "Fortnite.lua", "ESSENTIALS'", "NA defender", "I hate Tortas")

local function update_visibility()
    local enabled = ui.get(clan_tag_toggle)

    ui.set_visible(clan_tag_combo, enabled)
end

local function random_number()
    return tostring(math.random(0, 9))
end

local function generate_tag_sequence(tag)
    local sequence = {}

    for i = 1, #tag do
        local temp_text = tag:sub(1, i - 1) .. random_number() .. "|"
        table.insert(sequence, temp_text)

        temp_text = tag:sub(1, i) .. "|"
        table.insert(sequence, temp_text)
    end

    for _ = 1, 5 do
        table.insert(sequence, tag .. "|")
        table.insert(sequence, tag .. " ")
    end

    for i = #tag, 1, -1 do
        local temp_text = tag:sub(1, i) .. "|"
        table.insert(sequence, temp_text)
    end

    table.insert(sequence, " ")

    return sequence
end

local delay = 0.3
local index = 1
local next_update = globals.realtime()
local is_enabled = false

client.set_event_callback("paint", function()
    is_enabled = ui.get(clan_tag_toggle)
    update_visibility()

    if is_enabled then
        local selected_tag = ui.get(clan_tag_combo)

        if selected_tag == "None" then
            client.set_clan_tag("")
        elseif selected_tag == "Fortnite.lua" then
            if globals.realtime() > next_update then
                if #tag_sequence == 0 then
                    tag_sequence = generate_tag_sequence("Fortnite.lua")
                end
                client.set_clan_tag(tag_sequence[index])
                index = (index % #tag_sequence) + 1
                next_update = globals.realtime() + delay
            end
        elseif selected_tag == "ESSENTIALS'" then
            client.set_clan_tag("ESSENTIALS'")
        elseif selected_tag == "NA defender" then
            client.set_clan_tag("NA defender")
        elseif selected_tag == "I hate Tortas" then
            if globals.realtime() > next_update then
                if #tag_sequence == 0 then
                    tag_sequence = generate_tag_sequence("I hate Tortas")
                end
                client.set_clan_tag(tag_sequence[index])
                index = (index % #tag_sequence) + 1
                next_update = globals.realtime() + delay
            end
        end
    else
        client.set_clan_tag("")
        tag_sequence = {}
    end
end)

local kill_say_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Enable Kill Say")

local function on_player_death(event)
    local local_player = entity.get_local_player()
    local attacker = client.userid_to_entindex(event.attacker)

    if attacker == local_player then
        if ui.get(kill_say_checkbox) then
            if event.headshot == 1 or event.headshot == true then
                client.exec('say 1')
            else
                client.exec('Hush u nn spik')
            end
        end
    end
end

client.set_event_callback("player_death", on_player_death)

local resolver_checkbox = ui.new_checkbox("Rage", "Aimbot", "Enable Resolver")
local resolver_mode = ui.new_combobox("Rage", "Aimbot", "Other Mode", {
    "Standard", "Aggressive", "Freestanding", "Experimental", "Jitter", "Adaptive", "Randomized", "Dynamic", "Hybrid", "Predictive", "LagCompensation"
})
local function resolve_visible()
    local enabled = ui.get(resolver_checkbox)
    ui.set_visible(resolver_mode, enabled)
end

ui.set_callback(resolver_checkbox, resolve_visible)
resolve_visible()

ui.set(resolver_checkbox, true)

local function resolve(index)
    if not entity.is_alive(index) then return end

    local eye_angles_yaw = entity.get_prop(index, "m_angEyeAngles[1]")
    local eye_angles_pitch = entity.get_prop(index, "m_angEyeAngles[0]")
    local lby = entity.get_prop(index, "m_flLowerBodyYawTarget")
    local velocity_x = entity.get_prop(index, "m_vecVelocity[0]")
    local velocity_y = entity.get_prop(index, "m_vecVelocity[1]")
    local velocity = math.sqrt(velocity_x * velocity_x + velocity_y * velocity_y)
    local miss_count = entity.get_prop(index, "m_iShotsMissed") or 0
    local anim_state = entity.get_prop(index, "m_flPoseParameter[11]")
    local lean_amount = entity.get_prop(index, "m_flPoseParameter[0]")

    if not (eye_angles_yaw and eye_angles_pitch and lby and anim_state) then return end

    local yaw_diff = math.abs(((eye_angles_yaw - lby + 180) % 360) - 180)
    local desync_amount = anim_state * 58
    local freestanding_yaw = eye_angles_yaw

    local head_pos = entity.get_hitbox_pos(index, 0)
    local left_visible = entity.is_point_visible(index, head_pos + vec3(-20, 0, 0))
    local right_visible = entity.is_point_visible(index, head_pos + vec3(20, 0, 0))

    if left_visible and not right_visible then
        freestanding_yaw = eye_angles_yaw + 40
    elseif right_visible and not left_visible then
        freestanding_yaw = eye_angles_yaw - 40
    else
        freestanding_yaw = lby
    end

    local mode = ui.get(resolver_mode)
    local resolved_yaw = eye_angles_yaw
    local resolved_pitch = eye_angles_pitch

    if mode == "Standard" then
        if yaw_diff > 30 then
            resolved_yaw = lby
        elseif desync_amount > 20 then
            resolved_yaw = freestanding_yaw
        end
    elseif mode == "Aggressive" then
        resolved_yaw = lby + (miss_count * 45)
    elseif mode == "Freestanding" then
        resolved_yaw = freestanding_yaw
    elseif mode == "Experimental" then
        resolved_yaw = lby + math.random(-90, 90)
    elseif mode == "Jitter" then
        resolved_yaw = (miss_count % 2 == 0) and eye_angles_yaw + 25 or eye_angles_yaw - 25
    elseif mode == "Adaptive" then
        if velocity < 5 then
            resolved_yaw = eye_angles_yaw + 90
        elseif velocity > 50 then
            resolved_yaw = eye_angles_yaw - 45
        else
            resolved_yaw = eye_angles_yaw + (miss_count * 20)
        end
    elseif mode == "Randomized" then
        local random_mode = math.random(1, 4)
        if random_mode == 1 then resolved_yaw = lby + math.random(-30, 30) end
        if random_mode == 2 then resolved_yaw = eye_angles_yaw + math.random(-50, 50) end
        if random_mode == 3 then resolved_yaw = freestanding_yaw + math.random(-40, 40) end
        if random_mode == 4 then resolved_yaw = lby - math.random(30, 60) end
    elseif mode == "Dynamic" then
        resolved_yaw = eye_angles_yaw + (miss_count * 30) + math.random(-15, 15)
    elseif mode == "Hybrid" then
        if miss_count % 2 == 0 then
            resolved_yaw = lby + (miss_count * 45)
        else
            resolved_yaw = (miss_count % 2 == 0) and eye_angles_yaw + 25 or eye_angles_yaw - 25
        end
    elseif mode == "Predictive" then
        resolved_yaw = eye_angles_yaw + (miss_count * 20) + math.random(-20, 20)
    elseif mode == "LagCompensation" then
        resolved_yaw = eye_angles_yaw + math.random(-10, 10) + (miss_count * 40)
    end

    if miss_count >= 1 then resolved_yaw = resolved_yaw + 110 end
    if miss_count >= 2 then resolved_yaw = resolved_yaw - 220 end
    if miss_count >= 3 then resolved_yaw = resolved_yaw + 110 end
    if miss_count >= 4 then resolved_yaw = resolved_yaw + 220 end

    if eye_angles_pitch > 45 then
        resolved_pitch = 89
    elseif eye_angles_pitch < -45 then
        resolved_pitch = -89
    else
        resolved_pitch = 0
    end

    local head_yaw = math.atan2(head_pos.y - entity.get_origin(index).y, head_pos.x - entity.get_origin(index).x) * 180 / math.pi
    if math.abs(resolved_yaw - head_yaw) > 5 then
        resolved_yaw = head_yaw
    end

    local head_pitch = math.atan2(head_pos.z - entity.get_origin(index).z, math.sqrt((head_pos.x - entity.get_origin(index).x)^2 + (head_pos.y - entity.get_origin(index).y)^2)) * 180 / math.pi
    resolved_pitch = head_pitch

    if velocity < 2 then
        resolved_yaw = eye_angles_yaw + 110
    elseif velocity > 10 then
        resolved_yaw = velocity > 100 and eye_angles_yaw + 55 or eye_angles_yaw - 55
    end

    if lean_amount > 0.5 then
        resolved_yaw = eye_angles_yaw + 25
    else
        resolved_yaw = eye_angles_yaw - 25
    end

    resolved_yaw = resolved_yaw + math.random(-8, 8)
    resolved_yaw = resolved_yaw + math.random(-15, 15)
    resolved_yaw = resolved_yaw + math.random(-12, 12)

    entity.set_prop(index, "m_angEyeAngles[1]", resolved_yaw)
    entity.set_prop(index, "m_angEyeAngles[0]", resolved_pitch)
end

client.set_event_callback("paint", function()
    if ui.get(resolver_checkbox) then
        for _, index in pairs(entity.get_players(true)) do
            resolve(index)
        end
    end
end)

local enable_viewmodel = ui.new_checkbox("VISUALS", "Effects", "Enable Viewmodel Changer")

-- Sliders for adjusting viewmodel X, Y, Z, and FOV, now with a range of -10 to 10
local viewmodel_fov = ui.new_slider("VISUALS", "Effects", "Viewmodel FOV", 0, 100, 60)
local viewmodel_x = ui.new_slider("VISUALS", "Effects", "Viewmodel X", -10, 10, 0)
local viewmodel_y = ui.new_slider("VISUALS", "Effects", "Viewmodel Y", -10, 10, 0)
local viewmodel_z = ui.new_slider("VISUALS", "Effects", "Viewmodel Z", -10, 10, 0)

-- Function to update viewmodel settings
local updateViewmodel = function()
    if ui.get(enable_viewmodel) then
        -- Setting the viewmodel parameters based on slider values
        client.set_cvar("viewmodel_fov", ui.get(viewmodel_fov))
        client.set_cvar("viewmodel_offset_x", ui.get(viewmodel_x))
        client.set_cvar("viewmodel_offset_y", ui.get(viewmodel_y))
        client.set_cvar("viewmodel_offset_z", ui.get(viewmodel_z))
    end
end

-- Adding a callback to update the viewmodel whenever there's a change in the sliders or checkbox
ui.set_callback(enable_viewmodel, updateViewmodel)
ui.set_callback(viewmodel_fov, updateViewmodel)
ui.set_callback(viewmodel_x, updateViewmodel)
ui.set_callback(viewmodel_y, updateViewmodel)
ui.set_callback(viewmodel_z, updateViewmodel)

-- Initial update when the script is loaded
updateViewmodel()


local buybot_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Enable Buybot")
local disable_on_pistol_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Disable Buybot on Pistol Round")

local primary_weapon_combo = ui.new_combobox("Misc", "Miscellaneous", "Primary Weapon", {
    "None", "AK-47", "M4A4", "M4A1-S", "AWP", "SG553", "UMP45", "P90", "MAC-10", "Nova", "Mag7", "SSG 08", 
    "SCAR-20 / G3SG1", "FAMAS", "Galil AR"
})

local secondary_weapon_combo = ui.new_combobox("Misc", "Miscellaneous", "Secondary Weapon", {
    "None", "Glock", "USP-S", "P250", "Deagle", "Tec-9 / Five-SeveN", "CZ75", "Dual Berettas"
})

local grenades_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Grenades")
local armor_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Kevlar")
local taser_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Taser")
local auto_clear_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Auto clear console (less kicks)")

local bought_this_round = false

local function reset_buybot()
    bought_this_round = false
end

local function update_visibility()
    local enabled = ui.get(buybot_checkbox)
    
    ui.set_visible(disable_on_pistol_checkbox, enabled)
    ui.set_visible(primary_weapon_combo, enabled)
    ui.set_visible(secondary_weapon_combo, enabled)
    ui.set_visible(grenades_checkbox, enabled)
    ui.set_visible(armor_checkbox, enabled)
    ui.set_visible(taser_checkbox, enabled)
    ui.set_visible(auto_clear_checkbox, enabled)
end

ui.set_callback(buybot_checkbox, update_visibility)
update_visibility() 

local function has_weapon(weapon_name)
    local current_weapon = entity.get_player_weapon(entity.get_local_player())
    return current_weapon == weapon_name
end

local function buy_weapon()
    if bought_this_round then return end
    
    bought_this_round = true
    client.delay_call(0.3, function()
        local primary_weapon = ui.get(primary_weapon_combo)
        local secondary_weapon = ui.get(secondary_weapon_combo)

        local buy_commands = {}

        if primary_weapon and primary_weapon ~= "None" then
            local primary_weapon_cmd = {
                ["AK-47"] = "buy ak47",
                ["M4A4"] = "buy m4a4",
                ["M4A1-S"] = "buy m4a1_silencer",
                ["AWP"] = "buy awp",
                ["SG553"] = "buy sg553",
                ["UMP45"] = "buy ump45",
                ["P90"] = "buy p90",
                ["MAC-10"] = "buy mac10",
                ["Nova"] = "buy xm1014",
                ["Mag7"] = "buy mag7",
                ["SSG 08"] = "buy ssg08",
                ["SCAR-20 / G3SG1"] = "buy scar20",
                ["FAMAS"] = "buy famas",
                ["Galil AR"] = "buy galilar"
            }
            if primary_weapon_cmd[primary_weapon] and not has_weapon(primary_weapon) then
                table.insert(buy_commands, primary_weapon_cmd[primary_weapon])
            end
        end

        if secondary_weapon and secondary_weapon ~= "None" then
            local secondary_weapon_cmd = {
                ["Glock"] = "buy glock",
                ["USP-S"] = "buy usp_silencer",
                ["P250"] = "buy p250",
                ["Deagle"] = "buy deagle",
                ["Tec-9 / Five-SeveN"] = "buy tec9",
                ["CZ75"] = "buy cz75a",
                ["Dual Berettas"] = "buy elite"
            }
            if secondary_weapon_cmd[secondary_weapon] and not has_weapon(secondary_weapon) then
                table.insert(buy_commands, secondary_weapon_cmd[secondary_weapon])
            end
        end

        if ui.get(grenades_checkbox) then
            table.insert(buy_commands, "buy smokegrenade")
            table.insert(buy_commands, "buy hegrenade")
            table.insert(buy_commands, "buy incgrenade")
        end

        if ui.get(armor_checkbox) then
            table.insert(buy_commands, "buy vesthelm")
        end

        if ui.get(taser_checkbox) then
            table.insert(buy_commands, "buy taser")
        end

        for _, cmd in ipairs(buy_commands) do
            client.exec(cmd)
        end

        if ui.get(auto_clear_checkbox) then
            client.exec("clear")
        end
    end)
end

local function buybot_handler()
    if ui.get(buybot_checkbox) and not bought_this_round then
        if not ui.get(disable_on_pistol_checkbox) or not game_rules.is_pistol_round() then
            buy_weapon()
        end
    end
end

client.set_event_callback("round_start", reset_buybot)
client.set_event_callback("player_spawn", buybot_handler)

--------------------------------------------------------------------------------
-- Caching common functions
--------------------------------------------------------------------------------
local ffi = require 'ffi'
local uix = require 'gamesense/uix'
local client_set_event_callback, client_unset_event_callback, client_userid_to_entindex, entity_get_local_player, ui_get, ui_new_checkbox, ui_new_combobox, ui_set_callback, ui_set_visible = client.set_event_callback, client.unset_event_callback, client.userid_to_entindex, entity.get_local_player, ui.get, ui.new_checkbox, ui.new_combobox, ui.set_callback, ui.set_visible

--------------------------------------------------------------------------------
-- FFI functions
--------------------------------------------------------------------------------
local function bind_signature(module, interface, signature, typestring)
	local interface = client.create_interface(module, interface) or error("invalid interface", 2)
	local instance = client.find_signature(module, signature) or error("invalid signature", 2)
	local success, typeof = pcall(ffi.typeof, typestring)
	if not success then
		error(typeof, 2)
	end
	local fnptr = ffi.cast(typeof, instance) or error("invalid typecast", 2)
	return function(...)
		return fnptr(interface, ...)
	end
end

local function vmt_entry(instance, index, type)
	return ffi.cast(type, (ffi.cast("void***", instance)[0])[index])
end

local function vmt_bind(module, interface, index, typestring)
	local instance = client.create_interface(module, interface) or error("invalid interface")
	local success, typeof = pcall(ffi.typeof, typestring)
	if not success then
		error(typeof, 2)
	end
	local fnptr = vmt_entry(instance, index, typeof) or error("invalid vtable")
	return function(...)
		return fnptr(instance, ...)
	end
end

--------------------------------------------------------------------------------
-- Constants, variables, and data structures
--------------------------------------------------------------------------------
local enable_ref
local head_sound_ref
local body_sound_ref
local volume_ref

local sound_names = {}
local sound_name_to_file = {}

local int_ptr	   = ffi.typeof("int[1]")
local char_buffer   = ffi.typeof("char[?]")

local find_first	= bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x6A\x00\xFF\x75\x10\xFF\x75\x0C\xFF\x75\x08\xE8\xCC\xCC\xCC\xCC\x5D", "const char*(__thiscall*)(void*, const char*, const char*, int*)")
local find_next	 = bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x83\xEC\x0C\x53\x8B\xD9\x8B\x0D\xCC\xCC\xCC\xCC", "const char*(__thiscall*)(void*, int)")
local find_close	= bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x53\x8B\x5D\x08\x85", "void(__thiscall*)(void*, int)")

local current_directory = bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x56\x8B\x75\x08\x56\xFF\x75\x0C", "bool(__thiscall*)(void*, char*, int)")
local add_to_searchpath = bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x81\xEC\xCC\xCC\xCC\xCC\x8B\x55\x08\x53\x56\x57", "void(__thiscall*)(void*, const char*, const char*, int)")
local find_is_directory = bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x0F\xB7\x45\x08", "bool(__thiscall*)(void*, int)")

local sndplaydelay = cvar.sndplaydelay
local native_Surface_PlaySound = vmt_bind("vguimatsurface.dll", "VGUI_Surface031", 82, "void(__thiscall*)(void*, const char*)")

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------
local function collect_files()
	local files = {}
	local file_handle = int_ptr()
	local file = find_first("*", "XGAME", file_handle)
	while file ~= nil do
		local file_name = ffi.string(file)
		if find_is_directory(file_handle[0]) == false and (file_name:find(".mp3") or file_name:find(".wav")) then
			files[#files+1] = file_name
		end
		file = find_next(file_handle[0])
	end
	find_close(file_handle[0])
	return files
end

local function normalize_file_name(name)
	if name:find("_") then
		name = name:gsub("_", " ")
	end
	if name:find(".mp3") then
		name = name:gsub(".mp3", "")
	end
	if name:find(".wav") then
		name = name:gsub(".wav", "")
	end
	return name
end

--------------------------------------------------------------------------------
-- Callback functions
--------------------------------------------------------------------------------
local function on_player_hurt(e)
	if client_userid_to_entindex(e.attacker) == entity_get_local_player() then
		local sound_file = sound_name_to_file[e.hitgroup == 1 and ui_get(head_sound_ref) or ui_get(body_sound_ref)]
		if sound_file then
			for i=1, ui_get(volume_ref) do
				native_Surface_PlaySound(sound_file)
			end
		end
	end
end

local function on_player_blind(e)
	if client_userid_to_entindex(e.attacker) == entity_get_local_player() then
		local sound_file = sound_name_to_file[ui_get(body_sound_ref)]
		sndplaydelay:invoke_callback(0, sound_file)
	end
end

local function on_hit_sound_toggle(ref, value)
	local state = value or ui_get(ref)
	ui_set_visible(head_sound_ref, state)
	ui_set_visible(body_sound_ref, state)
	ui_set_visible(volume_ref, state)
end

--------------------------------------------------------------------------------
-- Initilization code
--------------------------------------------------------------------------------
local function init_sound(sound_name, sound_file)
	sound_names[#sound_names+1] = sound_name
	sound_name_to_file[sound_name] = sound_file
end

local function init()

	-- Setup serach path for hitsounds
	local current_path = char_buffer(128)
	current_directory(current_path, ffi.sizeof(current_path))
	current_path = string.format("%s\\csgo\\sound\\hitsounds", ffi.string(current_path))
	add_to_searchpath(current_path, "XGAME", 0)

	-- Collect sound files and add them to the hit sound list
	local sound_files = collect_files()
	for i=1, #sound_files do
		local file_name = sound_files[i]
		init_sound(normalize_file_name(file_name), string.format("hitsounds/%s", file_name))
	end

	enable_ref	  = uix.new_checkbox("Misc", "Miscellaneous", "Hit marker sound")
	head_sound_ref  = ui_new_combobox("Misc", "Miscellaneous", "Head shot sound", sound_names)
	body_sound_ref  = ui_new_combobox("Misc", "Miscellaneous", "Body shot sound", sound_names)
	volume_ref	  = ui.new_slider("Misc", "Miscellaneous", "\nSound volume", 1, 100, 1, true, "%")

	enable_ref:on("change", on_hit_sound_toggle)
	enable_ref:on("player_hurt", on_player_hurt)
	enable_ref:on("player_blind", on_player_blind)
end

init()

local button = ui.new_button("Misc", "Settings", "Disconnect", function()
    client.exec("disconnect")
end)

local button = ui.new_button("Misc", "Settings", "braindead 16k | no roll", function()
    client.exec("connect 193.243.190.35:28026")
end)

local button = ui.new_button("Misc", "Settings", "Infinity HvH | $16k (ACTIVE GIVEAWAY)", function()
    client.exec("connect 74.91.113.70:27015")
end)

local button = ui.new_button("Misc", "Settings", "[NA] EggHvH 🥚| ROLL FIX | 16K |", function()
    client.exec("connect 74.91.124.15:27015")
end)

local button = ui.new_button("Misc", "Settings", "Infinity HvH | Mirage Only", function()
    client.exec("connect 74.91.124.92:27015")
end)

local button = ui.new_button("Misc", "Settings", "Infinity HvH | Deathmatch (ACTIVE GIVEAWAY)", function()
    client.exec("connect 74.91.124.15:27015")
end)
local button = ui.new_button("Misc", "Settings", "[NA] Gobblegum HvH | Deathmatch", function()
    client.exec("connect 45.45.237.252:27015")
end)

local button = ui.new_button("Misc", "Settings", "[infinity] 1x1/2x2/3x3 Public", function()
    client.exec("connect 74.91.112.187:27015")
end)

local button = ui.new_button("Misc", "Settings", "[infinity] 1x1/2x2/3x3 Private", function()
    client.exec("connect 74.91.112.232:27015; password infinityhvh2v2")
end)

local WM_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Watermark")
ui.set(WM_checkbox, true)

local box_width = 300
local box_height = 25
local is_dragging = false
local drag_offset_x = 0
local drag_offset_y = 0

local fade_timer = 0
local last_ping_time = 0
local ping_interval = 60
local ping = 0

local function get_fps()
    return math.floor(1 / globals.frametime())
end

client.set_event_callback("round_start", function()
    local lp = entity.get_local_player()
    if lp then
        ping = entity.get_prop(lp, "m_iPing") or 0
    end
end)

client.set_event_callback("paint", function()
    local lp = entity.get_local_player()
    if not lp then return end

    local fps = get_fps()
    local screen_x, screen_y = client.screen_size()

    local box_x = screen_x - box_width - 10
    local box_y = 10

    fade_timer = fade_timer + globals.frametime() * 0.5
    if fade_timer > 1 then fade_timer = 0 end

    local fade_factor = math.sin(fade_timer * math.pi)
    local text = "diddys.lua|Ping:" .. (ping > 0 and ping or "N/A") .. "ms|FPS:" .. fps

    local r_bar = math.floor(255 * (1 - fade_factor) + 255 * fade_factor)
    local g_bar = math.floor(105 * (1 - fade_factor) + 255 * fade_factor)
    local b_bar = math.floor(180 * (1 - fade_factor) + 255 * fade_factor)

    renderer.rectangle(box_x, box_y, box_width, 2, r_bar, g_bar, b_bar, 255)

    renderer.rectangle(box_x, box_y + 2, box_width, box_height - 2, 30, 30, 40, 200)

    local text_length = string.len(text)
    for i = 1, text_length do
        local char_x = box_x + 10 + (i - 1) * 10
        local char = string.sub(text, i, i)
        
        local fade_position = i / text_length
        local r_value = math.floor(255 * (1 - fade_position) + 255 * fade_position)
        local g_value = math.floor(105 * (1 - fade_position) + 255 * fade_position)
        local b_value = math.floor(180 * (1 - fade_position) + 255 * fade_position)

        renderer.text(char_x, box_y + 5, r_value, g_value, b_value, 255, "d", 0, char)
    end

    box_y = box_y + box_height + 10
end)

client.set_event_callback("mousedown", function(button)
    local mouse_x, mouse_y = input.get_cursor_position()

    if mouse_x >= box_x and mouse_x <= box_x + box_width and mouse_y >= box_y and mouse_y <= box_y + box_height then
        is_dragging = true
        drag_offset_x = mouse_x - box_x
        drag_offset_y = mouse_y - box_y
    end
end)

client.set_event_callback("mouseup", function(button)
    is_dragging = false
end)

client.set_event_callback("mousemove", function()
    if is_dragging then
        local mouse_x, mouse_y = input.get_cursor_position()
        box_x = mouse_x - drag_offset_x
        box_y = mouse_y - drag_offset_y
    end
end)

local Spec_checkbox = ui.new_checkbox("Misc", "Miscellaneous", "Speclist")
ui.set(Spec_checkbox, false)

local box_width = 200
local box_height = 100
local is_dragging = false
local drag_offset_x, drag_offset_y = 0, 0
local screen_x, screen_y = client.screen_size()
local box_x, box_y = screen_x - box_width - 1725, 400

local fade_timer = 0

local function get_spectators(target)
    local spectators = {}
    for i = 1, globals.maxplayers() do
        if not entity.is_alive(i) then
            if entity.get_prop(i, "m_hObserverTarget") == target then
                table.insert(spectators, i)
            end
        end
    end
    return spectators
end

client.set_event_callback("paint", function()
    local lp = entity.get_local_player()
    if not lp then return end

    local target
    if entity.is_alive(lp) then
        target = lp
    else
        target = entity.get_prop(lp, "m_hObserverTarget")
    end

    if not target or target == 0 then return end

    local spectators = get_spectators(target)
    if #spectators == 0 then return end

    box_height = 30 + #spectators * 20
    fade_timer = fade_timer + globals.frametime() * 0.5
    if fade_timer > 1 then fade_timer = 0 end
    local fade_factor = math.sin(fade_timer * math.pi)

    local r_spectator = math.floor(255 * (1 - fade_factor) + 255 * fade_factor)
    local g_spectator = math.floor(105 * (1 - fade_factor) + 255 * fade_factor)
    local b_spectator = math.floor(180 * (1 - fade_factor) + 255 * fade_factor)
    
    renderer.text(box_x + box_width / 2, box_y + 10, r_spectator, g_spectator, b_spectator, 255, "c", 0, "Spectators")

    renderer.rectangle(box_x + 10, box_y + 30, box_width - 20, 2, r_spectator, g_spectator, b_spectator, 255)

    for i, spectator in ipairs(spectators) do
        local name = entity.get_player_name(spectator) or "Unknown"
        
        local player_fade_timer = fade_timer + (i * 0.1)
        if player_fade_timer > 1 then player_fade_timer = 0 end
        local player_fade_factor = math.sin(player_fade_timer * math.pi)

        local r_name = math.floor(255 * (1 - player_fade_factor) + 255 * player_fade_factor)
        local g_name = math.floor(255 * (1 - player_fade_factor) + 255 * player_fade_factor)
        local b_name = math.floor(255 * (1 - player_fade_factor) + 255 * player_fade_factor)
        
        renderer.text(box_x + 10, box_y + 40 + (i * 15), r_name, g_name, b_name, 255, "d", 0, name)
    end
end)

client.set_event_callback("mouse", function(button, down)
    if button ~= 1 then return end
    local mouse_x, mouse_y = input.get_cursor_position()

    if down then
        if mouse_x >= box_x and mouse_x <= box_x + box_width and mouse_y >= box_y and mouse_y <= box_y + 30 then
            is_dragging = true
            drag_offset_x = mouse_x - box_x
            drag_offset_y = mouse_y - box_y
        end
    else
        is_dragging = false
    end
end)

client.set_event_callback("paint_ui", function()
    if is_dragging then
        local mouse_x, mouse_y = input.get_cursor_position()
        box_x = mouse_x - drag_offset_x
        box_y = mouse_y - drag_offset_y
    end
end)

local backtrack = {
    records = {},
    maxTicks = nil, 
    enabled = true,
    autoSet = true
}

local ui_toggle = ui.new_checkbox("RAGE", "Other", "Enable Backtrack")
local ui_auto_set = ui.new_checkbox("RAGE", "Other", "Auto Set Server Tickrate(recommend)")
local ui_slider = ui.new_slider("RAGE", "Other", "Backtrack Ticks", 1, 128, 12)

local function update_visibility()
    local enabled = ui.get(ui_toggle)

    ui.set_visible(ui_auto_set, enabled)
    ui.set_visible(ui_slider, enabled)
end

ui.set_callback(ui_toggle, update_visibility)
update_visibility()

local function get_server_tickrate()
    return math.floor(1 / globals.tickinterval())
end

client.set_event_callback("create_move", function(cmd)
    if not ui.get(ui_toggle) then
        return
    end

    if ui.get(ui_toggle) then
        if ui.get(ui_auto_set) then
            local auto_maxTicks = get_server_tickrate()
            ui.set(ui_slider, auto_maxTicks) 
            backtrack.maxTicks = auto_maxTicks
        else
            backtrack.maxTicks = ui.get(ui_slider)
        end
    end

    local localPlayer = entity.get_local_player()
    if not localPlayer or not entity.is_alive(localPlayer) then return end

    for i = 1, globals.maxplayers() do
        local player = entity.get_player(i)
        if player and entity.get_prop(player, "m_iTeamNum") ~= entity.get_prop(localPlayer, "m_iTeamNum") and entity.is_alive(player) then
            local records = backtrack.records[i] or {}

            table.insert(records, {
                tick = globals.tickcount(),
                simTime = entity.get_prop(player, "m_flSimulationTime"),
                hitboxPos = entity.hitbox_position(player, 0)
            })

            while #records > backtrack.maxTicks do
                table.remove(records, 1)
            end

            backtrack.records[i] = records
        end
    end
end)

client.set_event_callback("create_move", function(cmd)
    if not ui.get(ui_toggle) then return end

    local localPlayer = entity.get_local_player()
    if not localPlayer or not entity.is_alive(localPlayer) then return end

    if bit.band(cmd.buttons, 1) == 1 then 
        local bestTarget = nil
        local bestSimTime = 0

        for i = 1, globals.maxplayers() do
            local player = entity.get_player(i)
            if player and entity.get_prop(player, "m_iTeamNum") ~= entity.get_prop(localPlayer, "m_iTeamNum") and entity.is_alive(player) then
                local records = backtrack.records[i]
                if records and #records > 0 then
                    for _, record in ipairs(records) do
                        -- Find the record with the best simulation time
                        if record.simTime > bestSimTime then
                            bestSimTime = record.simTime
                            bestTarget = record
                        end
                    end
                end
            end
        end

        if bestTarget then
            cmd.tick_count = bestTarget.tick
        end
    end
end)

