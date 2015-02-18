function OnPlayerRespawn(player)
	if (not player:GetBoolean("firstSpawn")) then
		player:SetBoolean("firstSpawn", true)
		cmd_Login(player, "") -- TODO: remove this dirty hack
	end
	player:SendMessage("Help: do /login to join a computer, or /logout to leave")
end