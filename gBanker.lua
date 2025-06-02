--[[
	gBanker

	Copyright (c) 2010-2014, sarafdswow@gmail.com
	All rights reserved.

	You're allowed to use this addon, free of monetary charge,
	but you are not allowed to modify, alter, or redistribute
	this addon without express, written permission of the author.
]]
local currentversion = 15
local name, gb = ...
local lower, gsub = string.lower, string.gsub

local BANKTYPE_NONE = Enum.PlayerInteractionType.None
local BANKTYPE_PLAYER = Enum.PlayerInteractionType.Banker
local BANKTYPE_GUILD = Enum.PlayerInteractionType.GuildBanker
local BANKTYPE_WARBAND = Enum.PlayerInteractionType.AccountBanker

local COMMAND_BLACKLIST = "blacklist"
local COMMAND_BLACKLIST_SHORT = "b"
local COMMAND_CASE = "case"
local COMMAND_CASE_SHORT = "c"
local COMMAND_DELAY = "delay"
local COMMAND_DELAY_SHORT = "d"
local COMMAND_GIVE = "give"
local COMMAND_GIVE_SHORT = "g"
local COMMAND_HELP = "help"
local COMMAND_QUICK = "quick"
local COMMAND_QUICK_SHORT = "q"
local COMMAND_QUICKNUM = "quicknum"
local COMMAND_TAKE = "take"
local COMMAND_TAKE_SHORT = "t"
local COMMAND_WAIT = "wait"
local COMMAND_WAIT_SHORT = "w"

local EVENT_PLAYER_INTERACTION_MANAGER_FRAME_SHOW = "PLAYER_INTERACTION_MANAGER_FRAME_SHOW"
local EVENT_PLAYER_INTERACTION_MANAGER_FRAME_HIDE = "PLAYER_INTERACTION_MANAGER_FRAME_HIDE"
local EVENT_ADDON_LOADED = "ADDON_LOADED"
local EVENT_BAG_UPDATE_DELAYED = "BAG_UPDATE_DELAYED"
local EVENT_UNIT_INVENTORY_CHANGED = "UNIT_INVENTORY_CHANGED"

local MOVE_STATE_DONE = "DONE"
local MOVE_STATE_MOVE = "MOVE"
local MOVE_STATE_INV_UPDATE = "INV_UPDATE"
local MOVE_STATE_BAG_UPDATE_DELAYED = "BAG_UPDATE_DELAYED"

-- debug output
local gbd = function(msg)
	if msg and gb.debug then
		print("|cff33dd00g|cffdd3300Banker debug: |r"..msg)
	end
end

-- standard output
local gbp = function(msg)
	if msg and not gBankerDB.silent then
		print("|cff33dd00g|cffdd3300Banker: |r"..msg)
	end
end

-- extract item name from an item link
local function l2t(link)
	link=link or ""
	return link:match("%[(.-)%]")
end

-- extract item id from an item link
local function l2i(link)
	link=link or ""
	return link:match(":(.-):")
end

-- scan gbank
local function scangbank()
	for i=1,GetNumGuildBankTabs() do
		QueryGuildBankTab(i)
	end
end

-- create frame for gui and event handling
local buttonsexist = false -- buttons do not exist yet
local gbf = CreateFrame("frame","gBankerMainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
gbf:SetFrameStrata("HIGH")
gbf:SetWidth(200)
gbf:SetHeight(65)
gbf:EnableMouse(true)
gbf:SetMovable(true)
gbf:RegisterForDrag("LeftButton")
gbf:SetScript("OnDragStart", gbf.StartMoving)
gbf:SetScript("OnDragStop", gbf.StopMovingOrSizing)
gbf:SetClampedToScreen(true)
gbf:SetUserPlaced(true)
gbf:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 12,
  insets = {
    left = 3,
    right = 3,
    top = 2,
    bottom = 2
  }
})
gbf:SetBackdropColor(0,0,0,1)
gbf:SetPoint("CENTER",0,0)
gbf.title = gbf:CreateFontString(nil,"ARTWORK","GameFontNormal")
gbf.title:SetPoint("TOPLEFT",gbf,"TOPLEFT",5,-7)
gbf.title:SetText("|cff33dd00g|cffdd3300Banker|r v"..currentversion)
gbf:RegisterEvent(EVENT_PLAYER_INTERACTION_MANAGER_FRAME_SHOW)
gbf:RegisterEvent(EVENT_PLAYER_INTERACTION_MANAGER_FRAME_HIDE)
gbf:RegisterEvent(EVENT_ADDON_LOADED)
gbf:RegisterEvent(EVENT_UNIT_INVENTORY_CHANGED)
gbf:RegisterEvent(EVENT_BAG_UPDATE_DELAYED)

