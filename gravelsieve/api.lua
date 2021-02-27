--[[
TODO: binary instead of linear search
but, the current method shouldn't be a problem unless there's a whole lot of possible outputs
--]]

gravelsieve.api = {}

local processes = {}
local process_totals = {}

local after_ores_calculated_callbacks = {}
function gravelsieve.api.after_ores_calculated(callback)
    if type(callback) ~= 'function' then
        error("Gravelsieve after_ores_calculated callbacks must be functions.")
    end
    table.insert(after_ores_calculated_callbacks, callback)
end

minetest.register_on_mods_loaded(function()
    gravelsieve.ore_probability = gravelsieve.api.get_ore_frequencies()
    gravelsieve.api.report_probabilities(gravelsieve.ore_probability)

    for _,callback in ipairs(after_ores_calculated_callbacks) do
        callback(gravelsieve.ore_probability)
    end
end)

--[[
e.g.
gravelsieve.api.register_input("default:gravel", {
    ["default:gravel"] = 1
    ["default:sand"] = 1
    ["default:coal_lump"] = 0.1
})
--]]
function register_input(input_name, outputs, allow_override)

    if not allow_override and gravelsieve.api.can_process(input_name) then
        error(("re-registering input \"%s\""):format(input_name))
    end

    if not minetest.registered_items[input_name] then
        error(("attempt to register unknown node \"%s\""):format(input_name))
    end

    if not outputs then
        outputs = {}
    end

    if type(outputs) == 'string' then
        outputs = { [outputs] = 1 }
    end

    if type(outputs) ~= 'table' then
        error("Gravelsieve outputs must be a table or a string.")
    end

    processes[input_name] = {}
    process_totals[input_name] = 0

    for output_name, output_probability in pairs(outputs) do
        gravelsieve.api.register_output(input_name, output_name, output_probability)
    end
end

function gravelsieve.api.override_input(...)
    return gravelsieve.api.register_input(..., true)
end

function gravelsieve.api.remove_input(input_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot remove an input (%s) that does not exist.", input_name)
        return
    end

    local output = processes[input_name]
    processes[input_name] = nil
    processes_totals[input_name] = nil
    return output
end

function gravelsieve.api.swap_input(input_name, new_input_name)
    local old_output = gravelsieve.api.remove_input(input_name)
    return gravelsieve.api.register_input(new_input_name, old_output)
end

function gravelsieve.api.get_outputs(input_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot get outputs for an input (%s) that does not exist.", input_name)
        return
    end

    return table.copy(processes[input_name])
end

--[[
e.g.
gravelsieve.api.register_output("default:gravel", "default:iron_lump", 0.01)
--]]
function gravelsieve.api.register_output(input_name, output_name, relative_probability, allow_override)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "You must register the input (%s) before registering the output (%s).", input_name, output_name)
        return
    end

    if not allow_override and processes[input_name][output_name] then
        error(("re-registering output \"%s\" for \"%s\""):format(input_name, output_name))
    end

    local stack = ItemStack(output_name)
    if not minetest.registered_items[stack:get_name()] then
        error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
    end

    local current_probability = processes[input_name][output_name] or 0
    processes[input_name][output_name] = relative_probability
    process_totals[input_name] = process_totals[input_name] + relative_probability - current_probability
end
function gravelsieve.api.override_output(...)
    return gravelsieve.api.register_output(..., true)
end

function gravelsieve.api.remove_output(input_name, output_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot remove an output for an input (%s) that does not exist.", input_name)
        return
    end

    local relative_probability = processes[input_name][output_name] or 0
    processes[input_name][output_name] = nil
    process_totals[input_name] = process_totals[input_name] - relative_probability
    return relative_probability
end

function gravelsieve.api.swap_output(input_name, output_name, new_output_name)
    local old_probability = gravelsieve.api.remove_output(input_name, output_name)
    return gravelsieve.api.register_output(input_name, new_output_name, old_probability)
end

function gravelsieve.api.can_process(input_name)
    return processes[input_name] ~= nil
end

function gravelsieve.api.get_random_output(input_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("warning", "can't get random output for unregistered input \"%s\"", input_name)
        return
    end

    local random_value = math.random() * process_totals[input_name]
    local running_total = 0
    local last_name = ""
    for output_name, value in pairs(processes[input_name]) do
        running_total = running_total + value
        if running_total >= random_value then
            return output_name
        end
        last_name = output_name
    end
    -- This returns the last seen value if floating point errors
    --   result in the probabilities not adding up to the recorded total
    -- This should not affect probabilities
    return last_name
end


