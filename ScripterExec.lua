-- Scripter (ESO Add-On)
-- Copyright 2014 Neo Natura


local ScriptCommand = SLASH_COMMANDS["/script"]
local DataBlock = LibStub("LibDataBlock-1.0")
local datablock_obj 

-- script parameters
s_args = {}
s_arg = ""

function si_round(value)
	return zo_round(value)
end

function si_highlight(text)
	return "|cff8f41" .. text .. "|r"
end

function si_formatcord(cord)
	return si_round(cord * 10000) / 10000
end
function si_formatmeter(cord)
	return si_round(300 * cord)
end

function si_cord(x, y)
	return si_formatmeter(x) .. ":" .. si_formatmeter(y)
end

function si_char_area(alternative)
	if alternative then
		return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+/[%w%-]+_[%w%-]+)"))
	end

	return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+)/([%w%-]+_[%w%-]+)"))
end

function si_cord_dist(x, y)
	local plrX, plrY = GetMapPlayerPosition('player')
	local distX = zo_abs(si_formatmeter(x - plrX)) 
	local distY = zo_abs(si_formatmeter(y - plrY)) 
	return (distX + distY) / 2
end

function si_cord_dir(x, y)
    local plrX, plrY = GetMapPlayerPosition('player')
    if (plrX == nil or plrY == nil) then return "" end

    local locX = si_formatmeter(plrX)
    local locY = si_formatmeter(plrY)

    x = si_formatmeter(x)
    y = si_formatmeter(y)

    local east = false
    local north = false
    local west = false
    local south = false
    if locX < x then east = true end
    if locY > y then north = true end
    if locX > x then west = true end
    if locY < y then south = true end

    if (north == true and east == true) then 
        return "NE"
    elseif (north == true and west == true) then
        return "NW"
    elseif (south == true and east == true) then
        return "SE"
    elseif (south == true and west == true) then
        return "SW"
    elseif north == true then
        return "N"
    elseif south == true then
        return "S"
    elseif east == true then
        return "E"
    elseif west == true then
        return "W"
    end

    return ""
end

function si_char_location()
	local zone, subzone = si_char_area()
	local x, y = GetMapPlayerPosition('player')
	local subdesc = GetMapName()

	loc = {}
	loc.x = si_formatcord(x)
	loc.y = si_formatcord(y)
	loc.area = subdesc
	loc.subzone = subdesc
	loc.zone = zone

	return loc
end

function si_location_text(loc)
        if loc == nil then loc = si_char_location() end
	if (loc.x == nil or loc.y == nil) then return "" end

	local text = ""
	local dist = 0

	if (loc.zone ~= nil and loc.subzone ~= nil) then
		text = text .. si_highlight(loc.zone) .. " of " .. loc.subzone
	end
	if loc.subzone == GetMapName() then
		dist = si_cord_dist(loc.x, loc.y)
	end
	text = text .. " ["
	if dist ~= 0 then
		text = text .. dist .. "m " .. si_cord_dir(loc.x, loc.y) .. " "
	end
	text = text .. si_cord(loc.x, loc.y)
	text = text .. "]"

	return text
end

function si_db_init()
        if datablock_obj == nil then 
		datablock_obj = DataBlock:GetDataObjectByName("Scripter")
                if datablock_obj == nil then
			datablock_obj = DataBlock:NewDataObject("Scripter", data)
		end
		if datablock_obj.userdata == nil then datablock_obj.userdata = {} end
		local vars = GetScripterValue(VAL_USERDATA_DB)
		for k, v in pairs(vars) do
			datablock_obj.userdata[k] = v
		end
	end

	return datablock_obj.userdata
end

function si_db_set(token, value)
	local data = si_db_init()
	data[token] = value
	SetScripterValue(VAL_USERDATA_DB, data)
end

function si_db_get(token)
	local data = si_db_init()
	return data[token]
end

-- split string into array
function si_strsplit(delim, text)
	return { zo_strsplit(delim, text) }
end

function si_exec(text, argtext)
	if argtext == nil then argtext = "" end

	s_args = argtext
	if type(argtext) == "string" then
		s_arg = si_strsplit(" ", argtext)
	else
		s_arg = argtext
	end
	ScriptCommand(text)
end

-- join strings
function si_strjoin(...)
	return zo_strjoin("", ...)
end


-- find string match
function si_strifind(text, kwd)
	if string.match(text:lower(), kwd:lower()) ~= nil then return true end
	return false
