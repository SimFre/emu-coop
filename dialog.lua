require "settings"

-- IUP gives us real dialog boxes. It ships as a Windows DLL; on other platforms it
-- may not be installed, in which case we fall back to the saved settings file.
local hasIup, iupErr = pcall(require, "iuplua")
if not hasIup then
	iup = nil
	print("IUP dialogs not available (" .. tostring(iupErr) .. "), using " .. settings.file)
end

-- Bizarre kludge: For reasons I do not understand at all, radio buttons do not work in FCEUX. Switch to menus there only
local optionLetter = "o"
if FCEU then optionLetter = "l" end

-- The ROM's internal title (SNES header at $00:FFC0, 21 bytes), with trailing spaces removed
function romTitle()
	local chars = {}
	for i = 0, 20 do
		local m = memory.readbyte(0xFFC0 + i)
		if m < 0x20 or m > 0x7E then m = 0x20 end -- Replace unprintable bytes
		chars[#chars + 1] = string.char(m)
	end
	return (table.concat(chars):gsub("%s+$", ""))
end

-- Seed hash of an alttpr.com ROM. Current randomizer builds write "VT <hash>" as the title,
-- e.g. "VT zMY96EwzMg". The hash is the same for every player's copy of a seed (the copies
-- only differ in the chosen Link sprite), so it makes a natural room name.
function seedHash()
	return romTitle():match("^VT (%w+)$")
end

-- Default IRC room: the seed hash if there is one, otherwise the ROM title.
-- Channel names cannot contain spaces, commas or control characters, so keep only letters, digits, - and _.
local function seedChannel()
	local name = seedHash() or romTitle()
	name = name:gsub("[^%w%-_]", "")
	if name == "" then name = "emu-coop" end
	return "#" .. name
end

local function b(x) return x and 1 or 0 end

function ircDialog()
	local saved = settings.load()
	local room = seedChannel()

	if not iup then
		if not nonempty(saved.nick) then
			settings.save(saved) -- Write a template the user can fill in
			errorMessage("Set your nick in " .. settings.file .. " and restart the script")
			return nil
		end
		print("Connecting with saved settings from " .. settings.file)
		saved.room = room
		saved.forceSend = RESTARTING_AFTER_CRASH == true
		return saved
	end

	local res, server, port, nick, roomIn, forceSend, hpshare, magicshare, retromode, reset = iup.GetParam("Connection settings", nil,
		"Enter an IRC server: %s\n" ..
		"IRC server port: %i\n" ..
		"Your nick: %s\n" ..
		"IRC room: %s\n" ..
		"%t\n" .. -- <hr>
		"Are you restarting\rafter a crash? %b\n" ..
		"%t\n" ..
		"Current Health share? %b\n" ..
		"Magic share? %b\n" ..
		"Retro mode? %b\n" ..
		"%t\n" ..
		"Reset saved settings? %b\n"
		, saved.server, saved.port, saved.nick, room, 0, b(saved.hpshare), b(saved.magicshare), b(saved.retromode), 0)

	if 0 == res then return nil end

	if reset == 1 then
		settings.reset()
		message("Saved settings cleared")
		return ircDialog()
	end

	local data = { server = server, port = port, nick = nick, room = roomIn, forceSend = forceSend == 1, hpshare = hpshare == 1, magicshare = magicshare == 1, retromode = retromode == 1 }
	settings.save(data)
	return data
end

function selectDialog(specs, reason)
	if not iup then
		if #specs == 1 then return specs[1] end -- Only one choice, take it
		print("Can't figure out which game to load (" .. reason .. "). Enable exactly one mode in modes/index.lua.")
		return nil
	end

	local names = ""
	for i, v in ipairs(specs) do
		names = names .. v.name .. "|"
	end

	local res, selection = iup.GetParam("Select game", nil,
		"Can't figure out\rwhich game to load\r(" .. reason .. ")\r" ..
		"Which game is this? " ..
		"%l|" .. names .. "\n",
		0)

	if 0 == res or nil == selection then return nil end

	return specs[selection + 1]
end

function refuseDialog(reason)
	reason = reason or "No ROM is running."
	if iup then
		iup.Message("Cannot run", reason)
	else
		print("Cannot run: " .. reason)
	end
end
