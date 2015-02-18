function OnPlayerDie(player, killer, reason)
	for i=1,#COMPUTERS_LIST do
		if (COMPUTERS_LIST[i].os.player and COMPUTERS_LIST[i].os.player:GetID() == player:GetID()) then
			COMPUTERS_LIST[i]:Hibernate()
		end
	end
end