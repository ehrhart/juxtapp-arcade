local class = require("middleclass")

local Game = class('Game')
function Game:initialize()
	self.os = nil
	
	self.DIR = { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3, MIN = 0, MAX = 3 }
	self.speed = { start = 0.6, decrement = 0.005, min = 0.1 }
	self.nx = 10
	self.ny = 16
	self.nu = 5
	
	self.dx = 1
	self.dy = 1
	self.blocks = {}
	self.actions = {}
	self.playing = true
	self.current = nil
	self.next = nil
	self.score = 0
	self.vscore = 0
	self.rows = {}
	self.step = 1
	
	self.i = { size = 2, blocks = {0x0F00, 0x2222, 0x00F0, 0x4444} }
	self.j = { size = 3, blocks = {0x44C0, 0x8E00, 0x6440, 0x0E20} }
	self.l = { size = 3, blocks = {0x4460, 0x0E80, 0xC440, 0x2E00} }
	self.o = { size = 2, blocks = {0xCC00, 0xCC00, 0xCC00, 0xCC00} }
	self.s = { size = 3, blocks = {0x06C0, 0x8C40, 0x6C00, 0x4620} }
	self.t = { size = 3, blocks = {0x0E40, 0x4C40, 0x4E00, 0x4640} }
	self.z = { size = 3, blocks = {0x0C60, 0x4C80, 0xC600, 0x2640} }
	
	self.pieces = {}
	self.invalid = {}
end

function Game:Load(operatingSystem)
	self.os = operatingSystem
	
	print("Game:Load, calling self:reset()")
	self:reset()
end

function Game:Update(ticks)
	local kUp = self.os:IsKeyDown(Keys.UP)
	local kDown = self.os:IsKeyDown(Keys.DOWN)
	local kLeft = self.os:IsKeyDown(Keys.LEFT)
	local kRight = self.os:IsKeyDown(Keys.RIGHT)
	
	self:handle(table.remove(self.actions, 1))
	
	if (ticks % 30 == 0) then
		-- update
		self:drop()
		
		--draw
		self.os:Clear()
		self:drawCourt()
		self:drawNext()
		self.os:Display()
	end
end

function Game:handle(action)
	if (not action) then return end
	if (action == self.DIR.LEFT) then self:move(self.DIR.LEFT)
	elseif (action == self.DIR.RIGHT) then self:move(self.DIR.RIGHT)
	elseif (action == self.DIR.UP) then self:rotate()
	elseif (action == self.DIR.DOWN) then self:drop() end
end

function Game:move(dir)
	local x, y = self.current.x, self.current.y
	if (dir == self.DIR.RIGHT) then
		x = x + 1
	elseif (dir == self.DIR.LEFT) then
		x = x - 1
	elseif (dir == self.DIR.DOWN) then
		y = y + 1
	end
	
	if (self:unoccupied(self.current.type, x, y, self.current.dir)) then
		self.current.x = x
		self.current.y = y
		self:invalidate()
		return true
	else
		return false
	end
end

function Game:rotate()
	local newdir = (self.current.dir == self.DIR.MAX and self.DIR.MIN or self.current.dir + 1)
	if (self:unoccupied(self.current.type, self.current.x, self.current.y, newdir)) then
		self.current.dir = newdir
		self:invalidate()
	end
end

function Game:drop()
	if (not self:move(self.DIR.DOWN)) then
		self:addScore(10)
		self:dropPiece()
		self:removeLines()
		self:setCurrentPiece(self.next)
		self:setNextPiece(self:randomPiece())
		self:clearActions()
		if (self:occupied(self.current.type, self.current.x, self.current.y, self.current.dir)) then
			self:lose()
		end
	end
end

function Game:lose()
	self:reset()
end

function Game:dropPiece()
	print("Game:dropPiece (" .. self.current.x .. ":" .. self.current.y .. ")")
	self:eachBlock(self.current.type, self.current.x, self.current.y, self.current.dir, function(x, y)
		self:setBlock(x, y, self.current.type)
	end)
end

function Game:removeLines()
	local complete = false
	local n = 0
	local y = self.ny
	while (y > 1) do
		y = y - 1
		complete = true
		local x = 1
		while (x < self.nx) do
			x = x + 1
			if (not self:getBlock(x, y)) then
				complete = false
			end
		end
		if (complete) then
			self:removeLine(y)
			y = y + 1 -- recheck same line
			n = n + 1
		end
	end
	if (n > 0) then
		self:addRows(n)
		self:addScore(100*math.pow(2,n-1))
	end
end

function Game:removeLine(n)
	local y = n
	while (y >= 1) do
		y = y - 1
		local x = 1
		while (x < self.nx) do
			x = x + 1
			self:setBlock(x, y, (y == 0) and nil or self:getBlock(x, y-1))
		end
	end
