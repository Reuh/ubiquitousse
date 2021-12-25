project = "Ubiquitousse"
title = "Ubiquitousse reference"
description = "Ubiquitousse game development tools"
full_description = [[Set of Lua libraries to make game development easier using the [LÖVE](https://love2d.org/) game framework.

See [main module](modules/init.html) for more information, or the [GitHub page](https://github.com/Reuh/ubiquitousse) for the source.
]]
--package = "ubiquitousse"

dir="docs"
format = "discount"
style = "!new"
not_luadoc = true

custom_tags = {
	{ "require", title="Requires" },
	{ "ftype", title="Type", format = function(x)
		local firstWord, rest = x:match("^([^%s]*)(.*)$")
		return ('<code>%s</code>%s'):format(firstWord, rest)
	end },
	{ "ro", hidden=true },
	{ "callback", hidden=true },
}
custom_display_name_handler = function(item, default_handler)
	if item.tags.callback then
		return default_handler(item) .. ' <sup><em>[callback]</em></sup>'
	elseif item.tags.ro then
		return default_handler(item) .. ' <sup><em>[read-only]</em></sup>'
	end
	return default_handler(item)
end

topics = { "README.md", "LICENSE" }
file = { "init.lua", "ldtk/ldtk.can", "ecs/ecs.can", "asset/asset.lua" }
