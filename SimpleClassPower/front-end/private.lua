local ADDON, Private = ...
local PREFIX = string.gsub(ADDON, "UI", "")

-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local select = select
local unpack = unpack

local colorDB = {}
local fontsDB = { normal = {}, outline = {} }

-- Utility Functions
-----------------------------------------------------------------
-- Simple non-deep table copying
local copy = function(color)
	local tbl = {}
	for i,v in pairs(color) do 
		tbl[i] = v
	end 
	return tbl
end 

-- RGB to Hex Color Code
local createColorCode = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local createColor = function(...)
	local tbl
	if (select("#", ...) == 1) then
		local old = ...
		if (old.r) then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if (#tbl == 3) then
		tbl.colorCode = createColorCode(unpack(tbl))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local createColorGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = createColor(v)
	end 
	return tbl
end 

-- Populate Font Tables
-----------------------------------------------------------------
for i = 10,100 do 
	local fontNormal = _G[PREFIX .. "Font" .. i]
	if fontNormal then 
		fontsDB.normal[i] = fontNormal
	end 
	local fontOutline = _G[PREFIX .. "Font" .. i .. "_Outline"]
	if fontOutline then 
		fontsDB.outline[i] = fontOutline
	end 
end 

-- Populate Color Tables
-----------------------------------------------------------------
-- power
colorDB.power = {}
--colorDB.power.MANA = createColor(0/255, 116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
colorDB.power.MANA = createColor(80/255,  116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
colorDB.power.RAGE = createColor(255/255, 22/255, 0/255) -- Druids, Warriors
colorDB.power.FOCUS = createColor(125/255, 168/255, 195/255) -- Hunters and Hunter Pets
colorDB.power.ENERGY = createColor(254/255, 245/255, 145/255) -- Rogues, Druids, Monks
--colorDB.power.ENERGY_CRYSTAL = createColor(40/255, 178/255, 141/255) -- Rogues, Druids, Monks
colorDB.power.ENERGY_CRYSTAL = createColor(0/255, 167/255, 141/255) -- Rogues, Druids, Monks
--colorDB.power.ENERGY = createColor(0/255, 255/255, 141/255) -- Rogues, Druids, Monks
--colorDB.power.COMBO_POINTS = createColor(0/255, 245/255, 104/255) -- Rogues, Druids
colorDB.power.COMBO_POINTS = createColor(220/255, 68/255,  25/255) -- Rogues, Druids, Vehicles
colorDB.power.RUNES = createColor(100/255, 155/255, 225/255) -- Death Knight 
colorDB.power.RUNIC_POWER = createColor(0/255, 236/255, 255/255) -- Death Knights
colorDB.power.SOUL_SHARDS = createColor(148/255, 130/255, 201/255) -- Warlock 
colorDB.power.LUNAR_POWER = createColor(121/255, 152/255, 192/255) -- Balance Druid Astral Power 
colorDB.power.HOLY_POWER = createColor(245/255, 254/255, 145/255) -- Retribution Paladins 
colorDB.power.MAELSTROM = createColor(0/255, 188/255, 255/255) -- Shamans
colorDB.power.INSANITY = createColor(102/255, 64/255, 204/255) -- Shadow Priests 
--colorDB.power.CHI = createColor(181/255, 255/255, 234/255) -- Monk 
colorDB.power.CHI = createColor(181/255 *.7, 255/255, 234/255 *.7) -- Monk 
colorDB.power.ARCANE_CHARGES = createColor(121/255, 152/255, 192/255) -- Arcane Mage
colorDB.power.FURY = createColor(255/255, 0/255, 111/255) -- Vengeance Demon Hunter
colorDB.power.PAIN = createColor(190/255, 255/255, 0/255) -- Havoc Demon Hunter 

-- vehicle powers
colorDB.power.AMMOSLOT = createColor(204/255, 153/255, 0/255)
colorDB.power.FUEL = createColor(0/255, 140/255, 127/255)
colorDB.power.STAGGER = {}
colorDB.power.STAGGER[1] = createColor(132/255, 255/255, 132/255) 
colorDB.power.STAGGER[2] = createColor(255/255, 250/255, 183/255) 
colorDB.power.STAGGER[3] = createColor(255/255, 107/255, 107/255) 

-- Fallback for the rare cases where an unknown type is requested.
colorDB.power.UNUSED = createColor(195/255, 202/255, 217/255) 

-- Allow us to use power type index to get the color
-- FrameXML/UnitFrame.lua
colorDB.power[0] = colorDB.power.MANA
colorDB.power[1] = colorDB.power.RAGE
colorDB.power[2] = colorDB.power.FOCUS
colorDB.power[3] = colorDB.power.ENERGY
colorDB.power[4] = colorDB.power.CHI
colorDB.power[5] = colorDB.power.RUNES
colorDB.power[6] = colorDB.power.RUNIC_POWER
colorDB.power[7] = colorDB.power.SOUL_SHARDS
colorDB.power[8] = colorDB.power.LUNAR_POWER
colorDB.power[9] = colorDB.power.HOLY_POWER
colorDB.power[11] = colorDB.power.MAELSTROM
colorDB.power[13] = colorDB.power.INSANITY
colorDB.power[17] = colorDB.power.FURY
colorDB.power[18] = colorDB.power.PAIN

-- Private API
-----------------------------------------------------------------
Private.Colors = colorDB
Private.GetFont = function(size, outline) return fontsDB[outline and "outline" or "normal"][size] end
Private.GetMedia = function(name, type) return ([[Interface\AddOns\%s\media\%s.%s]]):format(ADDON, name, type or "tga") end