gbf:Hide()

-- create another frame for quick links
local gbf2 = CreateFrame("frame","gBankerFrame2",gBankerMainFrame, BackdropTemplateMixin and "BackdropTemplate")
gbf2:SetFrameStrata("HIGH")
gbf2:SetWidth(200)
gbf2:SetHeight(45)
gbf2:SetClampedToScreen(true)
gbf2:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 12,
  insets = {
    left = 3,
    right = 3,
    top = 2,
    bottom = 2
  }
})
gbf2:SetBackdropColor(0,0,0,1)
gbf2:SetPoint("TOPLEFT",gBankerMainFrame,"BOTTOMLEFT",0,0)
gbf2:Hide()

-- toggle options
local function toggleoption(_,option)
	gBankerDB[option] = gBankerDB[option] == false and true
	if option == "quick" then -- show / hide quickbuttons frame
		if gBankerDB.quick == true then
			gbf2:Show()
		else
			gbf2:Hide()
		end
	end
end

gb.banktype = BANKTYPE_NONE -- default is no bank is open
gb.move_state = MOVE_STATE_DONE -- default is not moving an item to/from the gbank

-- to bypass guild bank throttling, items are queued and their actual movement is throttled by this func
-- trade phasing goes "Move item", "Wait for UNIT_INVENTORY_CHANGED" event, wait for "BAG_UPDATE" event, 
-- then ready to move the next item, so we update the move state between "MOVE", "INV_UPDATE", "BAG_UPDATE", until "MOVE_DONE"
gb.queue = {} -- bag/tab and slot numbers of items that shall be moved are stored here
local function gb_queue(movementtype)
	gb.queue_command = movementtype
	if gb.queue[1] then -- as moved items' table entries are removed rather than set to nil, we simply need to check if the first entry exists
		gb.move_state = MOVE_STATE_MOVE
		if movementtype == COMMAND_TAKE then
			AutoStoreGuildBankItem(gb.queue[1][1], gb.queue[1][2])
		else -- give
			C_Container.UseContainerItem(gb.queue[1][1], gb.queue[1][2])
		end
		tremove(gb.queue,1)
	else
		gb.move_state = MOVE_STATE_DONE
		gbp(gb.L.rdy)
	end
end

-- This function parses the argument and returns 3 params: filter type, filter param, and filter subparam
-- If arg is the format "x:#:#" or "x:#" then it returns "x, #, #" otherwise it returns "name, arg"
-- invalid (empty) arg return nil
local function arg2xpac(arg)
	if arg == nil then 
		gbd("arg2xpac nil")
		return nil, nil, nil
	end

	if arg == "" then
		gbd("arg2xpac empty string")
		return nil, nil, nil
	end

	local regex1 = "(%a+):(%d+):(%d+)"
	local regex2 = "(%a+):(%d+)"

	if arg:find(regex1) then
    local key, val, val2 = arg:match(regex1)
		gbd("arg2xpac  " .. key .. "=" .. val .. ", subkey=" .. val2)
		return key, val, val2
	elseif arg:find(regex2) then
    local key, val = arg:match(regex2)
		gbd("arg2xpac  " .. key .. "=" .. val)
		return key, val, nil
	elseif arg == "all" then
		gbd("arg2xpac all")
		return "all", "all"
	else
		gbd("arg2xpac keyword " .. arg)
		return "name", arg
	end
end

