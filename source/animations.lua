import "lib/AnimatedSprite.lua"

class("Animations").extends()

local pd = playdate
local gfx = pd.graphics
local explosionImages = gfx.imagetable.new("images/explosion")
local bigExplosionImages = gfx.imagetable.new("images/big-explosion")
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

-- function setAnimType(anim,type)

function Animations:explosion(x,y,type)
  local anim = nil
  type = type or "sm"
  if #explosionCache > 0 then
    anim = table.remove(explosionCache)
    anim:stopAnimation()
    if anim.type ~= type then
      if type == "sm" then
        anim.imageTable = explosionImages
      else
        anim.imageTable = bigExplosionImages
      end
      anim:setSize(anim:getImage(1):getSize())
    end
  else
    if type == "sm" then
      anim = AnimatedSprite.new(explosionImages)
    else
      anim = AnimatedSprite.new(bigExplosionImages)
    end
    anim.type = type
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
  -- if type == "sm" then
  --   anim:setImage(
  -- end
  -- Animations:setType(type or "sm")
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
