function OnServerTick(ticks)
	utils_OnServerTick(ticks)
	for i=1,#COMPUTERS_LIST do
		COMPUTERS_LIST[i]:Update(ticks)
	end
end