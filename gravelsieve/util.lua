gravelsieve.util = {}

function gravelsieve.util.pairs_by_values(t, f)
    if not f then
        f = function(a, b)
            return a > b
        end
    end
    local s = {}
    for k, v in pairs(t) do
        table.insert(s, { k, v })
    end
    table.sort(s, function(a, b)
        return f(a[2], b[2])
    end)
    local i = 0
    return function()
        i = i + 1
        local v = s[i]
        if v then
            return unpack(v)
        else
            return nil
        end
    end
end

function gravelsieve.util.normalize_probabilities(conf)
    local total = 0
    for _, val in pairs(conf) do
        if val > 0 then
            total = total + val
        end
    end
    local normalized = {}
    for key, val in pairs(conf) do
        if val > 0 then
            normalized[key] = val / total
        end
    end
    return normalized
end
