function OnPlayerBuild(player, x, y, tile)
	return player:HasFeature("view_rcon") and 1 or 0
end