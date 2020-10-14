local ADDON, Private = ...
local L = Wheel("LibLocale"):GetLocale(ADDON)
local Module = Wheel("LibModule"):NewModule(ADDON, "LibDB", "LibMessage", "LibEvent", "LibSlash", "LibSecureHook", "LibFrame", "LibUnitFrame", "LibStatusBar","LibMover")

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
	enableSmartVisibility = false -- hide when no target or unattackable
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
	showAlways = true, 

	-- Removed this to simplify it to a single option
	hideWhenNoTarget = false, -- hide when no target exists
	hideWhenUnattackable = false -- hiden when target is unattackable
}

---------------------------------------------------
-- Additional Mover Methods
---------------------------------------------------
local Mover = {}

Mover.OnEnter = function(self)
	local colors = Private.Colors
	local tooltip = self:GetTooltip()
	local bottom = self:GetBottom() 
	local top = Module:GetFrame("UICenter"):GetHeight() - self:GetTop()
	local point = ((bottom < top) and "BOTTOM" or "TOP")
	local rPoint = ((bottom < top) and "TOP" or "BOTTOM")
	local offset = (bottom < top) and 20 or -20
	
	tooltip:SetOwner(self, "ANCHOR_NONE")
	tooltip:Place(point, self, rPoint, 0, offset)
	tooltip:SetMinimumWidth(280)
	tooltip:AddLine(ADDON, colors.title[1], colors.title[2], colors.title[3])
	--tooltip:AddLine(L["<Left-Click> to raise"], colors.green[1], colors.green[2], colors.green[3])
	--tooltip:AddLine(L["<Left-Click> to lower"], colors.green[1], colors.green[2], colors.green[3])
	tooltip:AddLine(L["<Shift Left Click> to reset position"], colors.green[1], colors.green[2], colors.green[3])
	tooltip:AddLine(L["<Shift Right Click> to reset scale"], colors.green[1], colors.green[2], colors.green[3])
	tooltip:Show()
end

---------------------------------------------------
-- Class Resource Styling
---------------------------------------------------
local Style = function(self, unit, id, layout, ...)

	-- Get the saved settings
	local db = Module.db

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

	-- User configurable settings
	classPower.colorClass = db.enableClassColor
	classPower.hideWhenUnattackable = db.enableSmartVisibility 
	classPower.hideWhenNoTarget = db.enableSmartVisibility 
	classPower.hideWhenEmpty = db.enableSmartVisibility

	-- Addon chosen settings
	classPower.alphaEmpty = layout.ClassPowerAlphaWhenEmpty 
	classPower.alphaNoCombat = layout.ClassPowerAlphaWhenOutOfCombat
	classPower.alphaNoCombatRunes = layout.ClassPowerAlphaWhenOutOfCombatRunes
	classPower.flipSide = layout.ClassPowerReverseSides 
	classPower.maxComboPoints = layout.ClassPowerMaxComboPoints
	classPower.runeSortOrder = layout.ClassPowerRuneSortOrder 

	-- Creating 6 frames since runes require it
	for i = 1,6 do 
		
		-- Main point object
		local point = classPower:CreateStatusBar() -- the widget require Wheel statusbars
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

---------------------------------------------------
-- Module Callbacks
---------------------------------------------------
Module.IsDefaultPosition = function(self)
	return self.mover:IsDefaultPosition()
end 

Module.IsDefaultScale = function(self)
	return self.mover:IsDefaultScale()
end 

Module.IsDefaultPositionAndScale = function(self)
	return self.mover:IsDefaultPosition() and self.mover:IsDefaultScale()
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

Module.PostUpdateSettings = function(self)
	local db = self.db
	local element = self.frame.ClassPower

	self.frame:DisableElement("ClassPower")

	-- Update frame element switches
	element.hideWhenUnattackable = db.enableSmartVisibility
	element.hideWhenNoTarget = db.enableSmartVisibility 
	element.hideWhenEmpty = db.enableSmartVisibility
	element.colorClass = db.enableClassColor

	-- Force an update to apply new settings
	self.frame:EnableElement("ClassPower")

	element:ForceUpdate()
end

Module.OnEvent = function(self, event, ...)
	if (event == "CG_MOVER_UPDATED") then 
		local mover, target, point, offsetX, offsetY = ...
		if (mover == self.mover) and (target == self.frame) then 
			self.db.savedPosition = { point, "UICenter", point, offsetX, offsetY }
		end 
	elseif (event == "CG_MOVER_SCALE_UPDATED") then 
		local mover, target, scale = ... 
		if (mover == self.mover) and (target == self.frame) then 
			if (self:IsDefaultScale()) then 
				self.db.savedScale = nil
			else 
				self.db.savedScale = scale
			end 
		end
	elseif (event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD") then 
		NUMPOINTS = PlayerClass == "DEATHKNIGHT" and 6 or (PlayerClass == "MONK" and GetSpecialization() == SPEC_MONK_BREWMASTER) or 5
	end
end

Module.OnChatCommand = function(self, editBox, ...)
	local db = self.db
	local cmd, arg = ...
	if (cmd == "classcolor") then 
		local enableClassColor = db.enableClassColor
		if (arg == "on") or (arg == "enable") then 
			db.enableClassColor = true 
		elseif (arg == "off") or (arg == "disable") or (not arg) then
			db.enableClassColor = false
		end 
		if (enableClassColor ~= db.enableClassColor) then 
			self:PostUpdateSettings()
		end

	elseif (cmd == "show") then 
		local enableSmartVisibility = db.enableSmartVisibility
		db.enableSmartVisibility = (arg == "smart") and true or false 
		if (enableSmartVisibility ~= db.enableSmartVisibility) then 
			self:PostUpdateSettings()
		end
	elseif (cmd == "lock") then 
		self:LockMover(self.frame)
	elseif (cmd == "unlock") then 
		self:UnlockMover(self.frame)
	elseif (cmd == "help") then 
		print(L["/scp - Toggle the overlay for moving/scaling."])
		print(L["/scp classcolor on - Enable class colors."])
		print(L["/scp classcolor off - Disable class colors."])
		print(L["/scp show always - Always show."])
		print(L["/scp show smart - Hide when no target or unattackable."])
		print(L["/scp help - Show this."])
	else 
		self:ToggleMover(self.frame) 
	end 
end

---------------------------------------------------
-- Module Initialization
---------------------------------------------------
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
	self.frame = frame
	
	-- Make it movable!
	local mover = self:CreateMover(frame) 
	mover:SetName(ADDON)
	mover:SetMinMaxScale(.5, 1.5, .05)
	mover:SetDefaultPosition(unpack(self.layout.Place))
	mover:SetScale(self.db.savedScale or 1) -- use the mover to set the frame scale, or positions will be wonky
	for name,method in pairs(Mover) do 
		mover[name] = method
	end 
	self.mover = mover 

	-- Register a chat command to toggle the config window
	---------------------------------------------------------------------
	self:RegisterChatCommand("scp", "OnChatCommand")
	self:RegisterChatCommand("simpleclasspower", "OnChatCommand")
end 

Module.OnEnable = function(self)
	self:RegisterMessage("CG_MOVER_UPDATED", "OnEvent")
	self:RegisterMessage("CG_MOVER_SCALE_UPDATED", "OnEvent")
	if (PlayerClass == "MONK") then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") 
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnEvent") 
	elseif (PlayerClass == "DEATHKNIGHT") then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") 
	end 
end 