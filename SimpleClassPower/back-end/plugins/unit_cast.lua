local LibCast = Wheel("LibCast")
assert(LibCast, "UnitCast requires LibCast to be loaded.")

local LibClientBuild = Wheel("LibClientBuild")
assert(LibClientBuild, "UnitCast requires LibClientBuild to be loaded.")

local LibNumbers = Wheel("LibNumbers")
assert(LibNumbers, "UnitCast requires LibNumbers to be loaded.")

-- Lua API
local math_floor = math.floor
local string_find = string.find
local string_match = string.match
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetCVar = GetCVar
local GetNetStats = GetNetStats
local GetTime = GetTime
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitReaction = UnitReaction

-- Number Abbreviation
local short = LibNumbers:GetNumberAbbreviationShort()
local large = LibNumbers:GetNumberAbbreviationLong()

-- Localization
local L_FAILED = FAILED
local L_INTERRUPTED = INTERRUPTED
local L_MILLISECONDS_ABBR = MILLISECONDS_ABBR

-- Constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- Constants for client version
local IsAnyClassic = LibClientBuild:IsAnyClassic()
local IsClassic = LibClientBuild:IsClassic()
local IsTBC = LibClientBuild:IsTBC()
local IsWrath = LibClientBuild:IsWrath()
local IsRetail = LibClientBuild:IsRetail()

local playerGUID = UnitGUID("player")

-- Define it here so it can call itself later on
local Update

-- Utility Functions
-----------------------------------------------------------
local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

local formatTime = function(time)
	if time > DAY then -- more than a day
		return ("%.0f%s"):format((time / DAY) - (time / DAY)%1, "d")
	elseif time > HOUR then -- more than an hour
		return ("%.0f%s"):format((time / HOUR) - (time / HOUR)%1, "h")
	elseif time > MINUTE then -- more than a minute
		return ("%.0f%s %.0f%s"):format((time / MINUTE) - (time / MINUTE)%1, "m", (time%MINUTE) - (time%MINUTE)%1, "s")
	elseif time > 10 then -- more than 10 seconds
		return ("%.0f%s"):format((time) - (time)%1, "s")
	elseif time > 0 then
		return ("%.1f"):format(time)
	else
		return ""
	end
end


-- Spell Cast Updates
-----------------------------------------------------------
local clear = function(element)
	element.casting = nil
	element.channeling = nil
	element.tradeskill = nil
	element.notInterruptible = nil
	element.total = nil
	element.name = nil
	element.text = nil
	if (element.Name) then
		element.Name:SetText("")
	end
	if (element.Value) then
		element.Value:SetText("")
	end
	if (element.Failed) then
		element.Failed:SetText("")
	end
	if (element.SpellQueue) then
		element.SpellQueue:SetValue(0, true)
	end
	element:SetValue(0, true)
end

local updateSpellQueueOrientation = function(element)
	if (element.channeling) then
		local orientation = element:GetOrientation()
		if (orientation ~= element.SpellQueue:GetOrientation()) then
			element.SpellQueue:SetOrientation(orientation)
		end
	else
		local orientation
		local barDirection = element:GetOrientation()
		if (barDirection == "LEFT") then
			orientation = "RIGHT"
		elseif (barDirection == "RIGHT") then
			orientation = "LEFT"
		elseif (barDirection == "UP") then
			orientation = "DOWN"
		elseif (barDirection == "DOWN") then
			orientation = "UP"
		end
		local spellQueueDirection = element.SpellQueue:GetOrientation()
		if (spellQueueDirection ~= orientation) then
			element.SpellQueue:SetOrientation(orientation)
		end
	end
end

local updateSpellQueueValue = function(element)
	element.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow")) or 400 -- that large value is WoW's default
	return element.spellQueueWindow
end

local updateSpellQueueDisplay = function(element)

	local ms = updateSpellQueueValue(element)
	local max = element.total or element.max
	local value

	-- This could be a forced update,
	-- and can cause a division by zero.
	if (ms and (max and max > 0)) then
		-- Don't allow values above max, it'd look wrong
		value = ms / 1e3
		if (value > max) then
			value = max
		end

		-- Hide the overlay if it'd take up less than 5% of your bar,
		-- or if the total length of the window is shorter than 100ms.
		local ratio = value / max
		if (ratio < .05) or (ms < 100) then
			value = 0
		end

	else
		max = 1
		value = 0
	end

	element.SpellQueue:SetMinMaxValues(0, max)
	element.SpellQueue:SetValue(value, true)

