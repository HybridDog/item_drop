local load_time_start = minetest.get_us_time()


if minetest.settings:get_bool("enable_item_pickup") ~= false then
	local function pick_item(object, player)
		if object:is_player()
		or not vector.equals(object:getvelocity(), {x=0, y=0, z=0}) then
			return
		end
		local ent = object:get_luaentity()
		if not ent
		or ent.name ~= "__builtin:item"
		or ent.itemstring == "" then
			return
		end
		local inv = player:get_inventory()
		if not inv then
			minetest.log("error", "[item_drop] " .. player:get_player_name() ..
				" doesn't have an inventory.")
			return 1
		end
		local item = ItemStack(ent.itemstring)
		if not inv:room_for_item("main", item) then
			return
		end
		minetest.sound_play("item_drop_pickup", {pos = object:getpos(), gain = 0.4})
		ent.itemstring = ""
		inv:add_item("main", item)
		object:remove()
		return 0.01
	end

	local function pickup_step()
		local next_step
		local players = minetest.get_connected_players()
		for i = 1,#players do
			local player = players[i]
			if not player:get_player_control().sneak
			and minetest.get_player_privs(player:get_player_name()).interact
			and player:get_hp() > 0 then
				local pos = player:getpos()
				pos.y = pos.y + 0.5
				local near_objects = minetest.get_objects_inside_radius(pos, 1)
				for i = 1,#near_objects do
					local object = near_objects[i]
					local step = pick_item(object, player)
					if step then
						next_step = step
						break
					end
				end
			end
		end
		minetest.after(next_step or 0.1, pickup_step)
	end
	minetest.after(3.0, pickup_step)
end

if minetest.settings:get_bool("enable_item_drop") then
	local dropped_removal_delay = tonumber(minetest.setting_get("remove_items"))
	local creative_enabled = minetest.setting_getbool("creative_mode")
	function minetest.handle_node_drops(pos, drops, digger)
		local inv
		if creative_enabled
		and digger
		and digger:is_player() then
			inv = digger:get_inventory()
		end
		for i = 1,#drops do
			local item = drops[i]
			local count, name
			if type(item) == "string" then
				count = 1
				name = item
			else
				count = item:get_count()
				name = item:get_name()
			end
			if not inv
			or not inv:contains_item("main", ItemStack(name)) then
				for _ = 1,count do
					local obj = minetest.add_item(pos, name)
					if obj then
						obj:get_luaentity().collect = true
						local x = math.random(-5, 4)
						if x >= 0 then
							x = x+1
						end
						local z = math.random(-5, 4)
						if z >= 0 then
							z = z+1
						end
						obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})

						-- FIXME this doesnt work for deactiveted objects
						if dropped_removal_delay then
							minetest.after(dropped_removal_delay, function(obj)
								obj:remove()
							end, obj)
						end
					end
				end
			end
		end
	end
end


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[item_drop] loaded after ca. " .. time .. " seconds."
if time > 0.01 then
	print(msg)
else
	minetest.log("info", msg)
end
