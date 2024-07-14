local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const>, rad <const> = math.random, math.sin, math.cos, math.atan2, math.rad

class("Crab").extends(gfx.sprite)
class("Gremlin").extends(gfx.sprite)

local crabImagesTable = gfx.imagetable.new("images/crabcat")
local gremlinImagesTable = gfx.imagetable.new("images/gremlin")

local crabDeathSfx = sound.sampleplayer.new("sounds/crab-death-combined")
local gremlinDeathSfx = sound.sampleplayer.new("sounds/gremlin-death-combined")

local crabCache = {}
local gremlinCache = {}

--------
-- Crabs

function removeCrab(crab)
  crab.directionTimer:pause()
  crab.stepTimer:pause()
  crab:remove()
  crabCache[#crabCache+1] = crab
end

function addCrab(initialPosition)
  local crab = nil
  if #crabCache > 0 then
    crab = table.remove(crabCache)
    crab.directionTimer:start()
    crab.stepTimer:start()
  else
    crab = Crab(initialPosition)
  end

  crab.position = initialPosition or point.new(rnd(400), 0)
  crab.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  crab:moveTo(crab.position)
  return crab
end

function Crab:init()
  Crab.super.init(self)

  self:setImage(crabImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 40, 14)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(random(50)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.isEnemy = true
  self.points = 10
  self.chomp = 0
  self.chompBlock = nil

  return self
end

function Crab:changeDirection()
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 47.5/10000+1) * 1.25, (rnd()) * (enemySpeed * enemySpeed * 55.5/10000+1) * 1.55
  -- bounce off edge
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 1.75
  end
  self.velocity = vector2D.new(dx, dy)
  Gremlin:checkSpawn(self.position)
end

function Crab:die()
  crabDeathSfx:play()
  Animations:explosion(self.position.x, self.position.y)
  del(crabs, self)
  removeCrab(self)
  return true
end

function Crab:update()
  self:setImage(crabImagesTable:getImage(self.stepTimer.frame < 3 and 1 or 2))

  -- shoot towards player?
  if day>3 and random(1000)>995 then
    local angleToPlayer = atan2(player.y - self.y, player.x - self.x)
    -- local dx, dy = cos(angleToPlayer) * 1.5, sin(angleToPlayer) * 1.5
    addEnemyBullet(self.x, self.y, angleToPlayer, 2)
  end

  if self.chomp == 0 then

    -- move it unless we're chompin'
    self.position += self.velocity
    local x,y,c,l = self:moveWithCollisions(self.position)
    for i = 1, l do
      local other = c[i].other
      -- crab on top of brick? chomp it
      if self.chomp == 0 and other:isa(Block) and random(1000)>990 and closeness(self,other) < 3 then
        self.chompBlock = other
        self.chomp = 70
      end
    end

  else

    self.chomp -= 1
    -- TODO: add chomping animation? sounds?
    if self.chomp == 0 then
      -- break brick under enemy
      self.chompBlock:hit()
    end

  end

  -- offscreen?
  if self.position.y > enemyMaxY or self.position.y < -cameraY-10 then
    self.velocity.y = -self.velocity.y;
  end
  if self.position.x < enemyMinX or self.position.x > enemyMaxX then
    self.velocity.x = -self.velocity.x;
  end
end

-----------
-- Gremlins

function Gremlin:init(initialPosition)
  Gremlin.super.init(self)

  self:setImage(gremlinImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(0,0,gremlinImagesTable:getImage(1):getSize())
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true

  self.position = initialPosition
  self.velocity = vector2D.new(0, 1.5)
  self:moveTo(self.position)

  self.mode = "egg"
  self.bouncing = 0
  self.chomp = 0
  self.chompBlock = nil
  self.isEnemy = true
  self.points = 20
end

-- spawn gremlin from crab?
function Gremlin:checkSpawn(initialPosition)
  if maxEnemies > 1 and random(1000)>800 and #gremlins < maxEnemies and initialPosition.x > 35 and initialPosition.x < 365 then
    local enemy = Gremlin(initialPosition)
    enemy:add()
    add(gremlins, enemy)
  end
end

function Gremlin:changeDirection()
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 48/10000+1) * 0.5, (rnd()) * (enemySpeed * enemySpeed * 48/10000+1) * 0.5
  self.velocity = vector2D.new(dx, dy)
end

function Gremlin:die()
  gremlinDeathSfx:play()
  Animations:explosion(self.position.x, self.position.y)
  del(gremlins, self)
  self:remove()
end

-- function Gremlin:collisionResponse(other)
--   -- If hitting brick, slide off it
--   if self.mode == "egg" and other:isa(Block) then
--     return "slide"
--   else
--     return "overlap"
--   end
-- end

function Gremlin:update()
  -- animate egg or gremlin
  if self.mode == "egg" then
    self:setImage(gremlinImagesTable:getImage(self.stepTimer.frame < 3 and 3 or 4))
  elseif self.mode=="gremlin" then
    self:setImage(gremlinImagesTable:getImage(self.stepTimer.frame < 3 and 1 or 2))
  end

  --wandering gremlin
  if self.mode == "gremlin" then
    -- bounce from edges
    if (self.position.y<210 or self.position.y>236) then
      self.velocity.y = -self.velocity.y * 0.5
    end
    if (self.position.x < 35 or self.position.x > 365) then
      self.velocity.x = -self.velocity.x
    end
  end

  --move it unless chompin'
  if self.chomp == 0 then
    self.position += self.velocity
  else
    self.chomp -= 1
    -- TODO: add chomping animation?
    if self.chomp == 0 then
      -- break brick under gremlin
      self.chompBlock:hit()
      -- TODO: if gremlin collapsed a building row, it destroyed the building, kill gremlin
      -- maybe move this to collision checks when collapsing the whole building? destroy any gremlins overlapping?
    end
  end

  -- turn into gremlin?
  if self.mode == "egg" and self.position.y > 210 then
    -- sfx(16)
    self.mode = "gremlin"
    self.directionTimer = frameTimer.new(random(50)+100, function()
      self:changeDirection()
    end)
    self.directionTimer.repeats = true
    self.velocity.y = 0
  end

  local x,y,c,l = self:moveWithCollisions(self.position)
  for i = 1, l do

    local other = c[i].other
    -- if self.mode == "egg" and self.velocity.x == 0 and other:isa(Block) then
    --   -- mark point started bouncing against building
    --   self.position.y = self.position.y - self.velocity.y
    --   if rnd()>0.5 then self.velocity.x=-0.33 else self.velocity.x=0.33 end
    --   self.bouncing = 1
    -- end

    -- colliding with block? not chompin? sprites close enough? chomp it
    if self.mode == "gremlin" and self.chomp == 0 and random(1000)>990 and other:isa(Block) and closeness(self,other) < 3 then
      self.chompBlock = other
      self.chomp = 70
    end

  end

end