-- This function returns true if the item in the bank/tab/slot matches the filtertype and value
local function includeItem(bankType, bagSlot, containerSlot, filterType, filterValue, subValue)
	-- gbd("bt="..tostring(bankType)..",bs="..tostring(bagSlot)..",cs="..tostring(containerSlot)..",ft="..filterType..",fv="..filterValue..",sv="..tostring(subValue))
	if filterType == "all" then
		return true
	end

	local link = ""
	if bankType == BANKTYPE_PLAYER then
		link = C_Container.GetContainerItemLink(bagSlot,containerSlot)
	elseif bankType == BANKTYPE_GUILD then
		link = GetGuildBankItemLink(bagSlot,containerSlot)
	else
		return false
	end

	if (link:match("Hbattlepet:")) and filterType == "name" then
		local petName = l2t(link)
		if not gBankerDB.cs then petName = lower(petName) end
		return petName:match(filterValue)
	elseif (link:match("Hitem:")) then
		local classID, subClassID, expansionID, itemName = 0, 0, 0, ""
		local item = Item:CreateFromItemLink(link)
		item:ContinueOnItemLoad(function()
			itemName, _, _, _, _, _, _, _, _, _, _, classID, subClassID, _, expansionID, _, _ = C_Item.GetItemInfo(link)
			if expansionID == nil then
				expansionID = 0
			else
				expansionID = math.floor(expansionID)
			end
		end)

	-- skip it if it's on the blacklist
		if not gBankerDB.cs then itemName = lower(itemName) end
		if gBankerDB.blacklist[itemName] then
			return false
		end

		if filterType == "name" then
			return itemName:find(filterValue)
		elseif filterType == "xpac" or filterType == "type" then
			if filterType == "xpac" then
				gbd("n=" .. itemName .. ", f=" .. tostring(filterValue) .. ", x=" .. tostring(expansionID))
				return tonumber(filterValue) == tonumber(expansionID)
			elseif filterType == "type" then
				if subValue == nil then
					gbd("n=" .. itemName .. ", f=" .. tostring(filterValue) .. ", x=" .. tostring(classID))
					return tonumber(filterValue) == tonumber(classID)
				else
					gbd("n=" .. itemName .. ", f=" .. tostring(filterValue) .. ", x=" .. tostring(classID) .. ", s=" .. tostring(subClassID))
					return tonumber(filterValue) == tonumber(classID) and tonumber(subValue) == tonumber(subClassID)
				end
			end
		end

		gbd("I have no idea what '" .. filterType .. "' means")
	else
		-- gbd need to handle other object types, see https://warcraft.wiki.gg/wiki/Hyperlinks
	end
	return false
end

local function gb_take(self,btn,arg)
	gbd(tostring(btn))
	-- do nothing if bank isn't open
	if not gb.banktype then gbp(gb.L.nobank) return end
	-- if gui was used, get the searchstring from editbox
	if btn then arg = gbf.e1:GetText() end
	if not gBankerDB.cs then arg = lower(arg) end
	local filterType, filterValue, subValue = arg2xpac(arg)
	if filterType == nil then return end
	local movenum = 0 -- just a counter
	if gb.banktype == BANKTYPE_GUILD then
		local tab = GetCurrentGuildBankTab()
		for slot=1,98 do
			if GetGuildBankItemInfo(tab,slot) then
				if includeItem(BANKTYPE_GUILD, tab, slot, filterType, filterValue, subValue) then
					movenum=movenum+1
					tinsert(gb.queue,{tab, slot})
				end
			end
		end
	elseif gb.banktype == BANKTYPE_PLAYER then
		if BankSlotsFrame:IsShown() then
			for bag = BANK_CONTAINER, Enum.BagIndex.BankBag_7 do
				if bag == BANK_CONTAINER or bag >= Enum.BagIndex.BankBag_1 then
					for slot=1,C_Container.GetContainerNumSlots(bag) do
						if C_Container.GetContainerItemInfo(bag,slot) then
							local doTake = includeItem(BANKTYPE_PLAYER, bag, slot, filterType, filterValue, subValue)
							if doTake then
								gbd(" taking!")
								movenum=movenum+1
								C_Container.UseContainerItem(bag,slot)
							end
						end
					end
				end
			end
		elseif ReagentBankFrame:IsShown() then
			for slot=1, C_Container.GetContainerNumSlots(Enum.BagIndex.Reagentbank) do
				if C_Container.GetContainerItemInfo(Enum.BagIndex.Reagentbank, slot) then
					local doTake = includeItem(BANKTYPE_PLAYER, Enum.BagIndex.Reagentbank, slot, filterType, filterValue, subValue)
					if doTake then
						gbd(" taking!")
						movenum=movenum+1
						C_Container.UseContainerItem(Enum.BagIndex.Reagentbank,slot)
					end
				end
			end
		else -- Warband
			for tabOffset = 0, C_Bank.FetchNumPurchasedBankTabs(Enum.BankType.Account) do
				local tabID = Enum.BagIndex.AccountBankTab_1 + tabOffset
				for slot=1, C_Container.GetContainerNumSlots(tabID) do
					if C_Container.GetContainerItemInfo(tabID, slot) then
						local doTake = includeItem(BANKTYPE_PLAYER, tabID, slot, filterType, filterValue, subValue)
						if doTake then
							gbd(" taking!")
							movenum=movenum+1
							C_Container.UseContainerItem(tabID, slot)
						end
					end
				end
			end
		end

	end
	gbp(gb.L.taking..movenum..gb.L.items)
	gb_queue(COMMAND_TAKE)
