local LCS = require("class")

Computer = LCS.class{
	x = 0,
	y = 0,
	booted = false,
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
		x = self.x + math.floor(self.screen.width/2)-math.ceil(gamepadWidth/2),
		y = self.y + 1,
		width = gamepadWidth,
		height = gamepadHeight,
	}
end

function Computer:Boot()
	-- Draw screen border
	DrawRectangle(self.screen.x-1, self.screen.y-1, self.screen.x + self.screen.width, self.screen.y-1, Blocks.CASTLE_WALL) -- top
	DrawRectangle(self.screen.x-1, self.screen.y + self.screen.height, self.screen.x + self.screen.width, self.screen.y + self.screen.height, Blocks.CASTLE_WALL) -- bottom
	DrawRectangle(self.screen.x-1, self.screen.y-1, self.screen.x-1, self.screen.y + self.screen.height, Blocks.CASTLE_WALL) -- left
	DrawRectangle(self.screen.x + self.screen.width, self.screen.y-1, self.screen.x + self.screen.width, self.screen.y + self.screen.height, Blocks.CASTLE_WALL) -- rigt
	
	-- Draw screen background
	DrawRectangle(self.screen.x, self.screen.y, self.screen.x + self.screen.width - 1, self.screen.y + self.screen.height - 1, Blocks.WOODEN_BACK)
	
	-- Draw gamepad
	DrawRectangle(self.gamepad.x-1, self.gamepad.y-1, self.gamepad.x + self.gamepad.width, self.gamepad.y + self.gamepad.height, Blocks.CASTLE_WALL)
	DrawRectangle(self.gamepad.x, self.gamepad.y, self.gamepad.x + self.gamepad.width - 1, self.gamepad.y + self.gamepad.height - 1, Blocks.CASTLE_BACK)
	
	self.booted = true
end

function Computer:Update(ticks)
	
end

function DrawRectangle(x1, y1, x2, y2, b)
	print(x1..":"..y1.." to " .. x2..":"..y2)
	for x=x1,x2 do
		for y=y1,y2 do
			KAG.PushTile(x, y, b)
		end
	end
end