-- adaption to hopper
if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
    hopper:add_container({
        { "bottom", "gravelsieve:auto_sieve0", "src" },
        { "top", "gravelsieve:auto_sieve0", "dst" },
        { "side", "gravelsieve:auto_sieve0", "src" },

        { "bottom", "gravelsieve:auto_sieve1", "src" },
        { "top", "gravelsieve:auto_sieve1", "dst" },
        { "side", "gravelsieve:auto_sieve1", "src" },

        { "bottom", "gravelsieve:auto_sieve2", "src" },
        { "top", "gravelsieve:auto_sieve2", "dst" },
        { "side", "gravelsieve:auto_sieve2", "src" },

        { "bottom", "gravelsieve:auto_sieve3", "src" },
        { "top", "gravelsieve:auto_sieve3", "dst" },
        { "side", "gravelsieve:auto_sieve3", "src" },
    })
end
