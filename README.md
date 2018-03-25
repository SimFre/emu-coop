# emu-coop

This directory contains some Lua scripts that, when loaded by a compliant emulator such as snes9x-rr/snes9x-coop, can synchronize emulator state over the internet (allowing "cooperative" playthroughs of single-player games).

Each game you want to use this with requires a "mode" file in the modes/ directory. Currently included are modes for Link to the Past (JPv1.0) and the Link to the Past Randomizer.\
The files you see here are very likely not compatible with other forks of emu-coop. It is recommended to always exchange the entire coop-folder for every release/fork.\
**WARNING: Modes are PROGRAMS, like a .exe file. Do not install a mode file unless it came from someone you know and trust.**

You can reach me, FirenX, here at GitHub or at Discord as Feed4Fame#7342.

## What is shared?

All modes share:
	* The complete Inventory (all Y-items, all ability items, swords, shields, mails)
	* Bottle Contents
	* Arrows, Bombs, Rupees
	* Heart Containers/Pieces
	* Half Magic Buff
	* Curent HP/Magic (optional)
	* Triforce Pieces (in Rando)

On top of that, Link to the Past and Link to the Past Randomizer - Identical Seeds share:
	* Pendants/Crystals
	* Compasses, Maps
	* Keys (Big and Small)
	* Overworld/Dungeon data (e.g. Doors/Chests/Item Locations are opened/taken for both players if one player does so)
	* Boss kills (including Aga1 and Aga2)
	* Reaching the Triforce Room

For the Overworld/Dungeon data to share correctly it is recommended to not be in the same overworld screen/dungeon superroom simultaneously.

For Link to the Past Randomizer - Different Seeds it is recommended to play on a higher difficulty setting or with customizer seeds since you will otherwise end up at 20 Hearts, Golden Sword, Red Mail, Mirrorshield, Quarter Magic relatively quickly.


## How to Use

* Open the ROM using the snes9x-coop
* Have both players open the coop.lua using "File -> Lua Scripting -> New Lua Script Window..."
* If asked what mode to use, pick the one you intend to use
* Fill out the connection setting, pick your options and click "OK". Only use "Retro mode" if you are playing a Retro Variation seed of the Randomizer
* Wait for the script to say "Connected to Partner"
* You can now play the game

In case something terrible happens and you need to restart/reconnect:
* Save&Quit
* Close and restart the emulator
* Open the ROM you were using
* Open your save file starting the game
* Start the coop.lua as described above. This time use different nicks and pick the option "Restarting after a Crash?"
* The script will now take its time to sync both players again. Wait until it says "Syncing is done"
* You can now keep on playing

## Author / License

These files were originally written by Andi McClure and later edited by Alvytv, and then edited by me, FirenX.

Big thanks to:
* The LTTP Randomizer team, esp. Mike Trethewey, Zarby89 and Karkat, for information
* Alex Zandra and Maya Shinohara, and Andypro1 from github for help testing
* Andi McClure and Alvytv for creating/updating these scripts
* The various testers of each release

Unless otherwise noted, the license is:

	Copyright (C) 2017 Andi McClure

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
	ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
	TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
	SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
	ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
	OR OTHER DEALINGS IN THE SOFTWARE.

Included in this directory is Penlight. Here is its license:

	Copyright (C) 2009-2016 Steve Donovan, David Manura.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
	ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
	TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
	SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
	ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
	OR OTHER DEALINGS IN THE SOFTWARE.

Included in this directory is Luasocket. Here is its license:

	LuaSocket 3.0 license
	Copyright © 2004-2013 Diego Nehab

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the "Software"),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.

Included in this directory is IUP. Here is its license:

	Copyright (c) 1994-2017 Tecgraf/PUC-Rio.

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the "Software"),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
