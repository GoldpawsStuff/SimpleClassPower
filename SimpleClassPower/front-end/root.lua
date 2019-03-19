local ADDON, Private = ...
local Module = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibSlash", "LibSecureHook", "LibFrame", "LibUnitFrame", "LibStatusBar")

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

	enableClassColor = false, 
}

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
	enableStagger = true

}

local ParsePosition = function(self)
	local uiW, uiH = UIParent:GetSize()
	local x, y = self:GetCenter()
	local bottom = self:GetBottom()
	local left = self:GetLeft()
	local top = self:GetTop() - uiH
	local right = self:GetRight() - uiW

	local rPoint, xOffset, yOffset
	if y < uiH * 1/3 then 
		if x < uiW * 1/3 then 
			rPoint = "BOTTOMLEFT"
			xOffset = left
		elseif x > uiW * 2/3 then 
			rPoint = "BOTTOMRIGHT"
			xOffset = right
		else 
			rPoint = "BOTTOM"
			xOffset = x - uiW/2
		end 
		yOffset = bottom

	elseif y > uiH * 2/3 then 
		if x < uiW * 1/3 then 
			rPoint = "TOPLEFT"
			xOffset = left
		elseif x > uiW * 2/3 then 
			rPoint = "TOPRIGHT"
			xOffset = right 
		else 
			rPoint = "TOP"
			xOffset = x - uiW/2
		end 
		yOffset = top
	else 
		if x < uiW * 1/3 then 
			rPoint = "LEFT"
			xOffset = left
		elseif x > uiW * 2/3 then 
			rPoint = "RIGHT"
			xOffset = right
		else 
			rPoint = "CENTER"
			xOffset = x - uiW/2
		end 
		yOffset = y - uiH/2
	end 
	return rPoint, xOffset, yOffset
end

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