end

-- string color
function si_color(r, g, b)
	local r = math.min(255, 255 * r)
	local g = math.min(255, 255 * g)
	local b = math.min(255, 255 * b)
	return "|c" .. 
		string.format("%2.2X", r) ..
		string.format("%2.2X", g) ..
		string.format("%2.2X", b)
end

-- clear chat window
function si_chat_clear()
	if CHAT_SYSTEM == nil then return end

	local buffer = CHAT_SYSTEM["containers"][1]["currentBuffer"]
	if buffer ~= nil then
		buffer:Clear()
	else
		CHAT_SYSTEM:Clear()
	end
end

-- print string
function si_chat_print(...)
	if CHAT_SYSTEM == nil then return end

	local buffer = nil
	if (CHAT_SYSTEM["containers"] and CHAT_SYSTEM["containers"][1]) then
           buffer = CHAT_SYSTEM["containers"][1]["currentBuffer"]
        end
	local text = si_color(1,1,1) .. si_strjoin("", ...) .. "|r"
	if buffer ~= nil then
		buffer:AddMessage(text)
	else
		CHAT_SYSTEM:AddMessage(text)
	end

	CHAT_SYSTEM:AddMessage(nil)
end

function si_time()
    return GetTimeStamp()
end

function si_formatdate(time)
	time = tonumber(time)
	if time == nil then return "" end

	local midnightSeconds = GetSecondsSinceMidnight()
	local utcSeconds = GetTimeStamp() % 86400
	local offset = midnightSeconds - utcSeconds

	if offset < -43200 then
		offset = offset + 86400
	end

	local dateString = GetDateStringFromTimestamp(time)
	local timeString = ZO_FormatTime((time + offset) % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
	return string.format("%s %s", dateString, timeString)
end

function si_formattime(time)
	time = tonumber(time)
	if time == nil then return "" end

	local midnightSeconds = GetSecondsSinceMidnight()
	local utcSeconds = GetTimeStamp() % 86400
	local offset = midnightSeconds - utcSeconds

	if offset < -43200 then
		offset = offset + 86400
	end

	local timeString = ZO_FormatTime((time + offset) % 86400, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
	return string.format("%s", timeString)
end

-- item link by name
function si_ilink(itemName)
	return nil
end


-- -- character functions --
-- function s_ch_area()
-- 	return si_char_subzone()
-- end
-- function s_ch_region()
-- 	return si_char_zone()
-- end
-- function s_ch_cord()
-- 	local loc = si_char_location()
-- 	return si_format_cord(loc.x, loc.y)
-- end
-- function s_ch_level(attr)
-- 	local value = si_char_attr_percent(attr)
-- 	return string.format("%.2f", value) .. "%"
-- end
-- 
-- function s_ch_points(attr, cname)
-- end
-- 
-- function s_ch_rate(attr, cname)
-- end
-- 
-- function s_ch_gold()
-- end
-- 
-- function s_ch_name()
-- 	return si_display_name() .. si_account_name()
-- end
-- 
-- function s_ch_afk(argtext)
-- end
-- 
-- -- inventory functions --
-- 
-- -- channel functions --
-- function s_chan_say(text)
-- end
-- 
-- function s_chan_group(text)
-- end
-- 
-- 
-- -- conditionals --
-- function s_is_ch_afk()
-- end
-- function s_is_inv_full()
-- end
-- 

function s_print(...)
	return si_chat_print(...)
end

function s_pr_clr(r,g,b)
	return si_color(r,g,b)
end

function s_pr_date(time)
	if (time == nil or time == 0) then time = si_time() end
	return si_formatdate(time)
end

function s_pr_time(time)
	if (time == nil or time == 0) then time = si_time() end
	return si_formattime(time)
end


function s_pr_cord(loc)
	return si_cord(loc.x, loc.y)
end

function s_pr_loc(loc)
	return si_location_text(loc)
end

function s_call(func, argtext)
	if func == nil then return nil end

	local funcs = GetScripterValue(VAL_USERDATA_FUNC)
	local f_text = funcs[func]

	if f_text == nil then
		return nil
	end

	return si_exec(f_text, argtext)
end

function s_set(token, value)
	if token == nil then return end
	si_db_set(token, value)
end

function s_get(token)
	if token == nil then return "" end

	local data = si_db_get(token)
	if data == nil then data = "" end

	return data
end

function s_loc()
  return (si_char_location())
end

function s_time()
	return si_time()
end

