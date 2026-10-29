-- Run from the repository root: lua tests/test.lua
package.path = "./lib/?.lua;" .. package.path
local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1; print("ok - " .. name)
    else failed = failed + 1; print("FAIL - " .. name .. ": " .. tostring(err)) end
end
local function rejects(fn, message)
    local ok, err = pcall(fn)
    assert(not ok, "expected rejection")
    assert(tostring(err):find(message, 1, true), tostring(err))
end
local header = "sort_key,arch,backend,build_rev,format,name,platform,type,url,ver,ver_with_build_rev,padding\n"
local base = "https://rakudo.org/dl/rakudo/"
local index = header .. table.concat({
    "2026.09.01-macos-arm64,arm64,moar,1,tar.gz,rakudo,macos,archive," .. base .. "mac-01.tar.gz,2026.09,2026.09-01,",
    "2026.09.01-linux-x86_64,x86_64,moar,1,tar.gz,rakudo,linux,archive," .. base .. "linux.tar.gz,2026.09,2026.09-01,",
    "2026.09.01-macos-arm64,arm64,moar,10,tar.gz,rakudo,macos,archive," .. base .. "mac-10.tar.gz,2026.09,2026.09-10,",
    "2026.09.01-macos-arm64,arm64,moar,2,tar.gz,rakudo,macos,archive," .. base .. "mac-02.tar.gz,2026.09,2026.09-02,",
    "2026.09.01-macos-x86_64,x86_64,moar,1,tar.gz,rakudo,macos,archive," .. base .. "intel.tar.gz,2026.09,2026.09-01,",
    "2026.07.01-macos-arm64,arm64,moar,1,tar.gz,rakudo,macos,archive," .. base .. "old.tar.gz,2026.07,2026.07-01,",
    "2026.06.01-macos-arm64,arm64,jvm,1,tar.gz,rakudo,macos,archive," .. base .. "jvm.tar.gz,2026.06,2026.06-01,",
}, "\n") .. "\n"
local runtime = { osType = "darwin", archType = "arm64" }
local digest = string.rep("a", 64)
local sums = "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA512\n\nSHA256 (mac-10.tar.gz) = " .. digest .. "\n"
local function releases() return require("releases") end

test("selects one matching archive per version and highest numeric rebuild", function()
    local rows = releases().parse(index, runtime)
    assert(#rows == 2)
    assert(rows[1].version == "2026.09" and rows[1].url == base .. "mac-10.tar.gz")
    assert(rows[2].version == "2026.07")
end)
test("maps macOS Intel and Linux amd64", function()
    assert(releases().parse(index, {osType="darwin", archType="amd64"})[1].url == base .. "intel.tar.gz")
    assert(releases().parse(index, {osType="linux", archType="amd64"})[1].url == base .. "linux.tar.gz")
end)
test("rejects unsupported platforms and absent platform builds", function()
    rejects(function() releases().parse(index, {osType="windows", archType="amd64"}) end, "Unsupported")
    rejects(function() releases().parse(index, {osType="linux", archType="arm64"}) end, "Unsupported")
    rejects(function() releases().parse(index, {osType="linux", archType="amd64", envType="musl"}) end, "Unsupported")
    rejects(function() releases().parse(header, runtime) end, "No Rakudo")
end)
test("rejects changed schema, malformed rows and untrusted asset origins", function()
    rejects(function() releases().parse("bad\n", runtime) end, "schema")
    rejects(function() releases().parse(header .. "bad\n", runtime) end, "row")
    rejects(function() releases().parse(index:gsub("https://rakudo.org/", "https://evil.example/"), runtime) end, "URL")
    rejects(function() releases().parse(index:gsub(",10,tar.gz", ",x,tar.gz"), runtime) end, "revision")
end)
test("reads SHA256 from a signed checksum document", function()
    assert(releases().checksum(sums, "mac-10.tar.gz") == digest)
end)
test("rejects missing, malformed and wrong-file checksums", function()
    rejects(function() releases().checksum(sums, "mac-10Xtar.gz") end, "SHA-256")
    rejects(function() releases().checksum(sums:gsub(digest, "abc"), "mac-10.tar.gz") end, "SHA-256")
    rejects(function() releases().checksum("", "mac-10.tar.gz") end, "SHA-256")
end)

-- Only the HTTP boundary is substituted; the real hooks and parsers run.
local responses = {}
package.preload.http = function() return {get = function(req)
    return assert(responses[req.url], "unexpected HTTP URL: " .. req.url)
end} end
package.preload.file = function() return {join_path = function(a, b) return a .. "/" .. b end} end
test("available hook returns platform-specific versions newest first", function()
    dofile("metadata.lua"); RUNTIME = runtime
    responses[releases().index_url] = {status_code=200, body=index}
    dofile("hooks/available.lua")
    local versions = PLUGIN:Available({})
    assert(#versions == 2 and versions[1].version == "2026.09" and versions[2].version == "2026.07")
end)
test("install hook returns official URL and SHA256 and rejects missing versions", function()
    dofile("metadata.lua"); RUNTIME = runtime
    responses[releases().index_url] = {status_code=200, body=index}
    responses[base .. "mac-10.tar.gz.checksums.txt"] = {status_code=200, body=sums}
    dofile("hooks/pre_install.lua")
    local download = PLUGIN:PreInstall({version="2026.09"})
    assert(download.url == base .. "mac-10.tar.gz" and download.sha256 == digest and download.version == "2026.09")
    rejects(function() PLUGIN:PreInstall({version="9999.01"}) end, "No Rakudo")
end)
test("HTTP failure stops version discovery and installation", function()
    dofile("metadata.lua"); RUNTIME = runtime
    dofile("hooks/available.lua"); dofile("hooks/pre_install.lua")
    responses[releases().index_url] = {status_code=503, body="unavailable"}
    rejects(function() PLUGIN:Available({}) end, "HTTP 503")
    responses[releases().index_url] = {status_code=200, body=index}
    responses[base .. "mac-10.tar.gz.checksums.txt"] = {status_code=404, body="missing"}
    rejects(function() PLUGIN:PreInstall({version="2026.09"}) end, "HTTP 404")
end)
test("environment exposes both executable directories without network access", function()
    dofile("metadata.lua"); dofile("hooks/env_keys.lua")
    responses = {}
    local env = PLUGIN:EnvKeys({path="/tmp/raku path"})
    assert(#env == 2)
    assert(env[1].key == "PATH" and env[1].value == "/tmp/raku path/bin")
    assert(env[2].key == "PATH" and env[2].value == "/tmp/raku path/share/perl6/site/bin")
end)
print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
