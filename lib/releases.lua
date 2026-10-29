local M = {}

M.index_url = "https://raw.githubusercontent.com/skaji/rakudo-releases/main/rakudo-releases.v1.csv"
local schema = "sort_key,arch,backend,build_rev,format,name,platform,type,url,ver,ver_with_build_rev,padding"

function M.get(url)
    local response = require("http").get({ url = url })
    if response.status_code ~= 200 then
        error("Fetching " .. url .. " failed: HTTP " .. tostring(response.status_code))
    end
    return response.body
end

function M.parse(body, runtime)
    local os_names = { darwin = "macos", linux = "linux" }
    local arch_names = { amd64 = "x86_64", arm64 = "arm64" }
    local os_name, arch = os_names[runtime.osType], arch_names[runtime.archType]
    if not os_name or not arch or (os_name == "linux" and (arch ~= "x86_64" or runtime.envType == "musl")) then
        error("Unsupported Rakudo binary platform: " .. runtime.osType .. "/" .. runtime.archType
            .. "; requires macOS or Linux x86_64 with glibc")
    end
    local result, by_version, first = {}, {}, true
    for line in body:gmatch("[^\r\n]+") do
        if first then
            if line ~= schema then error("Unexpected Rakudo release index schema") end
            first = false
        else
            -- The publisher's v1 index has 12 unquoted fields, including padding.
            -- Reject a changed dialect rather than silently misreading columns.
            local fields = {}
            for field in (line .. ","):gmatch("(.-),") do fields[#fields + 1] = field end
            if #fields ~= 12 or line:find('"', 1, true) then
                error("Malformed Rakudo release index row")
            end
            if fields[2] == arch and fields[3] == "moar" and fields[5] == "tar.gz"
                and fields[6] == "rakudo" and fields[7] == os_name and fields[8] == "archive" then
                local url, version = fields[9], fields[10]
                if not url:match("^https://rakudo%.org/dl/rakudo/[%w._%-]+%.tar%.gz$") then
                    error("Unexpected Rakudo asset URL: " .. url)
                end
                if not (version:match("^%d%d%d%d%.%d%d$") or version:match("^%d%d%d%d%.%d%d%.%d+$")) then
                    error("Invalid Rakudo version in release index")
                end
                local revision = tonumber(fields[4])
                if not fields[4]:match("^%d+$") or not revision or revision < 1 then
                    error("Invalid Rakudo build revision")
                end
                local release = by_version[version]
                if not release then
                    release = { version = version, url = url, revision = revision }
                    by_version[version] = release
                    result[#result + 1] = release
                elseif revision > release.revision then
                    release.url, release.revision = url, revision
                end
            end
        end
    end
    if first then error("Missing Rakudo release index schema") end
    if #result == 0 then error("No Rakudo binaries for " .. os_name .. "/" .. arch) end
    -- The publisher orders the index newest first. Preserve that release policy.
    return result
end

function M.checksum(body, filename)
    for line in body:gmatch("[^\r\n]+") do
        local name, digest = line:match("^SHA256 %((.-)%) = (%x+)$")
        if name == filename and #digest == 64 then return digest:lower() end
    end
    error("No valid SHA-256 for " .. filename)
end

return M
