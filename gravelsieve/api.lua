--[[
TODO: binary instead of linear search
but, the current method shouldn't be a problem unless there's a whole lot of possible outputs
--]]

gravelsieve.api = {}

local mods_loaded = false

local processes = {}
local process_totals = {}
local registered_processes = {}

minetest.register_on_mods_loaded(function()
    gravelsieve.ore_probability = get_ore_frequencies()
    report_probabilities(gravelsieve.ore_probability)
--[[
    for input_name, _ in pairs(inputs) do
        local default_total = 0.0
        local output_total = 0.0
        for _, value in pairs(defaults[input_name]) do
            default_total = default_total + value
        end
        for _, value in pairs(outputs[input_name]) do
            output_total = output_total + value
        end
        default_totals[input_name] = default_total
        output_totals[input_name] = output_total
    end
]]
    mods_loaded = true
end)

local function get_random_output(input_name)
    local random_value = math.random() * output_totals[input_name]
    local running_total = 0
    local last_name = ""
    for output_name, value in pairs(outputs[input_name]) do
        running_total = running_total + value
        if running_total >= random_value then
            return output_name
        end
        last_name = output_name
    end
    return last_name
end

--[[
e.g.
gravelsieve.api.register_input("default:gravel", {
    ["default:gravel"] = 1
    ["default:sand"] = 1
})
--]]

function gravelsieve.api.register_input(input_name, output)
    if mods_loaded then
        -- This is here so you can do hard overrides after everything has loaded if you need to
        -- Otherwise the order mods are loaded may cause them to override your configs
        -- local current_config = gravelsieve.process_probabilities
        -- current_config = configure_probabilities_step(current_config, funct_or_table)
        -- gravelsieve.process_probabilities = normalize_config(current_config)
    else
        -- Build up a list of callbacks to be run after all mods are loaded
        table.insert(registered_processes, funct_or_table)
    end
end

function gravelsieve.api.register_input(input_name, default_chance, default_outputs)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")

    elseif inputs[input_name] or defaults[input_name] or outputs[input_name] then
        error(("re-registering input \"%s\""):format(input_name))

    elseif not minetest.registered_items[input_name] then
        error(("attempt to register unknown node \"%s\""):format(input_name))
    end

    for default_name, _ in pairs(default_outputs) do
        local stack = ItemStack(default_name)
        if not minetest.registered_items[stack:get_name()] then
            error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
        end
    end

    inputs[input_name] = default_chance
    defaults[input_name] = default_outputs
    outputs[input_name] = {}
end

function gravelsieve.api.override_input(input_name, default_chance, default_outputs)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")

    elseif not minetest.registered_items[input_name] then
        error(("attempt to register unknown node \"%s\""):format(input_name))
    end

    for default_name, _ in pairs(default_outputs) do
        local stack = ItemStack(default_name)
        if not minetest.registered_items[stack:get_name()] then
            error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
        end
    end

    inputs[input_name] = default_chance
    defaults[input_name] = default_outputs
    outputs[input_name] = {}
end

function gravelsieve.api.remove_input(input_name)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")
    end

    local default = defaults[input_name]
    local output = outputs[input_name]
    inputs[input_name] = nil
    defaults[input_name] = nil
    outputs[input_name] = nil
    return default, output
end

--[[
e.g.
gravelsieve.api.register_output("default:gravel", "default:iron_lump", 0.01)
--]]
function gravelsieve.api.register_output(input_name, output_name, relative_probability)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")

    elseif outputs[input_name][output_name] then
        error(("re-registering output \"%s\" for \"%s\""):format(input_name, output_name))
    end

    local stack = ItemStack(output_name)
    if not minetest.registered_items[stack:get_name()] then
        error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
    end

    outputs[input_name][output_name] = relative_probability
end

function gravelsieve.api.override_output(input_name, output_name, relative_probability)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")

    end

    local stack = ItemStack(output_name)
    if not minetest.registered_items[stack:get_name()] then
        error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
    end

    outputs[input_name][output_name] = relative_probability
end

function gravelsieve.api.remove_output(input_name, output_name)
    if mods_loaded then
        error("cannot update gravelsieve outputs after mods are loaded")
    end

    local relative_probability = outputs[input_name][output_name]
    outputs[input_name][output_name] = nil
    return relative_probability
end

function gravelsieve.api.can_process(input_name)
    return inputs[input_name]
end

function gravelsieve.api.get_random_output(input_name)
    if not inputs[input_name] then
        gravelsieve.log("warning", "can't get random output for unregistered input \"%s\"", input_name)
        return ""
    end
    if math.random() < inputs[input_name] then
        return get_random_default(input_name)
    else
        return get_random_output(input_name)
    end
end


