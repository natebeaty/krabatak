
local gfx <const> = playdate.graphics

class("Crab").extends(gfx.sprite)
class("Gremlin").extends(gfx.sprite)
class("Enemy").extends()

local point <const> = playdate.geometry.point
local rect <const> = playdate.geometry.rect
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const> = math.random

local enemySpeed = 1
local crabMinX = -40
local crabMaxX = 440
local minYPosition = verticalScroll and -230 or -20
local crabMaxY = 200

local crabImagesTable = gfx.imagetable.new("images/crabcat")
local gremlinImagesTable = gfx.imagetable.new("images/gremlin")

local crabs = {}
local gremlins = {}
local maxEnemies = 2

function Enemy:setMax(n)
  maxEnemies = n
end

function Enemy:resetAll()
  for a=1, #crabs do
    crabs[a].directionTimer:remove()
    crabs[a]:remove()
  end
  for a=1, #gremlins do
    gremlins[a]:remove()
  end
  crabs = {}
  gremlins = {}
end

function Crab:init(initialPosition)
  Crab.super.init(self)

  self.imageTable = crabImagesTable
  self:setImage(self.imageTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 40, 14)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(random(50)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.position = initialPosition or point.new(rnd(400), 0)
  self.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  self:moveTo(self.position)

  self.isEnemy = true
  self.points = 10
  self.chomp = 0
  self.chompCoords = {}
end

function Crab:checkSpawn()
  -- print("check spawn", #crabs, maxEnemies)
  if (#crabs < maxEnemies and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = Crab(point)
    print(point)
    enemy:addSprite()
    add(crabs, enemy)
  end
end

function Crab:changeDirection(s)
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  if self.position.y>50 then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  end
  self.velocity = vector2D.new(dx, dy)
  Gremlin:checkSpawn(self.position)
  -- print("enemy changedirection", self.velocity)
end

function Crab:die()
  Animations:explosion(self.position.x, self.position.y)
  del(crabs, self)
  self.directionTimer:remove()
  self:remove()
end

function Crab:update()
  self.position += self.velocity
  self:setImage(self.imageTable:getImage(self.stepTimer.frame < 3 and 1 or 2))
  self:moveTo(self.position)
  -- offscreen?
  if self.position.y > crabMaxY or self.position.x < crabMinX or self.position.x > crabMaxX or self.position.y < minYPosition then
    self.position = point.new(rnd(400), -cameraY)
  end
end


-- Gremlins

function Gremlin:init(initialPosition)
  Gremlin.super.init(self)

  self.imageTable = gremlinImagesTable
  self:setImage(self.imageTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(0,0,self.imageTable:getImage(1):getSize())
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true

  self.position = initialPosition
  self.velocity = vector2D.new(0, 1.5)
  self:moveTo(self.position)

  self.mode="egg"
  self.bouncing=0
  self.chomp = 0
  self.isEnemy = true
  self.points = 20
  self.chompCoords = {}
end

function Gremlin:checkSpawn(initialPosition)
  -- print("gremlin checkspawn",initialPosition)
  if random(1000)>500 and #gremlins < maxEnemies and initialPosition.x > 35 and initialPosition.x < 365 then
    local enemy = Gremlin(initialPosition)
    enemy:addSprite()
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
  Animations:explosion(self.position.x, self.position.y)
  del(gremlins, self)
  self:remove()
end

function Gremlin:update()
  -- animate egg or gremlin
  if self.mode=="egg" then
    self:setImage(self.imageTable:getImage(self.stepTimer.frame < 3 and 3 or 4))
  elseif self.mode=="gremlin" then
    self:setImage(self.imageTable:getImage(self.stepTimer.frame < 3 and 1 or 2))
  end

  --wandering gremlin
  if self.mode=="gremlin" then
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

  --move it unless chompin'
  if self.chomp == 0 then
    self.position += self.velocity
  else
    self.chomp -= 1
    -- add chomping animation?
    if self.chomp == 0 then
      -- break brick under gremlin
      -- local chk=damage_brick(self.chompcoords.mx,self.chompcoords.my)
      -- if gremlin collapsed a building row, it destroyed the building, kill gremlin
      -- if (chk) self.die(this)
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

  -- chomp?
  -- if self.mode=="gremlin" and self.chomp==0 and flr(self.position.x+8)%8==0 and self.position.y<=116 and rnd()>0.5 then
  --   local hit=is_undamaged_brick(self.position.x,self.position.y,this,gremlins,true)
  --   if hit then
  --     self.chompcoords=hit
  --     self.chomp=70
  --   end
  -- end

  -- offscreen?
  -- if (self.position.x<-10 or self.position.x>138) del(gremlins,this)

  -- if self.bouncing > 0 then
  --   local bb={0,0,1,2,3,3,2,1,0,0}
  --   spr(self.sprite,self.position.x,self.position.y-bb[self.bouncing%#bb+1],1,1,self.flipx)
  --   self.bouncing+=1
  -- else
  --   spr(self.sprite,self.position.x,self.position.y,1,1,self.flipx)
  -- end

  self:moveTo(self.position)

end
