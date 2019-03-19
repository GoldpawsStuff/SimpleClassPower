local ADDON, Private = ...

local Module = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibSlash", "LibFrame", "LibUnitFrame", "LibStatusBar")

-- Tell the back-end what addon to look for before 
-- initializing this module and all its submodules. 
Module:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any module configs are created.
Module:RegisterSavedVariablesGlobal(ADDON.."_DB")

-- Lua API
local _G = _G
local math_pi = math.pi
local select = select
local string_gsub = string.gsub
local string_match = string.match
local string_split = string.split
local unpack = unpack

local defaults = {

	-- Position & Scale


	-- Coloring (prio: custom > class > power)
	enableCustomColor = false,
	enableClassColor = false, 
	customColor = { Private.Colors.title[1], Private.Colors.title[2], Private.Colors.title[3] }, 

}

local deprecated = {
	enableArcaneCharges = true, 
	enableChi = true, 
	enableComboPoints = true, 
	enableHolyPower = true, 
	enableRunes = true, 
	enableSoulShards = true, 
	enableStagger = true
}

local Style = function(self, unit, id, layout, ...)

	-- Assign our own global custom colors
	self.colors = Private.Colors
	self.layout = layout

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(layout.ClassPowerSize)) 
	self:Place("CENTER", "UICenter", "CENTER", 0, 0)

	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self:EnableMouse(false) 
	self.ignoreMouseOver = true 

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)

	-- Class Power
	-----------------------------------------------------------
	local classPower = backdrop:CreateFrame("Frame")
	classPower:SetSize(unpack(layout.ClassPowerSize)) -- minimum size, this is really just an anchor
	classPower:SetPoint(unpack(layout.ClassPowerPlace)) 

	-- Only show it on hostile targets
	classPower.hideWhenUnattackable = layout.ClassPowerHideWhenUnattackable

	-- Maximum points displayed regardless 
	-- of max value and available point frames.
	-- This does not affect runes, which still require 6 frames.
	classPower.maxComboPoints = layout.ClassPowerMaxComboPoints

	-- Set the point alpha to 0 when no target is selected
	-- This does not affect runes 
	classPower.hideWhenNoTarget = layout.ClassPowerHideWhenNoTarget 

	-- Set all point alpha to 0 when we have no active points
	-- This does not affect runes 
	classPower.hideWhenEmpty = layout.ClassPowerHideWhenNoTarget

	-- Alpha modifier of inactive/not ready points
	classPower.alphaEmpty = layout.ClassPowerAlphaWhenEmpty 

	-- Alpha modifier when not engaged in combat
	-- This is applied on top of the inactive modifier above
	classPower.alphaNoCombat = layout.ClassPowerAlphaWhenOutOfCombat
	classPower.alphaNoCombatRunes = layout.ClassPowerAlphaWhenOutOfCombatRunes

	-- Set to true to flip the classPower horizontally
	-- Intended to be used alongside actioncam
	classPower.flipSide = layout.ClassPowerReverseSides 

	-- Sort order of the runes
	classPower.runeSortOrder = layout.ClassPowerRuneSortOrder 

	-- Creating 6 frames since runes require it
	for i = 1,6 do 
		
		-- Main point object
		local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
		point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
		point:SetMinMaxValues(0, 1)
		point:SetValue(1)

		-- Empty slot texture
		-- Make it slightly larger than the point textures, 
		-- to give a nice darker edge around the points. 
		point.slotTexture = point:CreateTexture()
		point.slotTexture:SetDrawLayer("BACKGROUND", -1)
		point.slotTexture:SetAllPoints(point)

		-- Overlay glow, aligned to the bar texture
		point.glow = point:CreateTexture()
		point.glow:SetDrawLayer("ARTWORK", 1)
		point.glow:SetAllPoints(point:GetStatusBarTexture())

		if layout.ClassPowerPostCreatePoint then 
			layout.ClassPowerPostCreatePoint(classPower, i, point)
		end 

		classPower[i] = point
	end

	self.ClassPower = classPower
	self.ClassPower.PostUpdate = layout.ClassPowerPostUpdate

end

Module.ShowAnchors = function(self)
end

Module.HideAnchors = function(self)
end

Module.ToggleAnchors = function(self)
end

Module.GetConfigWindow = function(self)
	if (not self.window) then 
		local db = self.db
		local anchor = self.anchor
		local classPower = self.classPower
		
		local window = self:CreateFrame("Frame", nil, "UIParent")
		window:Hide()

		-- position
		-- buttons for: 
		-- center vertically, center horizontally, 
		-- reset horizontal, reset vertical, reset all
		-- anchor: center, top, bottom

		-- scale
		-- move in steps of 10% from 50% to 150%

		-- color choices
		-- power, class, custom 

		self.window = window
	end

	return self.window
end

Module.ToggleConfigWindow = function(self)
	local window = self:GetConfigWindow()
	window:SetShown(not window:IsShown())
end

Module.PostUpdateSettings = function(self)

end

Module.ParseSavedSettings = function(self)
	local db = self:NewConfig("Core", defaults, "global")
	for key in pairs(deprecated) do 
		if db[key] then 
			db[key] = nil
		end
	end
	return db
end

Module.OnInit = function(self)
	self.db = self:ParseSavedSettings() 

	-- Retrieve the layout data
	self.layout = self:GetDatabase(ADDON..":[UnitFramePlayerHUD]")

	-- Setup our frame and its anchor
	---------------------------------------------------------------------
	-- The main frame, this is a secure unitframe, 
	-- though have no mouse interaction. 
	local frame = self:SpawnUnitFrame("player", "UICenter", function(frame, unit, id, _, ...)
		return Style(frame, unit, id, self.layout, ...)
	end)
	self.frame = frame

	-- The movable anchor
	-- Make our movable anchor unrelated to the unitframe
	local anchor = self:CreateFrame("Frame", nil, "UICenter")
	anchor:SetSize(frame:GetSize())
	anchor:Place("BOTTOM", "UICenter", "BOTTOM", 0, 340)
	self.anchor = anchor

	-- Glue the class power element to our anchor
	local classPower = frame.ClassPower
	classPower:Place("CENTER", anchor, "CENTER", 0, 0)
	self.classPower = classPower

	-- Register a chat command to toggle the config window
	---------------------------------------------------------------------
	self:RegisterChatCommand("scp", "ToggleConfigWindow")
	self:RegisterChatCommand("simpleclasspower", "ToggleConfigWindow")

end 
