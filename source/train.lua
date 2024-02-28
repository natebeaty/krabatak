import "CoreLibs/sprites"
import "lib/AnimatedSprite.lua"

local gfx <const> = playdate.graphics
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D

class("Train").extends(gfx.sprite)

local animTimer = playdate.frameTimer.new(6)
animTimer.repeats = true

local minXPosition = -100
local maxXPosition = 500
local yPosition = 231

local trainImagesTable = gfx.imagetable.new("images/train")

local screenWidth <const>, _ = playdate.display.getSize()

function Train:init()
  Train.super.init(self)

  self.imagesTable = trainImagesTable
  self:setImage(self.imagesTable:getImage(1))
  self:setZIndex(1000)
  local sw,sh = trainImagesTable:getImage(1):getSize()
  self:setCollideRect(4, 4, sw-8, sh-8)
  self:setGroups({3})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.position = point.new(-200,yPosition)
  self:moveTo(self.position)

  self.launched = false
  self:addSprite()
end

function Train:update()
  if self.launched then
    self.position += self.velocity

    local x,y,c,l = self:moveWithCollisions(self.position)
    for i = 1, l do
      local other = c[i].other
      if other.isa(Player) then
        other:die()
      end
    end

    if self.position.x < minXPosition or self.position.x > maxXPosition then
      self.launched = false
    end
  else
    self:checkLaunch()
  end
end

function Train:checkLaunch()
  if (not self.launched and rnd()>0.99) then
    self:launch()
  end
end

function Train:launch()
  self.position.x = rnd()>0.35 and -40 or screenWidth + 40
  self.velocity = vector2D.new(self.position.x < 0 and 3 or -3, 0)
  self:setImage(self.imagesTable:getImage(1))
  -- express?
  if rnd()>0.7 then
    self.velocity *= 2
    self:setImage(self.imagesTable:getImage(2))
  end
  self:moveTo(self.position)
  self.launched = true
end