end

local function gb_give(self,btn,arg)
	gbd(tostring(btn))
	-- do nothing if bank isn't open
	if not gb.banktype then gbp(gb.L.nobank) return end
	-- if gui was used, get the searchstring from editbox
	if btn then arg = gbf.e1:GetText() end
	if not gBankerDB.cs then arg = lower(arg) end
	local filterType, filterValue, subValue = arg2xpac(arg)
	if filterType == nil then return end
	local movenum = 0
	for bag = BACKPACK_CONTAINER, Enum.BagIndex.ReagentBag do
		for slot=1, C_Container.GetContainerNumSlots(bag) do
			if C_Container.GetContainerItemInfo(bag,slot) then
				if includeItem(BANKTYPE_PLAYER, bag, slot, filterType, filterValue, subValue) then
					movenum=movenum+1
					if gb.banktype == BANKTYPE_GUILD then
						tinsert(gb.queue,{bag, slot})
					elseif gb.banktype == BANKTYPE_PLAYER then
						C_Container.UseContainerItem(bag,slot,"none", Enum.BankType.Character, ReagentBankFrame:IsShown())
					end
				end
			end
		end
	end
	gbp(gb.L.giving..movenum..gb.L.items)
	gb_queue(COMMAND_GIVE)
end

local function gb_setquickbutton(src,index)
	if not src:find(";") then
		gBankerDB.quicklist[index] = src
		gbf2["b"..index]:SetText(gBankerDB.quicklist[index])
	else
		gBankerDB.quicklist[index] = {}
		for key in src:gmatch(";?.-;") do
			tinsert(gBankerDB.quicklist[index],(key:gsub(";","")))
		end		
		gbf2["b"..index]:SetText(gBankerDB.quicklist[index][1])
	end
end

local function gb_quickbutton(self,btn)
	gbd(tostring(self).."  "..tostring(self:GetName()).."  "..tostring(gsub(self:GetName(),"gBankerQuickButton","")))
	local listindex = tonumber((gsub(self:GetName(),"gBankerQuickButton","")))
	local arg = gBankerDB.quicklist[listindex]
	gbd(arg)
	if arg[1] then
		for i=2,#arg do
			if btn == "LeftButton" then
				gb_take(nil,nil,arg[i])
			elseif btn == "RightButton" then
				gb_give(nil,nil,arg[i])
			end
		end
	else
		if arg == "" and gbf.e1:GetText() ~= "" then
			gb_setquickbutton(gbf.e1:GetText(),listindex)
		end
		if arg ~= "" then
			if btn == "LeftButton" then
				gb_take(nil,nil,arg)
			elseif btn == "RightButton" then
				gb_give(nil,nil,arg)
			end
		end
	end
end

-- blacklist function
local function gb_blist(self,btn,arg)
	gbd(tostring(btn))
	if btn == "LeftButton" or btn == "RightButton" then arg = gbf.e1:GetText() end
	arg = lower(arg)
	if arg == "" then arg = nil end
	if btn == "LeftButton" or btn == "a" or btn == "add" or btn == "" then
		if arg then
			gBankerDB.blacklist[arg] = true
			gbp(gb.L.added..arg..gb.L.toblist)
		else
			local list = ""
			for k,_ in pairs(gBankerDB.blacklist) do
				list = list..", "..k
			end
			gbp(gb.L.blist..gsub(list,", ","",1))
		end
	elseif btn == "RightButton" or btn == "r" or btn == "remove" then
		if arg then
			gBankerDB.blacklist[arg] = nil
			gbp(gb.L.removed..arg..gb.L.fromblist)
		end
	end
end

-- delete quickbutton text
local function quickdelete(self,nr)
	gbd(self:GetName())
	gBankerDB.quicklist[nr] = ""
	gbf2["b"..nr]:SetText("")
