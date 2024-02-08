import "lib/AnimatedSprite.lua"

class("Animations").extends()

local gfx = playdate.graphics
local explosionImages = gfx.imagetable.new("images/explosion")

function Animations:explosion(x,y)
  local explosionAnimation = AnimatedSprite.new(explosionImages)
  explosionAnimation:setStates({
    {
      name = "explode",
      loop = 1,
      tickStep = 2,
      onAnimationEndEvent = function(self)
        self:remove()
      end
    }
  })
  explosionAnimation:moveTo(x, y)
  explosionAnimation:playAnimation()
end
