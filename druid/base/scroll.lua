--- Component to handle scroll content.
-- Scroll consist from two nodes: scroll parent and scroll input
-- Scroll input the user input zone, it's static
-- Scroll parent the scroll moving part, it will change position.
-- Setup initial scroll size by changing scroll parent size. If scroll parent
-- size will be less than scroll_input size, no scroll is available. For scroll
-- parent size should be more than input size
-- @module druid.scroll

--- Component events
-- @table Events
-- @tfield druid_event on_scroll On scroll move callback
-- @tfield druid_event on_scroll_to On scroll_to function callback
-- @tfield druid_event on_point_scroll On scroll_to_index function callback

--- Component fields
-- @table Fields
-- @tfield node node Scroll parent node
-- @tfield node input_zone Scroll input node
-- @tfield vector3 zone_size Current scroll content size
-- @tfield number soft_size Soft zone size from style table
-- @tfield vector3 center_offset Distance from node to node's center
-- @tfield bool is_inert Flag, if scroll now moving by inertion
-- @tfield vector3 inert Current inert speed
-- @tfield vector3 pos Current scroll posisition
-- @tfield vector3 target Current scroll target position

--- Component style params
-- @table Style
-- @tfield number FRICT_HOLD Multiplier for inertion, while touching
-- @tfield number FRICT Multiplier for free inertion
-- @tfield number INERT_THRESHOLD Scroll speed to stop inertion
-- @tfield number INERT_SPEED Multiplier for inertion speed
-- @tfield number DEADZONE Deadzone for start scrol in pixels
-- @tfield number SOFT_ZONE_SIZE Size of outside zone in pixels (for scroll back moving)
-- @tfield number BACK_SPEED Scroll back returning lerp speed
-- @tfield number ANIM_SPEED Scroll gui.animation speed for scroll_to function

local Event = require("druid.event")
local helper = require("druid.helper")
local const = require("druid.const")
local component = require("druid.component")

local M = component.create("scroll", { const.ON_UPDATE, const.ON_INPUT_HIGH })


-- Global on all scrolls
-- TODO: remove it
M.current_scroll = nil


local function get_border(node)
	local pivot = gui.get_pivot(node)
	local pivot_offset = helper.get_pivot_offset(pivot)
	local size = vmath.mul_per_elem(gui.get_size(node), gui.get_scale(node))
	return vmath.vector4(
		-size.x*(0.5 + pivot_offset.x),
		size.y*(0.5 + pivot_offset.y),
		size.x*(0.5 - pivot_offset.x),
		-size.y*(0.5 - pivot_offset.y)
	)
end


local function update_border(self)
	local input_border = get_border(self.input_zone)
	local content_border = get_border(self.node)

	-- border.x - min content.x node pos
	-- border.y - min content.y node pos
	-- border.z - max content.x node pos
	-- border.w - max content.y node pos
	self.border = vmath.vector4(
		input_border.x - content_border.x,
		-input_border.w + content_border.w,
		input_border.z - content_border.z,
		-input_border.y + content_border.y
	)
	self.can_x = (self.border.x ~= self.border.z)
	self.can_y = (self.border.y ~= self.border.w)
end



local function set_pos(self, pos)
	if self.pos.x ~= pos.x or self.pos.y ~= pos.y then
		self.pos.x = pos.x
		self.pos.y = pos.y
		gui.set_position(self.node, self.pos)

		self.on_scroll:trigger(self:get_context(), self.pos)
	end
end


--- Return scroll, if it outside of scroll area
-- Using the lerp with BACK_SPEED koef
local function check_soft_target(self)
	local t = self.target
	local b = self.border

	if t.y < b.y then
		t.y = helper.step(t.y, b.y, math.abs(t.y - b.y) * self.style.BACK_SPEED)
	end
	if t.x > b.x then
		t.x = helper.step(t.x, b.x, math.abs(t.x - b.x) * self.style.BACK_SPEED)
	end
	if t.y > b.w then
		t.y = helper.step(t.y, b.w, math.abs(t.y - b.w) * self.style.BACK_SPEED)
	end
	if t.x < b.z then
		t.x = helper.step(t.x, b.z, math.abs(t.x - b.z) * self.style.BACK_SPEED)
	end
