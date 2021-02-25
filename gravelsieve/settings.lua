gravelsieve.settings = {}

local mt_settings = minetest.settings

gravelsieve.settings.step_delay = tonumber(mt_settings:get("gravelsieve.step_delay")) or 1.0

-- tubelib aging feature
if minetest.get_modpath("tubelib") and tubelib ~= nil then
    gravelsieve.settings.aging_level1 = 15 * tubelib.machine_aging_value
    gravelsieve.settings.aging_level2 = 60 * tubelib.machine_aging_value
end

