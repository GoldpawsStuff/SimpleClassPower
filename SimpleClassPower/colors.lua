local Colors = CogWheel("LibDB"):NewDatabase("SimpleClassPower: Colors")

-- Lua API
local math_floor = math.floor
local pairs = pairs
local select = select
local unpack = unpack

-- RGB to Hex Color Code
local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local prepare = function(...)
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
		tbl.colorCode = hex(unpack(tbl))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local prepareGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = prepare(v)
	end 
	return tbl
end 

-- Simple non-deep table copying
local copy = function(color)
	local tbl = {}
	for i,v in pairs(color) do 
		tbl[i] = v
	end 
	return tbl
end 

-- power
Colors.power = {}
--Colors.power.MANA = prepare(0/255, 116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
Colors.power.MANA = prepare(80/255,  116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
Colors.power.RAGE = prepare(255/255, 22/255, 0/255) -- Druids, Warriors
Colors.power.FOCUS = prepare(125/255, 168/255, 195/255) -- Hunters and Hunter Pets
Colors.power.ENERGY = prepare(254/255, 245/255, 145/255) -- Rogues, Druids, Monks
--Colors.power.ENERGY_CRYSTAL = prepare(40/255, 178/255, 141/255) -- Rogues, Druids, Monks
Colors.power.ENERGY_CRYSTAL = prepare(0/255, 167/255, 141/255) -- Rogues, Druids, Monks
--Colors.power.ENERGY = prepare(0/255, 255/255, 141/255) -- Rogues, Druids, Monks
--Colors.power.COMBO_POINTS = prepare(0/255, 245/255, 104/255) -- Rogues, Druids
Colors.power.COMBO_POINTS = prepare(220/255, 68/255,  25/255) -- Rogues, Druids, Vehicles
Colors.power.RUNES = prepare(100/255, 155/255, 225/255) -- Death Knight 
Colors.power.RUNIC_POWER = prepare(0/255, 236/255, 255/255) -- Death Knights
Colors.power.SOUL_SHARDS = prepare(148/255, 130/255, 201/255) -- Warlock 
Colors.power.LUNAR_POWER = prepare(121/255, 152/255, 192/255) -- Balance Druid Astral Power 
Colors.power.HOLY_POWER = prepare(245/255, 254/255, 145/255) -- Retribution Paladins 
Colors.power.MAELSTROM = prepare(0/255, 188/255, 255/255) -- Shamans
Colors.power.INSANITY = prepare(102/255, 64/255, 204/255) -- Shadow Priests 
--Colors.power.CHI = prepare(181/255, 255/255, 234/255) -- Monk 
Colors.power.CHI = prepare(181/255 *.7, 255/255, 234/255 *.7) -- Monk 
Colors.power.ARCANE_CHARGES = prepare(121/255, 152/255, 192/255) -- Arcane Mage
Colors.power.FURY = prepare(255/255, 0/255, 111/255) -- Vengeance Demon Hunter
Colors.power.PAIN = prepare(190/255, 255/255, 0/255) -- Havoc Demon Hunter 

-- vehicle powers
Colors.power.AMMOSLOT = prepare(204/255, 153/255, 0/255)
Colors.power.FUEL = prepare(0/255, 140/255, 127/255)
Colors.power.STAGGER = {}
Colors.power.STAGGER[1] = prepare(132/255, 255/255, 132/255) 
Colors.power.STAGGER[2] = prepare(255/255, 250/255, 183/255) 
Colors.power.STAGGER[3] = prepare(255/255, 107/255, 107/255) 

-- Fallback for the rare cases where an unknown type is requested.
Colors.power.UNUSED = prepare(195/255, 202/255, 217/255) 

-- Allow us to use power type index to get the color
-- FrameXML/UnitFrame.lua
Colors.power[0] = Colors.power.MANA
Colors.power[1] = Colors.power.RAGE
Colors.power[2] = Colors.power.FOCUS
Colors.power[3] = Colors.power.ENERGY
Colors.power[4] = Colors.power.CHI
Colors.power[5] = Colors.power.RUNES
Colors.power[6] = Colors.power.RUNIC_POWER
Colors.power[7] = Colors.power.SOUL_SHARDS
Colors.power[8] = Colors.power.LUNAR_POWER
Colors.power[9] = Colors.power.HOLY_POWER
Colors.power[11] = Colors.power.MAELSTROM
Colors.power[13] = Colors.power.INSANITY
Colors.power[17] = Colors.power.FURY
Colors.power[18] = Colors.power.PAIN
