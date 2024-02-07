import "CoreLibs/sprites"

class("City").extends()

local gfx <const> = playdate.graphics
local background = gfx.image.new('images/background-tall')

function City:init()
  self.by = -240
  self.sprite = gfx.sprite.setBackgroundDrawingCallback(
    function(x, y, width, height)
      background:draw(0, self.by)
    end
  )
end

function City:setY(y)
  self.by = y
  gfx.sprite.redrawBackground()
  -- gfx.setDrawOffset(0, y)
end