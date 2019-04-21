local ADDON, Private = ...
local LibDB = CogWheel("LibDB")

-- Private Addon API
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Define everything here so the order 
-- in which they call each other doesn't matter.
local ClassPower_PostUpdate
local ClassPower_PostCreatePoint
local UnitFramePlayerHUD

-- Called once upon the initial point creation
ClassPower_PostCreatePoint = function(element, id, point)

	-- Retrieve the stylesheet
	local layout = UnitFramePlayerHUD

	-- Setup the point
	point:SetSize(unpack(layout.ClassPowerPointSize))
	point:SetSparkTexture(layout.ClassPowerSparkTexture) 
	point:SetStatusBarTexture(layout.ClassPowerPointTexture)
	point:SetTexCoord(layout.ClassPowerPointTexCoordFunction(id))

	-- Force disable smoothing, it's too inaccurate for this. 
	point:DisableSmoothing(true)

	-- Hardcode the bars to grow from bottom to top.
	point:SetOrientation("UP") 

	-- Position the point
	-- We don't offer any growth choices, it's always right to left.
	if (i == 1) then 
		point:Place("TOPLEFT", element, "TOPLEFT", 0, 0)
	else 
		point:Place("TOPLEFT", element[id-1], "TOPRIGHT", 0, 0)
	end 

	-- Backdrop, aligned to the full point
	point.slotTexture:ClearAllPoints()
	point.slotTexture:SetPoint("BOTTOM", 0, 0)
	point.slotTexture:SetSize(unpack(layout.ClassPowerSlotSize))
	point.slotTexture:SetTexture(layout.ClassPowerSlotTexture)
	point.slotTexture:SetTexCoord(layout.ClassPowerSlotTexCoordFunction(id))

	-- Overlay glow, aligned to the bar texture
	-- This needs post updates to adjust its texcoords based on bar value.
	point.glow:ClearAllPoints()
	point.glow:SetPoint("TOP", point:GetStatusBarTexture(), "TOP", 0, 0)
	point.glow:SetPoint("BOTTOM", 0, 0)
	point.glow:SetPoint("LEFT", 0, 0)
	point.glow:SetPoint("RIGHT", 0, 0)
	point.glow:SetSize(unpack(layout.ClassPowerGlowSize)) -- this is overriden by the points above
	point.glow:SetBlendMode(layout.ClassPowerGlowBlendMode)
	point.glow:SetTexture(layout.ClassPowerGlowTexture)
	point.glow:SetTexCoord(layout.ClassPowerGlowTexCoordFunction(id))
	point.glow.texCoords = {layout.ClassPowerGlowTexCoordFunction(id)}
end

-- Called after each class power update
ClassPower_PostUpdate = function(element, unit, min, max, newMax, powerType)

	-- Retrieve the stylesheet
	local layout = UnitFramePlayerHUD

	-- Make sure the resources are centered
	local elementWidth = (powerType == "RUNES" and 6 or powerType == "STAGGER" and 3 or 5) * layout.ClassPowerPointSize[1]
	if elementWidth ~= element.width then 
		element:SetWidth(elementWidth)
		element.width = elementWidth
	end

	-- Update Glow overlays
	for i = 1, #element do 
		local point = element[i]
		if point:IsShown() then 
			local value = point:GetValue()
			local min, max = point:GetMinMaxValues()
		
			-- Base it all on the bar's current color
			local r, g, b = point:GetStatusBarColor()
			point.glow:SetVertexColor(r, g, b, .75)
			point.slotTexture:SetVertexColor(r*.25, g*.25, b*.25, .85)
		
			-- Adjust texcoords of the overlay glow to match the bars
			local coords = point.glow.texCoords
			point.glow:SetTexCoord(coords[1], coords[2], coords[4] - (coords[4]-coords[3]) * ((value-min)/(max-min)), coords[4])
		end 
	end 

end

UnitFramePlayerHUD = {

	-- Default position of the entire frame, 
	-- will be overridden if the user changes position manually.  
	Place = { "BOTTOM", "UIParent", "BOTTOM", 0, 340 }, 

	-- These are not the size and places of the actual element, 
	-- do NOT change these as they are needed for it to function!
	ClassPowerSize = { 5*70, 70 }, 
	ClassPowerPlace = { "CENTER", 0, 0 },

	-- Point bars
	ClassPowerPointSize = { 70,70 }, 
	ClassPowerPointTexture = GetMedia("diabolic_runes"),
	ClassPowerPointTexCoordFunction = function(id) return (id-1)*128/1024, id*128/1024, 128/512, 256/512 end,

	-- Slot textures
	ClassPowerSlotSize = { 70,70 }, 
	ClassPowerSlotTexture = GetMedia("diabolic_runes"),
	ClassPowerSlotTexCoordFunction = function(id) return (id-1)*128/1024, id*128/1024, 0/512, 128/512 end,

	-- Overlay glow
	ClassPowerGlowSize = { 70,70 }, 
	ClassPowerGlowTexture = GetMedia("diabolic_runes"),
	ClassPowerGlowBlendMode = "ADD",
	ClassPowerGlowTexCoordFunction = function(id) return (id-1)*128/1024, id*128/1024, 256/512, 384/512 end,

	-- This will be too tricky to rotate and map, so we hide it
	ClassPowerSparkTexture = GetMedia("blank"),

	-- Visibility and sorting
	ClassPowerMaxComboPoints = 5, -- maximum displayed points (does not affect runes)
	ClassPowerHideWhenNoTarget = true, -- hide the element when no target is selected
	ClassPowerHideWhenUnattackable = true, -- hide the element when the target can't be attacked
	ClassPowerAlphaWhenEmpty = .5, -- alpha of empty points
	ClassPowerAlphaWhenOutOfCombat = .5, -- alpha multiplier of all points when not in combat
	ClassPowerAlphaWhenOutOfCombatRunes = .5, -- alpha multiplier of all runes when not in combat
	ClassPowerReverseSides = false, -- we don't use it here, just left it for semantics
	ClassPowerRuneSortOrder = "ASC", -- if we display full runes first (ASC) or last (DESC)

	-- Point creation and updates
	ClassPowerPostCreatePoint = ClassPower_PostCreatePoint,
	ClassPowerPostUpdate = ClassPower_PostUpdate
	
}

LibDB:NewDatabase(ADDON..":[UnitFramePlayerHUD]", UnitFramePlayerHUD)
