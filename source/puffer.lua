local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const>, rad <const> = math.random, math.sin, math.cos, math.atan2, math.rad

class("Puffer").extends(gfx.sprite)

local pufferImagesTable = gfx.imagetable.new("images/puffer")
local pufferPuffingImagesTable = gfx.imagetable.new("images/puffer-puffing")
local pufferHitSfx = sound.sampleplayer.new("sounds/bishop-hit")
local pufferCache = {}
local puffingFrames = {
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
  4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
  4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
  3,3,6,6,3,3,6,6,3,3,6,6,3,3,6,6,
  3,3,6,6,3,3,6,6,6,3,6,3,6,3,6,3,
  3,6,3,6,3,6,3,3,6,3,6,3,6,3,6,3,
}

-- Puffers
function removePuffer(puffer)
  puffer.directionTimer:reset()
  puffer.directionTimer:pause()
  puffer.stepTimer:pause()
  puffer.hits = 2
  puffer.puffing = 0
  puffer:remove()
  pufferCache[#pufferCache+1] = puffer
end

function addPuffer(initialPosition)
  local puffer = nil
  if #pufferCache > 0 then
    puffer = table.remove(pufferCache)
    puffer.directionTimer:start()
    puffer.stepTimer:start()
  else
    puffer = Puffer()
  end
  puffer.position = initialPosition or point.new(rnd(400), 0)
  puffer.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  puffer:moveTo(puffer.position)
  return puffer
end

function Puffer:init()
  Puffer.super.init(self)
  self:setImage(pufferImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(3, 5, 34, 30)
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
  self.points = 30
  self.hits = 2
  self.puffing = 0
  return self
end

function Puffer:isDamaged()
  return self.hits < 2
end

function Puffer:changeDirection()
  self.directionTimer.duration = random(10)+200
  self.directionTimer:reset()
  local multiplier = self:isDamaged() and 2 or 1.25
  local dx, dy = (rnd(2)-1) * (50/10000+1.25) * multiplier, (rnd()) * (50/10000+1.5) * multiplier
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (100/10000+1.5) * multiplier
  end
  self.velocity = vector2D.new(dx, dy)
end

function Puffer:die()
  Animations:explosion(self.position.x, self.position.y)
  if self.hits == 0 then
    pufferHitSfx:play()
    del(puffers, self)
    removePuffer(self)
    return true
  else
    pufferHitSfx:play()
    -- abruptly move towards player when hit
    -- local angleToPlayer = atan2(player.y - self.y, player.x - self.x)
    -- local dx, dy = cos(angleToPlayer) * 1.5, sin(angleToPlayer) * 1.5
    -- self.velocity = vector2D.new(dx, dy)
    -- self.directionTimer.duration = random(250)+50
    if self.puffing == 0 then
      self.puffing = #puffingFrames - 1
    end
    self.hits -= 1
    return false
  end
  -- self.directionTimer:remove()
  -- self:remove()
end

function Puffer:update()
  -- show damage if hit
  if self.puffing > 0 then
    self:setImage(pufferPuffingImagesTable:getImage(puffingFrames[#puffingFrames - self.puffing]))
  else
    self:setImage(pufferImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  end

  -- shoot stars!
  if self.puffing == 1 then
    local numStars = random(8,20)
    for i=1,numStars do
      addEnemyBullet(self.x, self.y, rad(360/numStars * i), 4)
    end
  end

  -- start puffing?
  if self.puffing == 0 and isVisible(self.x,self.y,self.width,self.height) and random(1000)>995 then
    self.puffing = #puffingFrames
  end

  -- if not puffing, move
  if self.puffing == 0 then
    self.position += self.velocity
    self:moveTo(self.position)
  else
    -- if self:isDamaged() then
    --   -- move slowly while puffing if damaged
    --   self.position += self.velocity * 0.15
    --   self:moveTo(self.position)
    --   -- self.laser:setPosition(self.x, self.y)
    -- end
    self.puffing -= 1
  end

  -- offscreen? reverse
  if self.position.y > enemyMaxY or self.position.y < (verticalScroll and -230 or 0) then
    self.velocity.y = -self.velocity.y;
  end
  if self.position.x < enemyMinX or self.position.x > enemyMaxX then
    self.velocity.x = -self.velocity.x;
  end
end
