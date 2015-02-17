function cmd_Position(player, message)
	local args = string.split(message, " ")
	if (args[2] ~= nil and args[2] ~= "@me") then
		local target = KAG.GetPlayerByPartialName(args[2])
		if (target) then
			player:SendMessage("The position of " .. target:GetName() .. " is " .. math.floor(target:GetX()) .. ":" .. math.floor(target:GetY()) .. " (" .. math.floor(target:GetX()/8) .. ":" .. math.floor(target:GetY()/8) .. ")")
		else
			player:SendMessage("Target not found")
		end
	else
		player:SendMessage("Your position is " .. math.floor(player:GetX()) .. ":" .. math.floor(player:GetY()) .. " (" .. math.floor(player:GetX()/8) .. ":" .. math.floor(player:GetY()/8) .. ")")
	end
end

KAG.CreateChatCommand("/pos", cmd_Position)