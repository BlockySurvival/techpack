gravelsieve.settings = {}

local settings_get
if minetest.setting_get then
	settings_get = minetest.setting_get
else
	settings_get = function(...) return minetest.settings:get(...) end
end

gravelsieve.settings.step_delay = tonumber(settings_get("gravelsieve.step_delay")) or 1.0

-- tubelib aging feature
if minetest.get_modpath("tubelib") and tubelib ~= nil then
    gravelsieve.settings.aging_level1 = 15 * tubelib.machine_aging_value
    gravelsieve.settings.aging_level2 = 60 * tubelib.machine_aging_value
end

