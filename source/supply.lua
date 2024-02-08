import "CoreLibs/sprites"
import "lib/AnimatedSprite.lua"
import "lib/state"

local gfx <const> = playdate.graphics
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D

class("Supply").extends(gfx.sprite)

local animTimer = playdate.frameTimer.new(6)
animTimer.repeats = true

local minXPosition = -100
local maxXPosition = 500
local minYPosition = -230
local maxYPosition = 260

local supplyImagesTable = gfx.imagetable.new("images/supply")
local balloonImagesTable = gfx.imagetable.new("images/balloon")

local gameState = State()
local screenWidth <const>, _ = playdate.display.getSize()

local balloon = AnimatedSprite.new(balloonImagesTable)
balloon:setCollideRect(0, 0, balloonImagesTable:getImage(1):getSize())
balloon:setGroups({3})
balloon:setCollidesWithGroups({1})
balloon.collisionResponse = gfx.sprite.kCollisionTypeOverlap
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
    if (self.position.y < minYPosition) then
      self.launched = false
      self:stopAnimation()
      self:remove()
    end
    local x,y,c,l = self:moveWithCollisions(self.position)
    for i=1,l do
      local other = c[i].other
      if other:isa(Enemy) then
        other:die()
        self:die()
      end
      if other:isa(Player) then
        player:refuel()
        self.launched = false
        self:stopAnimation()
        self:remove()
      end
      if other:isa(Block) then
        other:hit()
        self:die()
      end
    end
    self:updateAnimation()
  end
end
function balloon:die()
  self.launched = false
  animations:explosion(self.position.x, self.position.y)
  self:stopAnimation()
  self:remove()
end
function balloon:launch()
  self:addSprite()
  self.launched = true
  self:moveTo(self.position)
  self:playAnimation()
end

function Supply:init()
  Supply.super.init(self)

  self.imagesTable = supplyImagesTable
  self:setImage(self.imagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 46, 10)
  self:setGroups({3})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.position = point.new(-200,0)
  self:moveTo(self.position)

  self.launched = false
  self.deployed = false
  self:addSprite()
end

function Supply:die()
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
      if other:isa(Enemy) then
        other:die()
        self:die()
      end
      if other:isa(Player) then
        other:die()
        self:die()
      end
      if other:isa(Block) then
        other:hit()
        self:die()
      end
    end

    -- animate jet
    self:setImage(self.imagesTable:getImage(animTimer.frame < 2 and 1 or 2), self.velocity.x < 0 and '' or 'flipX')

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
  if (not balloon.launched and not self.launched and rnd()>0.99) then
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
