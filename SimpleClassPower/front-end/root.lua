local ADDON, Private = ...
local Module = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibSlash", "LibSecureHook", "LibFrame", "LibUnitFrame", "LibStatusBar","LibMover")

-- Tell the back-end what addon to look for before 
-- initializing this module and all its submodules. 
Module:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any module configs are created.
Module:RegisterSavedVariablesGlobal(ADDON.."_DB")

-- Lua API
local _G = _G
local select = select
local unpack = unpack

-- WoW API
local GetSpecialization = _G.GetSpecialization

-- WoW Constants
local SPEC_MONK_BREWMASTER = _G.SPEC_MONK_BREWMASTER or 1

-- Constant to track number of 
-- preview points on the draggable overlay
local NUMPOINTS = 5

-- Player class constant
local _,PlayerClass = UnitClass("player")

-- Default settings. 
-- Changing these have no real effect in-game, so don't. 
local defaults = {
	enableClassColor = false, -- use class color instead of our power colors
	hideWhenNoTarget = false, -- hide when no target exists
	hideWhenUnattackable = false -- hiden when target is unattackable
}

-- Various options I've used in the development cycle, 
-- referenced here to make sure saved variables are clean. 
local deprecated = {
	-- We removed this because it's always the 
	-- default fallback color, and doesn't need a setting. 
	enablePowerColor = true, 

	-- Too much hassle, maybe later. 
	enableCustomColor = true,
	customColor = true, 

	-- We removed these because the 
	-- addon selection for your char does the same. 
	enableArcaneCharges = true, 
	enableChi = true, 
	enableComboPoints = true, 
	enableHolyPower = true, 
	enableRunes = true, 
	enableSoulShards = true, 
	enableStagger = true, 

	-- I removed this beacuse I'm doing it the opposite way, 
	-- making it always visible by default.
	showAlways = true 
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

	-- Maximum points displayed regardless 
	-- of max value and available point frames.
	-- This does not affect runes, which still require 6 frames.
	classPower.maxComboPoints = layout.ClassPowerMaxComboPoints

	-- Only show it on hostile targets
	classPower.hideWhenUnattackable = Module.db.hideWhenUnattackable --layout.ClassPowerHideWhenUnattackable

	-- Set the point alpha to 0 when no target is selected
	-- This does not affect runes 
	classPower.hideWhenNoTarget = Module.db.hideWhenNoTarget -- layout.ClassPowerHideWhenNoTarget 

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

Module.Style = function(self, frame, unit, id, _, ...)
	return Style(frame, unit, id, self.layout, ...)
end

Module.ToggleConfigWindow = function(self)
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

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		-- hide any visible anchors 


	elseif (event == "PLAYER_REGEN_ENABLED") then 
		-- show anchors if they were hidden because of combat 

	elseif (event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD") then 
		NUMPOINTS = PlayerClass == "DEATHKNIGHT" and 6 or (PlayerClass == "MONK" and GetSpecialization() == SPEC_MONK_BREWMASTER) or 5
	end
end

Module.OnChatCommand = function(self, editBox, ...)
	local cmd, arg = ...
	if (cmd == "classcolor") then 
		if (arg == "on") or (arg == "enable") then 
			self.db.enableClassColor = true 

		elseif (arg == "off") or (arg == "disable") or (not arg) then
			self.db.enableClassColor = false
		end 

	elseif (cmd == "show") then 
		if (arg == "always") then 
			self.db.showAlways = true 

		elseif (arg == "smart") or (not arg) then 
			self.db.showAlways = false
		end 

	elseif (cmd == "lock") then 
		self:LockMover(self.frame)

	elseif (cmd == "unlock") then 
		self:UnlockMover(self.frame)
	else 
		-- assume lock toggle when no arguments is given
		self:ToggleMover(self.frame) 
	end 
end

Module.OnInit = function(self)
	self.db = self:ParseSavedSettings() 

	-- Retrieve the layout data
	self.layout = self:GetDatabase(ADDON..":[UnitFramePlayerHUD]")

	-- Setup our frame and its anchor
	---------------------------------------------------------------------
	-- The main frame, this is a secure unitframe, 
	-- though have no mouse interaction. 
	local frame = self:SpawnUnitFrame("player", "UICenter", "Style")
	frame:Place(unpack(self.db.savedPosition or self.layout.Place))
	self:CreateMover(frame) -- Make it movable!
	self.frame = frame

	-- Register a chat command to toggle the config window
	---------------------------------------------------------------------
	self:RegisterChatCommand("scp", "OnChatCommand")
	self:RegisterChatCommand("simpleclasspower", "OnChatCommand")
end 

Module.OnEnable = function(self)
	if (PlayerClass == "MONK") then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") 
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnEvent") 

	elseif (PlayerClass == "DEATHKNIGHT") then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") 

	end 
end 