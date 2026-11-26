-- COMPATIBILITY LAYER
-- Smooths over differences between Lua versions (5.1 through 5.4) and checks
-- that the emulator exposes the scripting API emu-coop needs.
-- Load this before anything else (coop.lua does).

compat = {}

-- Platform detection
compat.isWindows = package.config:sub(1, 1) == "\\"
compat.platform = compat.isWindows and "windows" or "linux"

-- Directory this script lives in, with a trailing separator ("" if unknown)
do
	local source = debug.getinfo(1, "S").source or ""
	local dir = source:match("^@(.*[/\\])") or ""
	compat.scriptDir = dir
end

-- Make sure our bundled Lua modules and the platform's native libraries are found
-- no matter what working directory the emulator was started from.
do
	local dir = compat.scriptDir
	local ext = compat.isWindows and "dll" or "so"
	package.path = dir .. "?.lua;" .. dir .. "?/init.lua;" .. package.path
	package.cpath = dir .. "lib/" .. compat.platform .. "/?." .. ext .. ";" ..
	                dir .. "?." .. ext .. ";" .. package.cpath
end

-- unpack moved into table in 5.2
unpack = unpack or table.unpack

-- BIT OPERATIONS
-- snes9x-rr defines AND/OR/XOR/BIT globals. Other hosts may not, and Lua 5.3+
-- has native operators instead of a bit library, so provide our own.
do
	local band, bor, bxor, lshift

	local nativeOps = load and not (_VERSION == "Lua 5.1" or _VERSION == "Lua 5.2")
	if nativeOps then
		-- Compiled from a string so Lua 5.1/5.2 never has to parse the operators
		band, bor, bxor, lshift = load([[
			return function(a, b) return a & b end,
			       function(a, b) return a | b end,
			       function(a, b) return a ~ b end,
			       function(a, n) return a << n end
		]])()
	elseif bit32 then
		band, bor, bxor, lshift = bit32.band, bit32.bor, bit32.bxor, bit32.lshift
	elseif bit then -- LuaJIT / LuaBitOp
		band, bor, bxor, lshift = bit.band, bit.bor, bit.bxor, bit.lshift
	end

	if not band then -- Plain Lua 5.1 with no bit library: arithmetic fallback for non-negative integers
		local function bitwise(test)
			return function(a, b)
				local result, place = 0, 1
				while a > 0 or b > 0 do
					local x, y = a % 2, b % 2
					if test(x, y) then result = result + place end
					a, b, place = (a - x) / 2, (b - y) / 2, place * 2
				end
				return result
			end
		end
		band = bitwise(function(x, y) return x == 1 and y == 1 end)
		bor  = bitwise(function(x, y) return x == 1 or y == 1 end)
		bxor = bitwise(function(x, y) return x ~= y end)
		lshift = function(a, n) return a * 2 ^ n end
	end

	local function fold(op)
		return function(a, b, ...)
			local result = op(a, b)
			if ... then return fold(op)(result, ...) end
			return result
		end
	end

	compat.band, compat.bor, compat.bxor = fold(band), fold(bor), fold(bxor)
	compat.bit = function(n) return lshift(1, n) end

	-- Only fill in globals the host did not already provide
	AND = AND or compat.band
	OR  = OR  or compat.bor
	XOR = XOR or compat.bxor
	BIT = BIT or compat.bit

	if not (AND and OR and XOR and BIT) then
		error("emu-coop: no bit operations available in this Lua (" .. tostring(_VERSION) .. ")")
	end
end

-- EMULATOR API CHECK
-- Returns nil if everything we need is present, otherwise a list of missing functions.
function compat.missingEmulatorApi()
	local required = {
		{"emu", "emulating"}, {"emu", "registerexit"},
		{"gui", "register"}, {"gui", "text"},
		{"memory", "readbyte"}, {"memory", "readword"}, {"memory", "readdword"},
		{"memory", "writebyte"}, {"memory", "writeword"}, {"memory", "writedword"},
		{"memory", "registerwrite"},
	}
	local missing = {}
	for _, v in ipairs(required) do
		local lib = _G[v[1]]
		if type(lib) ~= "table" or type(lib[v[2]]) ~= "function" then
			table.insert(missing, v[1] .. "." .. v[2])
		end
	end
	if #missing > 0 then return missing end
	return nil
end

-- DEBUG LOG FILE
-- Set COOP_LOG = "coop_debug.log" (debug.lua does) to copy everything printed to a file
-- next to the scripts, with a timestamp per line. Handy for playtests: send the file afterwards.
if COOP_LOG then
	local path = compat.scriptDir .. COOP_LOG
	local logFile = io.open(path, "a")
	if logFile then
		local rawPrint = print
		local started = os.clock()
		print = function(...)
			rawPrint(...)
			local parts = {}
			for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
			logFile:write(string.format("%s +%.2fs ", os.date("%H:%M:%S"), os.clock() - started), table.concat(parts, "\t"), "\n")
			logFile:flush()
		end
		print("=== emu-coop log started " .. os.date("%Y-%m-%d %H:%M:%S") .. " (" .. tostring(_VERSION) .. ") ===")
	else
		print("Could not open log file " .. path)
	end
end
