function OnPlayerRespawn(player)
	if (not player:GetBoolean("firstSpawn")) then
		player:SetBoolean("firstSpawn", true)
		cmd_Login(player, "") -- TODO: remove this dirty hack
	end
	player:SendMessage("Help: do /login to join a computer, or /logout to leave. If you want to pause or unpause the game, then do /p")
	player:SendMessage("To load a game, do /load <game name>")
	player:SendMessage("For a full list of available games: do /games")
end