end


--- Free inert update function
local function update_hand_scroll(self, dt)
	local inert = self.inert
	local delta_x = self.target.x - self.pos.x
	local delta_y = self.target.y - self.pos.y

	if helper.sign(delta_x) ~= helper.sign(inert.x) then
		inert.x = 0
	end
	if helper.sign(delta_y) ~= helper.sign(inert.y) then
		inert.y = 0
	end

	inert.x = inert.x + delta_x
	inert.y = inert.y + delta_y

	inert.x = math.abs(inert.x) * helper.sign(delta_x)
	inert.y = math.abs(inert.y) * helper.sign(delta_y)

	inert.x = inert.x * self.style.FRICT_HOLD
	inert.y = inert.y * self.style.FRICT_HOLD

	set_pos(self, self.target)
end


local function get_zone_center(self)
	return self.pos + self.center_offset
end


--- Find closer point of interest
-- if no inert, scroll to next point by scroll direction
-- if inert, find next point by scroll director
-- @local
local function check_points(self)
	if not self.points then
		return
	end

	local inert = self.inert
	if not self.is_inert then
		if math.abs(inert.x) > self.style.DEADZONE then
			self:scroll_to_index(self.selected - helper.sign(inert.x))
			return
		end
		if math.abs(inert.y) > self.style.DEADZONE then
			self:scroll_to_index(self.selected + helper.sign(inert.y))
			return
		end
	end

	-- Find closest point and point by scroll direction
	-- Scroll to one of them (by scroll direction in priority)
	local temp_dist = math.huge
	local temp_dist_on_inert = math.huge
	local index = false
	local index_on_inert = false
	local pos = get_zone_center(self)
	for i = 1, #self.points do
		local p = self.points[i]
		local dist = helper.distance(pos.x, pos.y, p.x, p.y)
		local on_inert = true
		-- If inert ~= 0, scroll only by move direction
		if inert.x ~= 0 and helper.sign(inert.x) ~= helper.sign(p.x - pos.x) then
			on_inert = false
		end
		if inert.y ~= 0 and helper.sign(inert.y) ~= helper.sign(p.y - pos.y) then
			on_inert = false
		end

		if dist < temp_dist then
			index = i
			temp_dist = dist
		end
		if on_inert and dist < temp_dist_on_inert then
			index_on_inert = i
			temp_dist_on_inert = dist
		end
	end

	self:scroll_to_index(index_on_inert or index)
end


local function check_threshold(self)
	local inert = self.inert
	if not self.is_inert or vmath.length(inert) < self.style.INERT_THRESHOLD then
		check_points(self)
		inert.x = 0
		inert.y = 0
	end
end


local function update_free_inert(self, dt)
	local inert = self.inert
	if inert.x ~= 0 or inert.y ~= 0 then
		self.target.x = self.pos.x + (inert.x * dt * self.style.INERT_SPEED)
		self.target.y = self.pos.y + (inert.y * dt * self.style.INERT_SPEED)

		inert.x = inert.x * self.style.FRICT
		inert.y = inert.y * self.style.FRICT

		-- Stop, when low inert speed and go to points
		check_threshold(self)
	end

	check_soft_target(self)
	set_pos(self, self.target)
end


--- Cancel animation on other animation or input touch
local function cancel_animate(self)
	if self.animate then
		self.target = gui.get_position(self.node)
		self.pos.x = self.target.x
		self.pos.y = self.target.y
		gui.cancel_animation(self.node, gui.PROP_POSITION)
		self.animate = false
	end
end


