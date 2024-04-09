
import "CoreLibs/sprites"
import "lib/AnimatedSprite.lua"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D

class("Supply").extends(gfx.sprite)

local animTimer = playdate.frameTimer.new(2)
animTimer.repeats = true

local minXPosition = -100
local maxXPosition = 500
local minYPosition = -230
local maxYPosition = 208

local supplyImagesTable = gfx.imagetable.new("images/supply")
local balloonImagesTable = gfx.imagetable.new("images/balloon")
local deathSfx = sound.sampleplayer.new("sounds/death")
local balloonDeploySfx = sound.sampleplayer.new("sounds/balloon-deploy")

local screenWidth <const>, _ = playdate.display.getSize()

-- class('Shadows').extends(AnimatedSprite)
-- function Shadows:init(x,y)
--   self.shadowsSprite = gfx.imagetable.new("images/shadows")
--   Shadows.super.init(self, self.shadowsSprite)
--   self:moveTo(x, y)
--   self:playAnimation()
-- end

-----------------
-- supply balloon
-- (emits from supply ship below)

local balloon = AnimatedSprite.new(balloonImagesTable)
balloon:setCollideRect(0, 0, balloonImagesTable:getImage(1):getSize())
balloon:setGroups({3})
balloon:setCollidesWithGroups({1})
-- balloon.collisionResponse = gfx.sprite.kCollisionTypeOverlap
balloon:addState("open", 3, 4, { tickStep = 2 })
balloon:addState("parachute", 1, 2, { tickStep = 2, loop = 5, nextAnimation = "open" }).asDefault()
balloon.states["parachute"].onAnimationEndEvent = function()
  balloon.velocity.x = 0
end
balloon.isBalloon = true -- for collisions
balloon.launched = false

function balloon:update()
  if self.launched then
    self.position += self.velocity
    if (self.position.y > maxYPosition) then
      self:die()
    end
    local x,y,c,l = self:moveWithCollisions(self.position)
    for i=1,l do
      local other = c[i].other
      if other.isEnemy then
        other:die()
        self:die()
      elseif other:isa(Player) and not player.dying then
        player:refuel()
        self.launched = false
        self:stopAnimation()
        self:remove()
      elseif other:isa(Block) then
        other:hit()
        self:die()
      end
    end
    self:updateAnimation()
  end
end

-- function balloon:collisionResponse(other)
--   if other:isa(Player) then
--     return "overlap"
--   else
--     return "freeze"
--   end
-- end

function balloon:die()
  deathSfx:play()
  if self.launched then
    self.launched = false
    animations:explosion(self.position.x, self.position.y)
  end
  self:stopAnimation()
  self:remove()
end

function balloon:launch()
  balloonDeploySfx:play()
  self:add()
  self.launched = true
  self:moveTo(self.position)
  self:playAnimation()
end

--------------
-- supply ship

function Supply:init()
  Supply.super.init(self)

  self:setImage(supplyImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 46, 10)
  self:setGroups({3})
  self:setCollidesWithGroups({1})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.position = point.new(-200,0)
  self:moveTo(self.position)

  self.launched = false
  self.deployed = false
  self:add()
end

function Supply:die()
  deathSfx:play()
  animations:explosion(self.position.x, self.position.y)
  self.position = point.new(-200,0)
  self:moveTo(self.position)
  self.launched = false
end

function Supply:update()
  if self.launched then
    self.position += self.velocity
    local x,y,c,l = self:moveWithCollisions(self.position)

    for i=1,l do
      local other = c[i].other
      if other.isEnemy then
        other:die()
        self:die()
      elseif other:isa(Player) and not player.dying then
        other:die()
        self:die()
      end
    end

    -- animate jet
    self:setImage(supplyImagesTable:getImage(animTimer.frame < 1 and 1 or 2), self.velocity.x < 0 and '' or 'flipX')

    if self.position.x < minXPosition or self.position.x > maxXPosition then
      self.launched = false
    end

    -- emit balloon? check position across screen
    local screen_pos = self.velocity.x<1 and self.position.x/screenWidth or (screenWidth-self.position.x)/screenWidth
    if (not self.deployed and screen_pos>0.2 and screen_pos<0.8 and rnd()>0.96) then
      self.deployed = true
      self.velocity.x *= 1.5
      balloon.position = self.position
      balloon.velocity = vector2D.new(self.position.x < 0 and 1 or -1, 1)
      balloon:launch()
    end

  else

    self:checkLaunch()

  end

  -- offscreen?
  -- if (is_offstage(this,10)) del(supply,this)
end

function Supply:checkLaunch()
  if ((mode=="game" or mode=="title") and not balloon.launched and not self.launched and rnd()>0.997) then
    self:launch()
  end
end

function Supply:launch()
  -- todo: honor cameraY (gameState?)
  self.position = point.new(rnd(1)>0.35 and -40 or screenWidth + 40, 33+(math.random(20)))
  self.velocity = vector2D.new(self.position.x < 0 and 3 or -3, 0)
  self:moveTo(self.position)

  self.launched = true
  self.deployed = false
end

function Supply:reset()
  balloon.launched = false
  balloon:remove()
  if self.launched then
    self.launched = false
    self:remove()
  end
end
