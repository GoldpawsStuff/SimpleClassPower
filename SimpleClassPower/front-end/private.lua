local ADDON, Private = ...

local LibColorTool = Wheel("LibColorTool")
assert(LibColorTool, ADDON.." requires LibColorTool to be loaded.")

local LibFontTool = Wheel("LibFontTool")
assert(LibFontTool, ADDON.." requires LibFontTool to be loaded.")

local Colors = LibColorTool:GetColorTable()
local GetFont = function(...) return LibFontTool:GetFont(...) end
local GetMedia = function(name, type) return ([[Interface\AddOns\%s\media\%s.%s]]):format(ADDON, name, type or "tga") end

------------------------------------------------
-- Custom Colors
------------------------------------------------
Colors.power.COMBO_POINTS = Colors:CreateColor(220/255, 68/255,  25/255) -- Rogues, Druids, Vehicles

------------------------------------------------
-- Module Defaults
------------------------------------------------
-- The purpose of this is to supply all the front-end modules
-- with default settings for all the user configurable choices.
-- 
-- Note that changing these won't change anything for existing characters,
-- they only affect new characters or the first install.
-- I generally advice tinkerers to leave these as they are. 
local Defaults = {}
Defaults[ADDON] = {
	enableClassColor = false, -- use class color instead of our power colors
	enableSmartVisibility = false -- hide when no target or unattackable
}

------------------------------------------------
-- Private Addon API
------------------------------------------------
Private.Colors = Colors
Private.GetFont = GetFont
Private.GetMedia = GetMedia

local GetProfile = function()
	local db = Private.GetConfig(ADDON, "character") -- crossing the beams!
	return db.settingsProfile or "character"
end

-- Initialize or retrieve the saved settings for the current character.
-- Note that this will silently return nothing if no defaults are registered.
-- This is to prevent invalid databases being saved.
Private.GetConfig = function(name, profile)
	local db = Wheel("LibModule"):GetModule(ADDON):GetConfig(name, profile or GetProfile(), nil, true)
	if (db) then
		return db
	else
		local defaults = Private.GetDefaults(name)
		if (defaults) then
			return Wheel("LibModule"):GetModule(ADDON):NewConfig(name, defaults, profile or GetProfile())
		end
	end
end 

-- Initialize or retrieve the global settings
Private.GetGlobalConfig = function(name)
	local db = Wheel("LibModule"):GetModule(ADDON):GetConfig(name, "global", nil, true)
	return db or Wheel("LibModule"):GetModule(ADDON):NewConfig(name, Private.GetDefaults(name), "global")
end 

-- Retrieve default settings
Private.GetDefaults = function(name) 
	return Defaults[name] 
end 
