-- ubiquitousse.asset

-- The asset cache. Each cached asset is indexed with a string key "type.assetName".
local cache = setmetatable({}, { __mode = "v" }) -- weak values

--- Asset manager. Loads asset and cache them.
-- This file has no dependicy to either ubiquitousse or a ubiquitousse backend.
-- This only provides a streamlined way to handle asset, and doesn't handle the actual file loading/object creation itself; you are expected to provide your own asset loaders.
-- See asset.load for more details. Hopefully this will allow you to use asset which are more game-specific than "image" or "audio".
local asset
asset = setmetatable({
	--- A prefix for asset names
	-- @impl ubiquitousse
	prefix = "",

	--- Load (and cache) an asset.
	-- Asset name are similar to Lua module names (directory separator is the dot . and no extention should be specified).
	-- To load an asset, ubiquitousse will, in this order:
	-- * try to load the directory loader: a file named loader.lua in the same directory as the asset we are trying to load
	-- * try to load the asset-specific loader: a file in the same directory and with the same name (except with the .lua extension) as the asset we are trying to load
	-- Loaders are expected to return the new asset.
	-- These loaders have acces to the following variables:
	-- * directory: the asset directory (including prefix)
	-- * name: the asset name (directory information removed)
	-- * asset: the asset data. May be nil if this is the first loader to run.
	-- @tparam assetName string the asset's full name
	-- @return the asset
	-- @impl ubiquitousse
	load = function(assetName)
		if not cache[assetName] then
			-- Get directory and name
			local path, name = assetName:match("^([^.]+)%.(.+)$")
			if not path then
				path, name = "", assetName
			end
			local dir = (asset.prefix..path):gsub("%.", "/")

			-- Setup env
			local oName, oAsset, oDirectory = name, asset, directory
			name, asset, directory = name, nil, dir

			-- Asset directory loader
			local f = io.open(dir.."/loader.lua")
			if f then
				f:close()
				asset = dofile(dir.."/loader.lua")
			end

			-- Asset specific loader
			local f = io.open(dir.."/"..name..".lua")
			if f then
				f:close()
				asset = dofile(dir.."/"..name..".lua")
			end

			-- Done
			cache[assetName] = asset

			-- Restore env
			name, asset, directory = oName, oAsset, oDirectory
		end

		return cache[assetName]
	end,
}, {
	--- asset(...) is a shortcut for asset.load(...)
	__call = function(self, ...)
		return asset.load(...)
	end
})

return asset
