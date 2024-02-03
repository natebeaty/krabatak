
class('Enemy').extends(playdate.graphics.sprite)

-- local references
local point = playdate.geometry.point
local rect = playdate.geometry.rect
local vector2D = playdate.geometry.vector2D
local floor = math.floor

-- class variables
local stepTimer = playdate.frameTimer.new(6)
stepTimer.repeats = true
local directionTimer = playdate.frameTimer.new(200)
directionTimer.repeats = true
local enemySpeed = 1

local minXPosition = 10
local maxXPosition = 390
local minYPosition = -230
local maxYPosition = 230

function Enemy:init(initialPosition)
  print("new enemy", initialPosition)
  Enemy.super.init(self)

  self.enemyImages = playdate.graphics.imagetable.new('images/crabcat')
  self:setImage(self.enemyImages:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 40, 14)
  self.position = initialPosition or point.new(rnd(400), 0)
  self:moveTo(self.position)

  self.mode = "crab"
  self.chomp = 0
  self.chompCoords = {}
  self.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
end


function Enemy:collisionResponse(other)
  -- if other:isa(Player) then
    return "overlap"
  -- end
  -- return "freeze"
end


function Enemy:changeDirections()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  if self.position.y>50 then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  end
  self.velocity = vector2D.new(dx, dy)
  -- print("enemy changedirections", self.velocity)
end


function Enemy:die()
  new_explosion(self.position.x, self.position.y)
  remove_enemy(self)
end


function Enemy:update()

  self.position.x = self.position.x + self.velocity.x
  self.position.y = self.position.y + self.velocity.y

  local collisions, len
  self.position.x, self.position.y, collisions, len = self:moveWithCollisions(self.position)

  if stepTimer.frame < 3 then
    self:setImage(self.enemyImages:getImage(1))
  else
    self:setImage(self.enemyImages:getImage(2))
  end

  -- todo: randomize this
  if directionTimer.frame % 10==0 and rnd()>0.95 then
    self:changeDirections()
  end

  if directionTimer.frame > rnd(50)+50 then
    directionTimer:reset()
    self:changeDirections()
  end

  if self.position.y > maxYPosition or self.position.x < minXPosition or self.position.x > maxXPosition or self.position.y < minYPosition then
    remove_enemy(self)
  end

end
