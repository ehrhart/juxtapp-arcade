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

function OnInit()
	math.randomseed(os.time())
	DB.load("players.db")
	
	local cp = Computer(34, 63)
	table.insert(COMPUTERS_LIST, cp)
	cp:Boot()
end