local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

class("Crab").extends(gfx.sprite)
class("Gremlin").extends(gfx.sprite)
class("Bishop").extends(gfx.sprite)
class("Enemy").extends()

local point <const> = playdate.geometry.point
local rect <const> = playdate.geometry.rect
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const> = math.random

local enemySpeed = 1
local crabMinX = -20
local crabMaxX = 420
local crabMaxY = 190

local crabImagesTable = gfx.imagetable.new("images/crabcat")
local gremlinImagesTable = gfx.imagetable.new("images/gremlin")
local bishopImagesTable = gfx.imagetable.new("images/bishop")
local bishopDamagedImagesTable = gfx.imagetable.new("images/bishop-damaged")

local crabDeathSfx = sound.sampleplayer.new("sounds/crab-death-combined")
local gremlinDeathSfx = sound.sampleplayer.new("sounds/gremlin-death-combined")
local bishopDeathSfx = sound.sampleplayer.new("sounds/bishop-death")
local bishopHitSfx = sound.sampleplayer.new("sounds/bishop-hit")

local crabs = {}
local bishops = {}
local gremlins = {}
local maxEnemies = 1

local crabCache = {}
local bishopCache = {}
local gremlinCache = {}

-- Bishops
function removeBishop(bishop)
  if bishop.laser then
    removeLaser(bishop.laser)
  end
  bishop.directionTimer:pause()
  bishop.stepTimer:pause()
  bishop.hits = 1
  bishop:remove()
  bishopCache[#bishopCache+1] = bishop
end

function addBishop(initialPosition)
  local bishop = nil
  if #bishopCache > 0 then
    bishop = table.remove(bishopCache)
    bishop.directionTimer:start()
    bishop.stepTimer:start()
  else
    bishop = Bishop()
  end
  bishop.position = initialPosition or point.new(rnd(400), 0)
  bishop.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  bishop:moveTo(bishop.position)
  return bishop
end

function Bishop:init()
  Bishop.super.init(self)
  self:setImage(bishopImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(2, 2, 33, 24)
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
  self.points = 20
  self.hits = 1
  self.lasering = 0
  return self
end

function Bishop:isDamaged()
  return self.hits < 1
end

function Bishop:changeDirection(s)
  self.directionTimer.duration = self:isDamaged() and random(50)+50 or random(100)+200
  self.directionTimer:reset()
  local multiplier = self:isDamaged() and 5 or 0.55
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * multiplier, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * multiplier
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * multiplier
  end
  self.velocity = vector2D.new(dx, dy)
end

function Bishop:die()
  Animations:explosion(self.position.x, self.position.y)
  if self.hits == 0 then
    bishopDeathSfx:play()
    del(bishops, self)
    removeBishop(self)
    return true
  else
    bishopHitSfx:play()
    self.directionTimer.duration = random(50)+50
    self.hits -= 1
    return false
  end
  -- self.directionTimer:remove()
  -- self:remove()
end

function Bishop:update()
  -- show damage if hit
  if self:isDamaged() then
    self:setImage(bishopDamagedImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  else
    self:setImage(bishopImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  end

  -- start lasering? ( and self.y > 50 and self.y < 200)
  if self.lasering == 0 and self.x > 50 and self.x < 350 and random(1000)>999 then
    self.lasering = 150
    self.laser = addLaser(self.x, self.y)
  end

  -- if not lasering, move
  if self.lasering == 0 then
    self.position += self.velocity
    self:moveTo(self.position)
  else
    self.lasering -= 1
  end

  -- offscreen?
  if self.position.y > crabMaxY or self.position.y < (verticalScroll and -230 or 0) then
    self.velocity.y = -self.velocity.y;
  end
  if self.position.x < crabMinX or self.position.x > crabMaxX then
    -- self.position = point.new(rnd(400), -cameraY)
    self.velocity.x = -self.velocity.x;
  end
end

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

function Crab:changeDirection(s)
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  end
  self.velocity = vector2D.new(dx, dy)
  Gremlin:checkSpawn(self.position)
  -- print("enemy changedirection", self.velocity)
end

function Crab:die()
  crabDeathSfx:play()
  Animations:explosion(self.position.x, self.position.y)
  del(crabs, self)
  removeCrab(self)
  -- self.directionTimer:remove()
  -- self:remove()
  return true
end

function Crab:update()
  self:setImage(crabImagesTable:getImage(self.stepTimer.frame < 3 and 1 or 2))

  if self.chomp == 0 then

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
    -- TODO: add chomping animation?
    if self.chomp == 0 then
      -- break brick under enemy
      self.chompBlock:hit()
    end

  end

  -- offscreen?
  if self.position.y > crabMaxY or self.position.y < (verticalScroll and -230 or -10) then
    self.velocity.y = -self.velocity.y*1.25;
  end
  if self.position.x < crabMinX or self.position.x > crabMaxX then
    -- self.position = point.new(rnd(400), -cameraY)
    self.velocity.x = -self.velocity.x*1.25;
  end
end


-- Gremlins
function Gremlin:init(initialPosition)
  Gremlin.super.init(self)
  -- print("gremlin init")

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
  -- print("gremlin checkspawn",initialPosition)
  if maxEnemies > 1 and random(1000)>800 and #gremlins < maxEnemies and initialPosition.x > 35 and initialPosition.x < 365 then
    local enemy = Gremlin(initialPosition)
    enemy:add()
    add(gremlins, enemy)
  end
end

function Gremlin:changeDirection(s)
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.5, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.5
  self.velocity = vector2D.new(dx, dy)
  -- print("gremlin changedirection", self.velocity)
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

  --bounce egg off buildings
  -- if self.mode=="egg" then
  --   local hit=is_undamaged_brick(self.position.x+3,self.position.y+self.velocity.y+6,this,"egg",true)
  --   if self.velocity.y>0 and self.position.y<100 and hit then
  --     self.velocity.y=0
  --     if rnd()>0.5 then self.velocity.x=-0.33 else self.velocity.x=0.33 end
  --     self.bouncing=1
  --   end
  --   if self.velocity.y==0 and not hit then
  --     self.velocity.y=1
  --     self.bouncing=0
  --     -- if (self.velocity.x<0) self.position.x-=3
  --     self.velocity.x=0
  --   end
  -- end

  -- if self.bouncing and self.y > self.bouncing then
  --   self.velocity.x = 0
  --   self.bouncing = 0
  -- end

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

  -- offscreen?
  -- if (self.position.x<-10 or self.position.x>138) del(gremlins,this)

  -- if self.bouncing > 0 then
  --   local bb={0,0,1,2,3,3,2,1,0,0}
  --   spr(self.sprite,self.position.x,self.position.y-bb[self.bouncing%#bb+1],1,1,self.flipx)
  --   self.bouncing+=1
  -- else
  --   spr(self.sprite,self.position.x,self.position.y,1,1,self.flipx)
  -- end

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

-- static Enemy
function Enemy:setMax(n)
  maxEnemies = n
end
function Enemy:resetAll()
  for a=1, #crabs do
    removeCrab(crabs[a])
  end
  for a=1, #gremlins do
    gremlins[a]:remove()
  end
  for a=1, #bishops do
    removeBishop(bishops[a])
  end
  crabs = {}
  gremlins = {}
  bishops = {}
end

function Enemy:checkSpawn()
  -- spawn crabs
  if (#crabs < maxEnemies and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = addCrab(point)
    -- print(point)
    enemy:add()
    add(crabs, enemy)
  end

  -- spawn bishops
  if (day > 0 and #bishops < maxEnemies and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = addBishop(point)
    -- print(point)
    enemy:add()
    add(bishops, enemy)
  end
end
