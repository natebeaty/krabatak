import "lib/AnimatedSprite.lua"

class('Animations').extends()


-- local refs
local gfx = playdate.graphics
local Point = playdate.geometry.point
local Vector2D = playdate.geometry.vector2D

local explosionImages = gfx.imagetable.new("images/explosion")
-- local explosionAnimation = AnimatedSprite.new(explosionImages)

function Animations:explosion(x,y)
  print(x,y)
  local explosionAnimation = AnimatedSprite.new(explosionImages)
  explosionAnimation:setStates({
    {
      name = "explode",
      loop = 1,
      tickStep = 2,
      onAnimationEndEvent = function (self)
        self:remove()
      end
    }
  })
  explosionAnimation:moveTo(x, y)
  explosionAnimation:playAnimation()
end
