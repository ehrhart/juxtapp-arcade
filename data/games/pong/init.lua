local class = require("middleclass")

local Game = class('Game')
function Game:initialize()
	self.os = nil
end

function Game:Load(operatingSystem)
	self.os = operatingSystem
	if (self.os.player) then
		self.os.player:SendMessage("Rules: press the movement keys (default: W, S) to move the paddle")
	end
	
	self.start_speed = 5
	self.incr_speed = 0.5
	self.max_speed = 2
	self.plr_height = 4
	
	self.tickrate = 0
	self.tick = 0
	self.ball = 0
	self.pl = {}
	self.pr = {}
	self.py = math.floor((self.os.screen.height - self.plr_height) / 2)
	self.pmy = self.plr_height
	self.score = {0, 0}
	
	self:reset()
end

function Game:Update(ticks)
	if (self.os:IsKeyDown(Keys.UP)) then
		self.pr.dy = -1
	elseif (self.os:IsKeyDown(Keys.DOWN)) then
		self.pr.dy = 1
	end
	
	if (ticks % self.tickrate == 0) then
		self:update_player(self.pl);
		self:update_player(self.pr);
		--self.tick = self.tick - 1
		--if (speed == 0 or self.tick ~= 1) then return end --TODO: check if it's correct
		--self.tick = self.speed
		self.ball.x = self:clamp(self.ball.x + self.ball.dx, 1, self.os.screen.width)
		self.ball.y = self:clamp(self.ball.y + self.ball.dy, 1, self.os.screen.height)
		if (self.ball.dx < 1) then
			local x = self.ball.x
			local dx = self.ball.dx
			local y = self.ball.y
			local dy = self.ball.dy
			while (x > 1) do
				x = x + dx
				y = y + dy
				if (not self:bw(y, 2, self.os.screen.height - 2)) then break end
			end
			self.pl.dy = self:bw(y, self.pl.y, self.pl.y + self.pl.my) and 0 or (self.pl.y > y and -1 or 1)
		end
		if (not self:bw(self.ball.y, 2, self.os.screen.height - 2)) then
			self.ball.dy = -self.ball.dy
			self:speedup()
		end
		if ((self.ball.x == 3 and self:bw(self.ball.y, self.pl.y-1, self.pl.y + self.pl.my)) or (self.ball.x == (self.os.screen.width - 2) and self:bw(self.ball.y, self.pr.y-1, self.pr.y + self.pr.my))) then
			self.ball.dx = -self.ball.dx
			
			-- Solo score, increments everytime the ball bounces on the paddle
			if (self.ball.x > 3) then
				self.score[2] = self.score[2] + 1
			end
			
			if (math.random() > 0.5) then self.ball.dy = -self.ball.dy end
			self:speedup()
		elseif ((self.ball.x == 1) or (self.ball.x == self.os.screen.width)) then
			-- Multi score
			--local score_index = self.ball.x == 3 and 1 or 2
			--self.score[score_index] = self.score[score_index] + 1
			
			-- Solo score
			if (self.os.player) then
				local msg = self.os.player:GetName() .. "'s Pong Score: " .. self.score[2]
				if (self.score[2] > 10) then
					KAG.SendMessage(msg)
				elseif (self.score[2] > 1) then
					self.os.player:SendMessage(msg)
				end
			end
			
			self:reset()
		end
		
		self.os:Clear()
		self:draw_player(self.pl)
		self:draw_player(self.pr)
		self.os:DrawPoint(self.ball.x, self.ball.y, 196)
		self.os:Display()
	end
end

function Game:bw(v, a, b)
	return (v >= a) and (v <= b)
end

function Game:clamp(v, a, b)
	return v < a and a or (v > b and b or v)
end

function Game:speedup()
	self.speed = self:clamp(self.speed - self.incr_speed, self.max_speed, self.start_speed)
	self.tickrate = math.ceil(self.speed)
end

function Game:update_player(p)
	p.y = self:clamp(p.y + p.dy, 1, self.os.screen.height - self.plr_height + 1)
	p.dy = 0
end

function Game:draw_player(p)
	for i=1,self.plr_height do
		self.os:DrawPoint(p.x, (p.y + i)-1, Blocks.GOLD)
	end
end

function Game:reset()
	self.speed = self.start_speed;
	self.tickrate = math.ceil(self.speed)
	self.pl = {
		x = 2,
		y = self.py,
		dy = 0,
		my = self.pmy
	}
	self.pr = {
		x = self.os.screen.width - 1,
		y = self.py,
		dy = 0,
		my = self.pmy
	}
	self.ball = {
		x = math.floor(self.os.screen.width / 2),
		y = math.floor(self.os.screen.height / 2),
		dx = (math.random() > 0.5 and 1 or -1),
		dy = (math.random() > 0.5 and 1 or -1)
	}
	self.score = {0, 0}
	
	self.os:Clear()
end

return Game