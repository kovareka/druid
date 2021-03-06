--- Druid constants
-- @local
-- @module const

local M = {}

M.ACTION_TOUCH = hash("touch")
M.ACTION_TEXT = hash("text")
M.ACTION_BACKSPACE = hash("backspace")
M.ACTION_ENTER = hash("enter")
M.ACTION_BACK = hash("back")


M.RELEASED = "released"
M.PRESSED = "pressed"
M.STRING = "string"
M.TABLE = "table"
M.ZERO = "0"
M.ALL = "all"


--- Component Interests
M.ON_MESSAGE = hash("on_message")
M.ON_UPDATE = hash("on_update")
M.ON_INPUT_HIGH = hash("on_input_high")
M.ON_INPUT = hash("on_input")
M.ON_CHANGE_LANGUAGE = hash("on_change_language")
M.ON_LAYOUT_CHANGED = hash("on_layout_changed")


M.PIVOTS = {
	[gui.PIVOT_CENTER] = vmath.vector3(0),
	[gui.PIVOT_N] = vmath.vector3(0, 0.5, 0),
	[gui.PIVOT_NE] = vmath.vector3(0.5, 0.5, 0),
	[gui.PIVOT_E] = vmath.vector3(0.5, 0, 0),
	[gui.PIVOT_SE] = vmath.vector3(0.5, -0.5, 0),
	[gui.PIVOT_S] = vmath.vector3(0, -0.5, 0),
	[gui.PIVOT_SW] = vmath.vector3(-0.5, -0.5, 0),
	[gui.PIVOT_W] = vmath.vector3(-0.5, 0, 0),
	[gui.PIVOT_NW] = vmath.vector3(-0.5, 0.5, 0),
}


M.SPECIFIC_UI_MESSAGES = {
	[M.ON_CHANGE_LANGUAGE] = "on_change_language",
	[M.ON_LAYOUT_CHANGED] = "on_layout_changed"
}


M.UI_INPUT = {
	[M.ON_INPUT_HIGH] = true,
	[M.ON_INPUT] = true
}


M.SIDE = {
	X = "x",
	Y = "y"
}


M.EMPTY_FUNCTION = function() end
M.EMPTY_STRING = ""
M.EMPTY_TABLE = {}


return M