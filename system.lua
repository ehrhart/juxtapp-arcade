local class = require("middleclass")

Computer = class('Computer')
function Computer:initialize(x, y)
	self.booted = false
	self.os = nil
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
		x = self.gamepad.x + 2,
		y = self.gamepad.y + 2,
	}
end

function Computer:Boot()
	local fos = FOS:new()
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
	self.booted = true
	self.os:LoadGame("snake")
end

function Computer:SetOperatingSystem(ops)
	self.os = ops
	self.os:SetScreen(self.screen)
	self.os:SetGamepad(self.gamepad)
end

function Computer:Hibernate()
	if (self.os) then
		self.os.player = nil
		self.os.running = false
	end
end

function Computer:WakeUp()
	if (self.os) then
		self.os.running = true
	end
end

function Computer:SwitchPlayer(player)
	-- Remove the player from other computers
	if (player) then
		for i=1,#COMPUTERS_LIST do
			if (COMPUTERS_LIST[i].booted and COMPUTERS_LIST[i].os.player ~= nil and COMPUTERS_LIST[i].os.player:GetID() == player:GetID()) then
				COMPUTERS_LIST[i]:Hibernate()
			end
		end
	end
	-- Set the new player in the OS
	self.os.player = player
	-- Change the status of the OS (running or not)
	if (not player) then
		self.os.running = false
	else
		self.os.running = true
		-- Teleport the player to the gamepad
		if (self.gamepad) then
			self.os.player:ForcePosition(self.gamepad.spawn.x*8, self.gamepad.spawn.y*8)
		end
	end
end

function Computer:Update(ticks)
	if (not self.os) then
		return
	end
	self.os:Update(ticks)
end

FOS = class('FOS')
function FOS:initialize()
	self.screen = nil
	self.gamepad = nil
	self.utils = {
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
	}
	self.buffer = {}
	self.newBuffer = {}
	self.bufferQueue = {}
	self.player = nil
	self.tilesPerTick = 0
	self.debug = false
end

function FOS:SetScreen(s)
	self.screen = s
	for x=1,self.screen.width do
		self.buffer[x] = {}
		for y=1,self.screen.height do
			self.buffer[x][y] = KAG.GetTile((self.screen.x + x)*8, (self.screen.y + y)*8)
		end
	end
end

function FOS:SetGamepad(g)
	print("SetGamepad")
	self.gamepad = g
end

function FOS:DrawLine(x1, y1, x2, y2, b)
	-- TODO: bresenham algorithm?
	self:DrawRectangle(x1, y1, x2, y2, b)
end

function FOS:DrawRectangle(x1, y1, x2, y2, b)
	for x=x1,x2 do
		for y=y1,y2 do
			self.newBuffer[x] = self.newBuffer[x] or {}
			if (self.newBuffer[x][y] ~= b) then
				self.newBuffer[x][y] = b
			end
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
	b = b or Blocks.WOODEN_BACK
	self:DrawRectangle(1,1,self.screen.width,self.screen.height,b)
end

function FOS:ClearArea(x1, y1, x2, y2, b)
	b = b or Blocks.WOODEN_BACK
	self:DrawRectangle(x1,y1,x2,y2,b)
end

function FOS:DrawPoint(x, y, b)
	if (not x or not y or not b) then return end
	self.newBuffer[x] = self.newBuffer[x] or {}
	if (self.newBuffer[x][y] ~= b) then
		self.newBuffer[x][y] = b
	end
end

function FOS:Update(ticks)
	if (self.game and self.running) then
		self.game:Update(ticks)
	end
end

function FOS:Display()
	-- TODO: optimize
	self.tilesPerTick = 0
	for x,v in pairs(self.newBuffer) do
		for y,b in pairs(self.newBuffer[x]) do
			if (self.buffer[x][y] ~= b) then
				self.tilesPerTick = self.tilesPerTick + 1
				KAG.PushTile(self.screen.x+x, self.screen.y+y, b, 1)
				self.buffer[x][y] = b
			end
		end
	end
	self.newBuffer = {}
	if (self.debug) then print("Tiles per tick = " .. self.tilesPerTick) end
end

gameclasses = {}
function FOS:LoadGame(gameName, forceReload)
	if (type(forceReload) ~= "boolean") then forceReload = false end
	if (not gameclasses[gameName] or forceReload) then
		gameclasses[gameName] = dofile(Plugin.GetPath() .. "/data/games/" .. gameName .. "/init.lua")
	end
	self.game = gameclasses[gameName]()
	self.game:Load(self)
end

function FOS:IsKeyDown(key)
	if (not self.player) then return false end
	return self.player:IsKeyDown(key)
end

function FOS:WasKeyPressed(key)
	if (not self.player) then return false end
	return self.player:WasKeyPressed(key)
end

function FOS:WasKeyReleased(key)
	if (not self.player) then return false end
	return self.player:WasKeyReleased(key)
end