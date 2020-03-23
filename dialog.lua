require "iuplua"

-- Bizarre kludge: For reasons I do not understand at all, radio buttons do not work in FCEUX. Switch to menus there only
local optionLetter = "o"
if FCEU then optionLetter = "l" end

function ircDialog()
	if not defaultNickname then defaultNickname = "" end
	if not defaultChannel then defaultChannel = "" end
	
	-- Get seed
	local seed = "#"
	for i=0, 9, 1
	do
		m = memory.readbyte(0xFFC3 + i)
		seed = seed .. string.char(m)
	end

	local res, server, port, nick, partner, forceSend, hpshare, magicshare, retromode = iup.GetParam("Connection settings", nil,
	    "Enter an IRC server: %s\n" ..
		"IRC server port: %i\n" ..
		"Your nick: %s\n" ..
		"Partner nick: %s\n" ..
		"%t\n" .. -- <hr>
		"Are you restarting\rafter a crash? %b\n" ..
		"%t\n" ..
		"Current Health share? %b\n" ..
		"Magic share? %b\n" ..
		"Retro mode? %b\n"
		,"svn.eastcoast.hosting", 6667, defaultNickname, seed, 0,0,0,0)

	if 0 == res then return nil end

	return {server=server, port=port, nick=nick, partner=partner, forceSend=forceSend==1, hpshare=hpshare==1, magicshare=magicshare==1, retromode=retromode==1 }
end

function selectDialog(specs, reason)
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

function refuseDialog(options)
	iup.Message("Cannot run", "No ROM is running.")
end
