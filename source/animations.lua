import "lib/AnimatedSprite.lua"

class("Animations").extends()

local gfx = playdate.graphics
local explosionImages = gfx.imagetable.new("images/explosion")
local bonusYayImages = gfx.imagetable.new("images/bonus-yay")

function Animations:explosion(x,y)
  local anim = AnimatedSprite.new(explosionImages)
  anim:setZIndex(1100)
  anim:setStates({
    {
      name = "explode",
      loop = 1,
      tickStep = 2,
      onAnimationEndEvent = function(self)
        self:remove()
      end
    }
  })
  anim:moveTo(x, y)
  anim:playAnimation()
end

function Animations:bonusYay(x,y)
  local anim = AnimatedSprite.new(bonusYayImages)
  anim:setZIndex(1100)
  anim:setStates({
    {
      name = "yay",
      loop = 1,
      tickStep = 2,
      onAnimationEndEvent = function(self)
        self:remove()
      end
    }
  })
  anim:moveTo(x, y)
  anim:playAnimation()
end
