-- Did you add any files to this directory? Add their names to the table below.
-- If your file is named "lttp.lua", put it in the table like "modes.lttp".

-- Each require is wrapped in parentheses: since Lua 5.4, require returns a second value
-- (the file path), which would otherwise end up in this table as an extra "mode".
modes = {
	--(require "modes.lttp"),
	(require "modes.lttp_randomizer_identseeds"),
	--(require "modes.lttp_randomizer_diffseeds"),
}
