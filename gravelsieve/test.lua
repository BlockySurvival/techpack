-- Automatic...ish tests for api methods
local api = gravelsieve.api

local log_calls = {}
gravelsieve.log = function(...)
    table.insert(log_calls, {...})
end

local function table_eq(a,b)
    if type(a) ~= type(b) then
        return false
    end
    if a == b then
        return true
    end
    if #a ~= #b then
        return false
    end
    for k,v in pairs(a) do
        if b[k] ~= v then
            return false
        end
    end
    for k,v in pairs(b) do
        if a[k] ~= v then
            return false
        end
    end
    return true
end

local function reset_log_calls()
    log_calls = {}
end

local failure_prefix = "[TEST FAILED] "
local function fail_test(reason)
    error(failure_prefix..reason)
end
local function log_called_times(n)
    if n ~= #log_calls then
        fail_test(("gravelsieve.log was called %d times, not %d times"):format(#log_calls, n))
    end
end
local function log_called_with(...)
    local args = {...}
    for _,call_args in ipairs(log_calls) do
        if table_eq(args, call_args) then
            return true
        end
    end
    local arg_str = ""
    for _,arg in ipairs(args) do
        arg_str = arg_str..tostring(arg)..", "
    end
    fail_test("gravelsieve.log was not called with args: "..arg)
end

local expected_error = false
local function expect_error(message)
    if not message then
        expected_error = true
    else
        expected_error = message
    end
end
local function reset_expected_error()
    expected_error = false
end

local failed_tests = {}
local function test(description, callback)
    minetest.log("[gravelsieve] [tests] ".. description)
    reset_log_calls()
    reset_expected_error()
    api.reset_config()
    local success, err = pcall(callback)
    if success then
        if expected_error then
            minetest.log("error", "[gravelsieve] [tests] Error expected but none occurred")
            if type(expected_error) == 'string' then
                minetest.log("error", "[gravelsieve] [tests] Expected: "..expected_error)
            end
            table.insert(failed_tests, description)
        else
            minetest.log("[gravelsieve] [tests] Passed")
        end
    else
        if string.find(err, failure_prefix, 1, true) then
            minetest.log("error", "[gravelsieve] [tests] "..err)
            table.insert(failed_tests, description)
        elseif not expected_error then
            minetest.log("error", "[gravelsieve] [tests] Error occurred but none expected")
            minetest.log("error", "[gravelsieve] [tests] Occurred: "..err)
            table.insert(failed_tests, description)
        else
            if type(expected_error) == 'string' and not string.find(err, expected_error, 1, true) then
                minetest.log("error", "[gravelsieve] [tests] Error occurred was not the one expected")
                minetest.log("error", "[gravelsieve] [tests] Expected: "..expected_error)
                minetest.log("error", "[gravelsieve] [tests] Occurred: "..err)
                table.insert(failed_tests, description)    
            else
                minetest.log("[gravelsieve] [tests] Passed")
            end
        end
    end
end

-- collect all registered ores and calculate the probability
-- api.get_ore_frequencies()

test("report_probabilities prints out correct values", function ()
    api.report_probabilities({
        test1 = 1,
        test2 = 2,
        test3 = 4
    })
    log_called_times(5)
    log_called_with("action", "ore probabilities:")
    log_called_with("action", "%-32s: 1 / %.02f", "test1", 1)
    log_called_with("action", "%-32s: 1 / %.02f", "test2", 0.5)
    log_called_with("action", "%-32s: 1 / %.02f", "test3", 0.25)
    log_called_with("action", "Overall probability %f", 7)
end)

test("sum_probabilities properly adds up all values in table", function ()

    local sum_result = api.sum_probabilities({
        test1 = 1,
        test2 = 2,
        test3 = 4
    })
    if sum_result ~= 7 then
        fail_test(("sum result is %d instead of 7"):format(sum_result))
    end

end)

test("scale_probabilities properly scales up probabilities", function ()

    local doubled_probabilities = api.scale_probabilities({
        test1 = 1,
        test2 = 2,
        test3 = 4
    }, 2)

    if api.sum_probabilities(doubled_probabilities) ~= 14 then
        fail_test("Scaled up probabilities do not sum to total")
    end

    if not table_eq(doubled_probabilities, {
        test1 = 2,
        test2 = 4,
        test3 = 8
    }) then
        fail_test("Probabilities were not properly scaled up") 
    end
end)

test("scale_probabilities_to_fill properly scales up probabilities", function ()

    local doubled_probabilities = api.scale_probabilities_to_fill({
        test1 = 1,
        test2 = 2,
        test3 = 4
    }, 14)

    if api.sum_probabilities(doubled_probabilities) ~= 14 then
        fail_test("Scaled up probabilities do not sum to total")
    end

    if not table_eq(doubled_probabilities, {
        test1 = 2,
        test2 = 4,
        test3 = 8
    }) then
        fail_test("Probabilities were not properly scaled up") 
    end
end)

test("scale_probabilities_to_fill properly scales down probabilities", function ()

    local normalized_probabilities = api.scale_probabilities_to_fill({
        test1 = 1,
        test2 = 2,
        test3 = 4
    }, 1)

    if api.sum_probabilities(normalized_probabilities) ~= 1 then
        fail_test("Scaled down probabilities do not sum to total")
    end

    if not table_eq(normalized_probabilities, {
        test1 = 1/7,
        test2 = 2/7,
        test3 = 4/7
    }) then
        fail_test("Probabilities were not properly scaled down") 
    end
end)

test("merge_probabilities merges unique tables", function ()
    local input1 = {
        test1 = 1,
        test2 = 2,
        test3 = 4
    }
    local input2 = {
        test4 = 1,
        test5 = 2,
        test6 = 4
    }
    local output = {
        test1 = 1,
        test2 = 2,
        test3 = 4,
        test4 = 1,
        test5 = 2,
        test6 = 4
    }

    local result = api.merge_probabilities(input1, input2)

    if not table_eq(result, output) then
        fail_test("Probabilities were not properly merged")
    end
end)

test("merge_probabilities will add up similar values in tables", function ()
    local input1 = {
        test1 = 1,
        test2 = 2,
        test3 = 4
    }
    local input2 = {
        test2 = 1,
        test3 = 2,
        test4 = 4
    }
    local output = {
        test1 = 1,
        test2 = 3,
        test3 = 6,
        test4 = 4
    }

    local result = api.merge_probabilities(input1, input2)

    if not table_eq(result, output) then
        fail_test("Probabilities were not properly merged")
    end
end)
test("merge_probabilities can merge several tables", function ()
    local input1 = {
        test1 = 1,
        test2 = 2,
        test3 = 4
    }
    local input2 = {
        test2 = 1,
        test3 = 2,
        test4 = 4
    }
    local input3 = {
        test4 = 1,
        test5 = 2,
        test6 = 4
    }
    local output = {
        test1 = 1,
        test2 = 3,
        test3 = 6,
        test4 = 5,
        test5 = 2,
        test6 = 4
    }

    local result = api.merge_probabilities(input1, input2, input3)

    if not table_eq(result, output) then
        fail_test("Probabilities were not properly merged")
    end
end)



test("get_outputs returns the outputs of an input", function ()

    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }
    api.register_input("default:gravel", output)

    local registered_output = api.get_outputs("default:gravel")

    if not table_eq(output, registered_output) then
        fail_test("Output not properly retrieved")
    end
end)

test("result of get_outputs cannot be modified", function ()
    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }

    api.register_input("default:gravel", output)

    local registered_output1 = api.get_outputs("default:gravel")
    registered_output1["default:gravel"] = 100
    local registered_output2 = api.get_outputs("default:gravel")

    if table_eq(registered_output1, registered_output2) then
        fail_test("Output can be modified")
    end
    if not table_eq(output, registered_output2) then
        fail_test("Output does not remain the same when modified")
    end
end)




