local LCS = require("class")

Computer = LCS.class{
	x = 0,
	y = 0,
	booted = false,
	os = nil,
}

function Computer:init(x, y)
	self.x = x
	self.y = y
	
	local screenWidth, screenHeight = 32, 16
	self.screen = {
		x = self.x,
		y = self.y - screenHeight,
		width = screenWidth,
		height = screenHeight,
	}
	
	local gamepadWidth, gamepadHeight = 2, 2
	self.gamepad = {
		x = self.screen.x + math.floor(self.screen.width/2)-math.ceil(gamepadWidth/2),
		y = self.screen.y + self.screen.height + 1,
		width = gamepadWidth,
		height = gamepadHeight,
	}
	self.gamepad.spawn = {
		x = self.gamepad.x + 1.5,
		y = self.gamepad.y + 1.5,
	}
end

function Computer:Boot()
	local fos = FOS()
	if (not fos) then
		error("BSOD: Computer could not boot OS")
		return
	end
	
	self:SetOperatingSystem(fos)
	
	-- Draw border around screen
	for x=0,self.screen.width+1 do
		KAG.PushTile(self.screen.x+x, self.screen.y, Blocks.CASTLE_WALL)
		KAG.PushTile(self.screen.x+x, self.screen.y+self.screen.height+1, Blocks.CASTLE_WALL)
	end
	for y=0,self.screen.height+1 do
		KAG.PushTile(self.screen.x, self.screen.y+y, Blocks.CASTLE_WALL)
		KAG.PushTile(self.screen.x+self.screen.width+1, self.screen.y+y, Blocks.CASTLE_WALL)
	end
	
	-- Draw screen
	self.os:DrawRectangle(1, 1, self.screen.width, self.screen.height, Blocks.WOODEN_BACK)
	
	-- Draw gamepad
	for x=0,self.gamepad.width+1 do
		--KAG.PushTile(self.gamepad.x+x, self.gamepad.y, Blocks.CASTLE_WALL)
		KAG.PushTile(self.gamepad.x+x, self.gamepad.y+self.gamepad.height+1, Blocks.CASTLE_WALL)
	end
	for y=0,self.gamepad.height+1 do
		KAG.PushTile(self.gamepad.x, self.gamepad.y+y, Blocks.CASTLE_WALL)
		KAG.PushTile(self.gamepad.x+self.gamepad.width+1, self.gamepad.y+y, Blocks.CASTLE_WALL)
	end
	
	self.os:LoadGame("snake")
	
	self.booted = true
end

function Computer:SetOperatingSystem(ops)
	self.os = ops
	self.os:SetScreen(self.screen)
	self.os:SetGamepad(self.gamepad)
end

function Computer:Update(ticks)
	if (not self.os) then
		return
	end
	self.os:Update(ticks)
end

FOS = LCS.class{
	screen = nil,
	gamepad = nil,
	utils = {
		los = function(x0,y0,x1,y1, callback)
			local sx,sy,dx,dy

			if x0 < x1 then
			sx = 1
			dx = x1 - x0
			else
			sx = -1
			dx = x0 - x1
			end

			if y0 < y1 then
			sy = 1
			dy = y1 - y0
			else
			sy = -1
			dy = y0 - y1
			end

			local err, e2 = dx-dy, nil

			if not callback(x0, y0) then return false end

			while not(x0 == x1 and y0 == y1) do
			e2 = err + err
			if e2 > -dy then
			err = err - dy
			x0  = x0 + sx
			end
			if e2 < dx then
			err = err + dx
			y0  = y0 + sy
			end
			if not callback(x0, y0) then return false end
			end

			return true
		end,
		line = function(x0,y0,x1,y1,callback)
				local points = {}
				local count = 0
				local result = los(x0,y0,x1,y1, function(x,y)
					if callback and not callback(x,y) then return false end
						count = count + 1
						points[count] = {x,y}
						return true
				end)
					return points, result
		end,
	},
	buffer = {},
	bufferQueue = {},
	player = nil,
	running = true
}

function FOS:init()
	KAG.CreateChatCommand("/point", cmd_Point)
	KAG.CreateChatCommand("/clear", cmd_Clear)
	KAG.CreateChatCommand("/pause", cmd_Pause)
	KAG.CreateChatCommand("/player", cmd_SetPlayer)
end
function cmd_Point(player, message)
	local args = string.split(message, " ")
	if (args[2] and args[3] and args[4]) then
		local x, y, b = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
		COMPUTERS_LIST[1].os:DrawPoint(x, y, b)
		player:SendMessage("Drawing point " .. b .. " at " .. x .. ":" .. y)
	end