-- This is chaotic, will clean it up later. 
-- It has no impact on performance, though, 
-- so this is purely a case of semantics and poetry. 
Module.GetConfigWindow = function(self)
	if (not self.window) then 
		local db = self.db
		local layout = self.layout
		local frame = self.frame
		local anchor = self.anchor
		local classPower = self.classPower
		local visibility =  self.visibility

		local backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeSize = 4, 
			tile = false, 
			insets = { 
				top = 0, 
				bottom = 0, 
				left = 0, 
				right = 0 
			}
		}
		
		local padding = 20
		local buttonSize = { 160, 40 }
		local borderColor = { .025, .025, .025, 1 }
		local layer1Color = { .075, .075, .075, 1 }
		local layer2Color = { .065, .065, .065, 1 }

		local window = self:CreateFrame("Frame", nil, "UIParent")
		window:Hide()

		local rPoint = anchor:GetPoint()

		local anchorOverlay = window:CreateFrame("Frame")
		anchorOverlay:SetFrameStrata("DIALOG")
		anchorOverlay:SetFrameLevel(100)
		anchorOverlay:SetSize(layout.ClassPowerSize[1] + 10, layout.ClassPowerSize[2] + 10)
		anchorOverlay:SetBackdrop(backdrop)
		anchorOverlay:SetBackdropColor(.4, .4, .9)
		anchorOverlay:SetBackdropBorderColor(.3, .3, .7)
		anchorOverlay:SetPoint(rPoint, anchor, rPoint, 0, 0)
		anchorOverlay:SetAlpha(.85)

		for i = 1,#classPower-1 do 
			local pointOverlay = anchorOverlay:CreateTexture()
			pointOverlay:SetDrawLayer("ARTWORK")
			pointOverlay:SetColorTexture(.3, .3, .7)
			pointOverlay:SetSize(4, layout.ClassPowerPointSize[2]-2)
			anchorOverlay[i] = pointOverlay
		end 

		local dragFrame = window:CreateFrame("Frame")
		dragFrame:SetFrameStrata("DIALOG")
		dragFrame:SetFrameLevel(110)
		dragFrame:SetPoint(rPoint, anchor, rPoint, 0, 0)
		dragFrame:SetSize(layout.ClassPowerSize[1], layout.ClassPowerSize[2])
		dragFrame:EnableMouse(true)
		dragFrame:EnableMouseWheel(true)
		dragFrame:SetMovable(true)
		dragFrame:RegisterForDrag("LeftButton")
		dragFrame.numPoints = 6
		dragFrame.scale = 1

		dragFrame:SetScript("OnDragStart", function(self) 
			self:StartMoving()
			self.overlay:Show()
			anchorOverlay:SetAlpha(.5)
		end)

		dragFrame:SetScript("OnDragStop", function(self) 
			self:StopMovingOrSizing()
			self:UpdateTexts()
			self.overlay:Hide()
			anchorOverlay:SetAlpha(.85)

			local rPoint, xOffset, yOffset = ParsePosition(self)

			anchor:Place(rPoint, "UIParent", rPoint, xOffset, yOffset)
			classPower:Place(rPoint, anchor, rPoint, 0, 0)
			anchorOverlay:Place(rPoint, anchor, rPoint, 0, 0)
			if rPoint:find("TOP") then 
				self.infoFrame:Place("TOP", anchorOverlay, "BOTTOM", 0, -6)
			else 
				self.infoFrame:Place("BOTTOM", anchorOverlay, "TOP", 0, 6)
			end 
		end)

		dragFrame:SetScript("OnMouseWheel", function(self, delta)
			if (delta < 0) then
				scale = math.max(self.scale - .1, .5)
			else
				scale = math.min(self.scale + .1, 1.5)
			end
			self.scale = scale
			self:UpdateScale()
		end)

		-- Update all scales, sizes and positions
		dragFrame.UpdateScale = function(self)
			local pointW, pointH = unpack(layout.ClassPowerPointSize)
			local width = pointW * self.numPoints * self.scale
			local height = pointW * self.scale
	
			self:UpdateTexts()
			self:SetSize(width, height)
			anchor:SetSize(width, height)
			anchorOverlay:SetSize(width + 10, height + 10)
			classPower:SetScale(self.scale)

			local spacing = width/self.numPoints
			local displayedBars = self.numPoints - 1

			for i = 1,displayedBars do 
				local pointOverlay = anchorOverlay[i]
				pointOverlay:ClearAllPoints()
				pointOverlay:SetPoint("TOP", anchorOverlay, "TOPLEFT", 5+ spacing*i , 0)
				pointOverlay:SetPoint("BOTTOM", anchorOverlay, "BOTTOMLEFT", 5+ spacing*i, 0)
				pointOverlay:Show()
			end 

			for i = displayedBars+1,#anchorOverlay do 
				local pointOverlay = anchorOverlay[i]
				pointOverlay:ClearAllPoints()
				pointOverlay:Hide()
			end 

		end 
		
		local morePoints, lessPoints
		morePoints = anchorOverlay:CreateFrame("Button")
		morePoints:SetPoint("TOPLEFT", anchorOverlay, "TOPRIGHT", 6, 0)
		morePoints:SetPoint("BOTTOMLEFT", anchorOverlay, "BOTTOMRIGHT", 6, 0)
		morePoints:SetWidth(30)
		morePoints:SetBackdrop(backdrop)
		morePoints:SetBackdropColor(.4, .4, .9)
		morePoints:SetBackdropBorderColor(.3, .3, .7)
		morePoints:RegisterForClicks("AnyUp")
		morePoints:SetAlpha((dragFrame.numPoints < #classPower) and 1 or .5)
		morePoints:SetScript("OnClick", function(self) 
			if dragFrame.numPoints < #classPower then 
				dragFrame.numPoints = dragFrame.numPoints + 1
				dragFrame:UpdateScale()
				morePoints:SetAlpha((dragFrame.numPoints < #classPower) and 1 or .5)
				lessPoints:SetAlpha((dragFrame.numPoints > 3) and 1 or .5)
			end
		end)

		local morePointsMsg = morePoints:CreateFontString()
		morePointsMsg:SetFontObject(Private.GetFont(20,true))
		morePointsMsg:SetText("+")
		morePointsMsg:SetPoint("CENTER")

		lessPoints = anchorOverlay:CreateFrame("Button")
		lessPoints:SetPoint("TOPRIGHT", anchorOverlay, "TOPLEFT", -6, 0)
		lessPoints:SetPoint("BOTTOMRIGHT", anchorOverlay, "BOTTOMLEFT", -6, 0)
		lessPoints:SetWidth(30)
		lessPoints:SetBackdrop(backdrop)
		lessPoints:SetBackdropColor(.4, .4, .9)
		lessPoints:SetBackdropBorderColor(.3, .3, .7)
		lessPoints:SetAlpha((dragFrame.numPoints > 3) and 1 or .5)
		lessPoints:RegisterForClicks("AnyUp")
		lessPoints:SetScript("OnClick", function(self) 
			if dragFrame.numPoints > 3 then 
				dragFrame.numPoints = dragFrame.numPoints - 1
				dragFrame:UpdateScale()
				morePoints:SetAlpha((dragFrame.numPoints < #classPower) and 1 or .5)
				lessPoints:SetAlpha((dragFrame.numPoints > 3) and 1 or .5)
			end
		end)

		local lessPointsMsg = lessPoints:CreateFontString()
		lessPointsMsg:SetFontObject(Private.GetFont(20,true))
		lessPointsMsg:SetText("-")
		lessPointsMsg:SetPoint("CENTER")

		local infoFrame = dragFrame:CreateFrame("Frame")
		infoFrame:SetSize(2,14+2+14+2)
		if rPoint:find("TOP") then 
			infoFrame:SetPoint("TOP", anchorOverlay, "BOTTOM", 0, -6)
		else 
			infoFrame:SetPoint("BOTTOM", anchorOverlay, "TOP", 0, 6)
		end 
		dragFrame.infoFrame = infoFrame

		local positionText = infoFrame:CreateFontString()
		positionText:SetFontObject(Private.GetFont(14, true))
		positionText:SetPoint("BOTTOM", infoFrame, "BOTTOM", 0, 2)
		dragFrame.positionText = positionText

		local scaleText = infoFrame:CreateFontString()
		scaleText:SetFontObject(Private.GetFont(14, true))
		scaleText:SetPoint("BOTTOM", positionText, "TOP", 0, 2)
		dragFrame.scaleText = scaleText

		-- An overlay visible while dragging the frame
		local dragFrameOverlay = dragFrame:CreateTexture()
		dragFrameOverlay:Hide()
		dragFrameOverlay:SetDrawLayer("ARTWORK")
		dragFrameOverlay:SetAllPoints(dragFrame)
		dragFrameOverlay:SetColorTexture(.4, .4, .9, .5)
		dragFrame.overlay = dragFrameOverlay

		dragFrame.UpdateTexts = function(self)
			local point, _, _, x, y = anchor:GetPoint()
			self.positionText:SetFormattedText("|cffaeaeaeAnchor|r: |cffffd200%s|r - |cffaeaeaeX|r: |cffffd200%.1f|r - |cffaeaeaeY|r: |cffffd200%.1f|r", point, x, y)
			self.scaleText:SetFormattedText("|cffaeaeaeScale|r: |cffffd200%.0f|r%% |cff666666(change with mousewheel)|r", self.scale*100)
		end

		dragFrame:UpdateScale()
		--dragFrame:UpdateTexts()

		-- Hide the resources while the dragframe is visible
		window:HookScript("OnShow", function() visibility:Hide() end)
		window:HookScript("OnHide", function() visibility:Show() end)

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
	-- Make our movable anchor unrelated to the unitframe,
	-- but make sure it has the same parent for consistent scales. 
	local anchor = self:CreateFrame("Frame", nil, "UICenter")
	anchor:SetSize(2,2)
	self.anchor = anchor

	-- All positioning should be relative to UIParent
	anchor:Place("BOTTOM", "UIParent", "BOTTOM", 0, 340)

	-- Parse and re-apply anchor position, to make sure it's correct.
	local rPoint, xOffset, yOffset = ParsePosition(anchor)
	anchor:Place(rPoint, xOffset, yOffset)

	local classPower = frame.ClassPower

	-- Make a visibility layer to hide the resources 
	-- while the configuration mode is active. 
	local strata = classPower:GetFrameStrata()
	local level = classPower:GetFrameLevel()
	local visibility = classPower:GetParent():CreateFrame("Frame")
	visibility:SetAllPoints()
	self.visibility = visibility

	classPower:SetParent(visibility)
	classPower:SetScale(1)
	classPower:Place(rPoint, anchor, rPoint, 0, 0)
	self.classPower = classPower

	-- Register a chat command to toggle the config window
	---------------------------------------------------------------------
	self:RegisterChatCommand("scp", "ToggleConfigWindow")
	self:RegisterChatCommand("simpleclasspower", "ToggleConfigWindow")

end 
