local LibMover = CogWheel:Set("LibMover", 4)
if (not LibMover) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMover requires LibFrame to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMover requires LibEvent to be loaded.")

LibFrame:Embed(LibMover)
LibEvent:Embed(LibMover)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local GetCursorPosition = _G.GetCursorPosition

-- WoW Frames
local UIParent = _G.UIParent

-- Library registries
LibMover.embeds = LibMover.embeds or {}
LibMover.anchors = LibMover.anchors or {}
LibMover.contents = LibMover.contents or {}
LibMover.movers = LibMover.movers or {}
LibMover.handles = LibMover.handles or {}
LibMover.defaults = LibMover.defaults or {}

-- Create the secure master frame
if (not LibMover.frame) then
	LibMover.frame = LibMover:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
else 
	LibMover.frame:ClearAllPoints()
	UnregisterAttributeDriver(LibMover.frame, "state-visibility")
end 

-- Keep it and all its children hidden during combat. 
-- *note that being a child of the UICenter frame, it's also hidden during pet-battles.
RegisterAttributeDriver(LibMover.frame, "state-visibility", "[combat] hide; show")

-- Speedcuts
local Parent = LibMover.frame
local Anchor = LibMover.anchors
local Content = LibMover.contents
local Mover = LibMover.movers
local Handle = LibMover.handles

-- Just to easier be able to change things for me.
local LABEL, VALUE = "|cffaeaeae", "|cffffd200"

-- Messages that don't need localization,
-- so we can keep them as part of the back- end
local POSITION = LABEL.."Anchor|r: "..VALUE.."%s|r - "..LABEL.."X|r: "..VALUE.."%.1f|r - "..LABEL.."Y|r: "..VALUE.."%.1f|r"
local SCALE = LABEL.."Scale|r: "..VALUE.."%.0f|r%%"

-- Alpha of the movers and handles
local ALPHA_DRAGGING = .5
local ALPHA_STOPPED = .85

-- General backdrop for all overlays
local BACKDROP_COLOR = { .4, .4, .9 }
local BACKDROP_BORDERCOLOR = { .3, .3, .7 }
local BACKDROP = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeSize = 2, 
	tile = false, 
	insets = { 
		top = 0, 
		bottom = 0, 
		left = 0, 
		right = 0 
	}
}

---------------------------------------------------
-- Utility Functions
---------------------------------------------------
-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Parse a position
local AREA_START = 1/3
local AREA_END = 2/3
local parsePosition = function(parentWidth, parentHeight, x, y, bottom, left, top, right)
	if (y < parentHeight * AREA_START) then 
		if (x < parentWidth * AREA_START) then 
			return "BOTTOMLEFT", left, bottom
		elseif (x > parentWidth * AREA_END) then 
			return "BOTTOMRIGHT", right, bottom
		else 
			return "BOTTOM", x - parentWidth/2, bottom
		end 
	elseif (y > parentHeight * AREA_END) then 
		if (x < parentWidth * AREA_START) then 
			return "TOPLEFT", left, top
		elseif x > parentWidth * AREA_END then 
			return "TOPRIGHT", right, top
		else 
			return "TOP", x - parentWidth/2, top
		end 
	else 
		if (x < parentWidth * AREA_START) then 
			return "LEFT", left, y - parentHeight/2
		elseif (x > parentWidth * AREA_END) then 
			return "RIGHT", right, y - parentHeight/2
		else 
			return "CENTER", x - parentWidth/2, y - parentHeight/2
		end 
	end 
end

---------------------------------------------------
-- Mover Template
---------------------------------------------------
local Mover = LibMover:CreateFrame("Frame")
local Mover_MT = { __index = Mover }

-- Get the parsed position relative to UIParent
Mover.GetParsedPosition = function(self)
	local uiW, uiH = UIParent:GetSize()
	local x, y = self:GetCenter()
	local bottom = self:GetBottom()
	local left = self:GetLeft()
	local top = self:GetTop() - uiH
	local right = self:GetRight() - uiW
	return parsePosition(uiW, uiH, x, y, bottom, left, top, right)
end

Mover.OnUpdate = function(self, elapsed)
	local uiW, uiH = UIParent:GetSize()
	local scale = UIParent:GetScale()
	local x,y = GetCursorPosition()
	local realX, realY = x/scale, y/scale
	local w,h = self:GetSize()

	local bottom = y - h/2
	local left = x - w/2
	local top = (y + h/2) - uiH
	local right = (y + w/2) - uiW

	self:UpdateTexts(parsePosition(uiW, uiH, realX, realY, bottom, left, top, right))
end

Mover.OnDragStart = function(self) 
	self:SetScript("OnUpdate", self.OnUpdate)
	self:StartMoving()
	self:SetAlpha(ALPHA_DRAGGING)
	Handle[self]:Show()
end

Mover.OnDragStop = function(self) 
	self:SetScript("OnUpdate", nil)
	self:StopMovingOrSizing()
	self:SetAlpha(ALPHA_STOPPED)

	Handle[self]:Hide()

	local rPoint, xOffset, yOffset = self:GetParsedPosition()

	Anchor[self]:Place(rPoint, "UIParent", rPoint, xOffset, yOffset)
	Content[self]:Place(rPoint, anchor, rPoint, 0, 0)

	self:UpdateInfoFramePosition()
	self:UpdateTexts(rPoint, xOffset, yOffset)
	self:Place(rPoint, xOffset, uOffset)
end 

Mover.UpdateInfoFramePosition = function(self)
	local rPoint, xOffset, yOffset = self:GetParsedPosition()
	if string_find(rPoint, "TOP") then 
		self.infoFrame:Place("TOP", self, "BOTTOM", 0, -6)
	else 
		self.infoFrame:Place("BOTTOM", self, "TOP", 0, 6)
	end 
