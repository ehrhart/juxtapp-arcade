require("juxtappUtils")
require("chatCommands")
require("events")
DB = require("db")
require("system")

COMPUTERS_LIST = {}

function LoadPlayer(player)
	if (not player) then return end
	if (not player:IsPlaying()) then return end
	local defaultInfos = {
		coins = 0,
		health = 0,
		x = 0,
		y = 0,
	}
	local pInfos = table.extend(defaultInfos, DB.get(player:GetName(), "players.db") or {})
	print(DB.dump(pInfos))
	player:SetNumber("coins", pInfos["coins"])
end

function SavePlayer(player)
	if (not player) then return end
	if (not player:IsPlaying()) then return end
	DB.set(player:GetName(), {
		coins = player:GetNumber("coins"),
		health = player:GetHealth(),
		x = player:GetX(),
		y = player:GetY(),
	}, "players.db")
	DB.save("players.db")
end

function HandlePlayer(player, ticks)
	player:SetScore(math.floor(player:GetIdleTime()/30))
end

function OnUnload()
	for i=1,KAG.GetPlayersCount() do
		SavePlayer(KAG.GetPlayerByIndex(i))
	end
end

function AddComputer(x, y)
	local c = Computer:new(x, y)
	table.insert(COMPUTERS_LIST, c)
	c:Boot()
end

function OnInit()
	math.randomseed(os.time())
	DB.load("players.db")
	
	AddComputer(9,20)
	AddComputer(47,20)
	AddComputer(85,20)
	AddComputer(123,20)
	
	AddComputer(9,43)
	AddComputer(47,43)
	AddComputer(85,43)
	AddComputer(123,43)
	
	KAG.CreateChatCommand("/p", cmd_Pause)
	KAG.CreateChatCommand("/P", cmd_Pause)
	KAG.CreateChatCommand("/player", cmd_SetPlayer)
	KAG.CreateChatCommand("/boot", cmd_Boot)
	KAG.CreateChatCommand("/login", cmd_Login)
	KAG.CreateChatCommand("/logout", cmd_Logout)
	KAG.CreateChatCommand("/debug", cmd_Debug)
	KAG.CreateChatCommand("/load", cmd_Load)
	KAG.CreateChatCommand("/games", cmd_Games)
end

function cmd_Games(player, message)
	player:SendMessage("Games available: snake, tetris")
end

function cmd_Load(player, message)
	--if (not player:HasFeature("view_rcon")) then return end
	local args = string.split(message, " ")
	if (args[2]) then
		for i=1,#COMPUTERS_LIST do
			if (COMPUTERS_LIST[i].os.player and COMPUTERS_LIST[i].os.player:GetID() == player:GetID()) then
				COMPUTERS_LIST[i].os:LoadGame(args[2], true)
			end
		end
	end
end

function cmd_Pause(player, message)
	for i=1,#COMPUTERS_LIST do
		if (COMPUTERS_LIST[i].os.player and COMPUTERS_LIST[i].os.player:GetID() == player:GetID()) then
			COMPUTERS_LIST[i].os.running = not COMPUTERS_LIST[i].os.running
		end
	end
end

function cmd_SetPlayer(player, message)
	if (not player:HasFeature("view_rcon")) then return end
	local args = string.split(message, " ")
	if (args[2] and args[3]) then
		local index = tonumber(args[2])
		COMPUTERS_LIST[index]:SwitchPlayer(KAG.GetPlayerByPartialName(args[3]))
	elseif (args[2]) then
		local index = tonumber(args[2])
		COMPUTERS_LIST[index]:SwitchPlayer(player)
	end
end

function cmd_Login(player, message)
	local found = false
	for i=1,#COMPUTERS_LIST do
		if (COMPUTERS_LIST[i].os.player == nil) then
			COMPUTERS_LIST[i]:SwitchPlayer(player)
			found = true
			break
		end
	end
	if (not found) then
		player:SendMessage("It looks like there's no computers available :-(")
	end
end

function cmd_Logout(player, message)
	for i=1,#COMPUTERS_LIST do
		if (COMPUTERS_LIST[i].os.player and COMPUTERS_LIST[i].os.player:GetID() == player:GetID()) then
			COMPUTERS_LIST[i]:Hibernate()
			player:ForcePosition(player:GetX(), (KAG.GetMapHeight()+8)*8)
		end
	end
end

function cmd_Boot(player, message)
	if (not player:HasFeature("view_rcon")) then return end
	local args = string.split(message, " ")
	if (args[2]) then
		local index = tonumber(args[2])
		local cp = COMPUTERS_LIST[index]
		cp:Boot()
	end
end

function cmd_Debug(player, message)
	if (not player:HasFeature("view_rcon")) then return end
	local args = string.split(message, " ")
	if (not args[2]) then return end
	local index = tonumber(args[2])
	COMPUTERS_LIST[index].os.debug = not COMPUTERS_LIST[index].os.debug
end