end

-- func for creating quickbuttons
local qbposx = {35,100,[0]=165}
local function createquickbutton(i)
	gbf2["b"..i] = CreateFrame("Button","gBankerQuickButton"..i,gbf2,"OptionsListButtonTemplate")
	gbf2["b"..i]:SetHeight(18)
	gbf2["b"..i]:SetWidth(60)
	gbf2["b"..i]:SetPoint("CENTER",gbf2,"TOPLEFT",qbposx[i%3],7-(ceil(i/3)*20))
	gbf2["b"..i]:SetFrameStrata("HIGH")
	gBankerDB.quicklist[i] = gBankerDB.quicklist[i] or ""
	gbf2["b"..i]:SetText(gBankerDB.quicklist[i][1] or gBankerDB.quicklist[i])
	gbf2["b"..i]:RegisterForClicks("LeftButtonUp","RightButtonUp")
	gbf2["b"..i]:SetScript("OnClick",gb_quickbutton)
end

-- change num of QBs and framesize
local function changequickbuttons(n)
	gbf2:SetHeight(5 + ceil(n/3)*20)
	if gBankerDB.quicknum > n then
		for i=n+1, gBankerDB.quicknum do
			gbf2["b"..i]:Hide()
		end
	gBankerDB.quicknum = n
	elseif n > gBankerDB.quicknum then
		for i=gBankerDB.quicknum+1, n do
			if gbf2["b"..i] then
				gbf2["b"..i]:Show()
			else
				createquickbutton(i)
			end
		end
	gBankerDB.quicknum = n
	end
end