end 

-- Called when the target's parent changes, 
-- as we need to update the parent and position 
-- of our anchor as well for conistent scaling and size. 
Mover.OnParentUpdate = function(self)
	local rPoint, xOffset, yOffset = self:GetParsedPosition()

	Anchor[self]:SetParent(Content[self]:GetParent())
	Anchor[self]:Place(rPoint, "UIParent", rPoint, xOffset, yOffset)

	self:UpdateTexts(rPoint, xOffset, yOffset)
	self:Place(rPoint, xOffset, uOffset)

end

Mover.OnMouseWheel = function(self, delta)
	if (delta < 0) then
		if (self.scale - .1 > .5) then 
			self.scale = self.scale - .1
		end 
	else
		if (self.scale + .1 < 1.5) then 
			self.scale = self.scale + .1 
		end 
	end
	self:UpdateScale()
end

Mover.UpdateTexts = function(self, point, x, y)
	if self.PreUpdateTexts then 
		self:PreUpdateTexts(point, x, y)
	end 

	self.positionText:SetFormattedText(POSITION, point, x, y)
	self.scaleText:SetFormattedText(SCALE, self.scale*100)

	if self.PostUpdateTexts then 
		self:PostUpdateTexts(point, x, y)
	end 
end

Mover.UpdateScale = function(self)
	local width = self.realWidth * self.scale
	local height = self.realHeight * self.scale

	if self.PreUpdateScale then 
		self:PreUpdateScale()
	end

	Anchor[self]:SetSize(width, height)
	Content[self]:SetScale(self.scale)

	self:SetSize(width, height)
	self:UpdateTexts(Anchor[self]:GetPoint())

	if self.PostUpdateScale then 
		self:PostUpdateScale()
	end
	
end 

-- Sets the default position of the mover
Mover.SetDefaultPosition = function(self, ...)
end

-- Saves the current position of the mover
Mover.SavePosition = function(self)
end

-- Restores the saved position of the mover
Mover.RestorePosition = function(self)
end

-- Returns the mover to its default position
Mover.RestoreDefaultPosition = function(self)
end

---------------------------------------------------
-- Library Event Handling
---------------------------------------------------
LibMover.OnEvent = function(self, event, ...)
end

LibMover.CreateMover = function(self, target, ...)

	-- Retrieve the parsed position of the target frame
	local rPoint, xOffset, yOffset = Mover.GetParsedPosition(target)
	target:ClearAllPoints()

	local parent = target:GetParent()

	-- The movable anchor
	-- Make our movable anchor unrelated to the frame, 
	-- but make sure it has the same parent for consistent scales. 
	local anchor = Parent:CreateFrame("Frame", nil, parent)
	anchor:SetSize(2,2)

	-- Our overlay drag handle
	local mover = setmetatable(Parent:CreateFrame("Frame"), DragFrame_MT) 
	mover:SetFrameStrata("DIALOG")
	mover:EnableMouse(true)
	mover:EnableMouseWheel(true)
	mover:SetMovable(true)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("RightButtonUp", "MiddleButtonUp") 
	mover:SetScript("OnDragStart", Mover.OnDragStart)
	mover:SetScript("OnDragStop", Mover.OnDragStart)
	mover:SetScript("OnMouseWheel", Mover.OnMouseWheel)
	mover:SetScript("OnClick", Mover.OnClick)
	mover:SetFrameLevel(100)
	mover:SetBackdrop(BACKDROP)
	mover:SetBackdropColor(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3])
	mover:SetBackdropBorderColor(BACKDROP_BORDERCOLOR[1], BACKDROP_BORDERCOLOR[2], BACKDROP_BORDERCOLOR[3])
	mover:SetAlpha(ALPHA_STOPPED)
	mover.scale = target:GetScale()
	
	local infoFrame = mover:CreateFrame("Frame")
	infoFrame:SetSize(2,2)
	mover.infoFrame = infoFrame

	local positionText = infoFrame:CreateFontString()
	positionText:SetFontObject(Private.GetFont(14, true))
	positionText:SetPoint("BOTTOM", infoFrame, "BOTTOM", 0, 2)
	mover.positionText = positionText

	local scaleText = infoFrame:CreateFontString()
	scaleText:SetFontObject(Private.GetFont(14, true))
	scaleText:SetPoint("BOTTOM", positionText, "TOP", 0, 2)
	mover.scaleText = scaleText

	if rPoint:find("TOP") then 
		infoFrame:SetPoint("TOP", self.anchorOverlay, "BOTTOM", 0, -6)
	else 
		infoFrame:SetPoint("BOTTOM", self.anchorOverlay, "TOP", 0, 6)
	end 
	
	-- An overlay visible on the cursor while dragging the movable frame
	local handle = mover:CreateTexture()
	handle:Hide()
	handle:SetDrawLayer("ARTWORK")
	handle:SetAllPoints(frame)
	handle:SetColorTexture(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3], ALPHA_DRAGGING)
	handle:SetIgnoreParentAlpha(true)

	mover:UpdateScale()

	Anchor[mover] = anchor
	Content[mover] = target
	Handle[mover] = handle
	Movers[target] = mover

	if self.PostCreateMover then 
		return self:PostCreateMover(mover)
	end 
end

-- Just in case this is a library upgrade, we upgrade events & scripts.
LibMover:UnregisterAllEvents()
LibMover:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")

local embedMethods = {
	CreateMover = true
}

LibMover.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMover.embeds) do
	LibMover:Embed(target)
end
