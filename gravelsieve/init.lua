gravelsieve = {
    -- Load support for I18n
    S = minetest.get_translator("gravelsieve"),

    version = "20210214.0",

    modname = minetest.get_current_modname(),
    modpath = minetest.get_modpath(minetest.get_current_modname()),

    log = function(level, message, ...)
        minetest.log(level, ("[%s] %s"):format(gravelsieve.modname, message:format(...)))
    end
}

gravelsieve.log("info", "loading gravelsieve mod...")

local function gs_dofile(filename)
    dofile(("%s/%s"):format(gravelsieve.modpath, filename))
end

gs_dofile("settings.lua")
gs_dofile("api.lua")

gs_dofile("sieve.lua")
gs_dofile("nodes.lua")
gs_dofile("hammer.lua")
gs_dofile("crafts.lua")

gs_dofile("default_output.lua")

gs_dofile("compat.lua")
gs_dofile("interop/hopper.lua")
gs_dofile("interop/moreblocks.lua")
