import "lib/AnimatedSprite.lua"

class("Animations").extends()

local pd = playdate
local gfx = pd.graphics
local explosionImages = gfx.imagetable.new("images/explosion")
local bonusYayImages = gfx.imagetable.new("images/bonus-yay")
local explosionCache = {}
local bonusYayCache = {}
local shake = 0
local shakeDecay = 0.95

--ye olde screen rattle
function setScreenShake(n,d)
  shake = n
  shakeDecay = d or 0.95
end
function screenShake()
  if shake > 0 then
    local offsetX= 16-rnd(32)
    local offsetY= 16-rnd(32)
    offsetX *= shake
    offsetY *= shake

    pd.display.setOffset(offsetX, offsetY)
    shake *= shakeDecay
    if shake < 0.05 then
      stopShake()
    end
  end
end
function stopShake()
  pd.display.setOffset(0, 0)
  shake = 0
end


function Animations:explosion(x,y)
  local anim = nil
  if #explosionCache > 0 then
    anim = table.remove(explosionCache)
    anim:stopAnimation()
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
