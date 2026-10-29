local releases = require("releases")

function PLUGIN:Available(ctx)
    local result = {}
    for _, release in ipairs(releases.parse(releases.get(releases.index_url), RUNTIME)) do
        result[#result + 1] = { version = release.version }
    end
    return result
end
