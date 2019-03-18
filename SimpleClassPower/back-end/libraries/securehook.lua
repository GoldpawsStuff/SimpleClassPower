local LibSecureHook = CogWheel:Set("LibSecureHook", 6)
if (not LibSecureHook) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local type = type

LibSecureHook.embeds = LibSecureHook.embeds or {}
LibSecureHook.secureHooks = LibSecureHook.secureHooks or {}

local SecureHooks = LibSecureHook.secureHooks

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- @input 
-- globalName, hook[, uniqueID]
-- globalTable, methodName, hook[, uniqueID]
LibSecureHook.ClearSecureHook = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 2) then 
		local global, hook = ...

		check(global, 1, "string")
		check(hook, 2, "function", "string")

		local ref = _G[global]
		local hookList = SecureHooks[ref]

		if (hookList) then 
			for id = #hookList,1,-1 do 
				local func = hookList[id]
				if (func == hook) then 
					table_remove(hookList, id)
				end 
			end 			
		end 

	elseif (numArgs == 3) then 
		local global, method, hook = ...

		check(global, 1, "table")
		check(method, 2, "string")
		check(hook, 3, "function", "string")

		local ref = global[method]
		if (not ref) then 
			return 
		end 

		local hookList = SecureHooks[ref]
		if (hookList) then 
			for id = #hookList,1,-1 do 
				local func = hookList[id]
				if (func == hook) then 
					table_remove(hookList, id)
				end 
			end 			
		end 
	end 
end 

-- @input 
-- globalName, hook[, uniqueID]
-- globalTable, methodName, hook[, uniqueID]
LibSecureHook.SetSecureHook = function(self, ...)
	if (type(...) == "string") then 
		local global, hook, uniqueID = ...

		check(global, 1, "string")
		check(hook, 2, "function", "string")
		check(uniqueID, 3, "string", "nil")

		local ref = _G[global]
		if (not ref) then 
			return 
		end 

		local hookList = SecureHooks[ref]
		if (not hookList) then 
			local list = { list = {}, unique = {} }
			local call = function(...)
				for id,func in pairs(list.unique) do 
					if (type(func) == "string") then 
						self[func](self, id, ...)
					else
						func(...)
					end 
				end 
				for _,func in ipairs(list.list) do 
					if (type(func) == "string") then 
						self[func](self, global, ...)
					else
						func(...)
					end 
				end 
			end 
			hooksecurefunc(global, call)
			hookList = list
			SecureHooks[ref] = list
		end 

		if uniqueID then 
			hookList.unique[uniqueID] = hook
		else 
			local exists
			for _,func in ipairs(hookList.list) do 
				if (func == hook) then 
					exists = true 
					break 
				end 
			end 
			if (not exists) then 
				table_insert(hookList.list, hook)
			end 
		end 


	elseif (type(...) == "table") then 

		local global, method, hook, uniqueID = ...

		check(global, 1, "table")
		check(method, 2, "string")
		check(hook, 3, "function", "string")
		check(uniqueID, 4, "string", "nil")

		local ref = global[method]
		if (not ref) then 
			return 
		end 

		local hookList = SecureHooks[ref]
		if (not hookList) then 
			local list = { list = {}, unique = {} }
			local call = function(...)
				for id,func in pairs(list.unique) do 
					if (type(func) == "string") then 
						self[func](self, id, ...)
					else
						func(...)
					end 
	
				end 
				for _,func in ipairs(list.list) do 
					if (type(func) == "string") then 
						self[func](self, method, ...)
					else
						func(...)
					end 
	
				end 
			end 
			hooksecurefunc(global, method, call)
			hookList = list
			SecureHooks[ref] = list
		end 

		if uniqueID then 
			hookList.unique[uniqueID] = hook
		else 
			local exists
			for _,func in ipairs(hookList.list) do 
				if (func == hook) then 
					exists = true 
					break 
				end 
			end 
			if (not exists) then 
				table_insert(hookList.list, hook)
			end 
		end 

	end 
end 

-- Module embedding
local embedMethods = {
	SetSecureHook = true,
	ClearSecureHook = true
}

LibSecureHook.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibSecureHook.embeds) do
	LibSecureHook:Embed(target)
end