local function add_delta(self, dx, dy)
	local t = self.target
	local b = self.border
	local soft = self.soft_size

	-- TODO: Can we calc it more easier?
	-- A lot of calculations for every side of border

	-- Handle soft zones
	-- Percent - multiplier for delta. Less if outside of scroll zone
	local x_perc = 1
	local y_perc = 1

	if t.x > b.x and dx < 0 then
		x_perc = (soft - (b.x - t.x)) / soft
	end
	if t.x < b.z and dx > 0 then
		x_perc = (soft - (t.x - b.z)) / soft
	end
	-- If disabled scroll by x
	if not self.can_x then
		x_perc = 0
	end

	if t.y < b.y and dy < 0 then
		y_perc = (soft - (b.y - t.y)) / soft
	end
	if t.y > b.w and dy > 0 then
		y_perc = (soft - (t.y - b.w)) / soft
	end
	-- If disabled scroll by y
	if not self.can_y then
		y_perc = 0
	end

	-- Reset inert if outside of scroll zone
	if x_perc ~= 1 then
		self.inert.x = 0
	end
	if y_perc ~= 1 then
		self.inert.y = 0
	end

	t.x = t.x + dx * x_perc
	t.y = t.y + dy * y_perc
end


--- Component init function
-- @function scroll:init
-- @tparam node scroll_parent Gui node where placed scroll content. This node will change position
-- @tparam node input_zone Gui node where input is catched
function M.init(self, scroll_parent, input_zone)
	self.style = self:get_style()
	self.node = self:get_node(scroll_parent)
	self.input_zone = self:get_node(input_zone)

	self.zone_size = gui.get_size(self.input_zone)
	self.soft_size = self.style.SOFT_ZONE_SIZE

	-- Distance from node to node's center
	local offset = helper.get_pivot_offset(gui.get_pivot(self.input_zone))
	self.center_offset = vmath.vector3(self.zone_size)
	self.center_offset.x = self.center_offset.x * offset.x
	self.center_offset.y = self.center_offset.y * offset.y

	self.is_inert = true
	self.inert = vmath.vector3(0)
	self.pos = gui.get_position(self.node)
	self.target = vmath.vector3(self.pos)

	self.input = {
		touch = false,
		start_x = 0,
		start_y = 0,
		side = false,
	}

	update_border(self)

	self.on_scroll = Event()
	self.on_scroll_to = Event()
	self.on_point_scroll = Event()
end


function M.update(self, dt)
	if self.input.touch then
		if M.current_scroll == self then
			update_hand_scroll(self, dt)
		end
	else
		update_free_inert(self, dt)
	end
end


function M.on_input(self, action_id, action)
	if action_id ~= const.ACTION_TOUCH then
		return false
	end
	local inp = self.input
	local inert = self.inert
	local result = false

	if gui.pick_node(self.input_zone, action.x, action.y) then
		if action.pressed then
			inp.touch = true
			inp.start_x = action.x
			inp.start_y = action.y
			inert.x = 0
			inert.y = 0
			self.target.x = self.pos.x
			self.target.y = self.pos.y
		else
			local dist = helper.distance(action.x, action.y, inp.start_x, inp.start_y)
			if not M.current_scroll and dist >= self.style.DEADZONE then
				local dx = math.abs(inp.start_x - action.x)
				local dy = math.abs(inp.start_y - action.y)
				inp.side = (dx > dy) and const.SIDE.X or const.SIDE.Y

				-- Check scroll side if we can scroll
				if (self.can_x and inp.side == const.SIDE.X or
					self.can_y and inp.side == const.SIDE.Y) then
						M.current_scroll = self
				end
			end
		end
	end

	if inp.touch and not action.pressed then
		if M.current_scroll == self then
			add_delta(self, action.dx, action.dy)
			result = true
		end
	end

	if action.released then
		inp.touch = false
		inp.side = false
		if M.current_scroll == self then
			M.current_scroll = nil
			result = true
		end

		check_threshold(self)
	end

	return result
end


