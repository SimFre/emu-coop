-- SAVED SETTINGS
-- Remembers the last used connection details in coop_settings.txt next to the scripts,
-- so they don't have to be hard coded or retyped every session.

local SETTINGS_FILE = (compat and compat.scriptDir or "") .. "coop_settings.txt"

settings = {}

-- Values used when nothing has been saved yet (debug.lua can override these globals)
function settings.defaults()
	return {
		server = DEFAULT_HOSTNAME or "svn.eastcoast.hosting",
		port = DEFAULT_PORT or 6667,
		nick = DEFAULT_NICKNAME or "",
		hpshare = false,
		magicshare = false,
		retromode = false,
	}
end

function settings.load()
	local result = settings.defaults()
	local f = io.open(SETTINGS_FILE, "r")
	if not f then return result end
	local text = f:read("*a")
	f:close()

	local saved = pretty.read(text)
	if type(saved) ~= "table" then
		print("Ignoring unreadable settings file " .. SETTINGS_FILE)
		return result
	end
	for k, v in pairs(saved) do
		if result[k] ~= nil and type(v) == type(result[k]) then result[k] = v end
	end
	return result
end

function settings.save(values)
	local keep = {}
	for k in pairs(settings.defaults()) do keep[k] = values[k] end
	local f, err = io.open(SETTINGS_FILE, "w")
	if not f then
		print("Could not save settings: " .. tostring(err))
		return false
	end
	f:write(pretty.write(keep), "\n")
	f:close()
	return true
end

function settings.reset()
	os.remove(SETTINGS_FILE)
	return settings.defaults()
end

settings.file = SETTINGS_FILE
