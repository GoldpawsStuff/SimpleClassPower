local ADDON, Private = ...
local Colors = Private.Colors

-- Wooh! 
local SimpleClassPower = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")

-- Tell the back-end what addon to look for before 
-- initializing this module and all its submodules. 
SimpleClassPower:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any module configs are created.
SimpleClassPower:RegisterSavedVariablesGlobal(ADDON.."_DB")

-- Lua API
local _G = _G
local math_pi = math.pi
local select = select
local string_gsub = string.gsub
local string_match = string.match
local string_split = string.split
local unpack = unpack

-- WoW API
local hooksecurefunc = hooksecurefunc
local UnitClass = _G.UnitClass

-- Player Class
local _, PlayerClass = UnitClass("player")


-- Utility Functions
-----------------------------------------------------------------
-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

local PostUpdateClassPower = function(element, unit, min, max, newMax, powerType)
	-- Only thing we postupdate is the width of the frame,
	-- as we want the resources to be centered.
	element:SetWidth((powerType == "RUNES" and 6 or powerType == "STAGGER" and 3 or 5) * 70)
end 

local PostUpdateGlow = function(element, value, min, max)
	local r, g, b = element:GetStatusBarColor()
	local coords = element.glow.texCoords
	element.glow:SetTexCoord(coords[1], coords[2], coords[4] - (coords[4]-coords[3]) * ((value-min)/(max-min)), coords[4])
	element.glow:SetVertexColor(r, g, b, .75)
	element.background:SetVertexColor(r*1/4, g*1/4, b*1/4, .85)
end

local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	self:SetSize(2, 2) 
	self:Place("CENTER", "UICenter", "CENTER", 0, 0)

	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self:EnableMouse(false) 

	-- Doesn't do anything yet, 
	-- but leaving it here for when 
	-- our tooltip scripts support it.
	self.ignoreMouseOver = true 

	-- Assign our own global custom colors
	self.colors = Colors


	-- Scaffolds
	-----------------------------------------------------------

	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)


	-- Class Power
	-----------------------------------------------------------

	local classPower = backdrop:CreateFrame("Frame")
	classPower:SetSize(2,2) -- minimum size, this is really just an anchor
	classPower:SetPoint("CENTER", 0, 0) -- center it smack in the middle of the screen, will update later

	-- Maximum points displayed regardless 
	-- of max value and available point frames.
	-- This does not affect runes, which still require 6 frames.
	classPower.maxComboPoints = 5 

	-- Rune sort order according to time left
	classPower.runeSortOrder = "ASC" -- put available runes first

	-- Set the point alpha to 0 when no target is selected
	-- This does not affect runes 
	classPower.hideWhenNoTarget = true 

	-- Set all point alpha to 0 when we have no active points
	-- This does not affect runes 
	classPower.hideWhenEmpty = true 

	-- Alpha modifier of inactive/not ready points
	classPower.alphaEmpty = .35 

	-- Alpha modifier when not engaged in combat
	-- This is applied on top of the inactive modifier above
	classPower.alphaNoCombat = .5

	-- Creating 6 frames since runes require it
	for i = 1,6 do 
		
		-- Main point object
		local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
		point:SetSize(70,70)
		point:DisableSmoothing(true)
		point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
		point:SetOrientation("UP") -- set the bars to grow from bottom to top.
		point:SetSparkTexture(getPath("blank")) -- this will be too tricky to rotate and map
		point:SetStatusBarTexture(getPath("diabolic_runes"))
		point:SetTexCoord((i-1)*128/1024, i*128/1024, 128/512, 256/512)
		if i == 1 then 
			point:SetPoint("LEFT", 0, 0)
		else 
			point:SetPoint("LEFT", classPower[i-1], "RIGHT", 0, 0)
		end 

		-- Backdrop, aligned to the full point
		point.background = point:CreateTexture()
		point.background:SetSize(70,70)
		point.background:SetDrawLayer("BACKGROUND", -1)
		point.background:SetPoint("BOTTOM", 0, 0)
		point.background:SetTexture(getPath("diabolic_runes"))
		point.background:SetTexCoord((i-1)*128/1024, i*128/1024, 0/512, 128/512)

		-- Overlay glow, aligned to the bar texture
		point.glow = point:CreateTexture()
		point.glow:SetSize(70,70)
		point.glow:SetDrawLayer("ARTWORK")
		point.glow:SetBlendMode("ADD")
		point.glow:SetPoint("TOP", point:GetStatusBarTexture(), "TOP", 0, 0)
		point.glow:SetPoint("BOTTOM", 0, 0)
		point.glow:SetPoint("LEFT", 0, 0)
		point.glow:SetPoint("RIGHT", 0, 0)
		point.glow:SetTexture(getPath("diabolic_runes"))
		point.glow:SetTexCoord((i-1)*128/1024, i*128/1024, 256/512, 384/512) 
		point.glow.texCoords = { (i-1)*128/1024, i*128/1024, 256/512, 384/512 }

		-- This callback is handled by the statusbar library on all bar updates
		point.PostUpdate = PostUpdateGlow

		classPower[i] = point
	end

	self.ClassPower = classPower
	self.ClassPower.PostUpdate = PostUpdateClassPower

end

SimpleClassPower.PostUpdatePosition = function(self)
	local skull = _G.DiabolicUISkullTexture
	if skull then
		local x, y = skull:GetCenter()
		self.frame.ClassPower:Place("BOTTOM", "UICenter", "BOTTOM", 0, 340 + 10 + (y-77)) 
	else 
		self.frame.ClassPower:Place("BOTTOM", "UICenter", "BOTTOM", 0, 340)
	end 
end

SimpleClassPower.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 
		local skull = _G.DiabolicUISkullTexture
		if skull then 
			hooksecurefunc(skull, "SetPoint", function() 
				local x, y = skull:GetCenter()
				self.frame.ClassPower:Place("BOTTOM", "UICenter", "BOTTOM", 0, 340 + 10 + (y-77)) 
			end)
		end
		self:PostUpdatePosition()
	end
end

SimpleClassPower.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("player", "UICenter", Style)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end 
