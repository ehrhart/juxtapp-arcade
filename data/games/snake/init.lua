local class = require("middleclass")

local Game = class('Game')
function Game:initialize()
	self.os = nil
	self.food = {x = 1, y = 1}
	self.currentDir = 0
	self.nextDir = 0
	self.spd = 0
	self.defaultSpeed = 8
	self.maxSpeed = 4
	self.isReady = false
	self.x = 1
	self.y = 1
	self.queue = {}
	self.queueSize = 0
	self.currentDir = 0
	self.skipTail = false
	self.score = 0
	self.SNAKE_BLOCK = Blocks.GOLD
end

function Game:Load(operatingSystem)
	self.os = operatingSystem
	if (self.os.player) then
		self.os.player:SendMessage("Rules: press the movement keys (default: W, A, S, D) to move the snake, and collect the food without touching the border of the screen or the tail of the snake")
	end
end

function Game:Update(ticks)
	if (not self.isReady) then
		self:game_reset()
		return
	end
	
	local kUp = self.os:IsKeyDown(Keys.UP)
	local kDown = self.os:IsKeyDown(Keys.DOWN)
	local kLeft = self.os:IsKeyDown(Keys.LEFT)
	local kRight = self.os:IsKeyDown(Keys.RIGHT)
	
	-- 0 = right, 1 = up, 2 = left, 3 = down
	if (kRight and not kUp and not kDown and self.currentDir ~= 2) then
		self.nextDir = 0
	elseif (kLeft and not kUp and not kDown and self.currentDir ~= 0) then
		self.nextDir = 2
	elseif (kUp and not kLeft and not kRight and self.currentDir ~= 3) then
		self.nextDir = 1
	elseif (kDown and not kLeft and not kRight and self.currentDir ~= 1) then
		self.nextDir = 3
	end
	
	if(ticks % self.spd == 0 and self.isReady) then
		self:game_update()
		self.os:Display()
	end
	
end

function Game:game_reset()
	self.score = 0
	self.nextDir = 0
	self.currentDir = 0
	self.skipTail = false
	self.queue = {}
	self.queueSize = 0
	self.x = 2
	self.y = math.ceil(self.os.screen.height/2)
	self.spd = self.defaultSpeed
	self.isReady = true
	
	self.os:Clear()
	self:gen_food()
end

function Game:game_over()
	self.isReady = false
	if (self.score > 1) then
		KAG.SendMessage(self.os.player:GetName() .. "'s Snake Score: " .. self.score)
	end
	self:game_reset()
end

function Game:game_update()
	if (self.skipTail) then
		self.skipTail = false
	else
		local tail = table.remove(self.queue, 1)
		if (tail ~= nil) then
			self.os:DrawPoint(tail.x, tail.y, Blocks.WOODEN_BACK)
			self.queueSize = self.queueSize - 1
		end
	end
	
	self.currentDir = self.nextDir
	if (self.currentDir == 0) then
		self.x = self.x + 1
	elseif (self.currentDir == 1) then
		self.y = self.y - 1
	elseif (self.currentDir == 2) then
		self.x = self.x - 1
	elseif (self.currentDir == 3) then
		self.y = self.y + 1
	end
	
	if (self.x > self.os.screen.width or self.x < 1 or self.y > self.os.screen.height or self.y < 1 or self.os.buffer[self.x][self.y] == self.SNAKE_BLOCK) then
		self:game_over()
		return
	end
	
	self.os:DrawPoint(self.x, self.y, self.SNAKE_BLOCK)
	self.queue[self.queueSize+1] = {x=self.x, y=self.y}
	self.queueSize = self.queueSize + 1
	
	if(self.x == self.food.x and self.y == self.food.y) then
		if(self.spd > self.maxSpeed) then
			self.spd = self.spd - 1
		end
		self.skipTail = true
		self.score = self.score + 1
		self:gen_food()
	end
	
	-- redraw food
	self.os:DrawPoint(self.food.x, self.food.y, 196)
end

function Game:gen_food()
	local a = false
	while a == false do
		self.food.x = math.random(1, self.os.screen.width)
		self.food.y = math.random(1, self.os.screen.height)
		local b = self.os.buffer[self.food.x][self.food.y]
		a = (b ~= self.SNAKE_BLOCK and b ~= Blocks.CASTLE_WALL)
	end
	self.os:DrawPoint(self.food.x, self.food.y, 196)
end

return Game