end

function Game:invalidate()
	self.invalid.court = true
end

function Game:invalidateNext()
	self.invalid.next = true
end

function Game:invalidateScore()
	self.invalid.score = true
end

function Game:invalidateRows()
	self.invalid.rows = true
end

function Game:drawCourt()
	if (self.invalid.court) then
		self:drawPiece(self.current.type, self.current.x, self.current.y, self.current.dir)
		local x, y, block
		for y=1,self.ny do
			for x=1,self.nx do
				local block = self:getBlock(x, y)
				if (block) then
					self:drawBlock(x, y)
				end
			end
		end
		self.invalid.court = false
	end
end

function Game:drawNext()
	if (self.invalid.next) then
		self.padding = (self.nu - self.next.type.size) / 2
		self:drawPiece(self.next.type, 20, 5, self.next.dir)--self.padding, self.padding, self.next.dir)
		self.invalid.next = false
	end
end

function Game:drawPiece(t, x, y, dir)
	print("Game:drawPiece (" .. x .. ":" .. y .. ")")
	self:eachBlock(t, x, y, dir, function(x, y)
		self:drawBlock(x, y)
	end)
end

function Game:drawBlock(x, y)
	self.os:DrawPoint(x, y, Blocks.GOLD)
end

function Game:setRows(n)
	self.rows = n
	self.step = math.max(self.speed.min, self.speed.start - (self.speed.decrement*self.rows))
	self:invalidateRows()
end

function Game:addRows(n)
	self:setRows(self.rows + n)
end

function Game:getBlock(x, y)
	return (self.blocks and self.blocks[x]) and self.blocks[x][y] or nil
end

function Game:setBlock(x, y, t)
	self.blocks[x] = self.blocks[x] or {}
	self.blocks[x][y] = t
	self:invalidate()
end

function Game:setScore(n)
	self.score = n
end

function Game:addScore(n)
	self.score = self.score + n
end

function Game:clearRows()
	self:setRows(0)
end

function Game:clearActions()
	self.actions = {}
end

function Game:clearBlocks()
	self.blocks = {}
	self:invalidate()
end

function Game:clearScore()
	self:setScore(0)
end

function Game:setCurrentPiece(piece)
	self.current = piece or self:randomPiece()
	print("SET CURRENT PIECE TO " .. self.current.x .. ":" .. self.current.y)
	self:invalidate()
end

function Game:setNextPiece(piece)
	self.next = piece or self:randomPiece()
	self:invalidateNext()
end

function Game:reset()
	print("Game:reset")
	self.dt = 0
	self:clearActions()
	self:clearBlocks()
	self:clearRows()
	self:clearScore()
	self:setCurrentPiece(self:randomPiece())
	self:setNextPiece()
end

function Game:eachBlock(t, x, y, dir, fn)
	local row = 1
	local col = 1
	local blocks = t.blocks[dir+1]
	local b = 0x8000
	while(b > 0) do
		if (bit32.band(blocks, b)) then
			fn(x + col, y + row)
		end
		col = col + 1
		if (col == 4) then
			col = 0
			row = row + 1
		end
		b = bit32.arshift(b, 1)
	end
end

function Game:occupied(t, x, y, dir)
	local result = false
	self:eachBlock(t, x, y, dir, function(x, y)
		if ((x < 1) or (x >= self.nx) or (y < 1) or (y >= self.ny) or self:getBlock(x,y)) then
			result = true
		end
	end)
	return result
end

function Game:unoccupied(t, x, y, dir)
	return not self:occupied(t, x, y, dir)
end

function Game:table_splice(tbl, start, length)
   length = length or 1
   start = start or 1
   local endd = start + length
   local spliced = {}
   local remainder = {}
   for i,elt in ipairs(tbl) do
      if i < start or i >= endd then
         table.insert(spliced, elt)
      else
         table.insert(remainder, elt)
      end
   end
   return spliced, remainder
end

function Game:randomPiece()
	if (#self.pieces == 0) then
		self.pieces = {self.i,self.i,self.i,self.i,self.j,self.j,self.j,self.j,self.l,self.l,self.l,self.l,self.o,self.o,self.o,self.o,self.s,self.s,self.s,self.s,self.t,self.t,self.t,self.t,self.z,self.z,self.z,self.z}
	end
	local t = self:table_splice(self.pieces, math.random(1, #self.pieces), 1)[1]
	for k,v in pairs(t) do
		print("---")
		print(v)
		print("---")
	end
	return { type = t, dir = self.DIR.UP, x = math.floor(math.random(1, self.nx - t.size)), y = 1 }
end

return Game