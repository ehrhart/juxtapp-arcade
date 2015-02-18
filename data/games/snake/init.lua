local class = require("middleclass")

local Game = class('Game')
function Game:initialize()
	self.os = nil
	self.snake = {}
	self.food = {x = 1, y = 1}
	self.nextDir = 0
	self.spd = 0
	self.defaultSpeed = 12
	self.maxSpeed = 5
	self.isReady = false
	self.hi_name = ""
	self.hi_score = 0
end

function Game:Load(operatingSystem)
	self.os = operatingSystem
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
	
	if (kRight and not kUp and not kDown and self.snake[1].dir ~= 2) then
		self.nextDir = 0
	elseif (kLeft and not kUp and not kDown and self.snake[1].dir ~= 0) then
		self.nextDir = 2
	elseif (kUp and not kLeft and not kRight and self.snake[1].dir ~= 3) then
		self.nextDir = 1
	elseif (kDown and not kLeft and not kRight and self.snake[1].dir ~= 1) then
		self.nextDir = 3
	end
	
	if(ticks % self.spd == 0 and self.isReady) then
		self:game_update()
	end
	
	self.os:Display()
end

function Game:game_reset()
	print("game_reset")
	
	self.nextDir = 0
	
	if (self.os.player and #self.snake-2 > 0) then
		KAG.SendMessage(self.os.player:GetName().."'s Score: "..#self.snake-2)
		if(#self.snake-2 > self.hi_score) then
			KAG.SendMessage(self.os.player:GetName().." has set a new highscore!")
			self.hi_name = self.os.player:GetName()
			self.hi_score = #self.snake-2
		end
	end
	
	for k in pairs(self.snake) do
		if(k > 1) then
			self.os:DrawPoint(self.snake[k].x, self.snake[k].y, 205)
		end
		self.snake[k] = nil
	end
	table.insert(self.snake, {x = 2, y = math.ceil(self.os.screen.height/2), dir = 0})
	table.insert(self.snake, {x = 1, y = math.ceil(self.os.screen.height/2), dir = 0})
	
	-- Create our snake
	for k in pairs(self.snake) do
		self.os:DrawPoint(self.snake[k].x, self.snake[k].y, 80)
	end
	
	-- delete old food tile
	self.os:DrawPoint(self.food.x, self.food.y, 205)
	self:gen_food()
	self.spd = self.defaultSpeed
	self.isReady = true
end

function Game:game_update()
	-- Erase tail
	self.os:DrawPoint(self.snake[#self.snake].x, self.snake[#self.snake].y, 205)
	
	-- Find out direction for each snake peace
	self.snake[1].dir = self.nextDir
	for i=2,#self.snake do
		if(self.snake[i-1].x > self.snake[i].x and self.snake[i-1].y == self.snake[i].y) then self.snake[i].dir = 0 
		elseif(self.snake[i-1].x < self.snake[i].x and self.snake[i-1].y == self.snake[i].y) then self.snake[i].dir = 2 
		elseif(self.snake[i-1].y > self.snake[i].y and self.snake[i-1].x == self.snake[i].x) then self.snake[i].dir = 3 
		elseif(self.snake[i-1].y < self.snake[i].y and self.snake[i-1].x == self.snake[i].x) then self.snake[i].dir = 1 end
	end
	
	-- Update all tiles according to their directions
	for i = 1,#self.snake	do
		if(self.snake[i].dir == 0) then  
			self.snake[i].x = self.snake[i].x + 1
		elseif(self.snake[i].dir == 1) then
			self.snake[i].y= self.snake[i].y -1 
		elseif(self.snake[i].dir == 2)  then
			self.snake[i].x = self.snake[i].x - 1
		elseif(self.snake[i].dir == 3) then
			self.snake[i].y = self.snake[i].y + 1 
		end
	end
	
	if (self.snake[1].x < 1 or self.snake[1].x > self.os.screen.width or self.snake[1].y < 1 or self.snake[1].y > self.os.screen.height) then
		-- If we walk into borders
		self.isReady = false
		self:game_reset()
	elseif(self.os.buffer[self.snake[1].x][self.snake[1].y] == 48) then
		-- If we walk into stone obstacles
		self.isReady = false
		self:game_reset()
	end
	
	-- check if we eat food
	if(self.snake[1].x == self.food.x and self.snake[1].y == self.food.y) then
		if(self.spd > self.maxSpeed) then
			self.spd = self.spd - 1
		end
		self:gen_tail()
		self:gen_food()
	end
	
	-- check if we eat our tail
	for i=2, #self.snake do
		if(self.snake[1].x == self.snake[i].x and self.snake[1].y == self.snake[i].y) then
			self.isReady = false
			self:game_reset()
		end
	end	
	
	-- draw head
	self.os:DrawPoint(self.snake[1].x, self.snake[1].y, 80)
	
	-- redraw food
	self.os:DrawPoint(self.food.x, self.food.y, 196)
end

function Game:gen_tail()
	local ntail = {x = 0, y = 0, dir = 0}
	local tail = self.snake[#self.snake]
	
	ntail.x = tail.x
	ntail.y = tail.y
	ntail.dir = tail.dir
	if(tail.dir == 0) then ntail.x = tail.x-1 end
	if(tail.dir == 1) then ntail.y = tail.y+1 end
	if(tail.dir == 2) then ntail.x = tail.x+1 end
	if(tail.dir == 3) then ntail.y = tail.y-1 end
	
	table.insert(self.snake, ntail)
end

function Game:gen_food()
	local a = false
	while a == false do
		self.food.x = math.random(1, self.os.screen.width)
		self.food.y = math.random(1, self.os.screen.height)
		local b = self.os.buffer[self.food.x][self.food.y]
		a = (b ~= Blocks.GOLD and b ~= Blocks.CASTLE_WALL)
	end
	self.os:DrawPoint(self.food.x, self.food.y, 196)
end

return Game