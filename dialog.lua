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

-- IRC channel name derived from the ROM header title
local function seedChannel()
	local seed = "#"
	for i = 0, 9, 1 do
		local m = memory.readbyte(0xFFC3 + i)
		seed = seed .. string.char(m)
	end
	return seed
end

local function b(x) return x and 1 or 0 end

function ircDialog()
	local saved = settings.load()
	local partner = seedChannel()

	if not iup then
		if not nonempty(saved.nick) then
			settings.save(saved) -- Write a template the user can fill in
			errorMessage("Set your nick in " .. settings.file .. " and restart the script")
			return nil
		end
		print("Connecting with saved settings from " .. settings.file)
		saved.partner = partner
		saved.forceSend = RESTARTING_AFTER_CRASH == true
		return saved
	end

	local res, server, port, nick, partnerIn, forceSend, hpshare, magicshare, retromode, reset = iup.GetParam("Connection settings", nil,
		"Enter an IRC server: %s\n" ..
		"IRC server port: %i\n" ..
		"Your nick: %s\n" ..
		"Partner nick: %s\n" ..
		"%t\n" .. -- <hr>
		"Are you restarting\rafter a crash? %b\n" ..
		"%t\n" ..
		"Current Health share? %b\n" ..
		"Magic share? %b\n" ..
		"Retro mode? %b\n" ..
		"%t\n" ..
		"Reset saved settings? %b\n"
		, saved.server, saved.port, saved.nick, partner, 0, b(saved.hpshare), b(saved.magicshare), b(saved.retromode), 0)

	if 0 == res then return nil end

	if reset == 1 then
		settings.reset()
		message("Saved settings cleared")
		return ircDialog()
	end

	local data = { server = server, port = port, nick = nick, partner = partnerIn, forceSend = forceSend == 1, hpshare = hpshare == 1, magicshare = magicshare == 1, retromode = retromode == 1 }
	settings.save(data)
	return data
end

function selectDialog(specs, reason)
	if not iup then
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