--- Start scroll to target point
-- @function scroll:scroll_to
-- @tparam point vector3 target point
-- @tparam[opt] bool is_instant instant scroll flag
-- @usage scroll:scroll_to(vmath.vector3(0, 50, 0))
-- @usage scroll:scroll_to(vmath.vector3(0), true)
function M.scroll_to(self, point, is_instant)
	local b = self.border
	local target = vmath.vector3(point)
	target.x = helper.clamp(point.x - self.center_offset.x, b.x, b.z)
	target.y = helper.clamp(point.y - self.center_offset.y, b.y, b.w)

	cancel_animate(self)

	self.animate = not is_instant

	if is_instant then
		self.target = target
		set_pos(self, target)
	else
		gui.animate(self.node, gui.PROP_POSITION, target, gui.EASING_OUTSINE, self.style.ANIM_SPEED, 0, function()
			self.animate = false
			self.target = target
			set_pos(self, target)
		end)
	end

	self.on_scroll_to:trigger(self:get_context(), target, is_instant)
end


--- Start scroll to target scroll percent
-- @function scroll:scroll_to_percent
-- @tparam point vector3 target percent
-- @tparam[opt] bool is_instant instant scroll flag
-- @usage scroll:scroll_to_percent(vmath.vector3(0.5, 0, 0))
function M.scroll_to_percent(self, percent, is_instant)
	local border = self.border

	local size_x = math.abs(border.z - border.x)
	if size_x == 0 then
		size_x = 1
	end
	local size_y = math.abs(border.w - border.y)
	if size_y == 0 then
		size_y = 1
	end

	local pos = vmath.vector3(
		-size_x * percent.x + border.x,
		-size_y * percent.y + border.y,
		0)
	M.scroll_to(self, pos, is_instant)
end


--- Scroll to item in scroll by point index
-- @function scroll:init
-- @tparam number index Point index
-- @tparam[opt] bool skip_cb If true, skip the point callback
function M.scroll_to_index(self, index, skip_cb)
	index = helper.clamp(index, 1, #self.points)

	if self.selected ~= index then
		self.selected = index

		if not skip_cb then
			self.on_point_scroll:trigger(self:get_context(), index, self.points[index])
		end
	end

	self:scroll_to(self.points[index])
end


--- Set points of interest.
-- Scroll will always centered on closer points
-- @function scroll:set_points
-- @tparam table points Array of vector3 points
function M.set_points(self, points)
	self.points = points
	-- cause of parent move in other side by y
	for i = 1, #self.points do
		self.points[i].y = -self.points[i].y
	end

	table.sort(self.points, function(a, b)
		return a.x > b.x or a.y < b.y
	end)
	check_threshold(self)
end


--- Enable or disable scroll inert.
-- If disabled, scroll through points (if exist)
-- If no points, just simple drag without inertion
-- @function scroll:set_inert
-- @tparam bool state Inert scroll state
function M.set_inert(self, state)
	self.is_inert = state
end


--- Set the callback on scrolling to point (if exist)
-- @function scroll:on_point_move
-- @tparam function callback Callback on scroll to point of interest
function M.on_point_move(self, callback)
	self.on_point_scroll:subscribe(callback)
end


--- Set the scroll possibly area
-- @function scroll:set_border
-- @tparam vector3 border Size of scrolling area
function M.set_border(self, content_size)
	gui.set_size(self.node, content_size)
	update_border(self)
end


--- Return current scroll progress
-- @function scroll:get_scroll_percent
-- @treturn vector3 Scroll progress
function M.get_scroll_percent(self)
	local border = self.border
	local size_x = math.abs(border.z - border.x)
	if size_x == 0 then
		size_x = 1
	end

	local size_y = math.abs(border.w - border.y)
	if size_y == 0 then
		size_y = 1
	end
	local pos = self.pos

	return vmath.vector3(
		(border.x - pos.x) / size_x,
		(border.y - pos.y) / size_y,
		0
	)
end


return M