end
function cmd_Clear(player, message)
	local args = string.split(message, " ")
	local b = Blocks.WOODEN_BACK
	COMPUTERS_LIST[1].os:Clear(b)
	player:SendMessage("Clearing screen with block " .. b)
end
function cmd_Pause(player, message)
	COMPUTERS_LIST[1].os.running = not COMPUTERS_LIST[1].os.running
end
function cmd_SetPlayer(player, message)
	local args = string.split(message, " ")
	if (args[2]) then
		COMPUTERS_LIST[1].os:SwitchPlayer(KAG.GetPlayerByPartialName(args[2]))
	else
		COMPUTERS_LIST[1].os:SwitchPlayer(player)
	end
end

function FOS:SetScreen(s)
	self.screen = s
	for x=1,self.screen.width do
		self.buffer[x] = {}
		for y=1,self.screen.height do
			self.buffer[x][y] = Blocks.AIR
		end
	end
end

function FOS:SetGamepad(g)
	print("SetGamepad")
	self.gamepad = g
end

function FOS:SwitchPlayer(player)
	print("SwitchPlayer")
	if (not player) then
		error("SwitchPlayer: player is nil")
	end
	self.player = player
	
	if (self.gamepad) then
		self.player:ForcePosition(self.gamepad.spawn.x*8, self.gamepad.spawn.y*8)
	end
end

function FOS:DrawLine(x1, y1, x2, y2, b)
	-- TODO: bresenham algorithm?
	self:DrawRectangle(x1, y1, x2, y2, b)
end

function FOS:DrawRectangle(x1, y1, x2, y2, b)
	for x=x1, x2 do
		for y=y1, y2 do
			table.insert(self.bufferQueue, {x=x,y=y,b=b})
		end
	end
end

function FOS:DrawRectangleOutlined(x1, y1, x2, y2, b, b2)
	self:DrawLine(x1, y1, x2, y1, b) -- top
	self:DrawLine(x1, y2, x2, y2, b) -- bottom
	self:DrawLine(x1, y1, x1, y2, b) -- left
	self:DrawLine(x2, y1, x2, y2, b) -- right
	if (type(b2) == "number") then
		self:DrawRectangle(x1+1, y1+1, x2-1, y2-1, b2) -- inside
	end
end

function FOS:Clear(b)
	for x=1,#self.buffer do
		for y=1,#self.buffer[x] do
			if (self.buffer[x][y] ~= b) then
				self:DrawPoint(x, y, b)
				--print("Clearing " .. x .. ":" .. y)
			end
		end
	end
end

function FOS:DrawPoint(x, y, b)
	if (type(x) ~= "number") then error("(DrawPoint) x is not a number (" .. type(x) .. ")") end
	if (type(y) ~= "number") then error("(DrawPoint) y is not a number (" .. type(y) .. ")") end
	if (type(b) ~= "number") then error("(DrawPoint) b is not a number (" .. type(b) .. ")") end
	--print("DrawPoint("..x..","..y..","..b..")")
	if (not x or not y or not b) then return end
	table.insert(self.bufferQueue, {x=x,y=y,b=b})
end

function FOS:Update(ticks)
	if (self.game and self.running) then
		self.game:Update(ticks)
	end
end

function FOS:Display()
	-- TODO: optimize
	local newPixels = {}
	for i=1,#self.bufferQueue do
		local p = table.remove(self.bufferQueue, 1)
		if (not newPixels[p.x]) then newPixels[p.x] = {} end
		newPixels[p.x][p.y] = p.b
	end
	for k,v in pairs(newPixels) do
		for k2,v2 in pairs(v) do
			if (self.buffer[k][k2] ~= newPixels[k][k2]) then
				--print("Push tile " .. newPixels[k][k2] .. " at " .. k .. ":" .. k2)
				KAG.PushTile(self.screen.x+k, self.screen.y+k2, newPixels[k][k2])
				self.buffer[k][k2] = newPixels[k][k2]
			end
		end
	end
end

function FOS:LoadGame(gameName)
	self.game = dofile(Plugin.GetPath() .. "/data/games/" .. gameName .. "/init.lua")
	self.game:Load(self)
	
	--TODO: move this
	self:SwitchPlayer(KAG.GetPlayerByName("master4523"))
end

function FOS:IsKeyDown(key)
	if (not self.player) then return false end
	return self.player:IsKeyDown(key)
end