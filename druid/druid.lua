--- Druid UI Library.
-- Powerful Defold component based UI library. Use standart
-- components or make your own game-specific components to
-- make amazing GUI in your games.
--
-- Contains the several basic components and examples
-- to how to do your custom complex components to
-- separate UI game logic to small files
--
--    require("druid.druid")
--    function init(self)
--        self.druid = druid.new(self)
--    end
--
-- @module druid

local const = require("druid.const")
local druid_instance = require("druid.system.druid_instance")
local settings = require("druid.system.settings")

local default_style = require("druid.styles.default.style")

local M = {}


--- Register external druid component.
-- After register you can create the component with
-- druid_instance:new_{name}. For example `druid:new_button(...)`
-- @function druid:register
-- @tparam string name module name
-- @tparam table module lua table with component
function M.register(name, module)
	-- TODO: Find better solution to creating elements?
	-- Current way is very implicit
	druid_instance["new_" .. name] = function(self, ...)
		return druid_instance.create(self, module, ...)
	end
end


--- Create Druid instance.
-- @function druid.new
-- @tparam table context Druid context. Usually it is self of script
-- @tparam[opt] table style Druid style module
-- @treturn druid_instance Druid instance
function M.new(context, style)
	if settings.default_style == nil then
		M.set_default_style(default_style)
	end
	return druid_instance(context, style)
end


-- Set new default style.
-- @function druid.set_default_style
-- @tparam table style Druid style module
function M.set_default_style(style)
	settings.default_style = style
end


-- Set text function.
-- Druid locale component will call this function
-- to get translated text. After set_text_funtion
-- all existing locale component will be updated
-- @function druid.set_text_function(callback)
-- @tparam function callback Get localized text function
function M.set_text_function(callback)
	settings.get_text = callback or const.EMPTY_FUNCTION
	-- TODO: Update all localized text
	-- Need to store all current druid instances to iterate over it?
end


-- Set sound function.
-- Component will call this function to
-- play sound by sound_id
-- @function druid.set_sound_function
-- @tparam function callback Sound play callback
function M.set_sound_function(callback)
	settings.play_sound = callback or const.EMPTY_FUNCTION
end


return M
