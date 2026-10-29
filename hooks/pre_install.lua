local releases = require("releases")

function PLUGIN:PreInstall(ctx)
    for _, release in ipairs(releases.parse(releases.get(releases.index_url), RUNTIME)) do
        if release.version == ctx.version then
            local filename = release.url:match("([^/]+)$")
            return {
                version = ctx.version,
                url = release.url,
                sha256 = releases.checksum(releases.get(release.url .. ".checksums.txt"), filename),
            }
        end
    end
    error("No Rakudo binary for version " .. ctx.version .. " on " .. RUNTIME.osType .. "/" .. RUNTIME.archType)
end
