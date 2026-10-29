local file = require("file")

function PLUGIN:EnvKeys(ctx)
    return {
        { key = "PATH", value = file.join_path(ctx.path, "bin") },
        { key = "PATH", value = file.join_path(ctx.path, "share/perl6/site/bin") },
    }
end
