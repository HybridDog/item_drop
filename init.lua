local load_time_start = minetest.get_us_time()


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
		minetest.log("error", "[item_drop] "..player:get_player_name().." doesn't have an inventory.")
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

--[[ optional support for function delayer
local do_step
local delay_function = minetest.delay_function
if delay_function then
	local df = delay_function
	local function delayed_step()
		df(2, do_step)
	end
	function delay_function(time)
		minetest.after(time, delayed_step)
	end
else
	function delay_function(time)
		minetest.after(time, do_step)
	end
end--]]

local function do_step()
	local next_step
	for _,player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if minetest.get_player_privs(pname).interact
		and player:get_hp() > 0
		and not player:get_player_control().sneak then
			local pos = player:getpos()
			pos.y = pos.y+0.5
			for _,object in pairs(minetest.get_objects_inside_radius(pos, 1)) do
				local step = pick_item(object, player)
				if step then
					next_step = step
					break
				end
			end
		end
	end
	minetest.after(next_step or 0.1, do_step)
end

minetest.after(3, do_step)


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[item_drop] loaded after ca. " .. time .. " seconds."
if time > 0.01 then
	print(msg)
else
	minetest.log("info", msg)
end
