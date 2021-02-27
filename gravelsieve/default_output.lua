local api = gravelsieve.api


api.register_input("default:gravel", function ()
	local ore_rates = api.sum_probabilities(gravelsieve.ore_probability)
	return api.merge_probabilities(
		gravelsieve.ore_probability,
		api.scale_probabilities_to_fill({
			["default:gravel"] = 1,
			["gravelsieve:sieved_gravel"] = 1
		}, 1-ore_rates)
	)
end)
api.register_input("gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel")

--[[
api.register_input("default:gravel", function ()
	local junk_rates = 0.95
	return gravelsieve.api.merge_probabilities(
		scale_to_fill({
		    ["default:gravel"] = 1,
		    ["gravelsieve:sieved_gravel"] = 1
		}, junk_rates),
		scale_to_fill(gravelsieve.ore_probability, 1-junk_rates)
	)
end)
api.register_input("gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel")
]]

-- api.register_input("default:gravel", 0.95, {
--     ["default:gravel"] = 1,
--     ["gravelsieve:sieved_gravel"] = 1
-- })

-- api.register_output("default:gravel", "default:coal_lump", 1 / 96.06)
-- api.register_output("default:gravel", "default:iron_lump", 1 / 99.90)
-- api.register_output("default:gravel", "default:copper_lump", 1 / 244.05)
-- api.register_output("default:gravel", "default:tin_lump", 1 / 334.75)
-- api.register_output("default:gravel", "default:gold_lump", 1 / 744.65)
-- api.register_output("default:gravel", "default:mese_crystal", 1 / 948.07)
-- api.register_output("default:gravel", "default:diamond", 1 / 1486.28)