test("register_input registers an input with no output", function ()
    api.register_input("default:gravel")
    local registered_output = api.get_outputs("default:gravel")

    if not table_eq(registered_output, {}) then
        fail_test("Not registered properly")
    end
end)

test("register_input registers an input with a string output", function ()
    api.register_input("default:gravel", "default:sand")
    local registered_output = api.get_outputs("default:gravel")

    if not table_eq(registered_output, {["default:sand"] = 1}) then
        fail_test("Not registered properly")
    end
end)

test("register_input registers an input with a table output", function ()
    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }
    api.register_input("default:gravel", output)

    local registered_output = api.get_outputs("default:gravel")
    if not table_eq(registered_output, output) then
        fail_test("Not registered properly")
    end
end)

test("register_input does not allow a previously registered input to be registered again", function ()
    expect_error("re-registering input \"default:gravel\"")
    api.register_input("default:gravel")
    api.register_input("default:gravel")
end)

test("register_input does allow a previously registered input to be registered again if allow_override is switched on", function ()
    api.register_input("default:gravel")
    api.register_input("default:gravel", {}, true)
end)

test("override_input does allow a previously registered input to be registered again", function ()
    api.register_input("default:gravel")
    api.override_input("default:gravel")
end)

test("register_input does not allow an invalid input to be registered", function ()
    expect_error()
    api.register_input("garbage_nonsense")
end)

