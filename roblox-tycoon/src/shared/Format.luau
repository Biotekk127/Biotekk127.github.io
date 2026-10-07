--[[
	Number and time formatting shared by server and client.
]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1.23K", 15300000 -> "15.3M"
function Format.Short(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.abs(n)
	if n < 1000 then
		local text = if n == math.floor(n) then tostring(n) else string.format("%.1f", n)
		return (if negative then "-" else "") .. text
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	local text
	if scaled >= 100 then
		text = string.format("%d", math.floor(scaled))
	elseif scaled >= 10 then
		text = string.format("%.1f", math.floor(scaled * 10) / 10)
	else
		text = string.format("%.2f", math.floor(scaled * 100) / 100)
	end
	if text:find(".", 1, true) then
		text = text:gsub("0+$", ""):gsub("%.$", "")
	end
	return (if negative then "-" else "") .. text .. SUFFIXES[tier + 1]
end

function Format.Cash(n: number): string
	return "$" .. Format.Short(n)
end

-- 3725 -> "1:02:05", 125 -> "2:05"
function Format.Time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor(seconds % 3600 / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return Format
