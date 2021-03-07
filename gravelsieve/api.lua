--[[
TODO: binary instead of linear search
but, the current method shouldn't be a problem unless there's a whole lot of possible outputs
--]]

gravelsieve.api = {}

local processes = {}
local process_totals = {}

local output_types = {"fixed","relative","dynamic"}
local output_types_reversed = {fixed=1,relative=2,dynamic=3}
local default_output_type = "relative"
local function output_type_has_total(output_type)
    return output_type ~= "dynamic"
end

local ore_frequencies = {}
local ores_calculated = false
local after_ores_calculated_callbacks = {}
function gravelsieve.api.after_ores_calculated(callback)

    if type(callback) ~= 'function' then
        error("Gravelsieve after_ores_calculated callbacks must be functions.")
    end

    if ores_calculated then
        callback(table.copy(ore_frequencies))
    else
        table.insert(after_ores_calculated_callbacks, callback)
    end
end

minetest.register_on_mods_loaded(function()
    ore_frequencies = gravelsieve.api.get_ore_frequencies()
    gravelsieve.api.report_probabilities(ore_frequencies)
    ores_calculated = true
    for _,callback in ipairs(after_ores_calculated_callbacks) do
        callback(table.copy(ore_frequencies))
    end
    after_ores_calculated_callbacks = nil
end)

function gravelsieve.api.reset_config()
    processes = {}
    process_totals = {}
end

--[[
e.g.
gravelsieve.api.register_input("default:gravel", {
    ["default:gravel"] = 1,
    ["default:sand"] = 1,
    ["default:coal_lump"] = 0.1
})
--]]
function gravelsieve.api.register_input(input_name, outputs)

    if gravelsieve.api.can_process(input_name) then
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

    local outputs_by_type = outputs
    local contains_output_type = false
    for _,output_type in ipairs(output_types) do
        if outputs[output_type] then
            contains_output_type = true
            break
        end
    end
    if not contains_output_type then
        outputs_by_type = { [default_output_type] = outputs }
    end

    processes[input_name] = {}
    process_totals[input_name] = {}
    for _,output_type in ipairs(output_types) do
        processes[input_name][output_type] = {}
        if output_type_has_total(output_type) then
            process_totals[input_name][output_type] = 0
        end
    end

    for output_type, type_outputs in pairs(outputs_by_type) do
        for output_name, output_probability in pairs(type_outputs) do
            gravelsieve.api.register_output(input_name, output_name, output_probability, output_type)
        end
    end
end

function gravelsieve.api.override_input(input_name, outputs)
    gravelsieve.api.remove_input(input_name)
    return gravelsieve.api.register_input(input_name, outputs)
end

function gravelsieve.api.remove_input(input_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot remove an input (%s) that does not exist.", input_name)
        return
    end

    local output = processes[input_name]
    processes[input_name] = nil
    process_totals[input_name] = nil
    return output
end

function gravelsieve.api.swap_input(input_name, new_input_name)
    local old_output = gravelsieve.api.remove_input(input_name)
    return gravelsieve.api.register_input(new_input_name, old_output)
end

function gravelsieve.api.get_outputs(input_name, output_type)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot get outputs for an input (%s) that does not exist.", input_name)
        return
    end

    local process = processes[input_name]
    if output_type then
        if not process[output_type] then
            gravelsieve.log("error", "Cannot get outputs for an output type (%s) that does not exist.", output_type)
            return
        end

        return table.copy(process[output_type])
    end

    return table.copy(process)
end

function gravelsieve.api.get_output(input_name, output_name)
    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot get outputs for an input (%s) that does not exist.", input_name)
        return
    end

    local process = processes[input_name]
    for _,output_type in ipairs(output_types) do
        local val = process[output_type][output_name]
        if val then
            return val, output_type
        end
    end

end

--[[
e.g.
gravelsieve.api.register_output("default:gravel", "default:iron_lump", 0.01)
--]]
function gravelsieve.api.register_output(input_name, output_name, probability, output_type)

    if not output_type then
        output_type = default_output_type
    end

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "You must register the input (%s) before registering the output (%s).", input_name, output_name)
        return
    end

    local existing_value, existing_type = gravelsieve.api.get_output(input_name, output_name)

    if existing_value then
        local message = ("re-registering %s output \"%s\" for \"%s\""):format(output_type, input_name, output_name)
        if existing_type ~= output_type then
            message = message .. (" - already registered as \"%s\" output"):format(existing_type)
        end
        error(message)
    end

    local stack = ItemStack(output_name)
    if not minetest.registered_items[stack:get_name()] then
        error(("attempt to register unknown node \"%s\""):format(stack:get_name()))
    end

    if not output_types_reversed[output_type] then
        error(("attempt to register output with an unknown output type \"%s\""):format(output_type))
    end

    processes[input_name][output_type][output_name] = probability
    if output_type_has_total(output_type) then
        process_totals[input_name][output_type] = process_totals[input_name][output_type] + probability
    end
end

function gravelsieve.api.override_output(input_name, output_name, probability, output_type)
    gravelsieve.api.remove_output(input_name, output_name)
    return gravelsieve.api.register_output(input_name, output_name, probability, output_type)
end

function gravelsieve.api.remove_output(input_name, output_name)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("error", "Cannot remove an output for an input (%s) that does not exist.", input_name)
        return
    end

    local existing_value, existing_type = gravelsieve.api.get_output(input_name, output_name)

    if not existing_value then
        gravelsieve.log("error", "Cannot remove an output (%s) that does not exist.", output_name)
        return
    end

    processes[input_name][existing_type][output_name] = nil
    if output_type_has_total(output_type) then
        process_totals[input_name][existing_type] = process_totals[input_name][existing_type] - existing_value
    end
    return existing_value, existing_type
end

function gravelsieve.api.swap_output(input_name, output_name, new_output_name)
    local old_probability, old_output_type = gravelsieve.api.remove_output(input_name, output_name)
    return gravelsieve.api.register_output(input_name, new_output_name, old_probability, old_output_type)
end

function gravelsieve.api.can_process(input_name)
    return processes[input_name] ~= nil
end

local function get_random_output(probabilities, total)
    local random_value = math.random() * total
    local running_total = 0
    local last_name = ""
    for output_name, value in pairs(probabilities) do
        running_total = running_total + value
        if running_total >= random_value then
            return output_name
        end
        last_name = output_name
    end
    -- This returns the last seen value if floating point errors
    --   result in the probabilities not adding up to the recorded total
    -- This should not affect probabilities significantly
    return last_name
end

local function evaluate_dynamic_outputs(outputs, args)
    local total = 0
    local probabilities = {}

    for output_name, generator in pairs(outputs) do
        local value = generator(args, output_name, total)
        probabilities[output_name] = value
        total = total + value
    end

    return probabilities, total
end

function gravelsieve.api.get_random_output(input_name, ...)

    if not gravelsieve.api.can_process(input_name) then
        gravelsieve.log("warning", "can't get random output for unregistered input \"%s\"", input_name)
        return
    end

    local random_value = math.random()
    local process = processes[input_name]

    local fixed_total = process_totals[input_name]["fixed"]
    if fixed_total > 0 and fixed_total < random_value then
        return get_random_output(process["fixed"], fixed_total)
    end

    local dynamic_probabilities, dynamic_total = evaluate_dynamic_outputs(process["dynamic"], {...})
    if dynamic_total > 0 and fixed_total+dynamic_total < random_value then
        return get_random_output(dynamic_probabilities, dynamic_total)
    end

    return get_random_output(process["relative"], process_totals[input_name]["relative"])
end


