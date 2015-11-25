--Main Frame
local Addon = CreateFrame("FRAME", "HolyWars");

--Mode: 1 = bg | 2 = arena | 3 = both
local mode = 3;

--Table of all battlegrounds and arenas available to Cataclysm
local PvPInstances = {};
--Battlegrounds
PvPInstances[0] = 	{name = "Warsong Gulch",          	number = 0};
PvPInstances[1] = 	{name = "Arathi Basin",           	number = 0};
PvPInstances[2] = 	{name = "Alterac Valley",         	number = 0};
PvPInstances[3] = 	{name = "Eye of the Storm",       	number = 0};
PvPInstances[4] = 	{name = "Strand of the Ancients", 	number = 0};
PvPInstances[5] = 	{name = "Isle of Conquest",    	 	number = 0};
PvPInstances[6] = 	{name = "Battle for Gilneas", 	   	number = 0};
PvPInstances[7] = 	{name = "Twin Peaks",           	number = 0};
--Arenas
PvPInstances[8] = 	{name = "Ring of Trials",			number = 0};
PvPInstances[9] = 	{name = "Circle of Blood",			number = 0};
PvPInstances[10] =	{name = "Ruins of Lordaeron",		number = 0};
PvPInstances[11] =	{name = "Ring of Valor",			number = 0};
PvPInstances[12] =	{name = "Dalaran Arena",  			number = 0};

-------------------------------------
--
-- Checks if player is queued (Arena or Battleground)
-- @return boolean
--
-------------------------------------
function isQueued()
	local queued = GetBattlefieldStatus(1);
	if (queued == "queued") then
		return true;
	end
	return false;
end


-- "i" (from iterator) will be used for PvPInstances table
local i = 0;

-------------------------------------
--
-- Searchs for players in PvP instances.
-- Opens the WhoList frame to receive SendWho function, then it closes.
-- Only one instance is "who'ed".
--
-------------------------------------
function getNextPvPInstancesData()
	local query = 'z-\"' .. PvPInstances[i].name .. '\"';
	FriendsMicroButton:Click();
	FriendsFrameTab2:Click();
	SendWho(query);
	FriendsFrameCloseButton:Click();
	
	i = i + 1;
end


-- "total" will be used in onUpdate function to see how much time has passed.
local total = 5;

-------------------------------------
--
-- OnUpdate event handler function.
-- It calls the getNextPvPInstancesData function. It also stops itself when all bgs/arenas are searched.
-- @param self: "Not used"
-- @param elapsed: how many seconds elapsed since the last frame
--
-------------------------------------
function onUpdate(self, elapsed)
	total = total + elapsed;

	if (total >= 5) then	--every 4 seconds, it makes a new search
		total = 0;
		if ( ((mode == 2 or mode == 3) and i == 13) or (mode == 1 and i == 8) ) then	--	search is done
			MiniMapBattlefieldIcon:SetTexture("Interface\\BattlefieldFrame\\Battleground-"..UnitFactionGroup("player")); -- return default icon
			MiniMapBattlefieldIcon:SetSize(32,32)
			BattlegroundShineFadeIn(); 					-- blizz function that creates that glow when button shows up
			Addon:SetScript("OnUpdate", nil);     		-- remove update until player queues again.
			Addon:UnregisterEvent("WHO_LIST_UPDATE");	-- unresgister event, no need to track who events after the search
			local totalPlayers = 0;
			for instance,_ in pairs(PvPInstances) do
				totalPlayers = totalPlayers + PvPInstances[instance].number;
			end
			if (totalPlayers == 0) then
				SendSystemMessage("HolyWars didn't find any players");
			else
				SendSystemMessage("HolyWars found " .. totalPlayers .. " players");
			end
		else			
			getNextPvPInstancesData();
		end
	end
end


-------------------------------------
--
-- Filter function.
-- It will look for "0 players total" messages (common message when you "/who" something and return 0 - E.g.: empty bg/arena)
-- @param self: "Not used"
-- @param event: "Not used"
-- @param msg: message that will be "tested"
-- @return boolean: if the msg can be shown
--
-------------------------------------
local function filterSystemMessages(self, event, msg)
	if (string.match(msg, '%d+') == "0") then		-- gets the number of the string
		return true;
	else
		return false;
	end
end


-------------------------------------
--
-- Create a new variable on the SV file
-- Default mode is 3 (bgs and arenas)
--
-------------------------------------
local function newVariables()
	HolyWarsSV[UnitName("Player")] = 3;		--1 = bg | 2 = arena | 3 = both
end


