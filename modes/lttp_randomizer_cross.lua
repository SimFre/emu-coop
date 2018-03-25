-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: http://alttp.run/hacking/index.php?title=SRAM_Map , https://github.com/mmxbass/z3randomizer/blob/master
-- Thanks to the Zelda randomizer team, especially Mike Trethewey, Zarby89 and Karkat
-- This file is available under Creative Commons CC0

local function UNSET(x, bit) -- 0 index
	return AND(x, XOR(0xFF, BIT(bit)))
end

local function zeroRising(value, previousValue) -- "Allow if replacing 'no item', but not if replacing another item"
	return (value ~= 0 and previousValue == 0), (value)
end

local function zeroRisingOrUpgradeFlute(value, previousValue) -- "Allow if replacing 'no item', or if replacing 'flute' with 'bird+flute'"
	return ( (value ~= 0 and previousValue == 0) or (value == 3 and previousValue == 2) ), (value)
end

local mushroomByte = 0x7EF344

return {
	guid = "420ca877-f90b-4dd4-be96-cf319ae3357f",
	format = "1.14",
	name = "Link to the Past Randomizer - Different Seeds",
	match = {"stringtest", addr=0xFFC0, value="VT TOURNEY,VTC,ER_"},

	running = {"test", addr = 0x7E0010, values = {0x07, 0x09, 0x0B, 0x0E, 0x12, 0x13, 0x15, 0x16, 0x18, 0x19}},
	receiving = {"test", addr = 0x7E0011, values = {0x00}},
	sync = {
		-- INVENTORY_SWAP
		[0x7EF38C] = {
			nameBitmap={"Bird", "Flute", "Shovel", "unknown item", "Magic Powder", "Mushroom", "Magic Boomerang", "Boomerang"},
			kind=function(value, previousValue)
				local result = OR(value, previousValue)
				if 0 ~= AND(result, BIT(0)) then result = UNSET(result, 1) end -- If acquired bird, clear flute
				return (result ~= previousValue), (result)
			end,
			receiveTrigger=function(value, previousValue) -- Mushroom/powder byte is a disaster so set it indirectly when this mask changes
				-- If powder bit went high and no mushroom type item is being held, place powder in inventory
				if 0 ~= AND(value, BIT(4)) and 0 == AND(previousValue, BIT(4)) and 0 == memory.readbyte(mushroomByte) then
					memory.writebyte(mushroomByte, 2)
				end
				-- If mushroom bit went high and no mushroom type item is being held, place mushroom in inventory
				if 0 ~= AND(value, BIT(5)) and 0 == AND(previousValue, BIT(5)) and 0 == memory.readbyte(mushroomByte) then
					memory.writebyte(mushroomByte, 1)
				end
			end
		},
		[0x7E0010] = {kind="state",
			sleep=function(value)
			  local state = memory.readbyte(0x7E0010)
			  local submodule = memory.readbyte(0x7E0011)
				return (((not (state == 0x07 or state == 0x09 or state == 0x0B)) or submodule ~= 0x00) and (state ~= value))
			end,
			receiveTrigger=function(value, previousValue)
				if (value == 0x19 and previousValue ~= 0x19) then
					memory.writebyte(0x7EF443, 1)
				end
			end
		},
		-- INVENTORY_SWAP_2
		[0x7EF38E] = {
			nameBitmap={"unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "Silver Arrows", "Bow"},
			kind="bitOr"
		},

		-- PROGRESSIVE_SHIELD
		[0x7EF416] = {
			kind="high", -- Sync silently-- this is a backup in case your shield gets eaten
			mask=0xC0
		},
		-- PROGRESSIVE_SWORD
		[0x7EF417] = {
			kind="high", -- Sync silently-- this is a backup in case your sword gets eaten
			mask=0x07
		},
		[0x7EF340] = {kind=zeroRising},                     -- Bows, tracked in INVENTORY_SWAP_2 but must be nonzero to appear in inventory
		[0x7EF341] = {kind=zeroRising},                     -- Boomerangs, tracked in INVENTORY_SWAP
		[0x7EF342] = {name="Hookshot", kind="high"},
		[0x7EF343] = {kind="either"}, -- Bombs
		[0x7EF345] = {name="Fire Rod", kind="high"},
		[0x7EF346] = {name="Ice Rod", kind="high"},
		[0x7EF347] = {name="Bombos", kind="high"},
		[0x7EF348] = {name="Ether", kind="high"},
		[0x7EF349] = {name="Quake", kind="high"},
		[0x7EF34A] = {name="Lantern", kind="high"},
		[0x7EF34B] = {name="Hammer", kind="high"},
		-- Note this doesn't need to happen in INVENTORY_SWAP receiveTrigger bc you can only upgrade the flute while holding it
		[0x7EF34C] = {kind=zeroRisingOrUpgradeFlute},       -- Shovel flute etc, tracked in INVENTORY_SWAP
		[0x7EF34D] = {name="Net", kind="high"},
		[0x7EF34E] = {name="Book", kind="high"},
		[0x7EF34F] = {kind="high"}, -- Bottle count
		[0x7EF350] = {name="Red Cane", kind="high"},
		[0x7EF351] = {name="Blue Cane", kind="high"},
		[0x7EF352] = {name="Cape", kind="high"},
		[0x7EF353] = {name="Mirror", kind="high"},
		[0x7EF354] = {nameMap={"Power Glove", "Titan's Mitt"}, kind="high"},
		[0x7EF355] = {name="Boots", kind="high"},
		[0x7EF356] = {name="Flippers", kind="high"},
		[0x7EF357] = {name="Pearl", kind="high"},
		[0x7EF359] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="high",
			cond={"test", gte = 0x1, lte = 0x4} -- Avoid 0xFF trap during dwarf quest
		},
		[0x7EF35A] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="high"},
		[0x7EF35B] = {nameMap={"Blue Armor", "Red Armor"}, kind="high"},
		[0x7EF35C] = {nameMap={"Mush", "Empty Bottle", "Red Potion", "Green Potion", "Blue Potion", "Hostage", "Bee", "Gold Bee"}, kind="bottle"},
		[0x7EF35D] = {nameMap={"Mush", "Empty Bottle", "Red Potion", "Green Potion", "Blue Potion", "Hostage", "Bee", "Gold Bee"}, kind="bottle"},
		[0x7EF35E] = {nameMap={"Mush", "Empty Bottle", "Red Potion", "Green Potion", "Blue Potion", "Hostage", "Bee", "Gold Bee"}, kind="bottle"},
		[0x7EF35F] = {nameMap={"Mush", "Empty Bottle", "Red Potion", "Green Potion", "Blue Potion", "Hostage", "Bee", "Gold Bee"}, kind="bottle"},
		[0x7EF360] = {kind="either"}, -- Rupee byte 1
		[0x7EF361] = {kind="either"}, -- Rupee byte 2
		[0x7EF36D] = {kind="HealthShare", stype="uInstantRefill",
		sleep=function(value)
			local state = memory.readbyte(0x7E0010)
			local submodule = memory.readbyte(0x7E0011)
			return (((not (state == 0x07 or state == 0x09 or state == 0x0B)) or submodule ~= 0x00))
		end}, -- Health 2
		[0x7EF36E] = {kind="MagicShare", stype="uInstantRefill",
		sleep=function(value)
			local state = memory.readbyte(0x7E0010)
			local submodule = memory.readbyte(0x7E0011)
			return (((not (state == 0x07 or state == 0x09 or state == 0x0B)) or submodule ~= 0x00))
		end}, -- Magic 1
		[0x7EF379] = {kind="bitOr"}, -- Abilities
		[0x7EF377] = {kind="either"}, -- Arrows
		[0x7EF37B] = {nameMap={"1/2 Magic", "1/4 Magic"}, kind="high"},

		[0x7EF418] = {kind="high"}, -- Triforce pieces
	}
}