end

local UpdateColor = function(element, unit)
	if element.OverrideColor then
		return element:OverrideColor(unit)
	end
	local self = element._owner
	local color, r, g, b
	if (element.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		color = class and self.colors.class[class]
	elseif (element.colorPetAsPlayer and UnitIsUnit(unit, "pet")) then
		local _, class = UnitClass("player")
		color = class and self.colors.class[class]
	elseif (element.colorReaction and UnitReaction(unit, "player")) then
		color = self.colors.reaction[UnitReaction(unit, "player")]
	end
	if color then
		r, g, b = color[1], color[2], color[3]
	end
	if (r) then
		element:SetStatusBarColor(r, g, b)
	end
	if element.PostUpdateColor then
		element:PostUpdateColor(unit)
	end
end

local OnUpdate = function(element, elapsed)
	local self = element._owner
	local unit = self.unit
	if (not unit) or (not UnitExists(unit)) or (UnitIsDeadOrGhost(unit)) then
		clear(element)
		element:Hide()
		element.max = 0
		element.delay = 0
		if (element.PostUpdate) then
			return element:PostUpdate(unit)
		end
		return
	end
	local r, g, b
	if (element.casting or element.tradeskill) then
		local duration = element.duration + elapsed
		if (duration >= element.max) then
			clear(element)
			element:Hide()
			element.max = 0
			element.delay = 0
			if (element.PostUpdate) then
				return element:PostUpdate(unit)
			end
			return
		end
		if (element.Value) then
			if element.tradeskill then
				element.Value:SetText(formatTime(element.max - duration))
			elseif (element.delay and (element.delay > 0)) then
				element.Value:SetFormattedText("%s|cffff0000 +%s|r", formatTime(floor(element.max - duration)), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(element.max - duration))
			end
		end
		if (element.SpellQueue) and (not element.disableSpellQueue) then
			updateSpellQueueDisplay(element)
		end
		element.duration = duration
		element:SetValue(duration)
		if (element.PostUpdate) then
			element:PostUpdate(unit)
		end

	elseif (element.channeling) then
		local duration = element.duration - elapsed
		if (duration <= 0) then
			clear(element)
			element:Hide()
			element.max = 0
			element.delay = 0
			if (element.PostUpdate) then
				return element:PostUpdate(unit)
			end
			return
		end
		if (element.Value) then
			if (element.tradeskill) then
				element.Value:SetText(formatTime(duration))
			elseif (element.delay and (element.delay > 0)) then
				element.Value:SetFormattedText("%s|cffff0000 +%s|r", formatTime(duration), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(duration))
			end
		end
		if (element.SpellQueue) and (not element.disableSpellQueue) then
			updateSpellQueueDisplay(element)
		end
		element.duration = duration
		element:SetValue(duration)
		if (element.PostUpdate) then
			element:PostUpdate(unit)
		end

	elseif (element.failedMessageTimer) then
		element.failedMessageTimer = element.failedMessageTimer - elapsed
		if (element.failedMessageTimer > 0) then
			return
		end
		element.failedMessageTimer = nil
		if (element.Failed) then
			element.Failed:SetText("")
		end
	else
		clear(element)
		element:Hide()
		element.max = 0
		element.delay = 0
		if (element.PostUpdate) then
			return element:PostUpdate(unit)
		end
		return
	end
end

Update = function(self, event, unit, ...)
	-- This just messes with our system here.
	if (event == "FrequentUpdate") then
		return
	end

	-- Our custom events only return unitGUID, not unit
	local unitGUID = UnitGUID(self.unit)
	if (unit == unitGUID) then
		unit = self.unit
	end
	if (not unit) or (unit ~= self.unit) then
		return
	end

	local element = self.Cast
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	if (event == "GP_SPELL_CAST_START") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = LibCast:UnitCastingInfo(unit)
		if (name) then
			local now = GetTime()
			local max = endTime - startTime

			element.name = name
			element.text = text
			element.duration = now - startTime
			element.max = max
			element.delay = 0
			element.casting = true
			element.channeling = nil
			element.notInterruptible = notInterruptible
			element.tradeskill = isTradeSkill
			element.starttime = nil
			element.failedMessageTimer = nil
			element:SetMinMaxValues(0, element.total or element.max, true)
			element:SetValue(element.duration, true)
			element:UpdateColor(unit)

			if (element.Failed) then element.Failed:SetText("") end
			if (element.Name) then element.Name:SetText(utf8sub(text, element.maxNameChars or 32, true)) end
			if (element.Icon) then element.Icon:SetTexture(texture) end
			if (element.Value) then element.Value:SetText("") end
			if (element.Shield) then
				if (element.notInterruptible) and (not UnitIsUnit(unit ,"player")) then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
			if (element.SpellQueue) and (not element.disableSpellQueue) then
				updateSpellQueueOrientation(element)
				updateSpellQueueDisplay(element)
			end
			element:Show()
			element:SetScript("OnUpdate", OnUpdate)
		else
			element:Hide()
			element:SetValue(0, true)
			element:SetScript("OnUpdate", nil)
		end

	elseif (event == "GP_SPELL_CAST_FAILED") then

		local timeLeft
		if (element.timeToHold) then
			timeLeft = GetTime() - (element.starttime or 0) -- should be there
		end

		clear(element)

		if (element.Shield) then
			element.Shield:Hide()
		end

		if (element.timeToHold) then
			local spellQueueWindow = updateSpellQueueValue(element) / 1e3 -- get value in seconds
			if (timeLeft >= spellQueueWindow) then
				element.failedMessageTimer = element.timeToHold
				local msg = element.Failed or element.Value or element.Name
				if (msg) then
					msg:SetText(utf8sub(L_FAILED, element.maxNameChars or 32, true))
				end
			else
				element.failedMessageTimer = nil
				local msg = element.Failed or element.Value or element.Name
				if (msg) then
					msg:SetText("")
				end
			end

		else
			element:Hide()
			element:SetScript("OnUpdate", nil)
			local msg = element.Failed or element.Value or element.Name
			if (msg) then
				msg:SetText("")
			end
		end

	elseif (event == "GP_SPELL_CAST_SUCCESS") or (event == "GP_SPELL_CAST_STOP") or (event == "GP_SPELL_CAST_CHANNEL_STOP") then

		clear(element)
		element:Hide()
		element:SetScript("OnUpdate", nil)
		element.failedMessageTimer = nil

		-- Clear leftovers from earlier casts
		local msg = element.Failed or element.Value or element.Name
		if (msg) then
			msg:SetText("")
		end
		if (element.Shield) then
			element.Shield:Hide()
		end

	elseif (event == "GP_SPELL_CAST_INTERRUPTED") then

		local timeLeft
		if (element.timeToHold) then
			timeLeft = GetTime() - (element.starttime or 0) -- should be there
		end

		clear(element)

		if (element.Shield) then
			element.Shield:Hide()
		end

		if (element.timeToHold) then

			local spellQueueWindow = updateSpellQueueValue(element) / 1e3 -- get value in seconds
			if (timeLeft >= spellQueueWindow) then
				element.failedMessageTimer = element.timeToHold
				local msg = element.Failed or element.Value or element.Name
				if (msg) then
					msg:SetText(utf8sub(L_INTERRUPTED, element.maxNameChars or 32, true))
				end
			else
				element.failedMessageTimer = nil
				local msg = element.Failed or element.Value or element.Name
				if (msg) then
					msg:SetText("")
				end
			end

		else
			element:Hide()
			element:SetScript("OnUpdate", nil)
			local msg = element.Failed or element.Value or element.Name
			if (msg) then
				msg:SetText("")
			end
			if (element.Shield) then
				element.Shield:Hide()
			end
		end

	elseif (event == "GP_SPELL_CAST_INTERRUPTIBLE") then
		element.notInterruptible = nil
		if (element.Shield) then
			if (unitGUID ~= playerGUID) then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end

	elseif (event == "GP_SPELL_CAST_NOT_INTERRUPTIBLE") then
		element.notInterruptible = true
		if (element.Shield) then
			if (unitGUID ~= playerGUID) then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end

	elseif (event == "GP_SPELL_CAST_DELAYED") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = LibCast:UnitCastingInfo(unit)
		if (not startTime) or (not element.duration) then
			return
		end

		local duration = GetTime() - startTime
		if (duration < 0) then
			duration = 0
		end

		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration
		element:SetValue(duration)

	elseif (event == "GP_SPELL_CAST_CHANNEL_START") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = LibCast:UnitChannelInfo(unit)
		if (name) then
			local max = endTime - startTime
			local duration = endTime - GetTime()

			element.duration = duration
			element.max = max
			element.delay = 0
			element.casting = nil
			element.channeling = true
			element.notInterruptible = notInterruptible
			element.name = name
			element.text = text
			element.casting = nil
			element.failedMessageTimer = nil
			element:SetMinMaxValues(0, max, true)
			element:SetValue(duration, true)
			element:UpdateColor(unit)

			if (element.Failed) then element.Failed:SetText("") end
			if (element.Name) then element.Name:SetText(utf8sub(name, element.maxNameChars or 32, true)) end
			if (element.Icon) then element.Icon:SetTexture(texture) end
			if (element.Value) then element.Value:SetText("") end
			if (element.Shield) then
				if (element.notInterruptible) and (not UnitIsUnit(unit ,"player")) then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
			if (element.SpellQueue) and (not element.disableSpellQueue) then
				updateSpellQueueOrientation(element)
				updateSpellQueueDisplay(element)
			end
			element:Show()
			element:SetScript("OnUpdate", OnUpdate)

		else
			element:Hide()
			element:SetValue(0, true)
			element:SetScript("OnUpdate", nil)
			local msg = element.Failed or element.Value or element.Name
			if (msg) then
				msg:SetText("")
			end
		end

	elseif (event == "GP_SPELL_CAST_CHANNEL_UPDATE") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = LibCast:UnitChannelInfo(unit)
		if (not name) or (not element.duration) then
			return
		end

		local duration = endTime - GetTime()
		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration
		element.max = endTime - startTime

		if (element.SpellQueue) and (not element.disableSpellQueue) then
			updateSpellQueueDisplay(element)
		end

		element:SetMinMaxValues(0, element.max)
		element:SetValue(duration)

	elseif (event == "Forced") or (event == "PLAYER_TARGET_CHANGED") then

		if (LibCast:UnitCastingInfo(unit)) then
			return Update(self, "GP_SPELL_CAST_START", unitGUID)
		elseif (LibCast:UnitChannelInfo(unit)) then
			return Update(self, "GP_SPELL_CAST_CHANNEL_START", unitGUID)
		end

		if (event == "PLAYER_TARGET_CHANGED") or not(element.casting or element.channeling or element.tradeskill or element.failedMessageTimer) then
			clear(element)
			element:Hide()
			element:SetScript("OnUpdate", nil)
			element.max = 0
			element.delay = 0
			element.failedMessageTimer = nil
			local msg = element.Failed or element.Value or element.Name
			if (msg) then
				msg:SetText("")
			end
		end
	end
	if (element.PostUpdate) then
		return element:PostUpdate(unit)
	end
end

local Proxy = function(self, ...)
	return (self.Cast.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Cast
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		clear(element)
		element:Hide()
		element.max = 0
		element.delay = 0

		-- Make a little proxy to update only this.
		if (element.SpellQueue) then
			element.SpellQueue.ForceUpdate = function()
				updateSpellQueueOrientation(element)
				updateSpellQueueDisplay(element)
			end
		end

		if (self.unit == "target") or (self.unit == "targettarget") then
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Proxy, true)
		end

		self:RegisterMessage("GP_SPELL_CAST_START", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_STOP", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_FAILED", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_SUCCESS", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_INTERRUPTED", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_INTERRUPTIBLE", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_NOT_INTERRUPTIBLE", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_DELAYED", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_CHANNEL_START", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_CHANNEL_UPDATE", Proxy)
		self:RegisterMessage("GP_SPELL_CAST_CHANNEL_STOP", Proxy)

		element.UpdateColor = UpdateColor

		return true
	end
end

local Disable = function(self)
	local element = self.Cast
	if element then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_START", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_STOP", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_FAILED", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_SUCCESS", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_INTERRUPTED", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_INTERRUPTIBLE", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_NOT_INTERRUPTIBLE", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_DELAYED", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_CHANNEL_START", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_CHANNEL_UPDATE", Proxy)
		self:UnregisterMessage("GP_SPELL_CAST_CHANNEL_STOP", Proxy)

		element:SetScript("OnUpdate", nil)
		element:Hide()
		clear(element)
		element.max = 0
		element.delay = 0
	end
end

-- Register it with compatible libraries
for _,Lib in ipairs({ (Wheel("LibUnitFrame", true)), (Wheel("LibNamePlate", true)) }) do
	Lib:RegisterElement("Cast", Enable, Disable, Proxy, 56)
end