test("register_input does not allow an invalid output to be registered", function ()
    expect_error()
    api.register_input("default:gravel", "garbage_nonsense")
end)

test("register_input does not allow an invalid output type to be used", function ()
    expect_error("Gravelsieve outputs must be a table or a string")
    api.register_input("default:gravel", 28465)
end)


test("remove_input removes an input from the config", function ()
    api.register_input("default:gravel", "default:sand")
    api.remove_input("default:gravel")
    if api.can_process("default:gravel") ~= false then
        fail_test("Not properly removed")
    end
end)

test("remove_input informs you if an unregistered input is removed", function ()
    api.remove_input("default:gravel")
    log_called_times(1)
    log_called_with("error", "Cannot remove an input (%s) that does not exist.", "default:gravel")
end)

test("remove_input returns the registered output of the input", function ()
    local output = {["default:sand"]=1}
    api.register_input("default:gravel", output)
    local registered_output = api.remove_input("default:gravel")
    if not table_eq(output, registered_output) then
        fail_test("Did not return proper result")
    end
end)


-- --[[
test("swap_input deletes the old input", function ()
    api.register_input("default:gravel")
    api.swap_input("default:gravel", "default:sand")
    if api.can_process("default:gravel") ~= false then
        fail_test("Not properly deleted")
    end
end)

test("swap_input creates the new input with the same output", function ()
    local output = {["default:sand"]=1}
    api.register_input("default:gravel", output)
    api.swap_input("default:gravel", "default:sand")
    local registered_output = api.get_outputs("default:sand")
    if not table_eq(output, registered_output) then
        fail_test("Not properly swapped")
    end
end)


test("register_output registers an output to an input", function ()
    api.register_input("default:gravel")
    api.register_output("default:gravel", "default:sand", 0.1)
    local registered_output = api.get_outputs("default:gravel")
    if not table_eq(registered_output, {["default:sand"]=0.1}) then
        fail_test("Output not registered properly")
    end
end)

test("register_output informs you if you register an output to a non existent input", function ()
    api.register_output("default:gravel", "default:sand", 0.1)
    log_called_times(1)
    log_called_with("error", "You must register the input (%s) before registering the output (%s).", "default:gravel", "default:sand")
end)

test("register_output does not allow a previously registered output to be registered again", function ()
    expect_error("re-registering output \"default:gravel\" for \"default:sand\"")
    api.register_input("default:gravel", "default:sand")
    api.register_output("default:gravel", "default:sand", 1)
end)

test("register_output does allow a previously registered output to be registered again if allow_override is switched on", function ()
    api.register_input("default:gravel", "default:sand")
    api.register_output("default:gravel", "default:sand", 0.1, true)
    local registered_output = api.get_outputs("default:gravel")
    if not table_eq(registered_output, {["default:sand"]=0.1}) then
        fail_test("Output not overridden properly")
    end
end)

test("override_output does allow a previously registered output to be registered again", function ()
    api.register_input("default:gravel", "default:sand")
    api.override_output("default:gravel", "default:sand", 0.1)
    local registered_output = api.get_outputs("default:gravel")
    if not table_eq(registered_output, {["default:sand"]=0.1}) then
        fail_test("Output not overridden properly")
    end
end)

test("register_output does not allow an invalid output to be registered", function ()
    expect_error("attempt to register unknown node \"garbage_nonsense\"")
    api.register_input("default:gravel")
    api.register_output("default:gravel", "garbage_nonsense", 1)
end)


test("remove_output removes a single output from an input", function ()
    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }
    local expected_output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1
    }
    api.register_input("default:gravel", output)

    api.remove_output("default:gravel", "default:coal_lump")

    local registered_output = api.get_outputs("default:gravel")
    if not table_eq(registered_output, expected_output) then
        fail_test("Not removed properly")
    end

end)

