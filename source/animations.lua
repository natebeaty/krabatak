import "lib/AnimatedSprite.lua"

class("Animations").extends()

local gfx = playdate.graphics
local explosionImages = gfx.imagetable.new("images/explosion")
local bonusYayImages = gfx.imagetable.new("images/bonus-yay")
local explosionCache = {}
local bonusYayCache = {}

function Animations:explosion(x,y)
  local anim = nil
  if #explosionCache > 0 then
    anim = table.remove(explosionCache)
    anim:stopAnimation()
    print(#explosionCache, anim)
  else
    anim = AnimatedSprite.new(explosionImages)
    anim:setZIndex(1100)
    anim:setStates({
      {
        name = "explode",
        loop = 1,
        tickStep = 2,
        onAnimationEndEvent = function(self)
          -- self:remove()
          explosionCache[#explosionCache+1] = self
        end
      }
    })
  end
  anim:moveTo(x, y)
  anim:playAnimation()
end

function Animations:bonusYay(x,y)
  local anim = nil
  if #bonusYayCache > 0 then
    anim = table.remove(bonusYayCache)
    anim:stopAnimation()
  else
    anim = AnimatedSprite.new(bonusYayImages)
    anim:setZIndex(1100)
    anim:setStates({
      {
        name = "yay",
        loop = 1,
        tickStep = 2,
        onAnimationEndEvent = function(self)
          -- self:remove()
          bonusYayCache[#bonusYayCache+1] = self
        end
      }
    })
  end
  anim:moveTo(x, y)
  anim:playAnimation()
end
