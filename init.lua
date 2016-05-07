local function do_step()
	for _,player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if minetest.get_player_privs(pname).interact
		and player:get_hp() > 0
		and not player:get_player_control().sneak then
			local pos = player:getpos()
			pos.y = pos.y+0.5
			local inv
			for _,object in pairs(minetest.get_objects_inside_radius(pos, 1)) do
				if not object:is_player()
				and vector.equals(object:getvelocity(), {x=0, y=0, z=0}) then
					local ent = object:get_luaentity()
					if ent
					and ent.name == "__builtin:item"
					and ent.itemstring ~= "" then
						if not inv then
							inv = player:get_inventory()
							if not inv then
								minetest.log("error", "[item_drop] "..pname.." doesn't have an inventory.")
								break
							end
						end
						local item = ItemStack(ent.itemstring)
						if inv:room_for_item("main", item) then
							minetest.sound_play("item_drop_pickup", {
								to_player = pname,
							})
							ent.itemstring = ""
							inv:add_item("main", item)
							object:remove()
						end
					end
				end
			end
		end
	end

	minetest.after(0.1, do_step)
end

minetest.after(3, do_step)


if minetest.setting_get("log_mods") then
	minetest.log("action", "item_drop loaded")
end
