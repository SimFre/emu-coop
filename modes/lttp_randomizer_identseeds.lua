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

local currentKeysByte = 0x7EF36F
local dungeonWord = 0x7E040C
local sewerValue = 0x00
local hcValue = 0x02
local epValue = 0x04
local dpValue = 0x06
local atValue = 0x08
local spValue = 0x0A
local podValue = 0x0C
local mmValue = 0x0E
local swValue = 0x10
local ipValue = 0x12
local tohValue = 0x14
local ttValue = 0x16
local trValue = 0x18
local gtValue = 0x1A

return {
	guid = "d5cef985-ead9-4553-98d4-4dc6d95cc96c",
	format = "1.14",
	name = "Link to the Past Randomizer - Identical Seeds",
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
				if 0 == AND(value, BIT(5)) then result = UNSET(result, 5) end -- If Mushroom is lost, keep it that way
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
				-- If mushroom bit went low and mushroom was held, change to empty or powder
				if 0 == AND(value, BIT(5)) and 0 ~= AND(previousValue, BIT(5)) and 1 == memory.readbyte(mushroomByte) then
					if 0 == AND(previousValue, BIT(4)) then
						memory.writebyte(mushroomByte, 0)
					else
						memory.writebyte(mushroomByte, 2)
					end
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
			nameBitmap={"unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "unknown item", "Silver Arrows", "Wooden Arrows"},
			msgMask=0xC0,
			kind="bitOr"
		},

		-- NPC_FLAGS
		[0x7EF410] = {
			nameBitmap={"the old man", "king zora's stomach contents", "the sick kid", "stumpy - NOT", "shashlic", "catfish's present", "unknown npc", "the librarian"},
			verb="rescued",
			msgMask=0x1,
			mask=0xBF, -- Only sync old man [1], king zora [2], sick kid [4], stumpy [8], sahrashala [16], catfish [32] and library [128]
			kind="bitOr"
		},

		[0x7EF411] = {
			mask=0xBF, -- Only sync ether tablet [1], bombos tablet [2], smithies [4], fairy sword [8], mushroom spot [16], witch's hut [32] and magic bat [128]
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
		[0x7EF01B] = {name="aga2",verb="killed",kind="bitOr",mask=0x8},
		[0x7EF041] = {name="aga1",verb="killed",kind="bitOr",mask=0x8},
		[0x7EF2DB] = {kind="custom"},
		[0x7EF340] = {name="Bow", kind=zeroRising},					-- Bows, tracked in INVENTORY_SWAP_2 but must be nonzero to appear in inventory
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
		[0x7EF366] = {
			nameBitmap={"unknown BIG Key", "unknown BIG Key", "GT BIG Key", "TR BIG Key", "TT BIG Key", "ToH BIG Key", "IP BIG Key", "SW BIG Key"},
			kind="bitOr"
		},
		[0x7EF367] = {
			nameBitmap={"MM BIG Key", "PoD BIG Key", "SP BIG Key", "HC BIG Key", "DP BIG Key", "EP BIG Key", "HC BIG Key", "HC BIG Key"},
			kind="bitOr"
		},
		[0x7EF364] = {kind="bitOr"},
		[0x7EF365] = {kind="bitOr"},
		[0x7EF368] = {kind="bitOr"},
		[0x7EF369] = {kind="bitOr"},
		[0x7EF36B] = {kind="either"}, -- Heart pieces
		[0x7EF36C] = {kind="high"}, -- Health 1
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
		[0x7EF370] = {kind="high"}, -- Bomb upgrades
		[0x7EF371] = {kind="high"}, -- Arrow upgrades
		[0x7EF379] = {kind="bitOr"}, -- Abilities
		[0x7EF374] = {name="a Pendant", kind="bitOr"},
		[0x7EF377] = {kind="either"}, -- Arrows
		[0x7EF37A] = {name="a Crystal", kind="bitOr"},
		[0x7EF37B] = {nameMap={"1/2 Magic", "1/4 Magic"}, kind="high"},
		[0x7EF3C5] = {kind="high"}, -- Events
		[0x7EF3C6] = {kind="bitOr"}, -- Events 2
		[0x7EF3C7] = {kind="high"}, -- Map
		[0x7EF3C9] = {kind="bitOr"}, -- Events 3

		-- Current Keys for Retromode
		[0x7EF36F] = {name="a Key", kind="key",
		cond={"optiontest", addr = "retromode", value = true}},

		-- Shops for Retromode
		[0x7EF3A0] = {kind="high"},
		[0x7EF3A1] = {kind="high"},
		[0x7EF3A2] = {kind="high"},
		[0x7EF3A3] = {kind="high"},
		[0x7EF3A4] = {kind="high"},
		[0x7EF3A5] = {kind="high"},
		[0x7EF3A6] = {kind="high"},
		[0x7EF3A7] = {kind="high"},
		[0x7EF3A8] = {kind="high"},
		[0x7EF3A9] = {kind="high"},
		[0x7EF3AA] = {kind="high"},
		[0x7EF3AB] = {kind="high"},
		[0x7EF3AC] = {kind="high"},
		[0x7EF3AD] = {kind="high"},
		[0x7EF3AE] = {kind="high"},
		[0x7EF3AF] = {kind="high"},
		[0x7EF3B0] = {kind="high"},
		[0x7EF3B1] = {kind="high"},
		[0x7EF3B2] = {kind="high"},
		[0x7EF3B3] = {kind="high"},
		[0x7EF3B4] = {kind="high"},
		[0x7EF3B5] = {kind="high"},
		[0x7EF3B6] = {kind="high"},

		[0x7EF418] = {kind="high"}, -- Triforce pieces

		-- INDOORS
		[0x7EF000] = {kind="bitOr"},
		[0x7EF001] = {kind="bitOr"},
		[0x7EF002] = {kind="bitOr"},
		[0x7EF003] = {kind="bitOr"},
		[0x7EF004] = {kind="bitOr"},
		[0x7EF005] = {kind="bitOr"},
		[0x7EF006] = {kind="bitOr"},
		[0x7EF007] = {kind="bitOr"},
		[0x7EF008] = {kind="bitOr"},
		[0x7EF009] = {kind="bitOr"},
		[0x7EF00A] = {kind="bitOr"},
		[0x7EF00B] = {kind="bitOr"},
		[0x7EF00C] = {kind="bitOr"},
		[0x7EF00D] = {kind="bitOr"},
		[0x7EF00E] = {kind="bitOr"},
		[0x7EF00F] = {kind="bitOr"},
		[0x7EF010] = {kind="bitOr"},
		[0x7EF011] = {kind="bitOr"},
		[0x7EF012] = {kind="bitOr"},
		[0x7EF013] = {kind="bitOr"},
		[0x7EF014] = {kind="bitOr"},
		[0x7EF015] = {kind="bitOr"},
		[0x7EF016] = {kind="bitOr"},
		[0x7EF017] = {kind="bitOr"},
		[0x7EF018] = {kind="bitOr"},
		[0x7EF019] = {kind="bitOr"},
		[0x7EF01A] = {kind="bitOr"},
		[0x7EF01C] = {kind="bitOr"},
		[0x7EF01D] = {kind="bitOr"},
		[0x7EF01E] = {kind="bitOr"},
		[0x7EF01F] = {kind="bitOr"},
		[0x7EF020] = {kind="bitOr"},
		[0x7EF021] = {kind="bitOr"},
		[0x7EF022] = {kind="bitOr"},
		[0x7EF023] = {kind="bitOr"},
		[0x7EF024] = {kind="bitOr"},
		[0x7EF025] = {kind="bitOr"},
		[0x7EF026] = {kind="bitOr"},
		[0x7EF027] = {kind="bitOr"},
		[0x7EF028] = {kind="bitOr"},
		[0x7EF029] = {kind="bitOr"},
		[0x7EF02A] = {kind="bitOr"},
		[0x7EF02B] = {kind="bitOr"},
		[0x7EF02C] = {kind="bitOr"},
		[0x7EF02D] = {kind="bitOr"},
		[0x7EF02E] = {kind="bitOr"},
		[0x7EF02F] = {kind="bitOr"},
		[0x7EF030] = {kind="bitOr"},
		[0x7EF031] = {kind="bitOr"},
		[0x7EF032] = {kind="bitOr"},
		[0x7EF033] = {kind="bitOr"},
		[0x7EF034] = {kind="bitOr"},
		[0x7EF035] = {kind="bitOr"},
		[0x7EF036] = {kind="bitOr"},
		[0x7EF037] = {kind="bitOr"},
		[0x7EF038] = {kind="bitOr"},
		[0x7EF039] = {kind="bitOr"},
		[0x7EF03A] = {kind="bitOr"},
		[0x7EF03B] = {kind="bitOr"},
		[0x7EF03C] = {kind="bitOr"},
		[0x7EF03D] = {kind="bitOr"},
		[0x7EF03E] = {kind="bitOr"},
		[0x7EF03F] = {kind="bitOr"},
		[0x7EF040] = {kind="bitOr"},
		[0x7EF042] = {kind="bitOr"},
		[0x7EF043] = {kind="bitOr"},
		[0x7EF044] = {kind="bitOr"},
		[0x7EF045] = {kind="bitOr"},
		[0x7EF046] = {kind="bitOr"},
		[0x7EF047] = {kind="bitOr"},
		[0x7EF048] = {kind="bitOr"},
		[0x7EF049] = {kind="bitOr"},
		[0x7EF04A] = {kind="bitOr"},
		[0x7EF04B] = {kind="bitOr"},
		[0x7EF04C] = {kind="bitOr"},
		[0x7EF04D] = {kind="bitOr"},
		[0x7EF04E] = {kind="bitOr"},
		[0x7EF04F] = {kind="bitOr"},
		[0x7EF050] = {kind="bitOr"},
		[0x7EF051] = {kind="bitOr"},
		[0x7EF052] = {kind="bitOr"},
		[0x7EF053] = {kind="bitOr"},
		[0x7EF054] = {kind="bitOr"},
		[0x7EF055] = {kind="bitOr"},
		[0x7EF056] = {kind="bitOr"},
		[0x7EF057] = {kind="bitOr"},
		[0x7EF058] = {kind="bitOr"},
		[0x7EF059] = {kind="bitOr"},
		[0x7EF05A] = {kind="bitOr"},
		[0x7EF05B] = {kind="bitOr"},
		[0x7EF05C] = {kind="bitOr"},
		[0x7EF05D] = {kind="bitOr"},
		[0x7EF05E] = {kind="bitOr"},
		[0x7EF05F] = {kind="bitOr"},
		[0x7EF060] = {kind="bitOr"},
		[0x7EF061] = {kind="bitOr"},
		[0x7EF062] = {kind="bitOr"},
		[0x7EF063] = {kind="bitOr"},
		[0x7EF064] = {kind="bitOr"},
		[0x7EF065] = {kind="bitOr"},
		[0x7EF066] = {kind="bitOr"},
		[0x7EF067] = {kind="bitOr"},
		[0x7EF068] = {kind="bitOr"},
		[0x7EF069] = {kind="bitOr"},
		[0x7EF06A] = {kind="bitOr"},
		[0x7EF06B] = {kind="bitOr"},
		[0x7EF06C] = {kind="bitOr"},
		[0x7EF06D] = {kind="bitOr"},
		[0x7EF06E] = {kind="bitOr"},
		[0x7EF06F] = {kind="bitOr"},
		[0x7EF070] = {kind="bitOr"},
		[0x7EF071] = {kind="bitOr"},
		[0x7EF072] = {kind="bitOr"},
		[0x7EF073] = {kind="bitOr"},
		[0x7EF074] = {kind="bitOr"},
		[0x7EF075] = {kind="bitOr"},
		[0x7EF076] = {kind="bitOr"},
		[0x7EF077] = {kind="bitOr"},
		[0x7EF078] = {kind="bitOr"},
		[0x7EF079] = {kind="bitOr"},
		[0x7EF07A] = {kind="bitOr"},
		[0x7EF07B] = {kind="bitOr"},
		[0x7EF07C] = {kind="bitOr"},
		[0x7EF07D] = {kind="bitOr"},
		[0x7EF07E] = {kind="bitOr"},
		[0x7EF07F] = {kind="bitOr"},
		[0x7EF080] = {kind="bitOr"},
		[0x7EF081] = {kind="bitOr"},
		[0x7EF082] = {kind="bitOr"},
		[0x7EF083] = {kind="bitOr"},
		[0x7EF084] = {kind="bitOr"},
		[0x7EF085] = {kind="bitOr"},
		[0x7EF086] = {kind="bitOr"},
		[0x7EF087] = {kind="bitOr"},
		[0x7EF088] = {kind="bitOr"},
		[0x7EF089] = {kind="bitOr"},
		[0x7EF08A] = {kind="bitOr"},
		[0x7EF08B] = {kind="bitOr"},
		[0x7EF08C] = {kind="bitOr"},
		[0x7EF08D] = {kind="bitOr"},
		[0x7EF08E] = {kind="bitOr"},
		[0x7EF08F] = {kind="bitOr"},
		[0x7EF090] = {kind="bitOr"},
		[0x7EF091] = {kind="bitOr"},
		[0x7EF092] = {kind="bitOr"},
		[0x7EF093] = {kind="bitOr"},
		[0x7EF094] = {kind="bitOr"},
		[0x7EF095] = {kind="bitOr"},
		[0x7EF096] = {kind="bitOr"},
		[0x7EF097] = {kind="bitOr"},
		[0x7EF098] = {kind="bitOr"},
		[0x7EF099] = {kind="bitOr"},
		[0x7EF09A] = {kind="bitOr"},
		[0x7EF09B] = {kind="bitOr"},
		[0x7EF09C] = {kind="bitOr"},
		[0x7EF09D] = {kind="bitOr"},
		[0x7EF09E] = {kind="bitOr"},
		[0x7EF09F] = {kind="bitOr"},
		[0x7EF0A0] = {kind="bitOr"},
		[0x7EF0A1] = {kind="bitOr"},
		[0x7EF0A2] = {kind="bitOr"},
		[0x7EF0A3] = {kind="bitOr"},
		[0x7EF0A4] = {kind="bitOr"},
		[0x7EF0A5] = {kind="bitOr"},
		[0x7EF0A6] = {kind="bitOr"},
		[0x7EF0A7] = {kind="bitOr"},
		[0x7EF0A8] = {kind="bitOr"},
		[0x7EF0A9] = {kind="bitOr"},
		[0x7EF0AA] = {kind="bitOr"},
		[0x7EF0AB] = {kind="bitOr"},
		[0x7EF0AC] = {kind="bitOr"},
		[0x7EF0AD] = {kind="bitOr"},
		[0x7EF0AE] = {kind="bitOr"},
		[0x7EF0AF] = {kind="bitOr"},
		[0x7EF0B0] = {kind="bitOr"},
		[0x7EF0B1] = {kind="bitOr"},
		[0x7EF0B2] = {kind="bitOr"},
		[0x7EF0B3] = {kind="bitOr"},
		[0x7EF0B4] = {kind="bitOr"},
		[0x7EF0B5] = {kind="bitOr"},
		[0x7EF0B6] = {kind="bitOr"},
		[0x7EF0B7] = {kind="bitOr"},
		[0x7EF0B8] = {kind="bitOr"},
		[0x7EF0B9] = {kind="bitOr"},
		[0x7EF0BA] = {kind="bitOr"},
		[0x7EF0BB] = {kind="bitOr"},
		[0x7EF0BC] = {kind="bitOr"},
		[0x7EF0BD] = {kind="bitOr"},
		[0x7EF0BE] = {kind="bitOr"},
		[0x7EF0BF] = {kind="bitOr"},
		[0x7EF0C0] = {kind="bitOr"},
		[0x7EF0C1] = {kind="bitOr"},
		[0x7EF0C2] = {kind="bitOr"},
		[0x7EF0C3] = {kind="bitOr"},
		[0x7EF0C4] = {kind="bitOr"},
		[0x7EF0C5] = {kind="bitOr"},
		[0x7EF0C6] = {kind="bitOr"},
		[0x7EF0C7] = {kind="bitOr"},
		[0x7EF0C8] = {kind="bitOr"},
		[0x7EF0C9] = {kind="bitOr"},
		[0x7EF0CA] = {kind="bitOr"},
		[0x7EF0CB] = {kind="bitOr"},
		[0x7EF0CC] = {kind="bitOr"},
		[0x7EF0CD] = {kind="bitOr"},
		[0x7EF0CE] = {kind="bitOr"},
		[0x7EF0CF] = {kind="bitOr"},
		[0x7EF0D0] = {kind="bitOr"},
		[0x7EF0D1] = {kind="bitOr"},
		[0x7EF0D2] = {kind="bitOr"},
		[0x7EF0D3] = {kind="bitOr"},
		[0x7EF0D4] = {kind="bitOr"},
		[0x7EF0D5] = {kind="bitOr"},
		[0x7EF0D6] = {kind="bitOr"},
		[0x7EF0D7] = {kind="bitOr"},
		[0x7EF0D8] = {kind="bitOr"},
		[0x7EF0D9] = {kind="bitOr"},
		[0x7EF0DA] = {kind="bitOr"},
		[0x7EF0DB] = {kind="bitOr"},
		[0x7EF0DC] = {kind="bitOr"},
		[0x7EF0DD] = {kind="bitOr"},
		[0x7EF0DE] = {kind="bitOr"},
		[0x7EF0DF] = {kind="bitOr"},
		[0x7EF0E0] = {kind="bitOr"},
		[0x7EF0E1] = {kind="bitOr"},
		[0x7EF0E2] = {kind="bitOr"},
		[0x7EF0E3] = {kind="bitOr"},
		[0x7EF0E4] = {kind="bitOr"},
		[0x7EF0E5] = {kind="bitOr"},
		[0x7EF0E6] = {kind="bitOr"},
		[0x7EF0E7] = {kind="bitOr"},
		[0x7EF0E8] = {kind="bitOr"},
		[0x7EF0E9] = {kind="bitOr"},
		[0x7EF0EA] = {kind="bitOr"},
		[0x7EF0EB] = {kind="bitOr"},
		[0x7EF0EC] = {kind="bitOr"},
		[0x7EF0ED] = {kind="bitOr"},
		[0x7EF0EE] = {kind="bitOr"},
		[0x7EF0EF] = {kind="bitOr"},
		[0x7EF0F0] = {kind="bitOr"},
		[0x7EF0F1] = {kind="bitOr"},
		[0x7EF0F2] = {kind="bitOr"},
		[0x7EF0F3] = {kind="bitOr"},
		[0x7EF0F4] = {kind="bitOr"},
		[0x7EF0F5] = {kind="bitOr"},
		[0x7EF0F6] = {kind="bitOr"},
		[0x7EF0F7] = {kind="bitOr"},
		[0x7EF0F8] = {kind="bitOr"},
		[0x7EF0F9] = {kind="bitOr"},
		[0x7EF0FA] = {kind="bitOr"},
		[0x7EF0FB] = {kind="bitOr"},
		[0x7EF0FC] = {kind="bitOr"},
		[0x7EF0FD] = {kind="bitOr"},
		[0x7EF0FE] = {kind="bitOr"},
		[0x7EF0FF] = {kind="bitOr"},
		[0x7EF100] = {kind="bitOr"},
		[0x7EF101] = {kind="bitOr"},
		[0x7EF102] = {kind="bitOr"},
		[0x7EF103] = {kind="bitOr"},
		[0x7EF104] = {kind="bitOr"},
		[0x7EF105] = {kind="bitOr"},
		[0x7EF106] = {kind="bitOr"},
		[0x7EF107] = {kind="bitOr"},
		[0x7EF108] = {kind="bitOr"},
		[0x7EF109] = {kind="bitOr"},
		[0x7EF10A] = {kind="bitOr"},
		[0x7EF10B] = {kind="bitOr"},
		[0x7EF10C] = {kind="bitOr"},
		[0x7EF10D] = {kind="bitOr"},
		[0x7EF10E] = {kind="bitOr"},
		[0x7EF10F] = {kind="bitOr"},
		[0x7EF110] = {kind="bitOr"},
		[0x7EF111] = {kind="bitOr"},
		[0x7EF112] = {kind="bitOr"},
		[0x7EF113] = {kind="bitOr"},
		[0x7EF114] = {kind="bitOr"},
		[0x7EF115] = {kind="bitOr"},
		[0x7EF116] = {kind="bitOr"},
		[0x7EF117] = {kind="bitOr"},
		[0x7EF118] = {kind="bitOr"},
		[0x7EF119] = {kind="bitOr"},
		[0x7EF11A] = {kind="bitOr"},
		[0x7EF11B] = {kind="bitOr"},
		[0x7EF11C] = {kind="bitOr"},
		[0x7EF11D] = {kind="bitOr"},
		[0x7EF11E] = {kind="bitOr"},
		[0x7EF11F] = {kind="bitOr"},
		[0x7EF120] = {kind="bitOr"},
		[0x7EF121] = {kind="bitOr"},
		[0x7EF122] = {kind="bitOr"},
		[0x7EF123] = {kind="bitOr"},
		[0x7EF124] = {kind="bitOr"},
		[0x7EF125] = {kind="bitOr"},
		[0x7EF126] = {kind="bitOr"},
		[0x7EF127] = {kind="bitOr"},
		[0x7EF128] = {kind="bitOr"},
		[0x7EF129] = {kind="bitOr"},
		[0x7EF12A] = {kind="bitOr"},
		[0x7EF12B] = {kind="bitOr"},
		[0x7EF12C] = {kind="bitOr"},
		[0x7EF12D] = {kind="bitOr"},
		[0x7EF12E] = {kind="bitOr"},
		[0x7EF12F] = {kind="bitOr"},
		[0x7EF130] = {kind="bitOr"},
		[0x7EF131] = {kind="bitOr"},
		[0x7EF132] = {kind="bitOr"},
		[0x7EF133] = {kind="bitOr"},
		[0x7EF134] = {kind="bitOr"},
		[0x7EF135] = {kind="bitOr"},
		[0x7EF136] = {kind="bitOr"},
		[0x7EF137] = {kind="bitOr"},
		[0x7EF138] = {kind="bitOr"},
		[0x7EF139] = {kind="bitOr"},
		[0x7EF13A] = {kind="bitOr"},
		[0x7EF13B] = {kind="bitOr"},
		[0x7EF13C] = {kind="bitOr"},
		[0x7EF13D] = {kind="bitOr"},
		[0x7EF13E] = {kind="bitOr"},
		[0x7EF13F] = {kind="bitOr"},
		[0x7EF140] = {kind="bitOr"},
		[0x7EF141] = {kind="bitOr"},
		[0x7EF142] = {kind="bitOr"},
		[0x7EF143] = {kind="bitOr"},
		[0x7EF144] = {kind="bitOr"},
		[0x7EF145] = {kind="bitOr"},
		[0x7EF146] = {kind="bitOr"},
		[0x7EF147] = {kind="bitOr"},
		[0x7EF148] = {kind="bitOr"},
		[0x7EF149] = {kind="bitOr"},
		[0x7EF14A] = {kind="bitOr"},
		[0x7EF14B] = {kind="bitOr"},
		[0x7EF14C] = {kind="bitOr"},
		[0x7EF14D] = {kind="bitOr"},
		[0x7EF14E] = {kind="bitOr"},
		[0x7EF14F] = {kind="bitOr"},
		[0x7EF150] = {kind="bitOr"},
		[0x7EF151] = {kind="bitOr"},
		[0x7EF152] = {kind="bitOr"},
		[0x7EF153] = {kind="bitOr"},
		[0x7EF154] = {kind="bitOr"},
		[0x7EF155] = {kind="bitOr"},
		[0x7EF156] = {kind="bitOr"},
		[0x7EF157] = {kind="bitOr"},
		[0x7EF158] = {kind="bitOr"},
		[0x7EF159] = {kind="bitOr"},
		[0x7EF15A] = {kind="bitOr"},
		[0x7EF15B] = {kind="bitOr"},
		[0x7EF15C] = {kind="bitOr"},
		[0x7EF15D] = {kind="bitOr"},
		[0x7EF15E] = {kind="bitOr"},
		[0x7EF15F] = {kind="bitOr"},
		[0x7EF160] = {kind="bitOr"},
		[0x7EF161] = {kind="bitOr"},
		[0x7EF162] = {kind="bitOr"},
		[0x7EF163] = {kind="bitOr"},
		[0x7EF164] = {kind="bitOr"},
		[0x7EF165] = {kind="bitOr"},
		[0x7EF166] = {kind="bitOr"},
		[0x7EF167] = {kind="bitOr"},
		[0x7EF168] = {kind="bitOr"},
		[0x7EF169] = {kind="bitOr"},
		[0x7EF16A] = {kind="bitOr"},
		[0x7EF16B] = {kind="bitOr"},
		[0x7EF16C] = {kind="bitOr"},
		[0x7EF16D] = {kind="bitOr"},
		[0x7EF16E] = {kind="bitOr"},
		[0x7EF16F] = {kind="bitOr"},
		[0x7EF170] = {kind="bitOr"},
		[0x7EF171] = {kind="bitOr"},
		[0x7EF172] = {kind="bitOr"},
		[0x7EF173] = {kind="bitOr"},
		[0x7EF174] = {kind="bitOr"},
		[0x7EF175] = {kind="bitOr"},
		[0x7EF176] = {kind="bitOr"},
		[0x7EF177] = {kind="bitOr"},
		[0x7EF178] = {kind="bitOr"},
		[0x7EF179] = {kind="bitOr"},
		[0x7EF17A] = {kind="bitOr"},
		[0x7EF17B] = {kind="bitOr"},
		[0x7EF17C] = {kind="bitOr"},
		[0x7EF17D] = {kind="bitOr"},
		[0x7EF17E] = {kind="bitOr"},
		[0x7EF17F] = {kind="bitOr"},
		[0x7EF180] = {kind="bitOr"},
		[0x7EF181] = {kind="bitOr"},
		[0x7EF182] = {kind="bitOr"},
		[0x7EF183] = {kind="bitOr"},
		[0x7EF184] = {kind="bitOr"},
		[0x7EF185] = {kind="bitOr"},
		[0x7EF186] = {kind="bitOr"},
		[0x7EF187] = {kind="bitOr"},
		[0x7EF188] = {kind="bitOr"},
		[0x7EF189] = {kind="bitOr"},
		[0x7EF18A] = {kind="bitOr"},
		[0x7EF18B] = {kind="bitOr"},
		[0x7EF18C] = {kind="bitOr"},
		[0x7EF18D] = {kind="bitOr"},
		[0x7EF18E] = {kind="bitOr"},
		[0x7EF18F] = {kind="bitOr"},
		[0x7EF190] = {kind="bitOr"},
		[0x7EF191] = {kind="bitOr"},
		[0x7EF192] = {kind="bitOr"},
		[0x7EF193] = {kind="bitOr"},
		[0x7EF194] = {kind="bitOr"},
		[0x7EF195] = {kind="bitOr"},
		[0x7EF196] = {kind="bitOr"},
		[0x7EF197] = {kind="bitOr"},
		[0x7EF198] = {kind="bitOr"},
		[0x7EF199] = {kind="bitOr"},
		[0x7EF19A] = {kind="bitOr"},
		[0x7EF19B] = {kind="bitOr"},
		[0x7EF19C] = {kind="bitOr"},
		[0x7EF19D] = {kind="bitOr"},
		[0x7EF19E] = {kind="bitOr"},
		[0x7EF19F] = {kind="bitOr"},
		[0x7EF1A0] = {kind="bitOr"},
		[0x7EF1A1] = {kind="bitOr"},
		[0x7EF1A2] = {kind="bitOr"},
		[0x7EF1A3] = {kind="bitOr"},
		[0x7EF1A4] = {kind="bitOr"},
		[0x7EF1A5] = {kind="bitOr"},
		[0x7EF1A6] = {kind="bitOr"},
		[0x7EF1A7] = {kind="bitOr"},
		[0x7EF1A8] = {kind="bitOr"},
		[0x7EF1A9] = {kind="bitOr"},
		[0x7EF1AA] = {kind="bitOr"},
		[0x7EF1AB] = {kind="bitOr"},
		[0x7EF1AC] = {kind="bitOr"},
		[0x7EF1AD] = {kind="bitOr"},
		[0x7EF1AE] = {kind="bitOr"},
		[0x7EF1AF] = {kind="bitOr"},
		[0x7EF1B0] = {kind="bitOr"},
		[0x7EF1B1] = {kind="bitOr"},
		[0x7EF1B2] = {kind="bitOr"},
		[0x7EF1B3] = {kind="bitOr"},
		[0x7EF1B4] = {kind="bitOr"},
		[0x7EF1B5] = {kind="bitOr"},
		[0x7EF1B6] = {kind="bitOr"},
		[0x7EF1B7] = {kind="bitOr"},
		[0x7EF1B8] = {kind="bitOr"},
		[0x7EF1B9] = {kind="bitOr"},
		[0x7EF1BA] = {kind="bitOr"},
		[0x7EF1BB] = {kind="bitOr"},
		[0x7EF1BC] = {kind="bitOr"},
		[0x7EF1BD] = {kind="bitOr"},
		[0x7EF1BE] = {kind="bitOr"},
		[0x7EF1BF] = {kind="bitOr"},
		[0x7EF1C0] = {kind="bitOr"},
		[0x7EF1C1] = {kind="bitOr"},
		[0x7EF1C2] = {kind="bitOr"},
		[0x7EF1C3] = {kind="bitOr"},
		[0x7EF1C4] = {kind="bitOr"},
		[0x7EF1C5] = {kind="bitOr"},
		[0x7EF1C6] = {kind="bitOr"},
		[0x7EF1C7] = {kind="bitOr"},
		[0x7EF1C8] = {kind="bitOr"},
		[0x7EF1C9] = {kind="bitOr"},
		[0x7EF1CA] = {kind="bitOr"},
		[0x7EF1CB] = {kind="bitOr"},
		[0x7EF1CC] = {kind="bitOr"},
		[0x7EF1CD] = {kind="bitOr"},
		[0x7EF1CE] = {kind="bitOr"},
		[0x7EF1CF] = {kind="bitOr"},
		[0x7EF1D0] = {kind="bitOr"},
		[0x7EF1D1] = {kind="bitOr"},
		[0x7EF1D2] = {kind="bitOr"},
		[0x7EF1D3] = {kind="bitOr"},
		[0x7EF1D4] = {kind="bitOr"},
		[0x7EF1D5] = {kind="bitOr"},
		[0x7EF1D6] = {kind="bitOr"},
		[0x7EF1D7] = {kind="bitOr"},
		[0x7EF1D8] = {kind="bitOr"},
		[0x7EF1D9] = {kind="bitOr"},
		[0x7EF1DA] = {kind="bitOr"},
		[0x7EF1DB] = {kind="bitOr"},
		[0x7EF1DC] = {kind="bitOr"},
		[0x7EF1DD] = {kind="bitOr"},
		[0x7EF1DE] = {kind="bitOr"},
		[0x7EF1DF] = {kind="bitOr"},
		[0x7EF1E0] = {kind="bitOr"},
		[0x7EF1E1] = {kind="bitOr"},
		[0x7EF1E2] = {kind="bitOr"},
		[0x7EF1E3] = {kind="bitOr"},
		[0x7EF1E4] = {kind="bitOr"},
		[0x7EF1E5] = {kind="bitOr"},
		[0x7EF1E6] = {kind="bitOr"},
		[0x7EF1E7] = {kind="bitOr"},
		[0x7EF1E8] = {kind="bitOr"},
		[0x7EF1E9] = {kind="bitOr"},
		[0x7EF1EA] = {kind="bitOr"},
		[0x7EF1EB] = {kind="bitOr"},
		[0x7EF1EC] = {kind="bitOr"},
		[0x7EF1ED] = {kind="bitOr"},
		[0x7EF1EE] = {kind="bitOr"},
		[0x7EF1EF] = {kind="bitOr"},
		[0x7EF1F0] = {kind="bitOr"},
		[0x7EF1F1] = {kind="bitOr"},
		[0x7EF1F2] = {kind="bitOr"},
		[0x7EF1F3] = {kind="bitOr"},
		[0x7EF1F4] = {kind="bitOr"},
		[0x7EF1F5] = {kind="bitOr"},
		[0x7EF1F6] = {kind="bitOr"},
		[0x7EF1F7] = {kind="bitOr"},
		[0x7EF1F8] = {kind="bitOr"},
		[0x7EF1F9] = {kind="bitOr"},
		[0x7EF1FA] = {kind="bitOr"},
		[0x7EF1FB] = {kind="bitOr"},
		[0x7EF1FC] = {kind="bitOr"},
		[0x7EF1FD] = {kind="bitOr"},
		[0x7EF1FE] = {kind="bitOr"},
		[0x7EF1FF] = {kind="bitOr"},
		[0x7EF200] = {kind="bitOr"},
		[0x7EF201] = {kind="bitOr"},
		[0x7EF202] = {kind="bitOr"},
		[0x7EF203] = {kind="bitOr"},
		[0x7EF204] = {kind="bitOr"},
		[0x7EF205] = {kind="bitOr"},
		[0x7EF206] = {kind="bitOr"},
		[0x7EF207] = {kind="bitOr"},
		[0x7EF208] = {kind="bitOr"},
		[0x7EF209] = {kind="bitOr"},
		[0x7EF20A] = {kind="bitOr"},
		[0x7EF20B] = {kind="bitOr"},
		[0x7EF20C] = {kind="bitOr"},
		[0x7EF20D] = {kind="bitOr"},
		[0x7EF20E] = {kind="bitOr"},
		[0x7EF20F] = {kind="bitOr"},
		[0x7EF210] = {kind="bitOr"},
		[0x7EF211] = {kind="bitOr"},
		[0x7EF212] = {kind="bitOr"},
		[0x7EF213] = {kind="bitOr"},
		[0x7EF214] = {kind="bitOr"},
		[0x7EF215] = {kind="bitOr"},
		[0x7EF216] = {kind="bitOr"},
		[0x7EF217] = {kind="bitOr"},
		[0x7EF218] = {kind="bitOr"},
		[0x7EF219] = {kind="bitOr"},
		[0x7EF21A] = {kind="bitOr"},
		[0x7EF21B] = {kind="bitOr"},
		[0x7EF21C] = {kind="bitOr"},
		[0x7EF21D] = {kind="bitOr"},
		[0x7EF21E] = {kind="bitOr"},
		[0x7EF21F] = {kind="bitOr"},
		[0x7EF220] = {kind="bitOr"},
		[0x7EF221] = {kind="bitOr"},
		[0x7EF222] = {kind="bitOr"},
		[0x7EF223] = {kind="bitOr"},
		[0x7EF224] = {kind="bitOr"},
		[0x7EF225] = {kind="bitOr"},
		[0x7EF226] = {kind="bitOr"},
		[0x7EF227] = {kind="bitOr"},
		[0x7EF228] = {kind="bitOr"},
		[0x7EF229] = {kind="bitOr"},
		[0x7EF22A] = {kind="bitOr"},
		[0x7EF22B] = {kind="bitOr"},
		[0x7EF22C] = {kind="bitOr"},
		[0x7EF22D] = {kind="bitOr"},
		[0x7EF22E] = {kind="bitOr"},
		[0x7EF22F] = {kind="bitOr"},
		[0x7EF230] = {kind="bitOr"},
		[0x7EF231] = {kind="bitOr"},
		[0x7EF232] = {kind="bitOr"},
		[0x7EF233] = {kind="bitOr"},
		[0x7EF234] = {kind="bitOr"},
		[0x7EF235] = {kind="bitOr"},
		[0x7EF236] = {kind="bitOr"},
		[0x7EF237] = {kind="bitOr"},
		[0x7EF238] = {kind="bitOr"},
		[0x7EF239] = {kind="bitOr"},
		[0x7EF23A] = {kind="bitOr"},
		[0x7EF23B] = {kind="bitOr"},
		[0x7EF23C] = {kind="bitOr"},
		[0x7EF23D] = {kind="bitOr"},
		[0x7EF23E] = {kind="bitOr"},
		[0x7EF23F] = {kind="bitOr"},
		[0x7EF240] = {kind="bitOr"},
		[0x7EF241] = {kind="bitOr"},
		[0x7EF242] = {kind="bitOr"},
		[0x7EF243] = {kind="bitOr"},
		[0x7EF244] = {kind="bitOr"},
		[0x7EF245] = {kind="bitOr"},
		[0x7EF246] = {kind="bitOr"},
		[0x7EF247] = {kind="bitOr"},
		[0x7EF248] = {kind="bitOr"},
		[0x7EF249] = {kind="bitOr"},
		[0x7EF24A] = {kind="bitOr"},
		[0x7EF24B] = {kind="bitOr"},
		[0x7EF24C] = {kind="bitOr"},
		[0x7EF24D] = {kind="bitOr"},
		[0x7EF24E] = {kind="bitOr"},
		[0x7EF24F] = {kind="bitOr"},

		-- OVERWORLD

		[0x7EF280] = {kind="bitOr"},
		[0x7EF281] = {kind="bitOr"},
		[0x7EF282] = {kind="bitOr"},
		[0x7EF283] = {kind="bitOr"},
		[0x7EF284] = {kind="bitOr"},
		[0x7EF285] = {kind="bitOr"},
		[0x7EF286] = {kind="bitOr"},
		[0x7EF287] = {kind="bitOr"},
		[0x7EF288] = {kind="bitOr"},
		[0x7EF289] = {kind="bitOr"},
		[0x7EF28A] = {kind="bitOr"},
		[0x7EF28B] = {kind="bitOr"},
		[0x7EF28C] = {kind="bitOr"},
		[0x7EF28D] = {kind="bitOr"},
		[0x7EF28E] = {kind="bitOr"},
		[0x7EF28F] = {kind="bitOr"},
		[0x7EF290] = {kind="bitOr"},
		[0x7EF291] = {kind="bitOr"},
		[0x7EF292] = {kind="bitOr"},
		[0x7EF293] = {kind="bitOr"},
		[0x7EF294] = {kind="bitOr"},
		[0x7EF295] = {kind="bitOr"},
		[0x7EF296] = {kind="bitOr"},
		[0x7EF297] = {kind="bitOr"},
		[0x7EF298] = {kind="bitOr"},
		[0x7EF299] = {kind="bitOr"},
		[0x7EF29A] = {kind="bitOr"},
		[0x7EF29B] = {kind="bitOr"},
		[0x7EF29C] = {kind="bitOr"},
		[0x7EF29D] = {kind="bitOr"},
		[0x7EF29E] = {kind="bitOr"},
		[0x7EF29F] = {kind="bitOr"},
		[0x7EF2A0] = {kind="bitOr"},
		[0x7EF2A1] = {kind="bitOr"},
		[0x7EF2A2] = {kind="bitOr"},
		[0x7EF2A3] = {kind="bitOr"},
		[0x7EF2A4] = {kind="bitOr"},
		[0x7EF2A5] = {kind="bitOr"},
		[0x7EF2A6] = {kind="bitOr"},
		[0x7EF2A7] = {kind="bitOr"},
		[0x7EF2A8] = {kind="bitOr"},
		[0x7EF2A9] = {kind="bitOr"},
		[0x7EF2AA] = {kind="bitOr"},
		[0x7EF2AB] = {kind="bitOr"},
		[0x7EF2AC] = {kind="bitOr"},
		[0x7EF2AD] = {kind="bitOr"},
		[0x7EF2AE] = {kind="bitOr"},
		[0x7EF2AF] = {kind="bitOr"},
		[0x7EF2B0] = {kind="bitOr"},
		[0x7EF2B1] = {kind="bitOr"},
		[0x7EF2B2] = {kind="bitOr"},
		[0x7EF2B3] = {kind="bitOr"},
		[0x7EF2B4] = {kind="bitOr"},
		[0x7EF2B5] = {kind="bitOr"},
		[0x7EF2B6] = {kind="bitOr"},
		[0x7EF2B7] = {kind="bitOr"},
		[0x7EF2B8] = {kind="bitOr"},
		[0x7EF2B9] = {kind="bitOr"},
		[0x7EF2BA] = {kind="bitOr"},
		[0x7EF2BB] = {kind="bitOr"},
		[0x7EF2BC] = {kind="bitOr"},
		[0x7EF2BD] = {kind="bitOr"},
		[0x7EF2BE] = {kind="bitOr"},
		[0x7EF2BF] = {kind="bitOr"},
		[0x7EF2C0] = {kind="bitOr"},
		[0x7EF2C1] = {kind="bitOr"},
		[0x7EF2C2] = {kind="bitOr"},
		[0x7EF2C3] = {kind="bitOr"},
		[0x7EF2C4] = {kind="bitOr"},
		[0x7EF2C5] = {kind="bitOr"},
		[0x7EF2C6] = {kind="bitOr"},
		[0x7EF2C7] = {kind="bitOr"},
		[0x7EF2C8] = {kind="bitOr"},
		[0x7EF2C9] = {kind="bitOr"},
		[0x7EF2CA] = {kind="bitOr"},
		[0x7EF2CB] = {kind="bitOr"},
		[0x7EF2CC] = {kind="bitOr"},
		[0x7EF2CD] = {kind="bitOr"},
		[0x7EF2CE] = {kind="bitOr"},
		[0x7EF2CF] = {kind="bitOr"},
		[0x7EF2D0] = {kind="bitOr"},
		[0x7EF2D1] = {kind="bitOr"},
		[0x7EF2D2] = {kind="bitOr"},
		[0x7EF2D3] = {kind="bitOr"},
		[0x7EF2D4] = {kind="bitOr"},
		[0x7EF2D5] = {kind="bitOr"},
		[0x7EF2D6] = {kind="bitOr"},
		[0x7EF2D7] = {kind="bitOr"},
		[0x7EF2D8] = {kind="bitOr"},
		[0x7EF2D9] = {kind="bitOr"},
		[0x7EF2DA] = {kind="bitOr"},
		[0x7EF2DC] = {kind="bitOr"},
		[0x7EF2DD] = {kind="bitOr"},
		[0x7EF2DE] = {kind="bitOr"},
		[0x7EF2DF] = {kind="bitOr"},
		[0x7EF2E0] = {kind="bitOr"},
		[0x7EF2E1] = {kind="bitOr"},
		[0x7EF2E2] = {kind="bitOr"},
		[0x7EF2E3] = {kind="bitOr"},
		[0x7EF2E4] = {kind="bitOr"},
		[0x7EF2E5] = {kind="bitOr"},
		[0x7EF2E6] = {kind="bitOr"},
		[0x7EF2E7] = {kind="bitOr"},
		[0x7EF2E8] = {kind="bitOr"},
		[0x7EF2E9] = {kind="bitOr"},
		[0x7EF2EA] = {kind="bitOr"},
		[0x7EF2EB] = {kind="bitOr"},
		[0x7EF2EC] = {kind="bitOr"},
		[0x7EF2ED] = {kind="bitOr"},
		[0x7EF2EE] = {kind="bitOr"},
		[0x7EF2EF] = {kind="bitOr"},
		[0x7EF2F0] = {kind="bitOr"},
		[0x7EF2F1] = {kind="bitOr"},
		[0x7EF2F2] = {kind="bitOr"},
		[0x7EF2F3] = {kind="bitOr"},
		[0x7EF2F4] = {kind="bitOr"},
		[0x7EF2F5] = {kind="bitOr"},
		[0x7EF2F6] = {kind="bitOr"},
		[0x7EF2F7] = {kind="bitOr"},
		[0x7EF2F8] = {kind="bitOr"},
		[0x7EF2F9] = {kind="bitOr"},
		[0x7EF2FA] = {kind="bitOr"},
		[0x7EF2FB] = {kind="bitOr"},
		[0x7EF2FC] = {kind="bitOr"},
		[0x7EF2FD] = {kind="bitOr"},
		[0x7EF2FE] = {kind="bitOr"},
		[0x7EF2FF] = {kind="bitOr"},

		-- Small Keys

		[0x7EF37C] = {name="HC Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == sewerValue or memory.readword(dungeonWord) == hcValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF37D] =  {name="HC Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == sewerValue or memory.readword(dungeonWord) == hcValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF37E] =  {name="EP Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == epValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF37F] =  {name="DP Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == dpValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF380] = {name="AT Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == atValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF381] = {name="SP Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == spValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF382] = {name="PoD Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == podValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF383] = {name="MM Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == mmValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF384] = {name="SW Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == swValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF385] = {name="IP Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == ipValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF386] = {name="ToH Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == tohValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF387] = {name="TT Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == ttValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF388] = {name="TR Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == trValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},
		[0x7EF389] = {name="GT Key", kind="key",
		receiveTrigger=function(value, previousValue)
			if memory.readword(dungeonWord) == gtValue and previousValue < value then
				local previousCurrentKeys = memory.readbyte(currentKeysByte)
				memory.writebyte(currentKeysByte, previousCurrentKeys + 1)
			end
		end,
		cond={"optiontest", addr = "retromode", value = false}
					},

		-- Dungeon Item Counts

		[0x7EF434] = {kind="high"},
		[0x7EF435] = {kind="high"},
		[0x7EF436] = {kind="high"},
		[0x7EF437] = {kind="high"},
		[0x7EF438] = {kind="high"},
		[0x7EF439] = {kind="high"}
	}
}