-------------------------------------
--
-- Main "function".
-- There are 3 events: "VARIABLES_LOADED", "UPDATE_BATTLEFIELD_STATUS" and "WHO_LIST_UPDATE"
-- "VARIABLES_LOADED": Triggers when the addOn loads (login/reload).
-- "UPDATE_BATTLEFIELD_STATUS": Triggers when you queue up or leave queue.
-- "WHO_LIST_UPDATE": Triggers when the client receives a result of a "/who"
--
-------------------------------------
Addon:SetScript("OnEvent", function(self, event, ...)
	if (event == "VARIABLES_LOADED" ) then
		SetWhoToUI(1);
		print("|TInterface\\FriendsFrame\\PlusManz-Horde:16|t |cFFFF0000H|cFFEE0022o|cFFDD0033l|cFFCC0044y|cFFBB0055W|cFFAA0066a|cFF990077r|cFF880088s |cFF770099L|cFF6600AAo|cFF5500BBa|cFF4400CCd|cFF3300DDe|cFF2200EEd|r |TInterface\\FriendsFrame\\PlusManz-Alliance:16|t");
		if type(HolyWarsSV) ~= "table" then
			HolyWarsSV = {}
			newVariables();
		end

		local found = 0
		for name,number in pairs(HolyWarsSV) do
			if UnitName("Player") == name then
				found = 1
				break
			end
		end
		if found == 0 then
			newVariables();
		end
		mode = HolyWarsSV[UnitName("Player")];
	elseif (event == "UPDATE_BATTLEFIELD_STATUS") then
		if( isQueued() ) then
			Addon:RegisterEvent("WHO_LIST_UPDATE");				-- register who event when the player queues up
			if ( UnitFactionGroup("player") == "Horde") then
				MiniMapBattlefieldIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Horde");
			else
				MiniMapBattlefieldIcon:SetTexture("Interface\\FriendsFrame\\PlusManz-Alliance");
			end
			MiniMapBattlefieldIcon:SetSize(25,25)
			if( mode == 1 or mode == 3) then
				i = 0;
			else -- ( mode == 2 ) then
				i = 8;
			end
			Addon:SetScript("OnUpdate", onUpdate);
			ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterSystemMessages)
			--  disable system messages
		else
			--  enable system messages -- return default icon
			MiniMapBattlefieldIcon:SetTexture("Interface\\BattlefieldFrame\\Battleground-"..UnitFactionGroup("player"));
			MiniMapBattlefieldIcon:SetSize(32,32)
			Addon:SetScript("OnUpdate", nil);
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", filterSystemMessages)			
		end
	elseif (event == "WHO_LIST_UPDATE" and isQueued()) then
		if ( i-1 ~= 13 ) then
			_, PvPInstances[i-1].number = GetNumWhoResults();
			FriendsFrameCloseButton:Click();	-- GetNumWhoResults() toggles who frame
			SendSystemMessage(PvPInstances[i-1].name .. ": There are " .. PvPInstances[i-1].number .. " players");		
		end
	end
end);


--List of all "starting" commands
SLASH_HolyWars1, SLASH_HolyWars2 = "/holywars", "/hw";

-------------------------------------
--
-- Slash commands function.
-- The commands are: bg, arena and both.
-- @param cmd: command that will be checked
--
-------------------------------------
function SlashCmd(cmd)
	if (cmd:match"bg") then
		mode = 1
		HolyWarsSV[UnitName("Player")] = 1
		print("|cFFFFFF00HolyWars |cFFFF8800is now searching only for players in Battlegrounds|r")
	elseif (cmd:match"arena") then
		mode = 2
		HolyWarsSV[UnitName("Player")] = 2
		print("|cFFFFFF00HolyWars |cFFFF8800is now searching only for players in Arenas|r")
	elseif (cmd:match"both") then
		mode = 3
		HolyWarsSV[UnitName("Player")] = 3
		print("|cFFFFFF00HolyWars |cFFFF8800is now searching for players in Arenas and Battlegrounds|r")
	else -- if (cmd:match"help")
		print("|cFFFFFF00To use commands you need to type \"/hw cmd\"|r");
		print("|cFFFFFF00HolyWars commands:|r")
		print("|cFFFFFF00\"hw bg\" - |cFFFF8800Only search for players in Battlegrounds|r")
		print("|cFFFFFF00\"hw arena\" - |cFFFF8800Only search for players in Arenas|r")
		print("|cFFFFFF00\"hw both\" - |cFFFF8800Search for players in Battlegrounds and Arenas|r")
	end
end

SlashCmdList["HolyWars"] = SlashCmd;



--Event Registers	
Addon:RegisterEvent("VARIABLES_LOADED");
Addon:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
--Addon:RegisterEvent("WHO_LIST_UPDATE")	-- event registered in functions