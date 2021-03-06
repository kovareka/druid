local M = {}


local function init_grid(self)
	local prefab = gui.get_node("grid_prefab")

	local grid_scroll = self.druid:new_scroll("grid_content", "scroll_with_grid_size")
	local grid = self.druid:new_grid("grid_content", "grid_prefab", 20)
	grid:set_anchor(vmath.vector3(0, 0.5, 0))

	for i = 1, 40 do
		local clone_prefab = gui.clone_tree(prefab)

		grid:add(clone_prefab["grid_prefab"])
		gui.set_text(clone_prefab["grid_prefab_text"], "Node " .. i)

		local button = self.druid:new_button(clone_prefab["grid_button"], function()
			local position = gui.get_position(clone_prefab["grid_prefab"])
			position.x = -position.x
			grid_scroll:scroll_to(position)
		end)
		button:set_click_zone(gui.get_node("scroll_with_grid_size"))
	end

	gui.set_enabled(prefab, false)

	grid_scroll:set_border(grid:get_size())

	local scroll_slider = self.druid:new_slider("grid_scroll_pin", vmath.vector3(300, 0, 0), function(_, value)
		grid_scroll:scroll_to_percent(vmath.vector3(value, 0, 0), true)
	end)

	grid_scroll.on_scroll:subscribe(function(_, point)
		scroll_slider:set(grid_scroll:get_scroll_percent().x, true)
	end)
end


function M.setup_page(self)
	self.druid:new_scroll("scroll_page_content", "scroll_page")
	self.druid:new_scroll("simple_scroll_content", "simple_scroll_input")

	-- scroll contain scrolls:
	-- parent first
	self.druid:new_scroll("children_scroll_content", "children_scroll")
	-- chilren next
	self.druid:new_scroll("children_scroll_content_1", "children_scroll_1")
	self.druid:new_scroll("children_scroll_content_2", "children_scroll_2")
	self.druid:new_scroll("children_scroll_content_3", "children_scroll_3")

	init_grid(self)
end


return M
