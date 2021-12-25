--- Various functions useful for game developement.
--
-- No dependency.
-- @module util

--- Functions
-- @section Functions

local util, group_mt
util = {
	--- Basic maths
	-- @doc math

	--- AABB collision check.
	-- @tparam number x1 first rectangle top-left x coordinate
	-- @tparam number y1 first rectangle top-left y coordinate
	-- @tparam number w1 first rectangle width
	-- @tparam number h1 first rectangle height
	-- @tparam number x2 second rectangle top-left x coordinate
	-- @tparam number y2 second rectangle top-left y coordinate
	-- @tparam number w2 second rectangle width
	-- @tparam number h2 second rectangle height
	-- @treturn true if the objects collide, false otherwise
	aabb = function(x1, y1, w1, h1, x2, y2, w2, h2)
		if w1 < 0 then x1 = x1 + w1; w1 = -w1 end
		if h1 < 0 then y1 = y1 + h1; h1 = -h1 end
		if w2 < 0 then x2 = x2 + w2; w2 = -w2 end
		if h2 < 0 then y2 = y2 + h2; h2 = -h2 end
		return x1 + w1 >= x2 and x1 <= x2 + w2 and
		       y1 + h1 >= y2 and y1 <= y2 + h2
	end,

	--- List operations
	-- @doc list

	--- Check if the list contains a value.
	-- @tparam table t the list
	-- @param v value to search
	-- @treturn bool true if is in list, false otherwise
	has = function(t, v)
		for _, x in ipairs(t) do
			if x == v then return true end
		end
		return false
	end,

	--- Remove the first occurence of an element in a list.
	-- @tparam table t the list
	-- @param x the element to remove
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @return x the removed element
	remove = function(t, x, n)
		n = n or #t
		for i=1, n do
			if t[i] == x then
				table.remove(t, i)
				break
			end
		end
		return x
	end,

	--- Extract the list of elements with a specific key from a list of tables
	-- @tparam table t the list of tables
	-- @param k the chosen key
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @treturn table the extracted table
	extract = function(t, k, n)
		n = n or #t
		local r = {}
		for i=1, n do
			r[i] = t[i][k]
		end
		return r
	end,

	--- Chainable ipairs.
	-- Same as ipairs, but can take several tables, which will be chained, in order.
	-- @tparam table a first list to iterate over
	-- @tparam table b second list to iterate over after the first one
	-- @tparam[opt] table,... ... next tables to iterate over
	ipairs = function(a, b, ...)
		if b == nil then
			return ipairs(a)
		else
			local tables = {a, b, ...}
			local itable = 1
			local f, s, var = ipairs(tables[itable])
			return function()
				local i, v = f(s, var)
				if i == nil then
					itable = itable + 1
					if tables[itable] then
						f, s, var = ipairs(tables[itable])
						i, v = f(s, var)
					else
						return nil
					end
				end
				var = i
				return i, v
			end
		end
	end,

	--- Applies a function to every item in list t.
	-- The function receive two argument: the value and then the key.
	-- @tparam table t initial list
	-- @tparam function fn the function to apply
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @treturn table the initial list
	each = function(t, fn, n)
		n = n or #t
		for i=1, n do
			fn(t[i], i)
		end
		return t
	end,

	--- Applies a function to every item in list t and returns the associated new list.
	-- The function receive two argument: the value and then the key.
	-- @tparam table t initial list
	-- @tparam function fn the function to apply
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @treturn table the new list
	map = function(t, fn, n)
		n = n or #t
		local r = {}
		for i=1, n do
			r[i] = fn(t[i], i)
		end
		return r
	end,

	--- Test if all the values in the list are true. Optionnaly applies a function to get the truthness.
	-- The function receive two argument: the value and then the key.
	-- @tparam table t initial list
	-- @tparam function fn the function to apply
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @treturn boolean result
	all = function(t, fn, n)
		n = n or #t
		fn = fn or function(v) return v end
		local r = true
		for i=1, n do
			r = r and fn(t[i], i)
		end
		return r
	end,

	--- Test if at least one value in the list is true. Optionnaly applies a function to get the truthness.
	-- The function receive two argument: the value and then the key.
	-- @tparam table t initial list
	-- @tparam function fn the function to apply
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @treturn boolean result
	any = function(t, fn, n)
		n = n or #t
		fn = fn or function(v) return v end
		for i=1, n do
			if fn(t[i], i) then
				return true
			end
		end
		return false
	end,

	--- Dictionary operations
	-- @doc dict

	--- Returns a new table where the keys and values have been inverted.
	-- @tparam table t the table
	-- @treturn table the inverted table
	invert = function(t)
		local r = {}
		for k, v in pairs(t) do
			r[v] = k
		end
		return r
	end,

	--- Perform a deep copy of a table.
	-- The copied table will keep the share the same metatable as the original table.
	-- If a key is a table, it will be reused and not copied.
	-- Note this uses pairs() to perform the copy, which will honor the __pairs methamethod if present.
	-- @tparam table t the table
	-- @treturn table the copied table
	copy = function(t, cache)
		if cache == nil then cache = {} end
		local r = {}
		cache[t] = r
		for k, v in pairs(t) do
			if type(v) == "table" then
				r[k] = cache[v] or util.copy(v, cache)
			else
				r[k] = v
			end
		end
		return setmetatable(r, getmetatable(t))
	end,

	--- Returns a table which, when indexed, will require() the module with the index as a name (and a optional prefix).
	-- @tparam[opt=""] string prefix that will prefix modules names when calling require()
	-- @treturn table the requirer table
	requirer = function(prefix)
		prefix = prefix and tostring(prefix) or ""
		return setmetatable({}, {
			__index = function(self, key)
				self[key] = require(prefix..tostring(key))
				return self[key]
			end
		})
	end,

	--- Random and UUID
	-- @doc random

	--- Generate a UUID v4.
	-- @treturn string the UUID in its canonical representation
	uuid4 = function()
		return ("xxxxxxxx-xxxx-4xxx-Nxxx-xxxxxxxxxxxx") -- version 4
			:gsub("N", math.random(0x8, 0xb)) -- variant 1
			:gsub("x", function() return ("%x"):format(math.random(0x0, 0xf)) end) -- random hexadecimal digit
	end,

	--- Object grouping
	-- @doc grouping

	--- Groups objects in a meta-object-proxy-thingy.
	-- Works great with Lua 5.2+. LuaJit requires to be built with Lua 5.2 compatibility enabled to support group comparaison.
	-- @tparam table list of objects
	-- @tparam[opt=#t] number n the number of expected elements in the list, including nil values
	-- @tparam[opt=nil] table p list of parents. Used to find the first arguments of method calls.
	-- @treturn Group object
	group = function(list, n, p)
		n = n or #list
		return setmetatable({ _n = n, _t = list, _p = p or false }, group_mt)
	end
}

group_mt = {
	-- Everything but comparaison: returns a new group
	__add = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v + other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self + v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v + other end, self._n), self._n)
		end
	end,
	__sub = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v - other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self - v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v - other end, self._n), self._n)
		end
	end,
	__mul = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v * other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self * v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v * other end, self._n), self._n)
		end
	end,
	__div = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v / other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self / v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v / other end, self._n), self._n)
		end
	end,
	__mod = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v % other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self % v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v % other end, self._n), self._n)
		end
	end,
	__pow = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v ^ other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self ^ v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v ^ other end, self._n), self._n)
		end
	end,
	__unm = function(self)
		return util.group(util.map(self._t, function(v) return -v end, self._n), self._n)
	end,
	__concat = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.group(util.map(self._t, function(v, i) return v .. other._t[i] end, self._n), self._n)
			else
				return util.group(util.map(other._t, function(v) return self .. v end, self._n), self._n)
			end
		else
			return util.group(util.map(self._t, function(v) return v .. other end, self._n), self._n)
		end
	end,
	__len = function(self)
		return util.group(util.map(self._t, function(v) return #v end, self._n), self._n)
	end,
	__index = function(self, k)
		return util.group(util.extract(self._t, k, self._n), self._n, self._t)
	end,

	-- Comparaison: returns true if true for every object of the group
	__eq = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.all(self._t, function(v, i) return v == other._t[i] end, self._n)
			else
				return util.all(other._t, function(v) return self == v end, self._n)
			end
		else
			return util.all(self._t, function(v) return v == other end, self._n)
		end
	end,
	__lt = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.all(self._t, function(v, i) return v < other._t[i] end, self._n)
			else
				return util.all(other._t, function(v) return self < v end, self._n)
			end
		else
			return util.all(self._t, function(v) return v < other end, self._n)
		end
	end,
	__le = function(self, other)
		if getmetatable(other) == group_mt then
			if getmetatable(self) == group_mt then
				return util.all(self._t, function(v, i) return v <= other._t[i] end, self._n)
			else
				return util.all(other._t, function(v) return self <= v end, self._n)
			end
		else
			return util.all(self._t, function(v) return v <= other end, self._n)
		end
	end,

	-- Special cases
	__newindex = function(self, k, v)
		if getmetatable(v) == group_mt then -- unpack
			util.each(self._t, function(t, i) t[k] = v._t[i] end, self._n)
		else
			util.each(self._t, function(t) t[k] = v end, self._n)
		end
	end,
	__call = function(self, selfArg, ...)
		if getmetatable(selfArg) == group_mt and self._p then -- method call
			local a = {...}
			return util.group(util.map(self._t, function(v, i) return v(self._p[i], unpack(a)) end, self._n), self._n)
		else
			local a = {selfArg, ...}
			return util.group(util.map(self._t, function(v) return v(unpack(a)) end, self._n), self._n)
		end
	end,

	-- Full-blown debugger
	__tostring = function(self)
		return ("group{%s}"):format(table.concat(util.map(self._t, tostring, self._n), ", "))
	end
}

return util
