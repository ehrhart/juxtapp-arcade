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
		width = screenWidth,
		height = screenHeight,
		topLeft = {
			x = self.x,
			y = self.y - screenHeight,
		},
		topRight = {
			x = self.x + screenWidth,
			y = self.y - screenHeight,
		},
		bottomLeft = {
			x = self.x,
			y = self.y,
		},
		bottomRight = {
			x = self.x + screenWidth,
			y = self.y,
		}
	}
	
	local gamepadWidth, gamepadHeight = 1, 1
	self.gamepad = {
		x = self.x + math.floor(self.screen.width/2)-math.ceil(gamepadWidth/2),
		y = self.y + 2,
		width = gamepadWidth,
		height = gamepadHeight,
	}
end

function Computer:Boot()
	-- Draw screen border
	DrawRectangle(self.screen.topLeft.x-1, self.screen.topLeft.y-1, self.screen.topRight.x+1, self.screen.topRight.y-1, Blocks.CASTLE_WALL)
	DrawRectangle(self.screen.topLeft.x-1, self.screen.topLeft.y-1, self.screen.bottomLeft.x-1, self.screen.bottomLeft.y+1, Blocks.CASTLE_WALL)
	DrawRectangle(self.screen.topRight.x+1, self.screen.topRight.y-1, self.screen.bottomRight.x+1, self.screen.bottomRight.y+1, Blocks.CASTLE_WALL)
	DrawRectangle(self.screen.bottomLeft.x-1, self.screen.bottomLeft.y+1, self.screen.bottomRight.x+1, self.screen.bottomRight.y+1, Blocks.CASTLE_WALL)
	
	-- Draw screen background
	DrawRectangle(self.screen.topLeft.x, self.screen.topLeft.y, self.screen.bottomRight.x, self.screen.bottomRight.y, Blocks.WOODEN_BACK)
	
	-- Draw gamepad
	DrawRectangle(self.gamepad.x-1, self.gamepad.y-1, self.gamepad.x + self.gamepad.width+1, self.gamepad.y + self.gamepad.height+1, Blocks.CASTLE_WALL)
	DrawRectangle(self.gamepad.x, self.gamepad.y, self.gamepad.x + self.gamepad.width, self.gamepad.y + self.gamepad.height, Blocks.CASTLE_BACK)
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