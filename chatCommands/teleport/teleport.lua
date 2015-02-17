function cmd_Teleport(player, message)
	if (not player:HasFeature("teleport")) then
		player:SendMessage("You do not have access to that command!")
		return
	end
	if (player:IsDead()) then
		player:SendMessage("You cannot use this command while you're dead!")
		return
	end
	local args = string.split(message, " ")
	if (not args[2]) then return end
	local targets = {}
	if (string.lower(args[2]) == "@all") then
		if (not player:HasFeature("teleport_all")) then
			player:SendMessage("You're not allowed to use @all for this command")
			return
		end
		for i=1,KAG.GetPlayersCount() do
			local p = KAG.GetPlayerByIndex(i)
			if (p:GetID() ~= player:GetID()) then
				table.insert(targets, p:GetID())
			end
		end
	elseif (string.lower(args[2]) == "@me") then
		table.insert(targets, player:GetID())
	else
		local ps = KAG.GetPlayersByPartialName(args[2])
		if (#ps == 0) then
			player:SendMessage("Target not found")
			return
		else
			for i=1, #ps do
				if (not ps[i]:IsDead()) then
					table.insert(targets, ps[i]:GetID())
				end
			end
		end
	end
	if (#targets == 0) then
		player:SendMessage("No targets to teleport")
		return
	end
	-- Check for a second target
	local t2 = nil
	if (args[3]) then
		if (not player:HasFeature("teleport_target")) then
			player:SendMessage("You're not allowed to teleport another target other than yourself")
			return
		end
		if (string.lower(args[3]) == "@me") then
			t2 = player
		elseif (string.lower(args[3]) == "@all") then
			player:SendMessage("Invalid second target: @all")
		else
			t2 = KAG.GetPlayerByPartialName(args[3])
		end
		-- Check if second target exists
		if (t2 == nil) then
			player:SendMessage("Second target not found")
			return
		end
		-- Check if second target is alive
		if (t2:IsDead()) then
			player:SendMessage("Second target is dead")
			return
		end
	end
	for i=1, #targets do
		local target = KAG.GetPlayerByID(targets[i])
		if (target ~= nil) then
			if (t2 ~= nil) then
				target:ForcePosition(t2:GetX(), t2:GetY())
			else
				-- No second target, teleport to the first target
				-- (it's actually an array of targets because of GetPlayersByPartialName, but we teleport to the first occurrence)
				player:ForcePosition(target:GetX(), target:GetY())
				break
			end
		end
	end
end

KAG.CreateChatCommand("/tp", cmd_Teleport)