test("remove_output informs you if you try to remove an output from an input that doesn't exist", function ()
    api.remove_output("default:gravel", "default:coal_lump")
    log_called_times(1)
    log_called_with("error", "Cannot remove an output for an input (%s) that does not exist.", "default:gravel")
end)


test("swap_output removes the old output", function ()
    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }
    api.register_input("default:gravel", output)
    api.swap_output("default:gravel", "default:coal_lump", "default:iron_lump")

    local registered_output = api.get_outputs("default:gravel")
    if registered_output["default:coal_lump"] ~= nil then
        fail_test("Old output not properly removed")
    end
end)
test("swap_output adds in the new output with the old value", function ()
    local output = {
        ["default:gravel"] = 1,
        ["default:sand"] = 1,
        ["default:coal_lump"] = 0.1
    }
    api.register_input("default:gravel", output)
    api.swap_output("default:gravel", "default:coal_lump", "default:iron_lump")

    local registered_output = api.get_outputs("default:gravel")
    if registered_output["default:iron_lump"] ~= 0.1 then
        fail_test("New output not properly added")
    end
end)

test("can_process returns true if an input exists", function ()
    api.register_input("default:gravel")
    local registered = api.can_process("default:gravel")
    if registered ~= true then
        fail_test("Not returning correctly")
    end
end)

test("can_process returns false if an input does not exist", function ()
    local registered = api.can_process("default:gravel")
    if registered ~= false then
        fail_test("Not returning correctly")
    end
end)

test("get_random_output returns outputs (roughly) in the expected distributions", function ()

    local runs = 1000000
    local probabilities = {
        ["default:gravel"]                  = 0.5,
        ["default:sand"]                    = 0.5,
        ["default:coal_lump"]               = 1 / 57.63,
        ["default:iron_lump"]               = 1 / 59.87,
        ["default:copper_lump"]             = 1 / 146.31,
        ["default:tin_lump"]                = 1 / 200.69,
        ["default:gold_lump"]               = 1 / 445.36,
        ["default:mese_crystal"]            = 1 / 564.89,
        ["default:diamond"]                 = 1 / 882.17,
    }
    api.register_input("default:gravel", probabilities)
    local normalized_probabilities = api.scale_probabilities_to_fill(probabilities, runs)
    local results = {}
    for i=1,runs,1 do
        local output = api.get_random_output("default:gravel")
        results[output] = (results[output] or 0) + 1
    end

    for name,value in pairs(normalized_probabilities) do
        local diff = value-(results[name] or 0)
        local relative = math.abs(diff) / value
        if relative > 0.1 then
            fail_test("Random distribution not accurate")
        end
    end
end)


for _,description in ipairs(failed_tests) do
    minetest.log("error", "[gravelsieve] [tests] FAILED: "..description)
end

api.reset_config()
