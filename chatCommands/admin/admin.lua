function cmd_Admin(player, message)
	if (not player:HasFeature("view_rcon")) then
		player:SendMessage("You do not have access to that command!")
		return
	end
	local args = string.split(message, " ")
	if (args[2]) then
		if (args[2] == "save") then
			for i=1,KAG.GetPlayersCount() do
				SavePlayer(KAG.GetPlayerByIndex(i))
			end
			player:SendMessage("Players saved")
		elseif (args[2] == "mine:generate") then
			GenerateMine(0, 81, KAG.GetMapWidth(), KAG.GetMapHeight())
		elseif (args[2] == "mine:clean") then
			for x=0,10-1 do
				for y=0,85-75 do
					KAG.PushTile(x*8, y*8, Blocks.SPIKES)
				end
			end
			for x=0,10-1 do
				for y=0,85-75 do
					KAG.PushTile(x*8, y*8, Blocks.AIR)
				end
			end
		elseif (args[2] == "stuff") then
			player:SetWood(250)
			player:SetStone(250)
			player:SetGold(250)
			player:SetBombs(3)
		elseif (args[2] == "team") then
			player:SendMessage("Team: " .. player:GetTeam())
		elseif (args[2] == "cleanup") then
			local t = 0
			if (args[3]) then t = tonumber(args[3]) end
			for x=0,KAG.GetMapWidth()-1 do
				for y=82,0,-1 do
					KAG.PushTile(x*8,y*8,t)
				end
			end
		elseif (args[2] == "coins" and args[3]) then
			player:SetCoins(tonumber(args[3]))
		elseif (args[2] == "tile:get") then
			local t = 0
			if (args[3] and args[4]) then
				t = KAG.GetTile(tonumber(args[3]) or 0, tonumber(args[4]) or 0)
			else
				t = KAG.GetTile(player:GetX(), player:GetY())
			end
			player:SendMessage("Tile: " .. t)
		elseif (args[2] == "tile:set") then
			local x, y, t = 0, 0, 0
			if (args[3] and not args[4]) then
				t = tonumber(args[3]) or 0
				x = math.floor(player:GetX())
				y = math.floor(player:GetY())
			elseif (args[3] and args[4] and args[5]) then
				t = tonumber(args[3]) or 0
				x = tonumber(args[4]) or 0
				y = tonumber(args[5]) or 0
			else
				player:SendMessage("Wrong number of parameters")
				return
			end
			KAG.SetTile(x, y, t)
		elseif (args[2] == "dump:player") then
			if (args[3]) then
				local data = DB.fileData["players.db"]
				local s = string.lower(args[3])
				for k,v in pairs(data) do
					if (string.sub(string.lower(k), 1, string.len(s)) == s) then
						player:SendMessage("Dump of " .. k .. ": " .. DB.dump(v))
						break
					end
				end
			else
				player:SendMessage("Missing parameter")
			end
		elseif (args[2] == "dump:chunks") then
			player:SendMessage("Chunks: " .. #MAP_CHUNKS)
		elseif (args[2] == "dump:tiles") then
			player:SendMessage("Tiles Queue: " .. #TILES_QUEUE)
		elseif (args[2] == "grass:add") then
			KAG.WholeMap(function(tiles)
				for k,v in pairs(tiles) do
					local t = KAG.GetTile(v.x, v.y)
					local upT = KAG.GetTile(v.x, v.y-8)
					if (KAG.IsTileDirt(t) and upT == 0) then
						KAG.PushTile(v.x, v.y-8, 25)
					end
				end
			end, 0)
		elseif (args[2] == "grass:remove") then
			KAG.WholeMap(function(tiles)
				for k,v in pairs(tiles) do
					local t = KAG.GetTile(v.x, v.y)
					if (KAG.IsTileGrass(t)) then
						KAG.PushTile(v.x, v.y, 0)
					end
				end
			end, 0)
		elseif (args[2] == "gc:count") then
			player:SendMessage("Memory usage: " .. math.bytestosize(collectgarbage("count")))
		elseif (args[2] == "gc:collect") then
			collectgarbage()
			player:SendMessage("Garbage collected!")
		end
	end
end

KAG.CreateChatCommand("/admin", cmd_Admin)