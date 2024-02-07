
local gfx <const> = playdate.graphics

class("Enemy").extends(gfx.sprite)

local point <const> = playdate.geometry.point
local rect <const> = playdate.geometry.rect
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer

local enemySpeed = 1
local minXPosition = -20
local maxXPosition = 390
local minYPosition = -230
local maxYPosition = 260

local enemyImagesTable = gfx.imagetable.new("images/crabcat")

function Enemy:init(initialPosition)
  Enemy.super.init(self)

  self.enemyImages = enemyImagesTable
  self:setImage(self.enemyImages:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 40, 14)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(math.random(50)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.position = initialPosition or point.new(rnd(400), 0)
  self.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  self:moveTo(self.position)

  self.mode = "crab"
  self.chomp = 0
  self.chompCoords = {}
end


function Enemy:changeDirection(s)
  self.directionTimer.duration = math.random(50)+25
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  if self.position.y>50 then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  end
  self.velocity = vector2D.new(dx, dy)
  -- print("enemy changedirection", self.velocity)
end


function Enemy:die()
  new_explosion(self.position.x, self.position.y)
  remove_enemy(self)
end


function Enemy:update()
  self.position += self.velocity
  self:setImage(self.enemyImages:getImage(self.directionTimer.frame%5<3 and 1 or 2))
  local x,y,c,l = self:moveWithCollisions(self.position)
  if self.position.y > maxYPosition or self.position.x < minXPosition or self.position.x > maxXPosition or self.position.y < minYPosition then
    remove_enemy(self)
  end
end
