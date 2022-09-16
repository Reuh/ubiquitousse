--- Asset manager for Lua.
--
-- Loads asset and cache them.
--
-- This only provides a streamlined way to handle asset, and doesn't handle the actual file loading/object creation itself; you are expected to provide your own asset loaders.
--
-- See the `Asset:__call` method for more details on how assets are loaded. Hopefully this will allow you to use asset which are more game-specific than "image" or "audio".
--
-- TODO: async loading
--
-- No dependencies.
-- @module asset
-- @usage
-- TODO

--- Asset manager.
-- @type Asset
local asset_mt = {
	--- A prefix for asset names.
	-- @ftype string
	prefix = nil,

	--- The asset cache. Each cached asset is indexed with a string key "type.assetName".
	-- @ftype table {["assetName"]=asset}
	cache = nil,

	--- The loaders table.
	-- @ftype table {["prefix"]=function, ...}
	loaders = nil,

	--- Load (and cache) an asset.
	--
	-- Asset name are similar to Lua module names (directory separator is the dot . and no extention should be specified).
	-- To load an asset, ubiquitousse will try every loaders in the loader list with a name that prefix the asset name.
	-- The first value returned will be used as the asset value.
	--
	-- Loaders are called with the arguments:
	--
	-- * path: the asset full path, except extension
	-- * ...: other arguments given after the asset name. Can only be number and strings.
	-- @tparam string assetName string the asset's full name
	-- @tparam number/string ... other arguments for the asset loader
	-- @return the asset
	-- @usage
	-- local image = asset("image.example")
	__call = function(self, assetName, ...)
		local cache = self.cache
		local hash = table.concat({assetName, ...}, ".")

		if not cache[hash] then
			for prefix, fn in pairs(self.loaders) do
				if assetName:match("^"..prefix) then
					cache[hash] = fn((self.prefix..assetName):gsub("%.", "/"), ...)
					if cache[hash] then
						break
					end
				end
			end
			assert(cache[hash], ("couldn't load asset %q"):format(assetName))
		end

		return cache[hash]
	end,

	--- Preload a list of assets.
	-- @tparam {"asset1",...} list list of assets to load
	load = function(self, list)
		for _, asset in ipairs(list) do
			self(asset)
		end
	end,

	--- Allow loaded assets to be garbage collected.
	-- Only useful if the caching mode is set to "manual" duritng creation.
	clear = function(self)
		self.cache = {}
	end
}
asset_mt.__index = asset_mt

--- Asset module.
-- @section end

local asset = {
	--- Create a new asset manager.
	--
	-- If the caching "mode" is set to auto (default), the asset manager will allow assets to be automaticaly garbage collected by Lua.
	--
	-- If set to "manual", the assets will not be garbage collected unless the clear method is called.
	-- "manual" mode is useful if you have assets that are particularly slow to load and you want full control on when they are loaded and unloaded (typically a loading screen).
	-- @tparam string directory the directory in which the assets will be loaded
	-- @tparam table loaders loaders table: {prefix = function, ...}
	-- @tparam[opt="auto"] string mode caching mode
	-- @treturn Asset the new asset manager
	new = function(directory, loaders, mode)
		local cache = {}
		if mode == nil or mode == "auto" then
			setmetatable(cache, { __mode = "v" })
		end
		return setmetatable({
			prefix = directory..".",
			cache = cache,
			loaders = loaders
		}, asset_mt)
	end
}

return asset
