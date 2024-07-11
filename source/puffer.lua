local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const> = math.random, math.sin, math.cos, math.atan2

class("Puffer").extends(gfx.sprite)

local pufferImagesTable = gfx.imagetable.new("images/puffer")
local pufferHitSfx = sound.sampleplayer.new("sounds/bishop-hit")
local pufferCache = {}

-- Puffers
function removePuffer(puffer)
  puffer.directionTimer:pause()
  puffer.stepTimer:pause()
  puffer.hits = 2
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
  local multiplier = self:isDamaged() and 5 or 0.55
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier
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
    local angleToPlayer = atan2(player.y - self.y, player.x - self.x)
    local dx, dy = cos(angleToPlayer) * 1.5, sin(angleToPlayer) * 1.5
    self.velocity = vector2D.new(dx, dy)
    self.directionTimer.duration = random(250)+50
    self.hits -= 1
    return false
  end
  -- self.directionTimer:remove()
  -- self:remove()
end

function Puffer:update()
  -- show damage if hit
  -- if self:isDamaged() then
  --   self:setImage(pufferDamagedImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  -- else
    self:setImage(pufferImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  -- end

  -- start puffing? ( and self.y > 50 and self.y < 200)
  if self.puffing == 0 and self.x > 50 and self.x < 350 and random(1000)>995 then
    self.puffing = 150
    -- self.laser = addLaser(self.x, self.y)
  end

  -- if not puffing, move
  if self.puffing == 0 then
    self.position += self.velocity
    self:moveTo(self.position)
  else
    if self:isDamaged() then
      -- move slowly while puffing if damaged
      self.position += self.velocity * 0.15
      self:moveTo(self.position)
      -- self.laser:setPosition(self.x, self.y)
    end
    self.puffing -= 1
  end

  -- offscreen?
  if self.position.y > enemyMaxY or self.position.y < (verticalScroll and -230 or 0) then
    self.velocity.y = -self.velocity.y;
  end
  if self.position.x < enemyMinX or self.position.x > enemyMaxX then
    -- self.position = point.new(rnd(400), -cameraY)
    self.velocity.x = -self.velocity.x;
  end
end