-- create gui buttons
local function createbuttons()
	gbd("creating buttons...")
	-- take
	gbf.b1 = CreateFrame("Button",nil,gbf,"OptionsListButtonTemplate")
	gbf.b1:SetHeight(18)
	gbf.b1:SetWidth(50)
	gbf.b1:SetPoint("CENTER",gbf,"CENTER",-65,-20)
	gbf.b1:SetFrameStrata("HIGH")
	gbf.b1:SetText(gb.L.t)
	gbf.b1:SetScript("OnClick",gb_take)
	-- give
	gbf.b2 = CreateFrame("Button",nil,gbf,"OptionsListButtonTemplate")
	gbf.b2:SetHeight(18)
	gbf.b2:SetWidth(50)
	gbf.b2:SetPoint("CENTER",gbf,"CENTER",-0,-20)
	gbf.b2:SetFrameStrata("HIGH")
	gbf.b2:SetText(gb.L.g)
	gbf.b2:SetScript("OnClick",gb_give)
	-- blacklist
	gbf.b3 = CreateFrame("Button",nil,gbf,"OptionsListButtonTemplate")
	gbf.b3:SetHeight(18)
	gbf.b3:SetWidth(50)
	gbf.b3:SetPoint("CENTER",gbf,"CENTER",65,-20)
	gbf.b3:SetFrameStrata("HIGH")
	gbf.b3:SetText(gb.L.bl)
	gbf.b3:RegisterForClicks("LeftButtonUp","RightButtonUp")
	gbf.b3:SetScript("OnClick",gb_blist)
	-- editbox
	gbf.e1 = CreateFrame("EditBox",nil,gbf,"InputBoxTemplate")
	gbf.e1:SetPoint("CENTER",gbf,"CENTER",0,0)
	gbf.e1:SetFrameStrata("HIGH")
	gbf.e1:SetHeight(18)
	gbf.e1:SetWidth(180)
	gbf.e1:SetAutoFocus(false)
	gbf.e1:SetScript("OnEnterPressed",function() gbf.e1:ClearFocus() end)
	-- close
	gbf.c = CreateFrame("Button",nil,gbf,"UIPanelCloseButton")
	gbf.c:SetPoint("TOPRIGHT",0,0)
	gbf.c:SetHeight(28)
	gbf.c:SetWidth(28)
	gbf.c:SetScript("OnClick", function() gbf:SetScript("OnUpdate",nil) gbf:Hide() end)
	-- options dropdown menu
	gbf.options = function(self,level)
		level = level or 1
		if level == 1 then
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.css
			info.checked = gBankerDB.cs
			info.func = toggleoption
			info.arg1 = "cs"
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.aob
			info.checked = gBankerDB.autoopenb
			info.func = toggleoption
			info.arg1 = "autoopenb"
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.aog
			info.checked = gBankerDB.autoopeng
			info.func = toggleoption
			info.arg1 = "autoopeng"
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.silent
			info.checked = gBankerDB.silent
			info.func = toggleoption
			info.arg1 = "silent"
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.sqb
			info.checked = gBankerDB.quick
			info.func = toggleoption
			info.arg1 = "quick"
			info.hasArrow = true
			info.value = "quick"
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
		elseif level == 2 then
			local info = UIDropDownMenu_CreateInfo()
			info.text = gb.L.qbhelp
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)
			local info = UIDropDownMenu_CreateInfo()
			info.isTitle = true
			info.text = gb.L.cqb
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)
			if UIDROPDOWNMENU_MENU_VALUE == "quick" then
				for i=1,gBankerDB.quicknum do
					if gBankerDB.quicklist[i] ~= "" then
						local info = UIDropDownMenu_CreateInfo()
						info.text = gBankerDB.quicklist[i][1] or gBankerDB.quicklist[i]
						info.notCheckable = true
						info.func = quickdelete
						info.arg1 = i
						info.isNotRadio = true
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end
	end
	-- dropdown
	gbf.dropdown = CreateFrame("Frame","gBankerDropdownMenu",UIParent,"UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(gbf.dropdown,gbf.options,"MENU")
	local calloptions = function()
		ToggleDropDownMenu(1,nil,gbf.dropdown,gbf.b4,0,0)
	end
	-- options
	gbf.b4 = CreateFrame("Button",nil,gbf,"OptionsListButtonTemplate")
	gbf.b4:SetHeight(18)
	gbf.b4:SetWidth(50)
	gbf.b4:SetPoint("CENTER",gbf,"CENTER",45,20)
	gbf.b4:SetFrameStrata("HIGH")
	gbf.b4:SetText("Opt.")
	gbf.b4:SetScript("OnClick",calloptions)
	-- quickbuttons
	for i=1,gBankerDB.quicknum do
		createquickbutton(i)
	end
	gbf2:SetHeight(5 + ceil(gBankerDB.quicknum/3)*20)
	-- don't create again
	buttonsexist = true
end

-- event handling
gbf:SetScript("OnEvent",function(s,e,a)
	if e == EVENT_ADDON_LOADED and a == "gBanker" then
		gbf:UnregisterEvent(EVENT_ADDON_LOADED)
		gbd(e .. " fired")
		-- set defaults
		gBankerDB = gBankerDB or {
			["version"] = currentversion,
			["blacklist"] = {
			},
			["wishlist"] = {},
			["cs"] = false,
			["autoopenb"] = false,
			["autoopeng"] = true,
			["quick"] = true,
			["quicknum"] = 6,
			["quicklist"] = {
				[1] = "",
				[2] = "",
				[3] = "",
				[4] = "",
				[5] = "",
				[6] = "",
			},
			["silent"] = false,
			["wait"] = 0.4,
		}
		-- update message
		if gBankerDB.version < currentversion then
			gbp(gb.L.updv..currentversion)
		end
		-- actual updates
		if gBankerDB.version < 3 then
			gBankerDB.version = 3
			gBankerDB.cs = false
			for i,s in pairs(gBankerDB.blacklist) do
				gBankerDB.blacklist[lower(i)] = s
				gBankerDB.blacklist[i] = nil
			end
		end
		if gBankerDB.version < 5 then
			gBankerDB.autoopenb = false
			gBankerDB.autoopeng = true
			gBankerDB.version = 5
		end
		if gBankerDB.version < 6 then
			gBankerDB.quick = true
			gBankerDB.quicklist = {
				[1] = "",
				[2] = "",
				[3] = "",
				[4] = "",
				[5] = "",
				[6] = "",
			}
			gBankerDB.version = 6
		end
		if gBankerDB.version < 7 then
			gBankerDB.quicknum = 6
			gBankerDB.version = 7
		end
		if gBankerDB.version < 9 then
			gBankerDB.silent = false
			gBankerDB.version = 9
		end
		if gBankerDB.version < 11 then
			gBankerDB.wait = 0.4
			gBankerDB.version = 11
		end
		if gBankerDB.version < currentversion then
			gBankerDB.version = currentversion
		end
		-- init values that depend on savedvar
		gb.wait = gBankerDB.wait
		if gBankerDB.quick == true then
			gbf2:Show()
		else
			gbf2:Hide()
		end
	elseif e == EVENT_PLAYER_INTERACTION_MANAGER_FRAME_SHOW and a == BANKTYPE_GUILD then
		gb.banktype = BANKTYPE_GUILD
		if gBankerDB.autoopeng then
			scangbank()
			if not buttonsexist then createbuttons() end
			gbf:Show()
		end
	elseif e == EVENT_PLAYER_INTERACTION_MANAGER_FRAME_HIDE and a == BANKTYPE_GUILD then
		gb.banktype = BANKTYPE_NONE
		gbf:SetScript("OnUpdate",nil)
		gbf:Hide()
	elseif e == EVENT_PLAYER_INTERACTION_MANAGER_FRAME_SHOW and a == BANKTYPE_PLAYER then
		gb.banktype = BANKTYPE_PLAYER
		if gBankerDB.autoopenb then
			if not buttonsexist then createbuttons() end
			gbf:Show()
		end
	elseif e == EVENT_PLAYER_INTERACTION_MANAGER_FRAME_HIDE and a == BANKTYPE_PLAYER then
		gb.banktype = BANKTYPE_NONE
		gbf:SetScript("OnUpdate",nil)
		gbf:Hide()
	elseif e == EVENT_UNIT_INVENTORY_CHANGED then
		if gb.move_state == MOVE_STATE_MOVE and a == "player" then
			gb.move_state = MOVE_STATE_INV_UPDATE
		end
	elseif e == EVENT_BAG_UPDATE_DELAYED then
		if gb.move_state == MOVE_STATE_INV_UPDATE then
			gb.move_state = MOVE_STATE_BAG_UPDATE_DELAYED
		end

		if gb.move_state == MOVE_STATE_BAG_UPDATE_DELAYED then
			C_Timer.After(0.5, function()
				gb_queue(gb.queue_command)
			end)
		end
	end
end)

-- slashcommands
SLASH_GBANKER1, SLASH_GBANKER2 = '/gb', '/gbanker'
function SlashCmdList.GBANKER(msg)
	local a,n,b = msg:match("(%S*)%s*(%d*[,%.]?%d*)%s*(.*)")
	a = lower(a)
	if a == COMMAND_TAKE or a == COMMAND_TAKE_SHORT then
		if not gBankerDB.cs then b = lower(b) end
		gb_take(nil,nil,b)
	elseif a == COMMAND_GIVE or a == COMMAND_GIVE_SHORT then
		if not gBankerDB.cs then b = lower(b) end
		gb_give(nil,nil,b)
	elseif a == COMMAND_BLACKLIST or a == COMMAND_BLACKLIST_SHORT then
		b = lower(b)
		b,c = b:match("(%S*)%s*(.*)")
		gb_blist(nil,b,c)
	elseif a == COMMAND_QUICK or a == COMMAND_QUICK_SHORT then
		if n then
			n = tonumber(n)
			gb_setquickbutton(b,n)
		end
	elseif a == COMMAND_CASE or a == COMMAND_CASE_SHORT then
        gBankerDB.cs = gBankerDB.cs == false and true
        gbp(gb.L.css .. ": " .. (gBankerDB.cs and gb.L.on or gb.L.off))
	elseif a == COMMAND_QUICKNUM then
		if n then
			n = tonumber(n)
			if n > 0 then
				changequickbuttons(n)
			else
				gbp(gb.L.qb0)
			end
		end
	elseif a == "" then
		if not buttonsexist then createbuttons() end
		gbf:Show()
	elseif a == COMMAND_HELP or a == gb.L.helpkey then
		print(gb.L.help1..gBankerDB.version..gb.L.help2)
		for i=1, #gb.L.help do
			print(gb.L.help[i])
		end
	elseif a == COMMAND_DELAY or a == COMMAND_WAIT or a == COMMAND_DELAY_SHORT or a == COMMAND_WAIT_SHORT then
		if n then
			if n:find(",") then
				n = n:gsub(",",".")
			end
			n = tonumber(n)
			gBankerDB.wait = n
			gb.wait = n
		else
			n = gBankerDB.wait
		end
		gbp(gb.L.delay..n.." "..SECONDS)
	else
		gbp(gb.L.unknown1.." |cffff7700/gb "..gb.L.helpkey.."|r"..gb.L.unknown2)
	end
end