local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const>, rad <const> = math.random, math.sin, math.cos, math.atan2, math.rad

class("Jellyfish").extends(gfx.sprite)
local jellyfishImagesTable = gfx.imagetable.new("images/jellyfish")
local jellyfishHitSfx = sound.sampleplayer.new("sounds/bishop-hit")
local bubbleSfx = sound.sampleplayer.new("sounds/bubble")
local jellyfishCache = {}
local idleFrames = {
  1,1,1,1,1,
  2,2,2,2,2,
  3,3,3,3,3,
  4,4,4,4,4,
  5,5,5,5,5,
  6,6,6,6,6,
  7,7,7,7,7,
}
local surgingFrames = {
  8,8,8,8,8,
  9,9,9,9,9,
  10,10,10,10,10,
  11,11,11,11,11,
  12,12,12,12,12,
  13,13,13,13,13,
  14,14,14,14,14,
  15,15,15,15,15,
}
local frameAt = 1;

-- Jellyfish
function removeJellyfish(jellyfish)
  jellyfish.directionTimer:reset()
  jellyfish.directionTimer:pause()
  jellyfish.stepTimer:pause()
  jellyfish.hits = 2
  jellyfish.surging = 0
  jellyfish:remove()
  jellyfishCache[#jellyfishCache+1] = jellyfish
end

function addJellyfish(initialPosition, initialVelocity)
  local jellyfish = nil
  if #jellyfishCache > 0 then
    jellyfish = table.remove(jellyfishCache)
    jellyfish.directionTimer:start()
    jellyfish.stepTimer:start()
  else
    jellyfish = Jellyfish()
  end
  jellyfish.position = initialPosition or point.new(rnd(400), 0)
  jellyfish.velocity = initialVelocity or vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  jellyfish:moveTo(jellyfish.position)
  return jellyfish
end

function Jellyfish:init()
  Jellyfish.super.init(self)
  self:setImage(jellyfishImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(20, 3, 22, 50)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(random(80)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.isEnemy = true
  self.points = 30
  self.hits = 2
  self.surging = 0
  self.thrust = 1
  return self
end

function Jellyfish:isDamaged()
  return self.hits < 2
end

function Jellyfish:changeDirection()
  self.directionTimer.duration = random(80)+100
  self.directionTimer:reset()
  local multiplier = self:isDamaged() and 1.2 or 0.5
  local dx, dy = (rnd(2)-1) * (50/10000+0.5) * multiplier, (rnd()) * (50/10000+0.5) * multiplier
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (25/10000+1.5) * multiplier
  end
  self.velocity = vector2D.new(dx, dy)
end

function Jellyfish:die()
  Animations:explosion(self.position.x, self.position.y)
  if self.hits == 0 then
    jellyfishHitSfx:play()
    del(jellyfish, self)
    removeJellyfish(self)
    return true
  else
    jellyfishHitSfx:play()
    -- abruptly move towards player when hit
    -- local angleToPlayer = atan2(player.y - self.y, player.x - self.x)
    -- local dx, dy = cos(angleToPlayer) * 1.5, sin(angleToPlayer) * 1.5
    -- self.velocity = vector2D.new(dx, dy)
    -- self.directionTimer.duration = random(250)+50
    if self.surging == 0 then
      self.surging = #surgingFrames - 1
    end
    self.hits -= 1
    return false
  end
  -- self.directionTimer:remove()
  -- self:remove()
end

function Jellyfish:update()
  frameAt += 1;
  -- show damage if hit
  if self.surging > 0 then
    if frameAt > #surgingFrames then
      frameAt = 1
    end
    -- if self.surging > 20 then
    --   self.velocity = vector2D.new(self.velocity.x, -5)
    -- end
    self:setImage(jellyfishImagesTable:getImage(surgingFrames[#surgingFrames - self.surging]))
  else
    if frameAt > #idleFrames then
      frameAt = 1
    end
    self:setImage(jellyfishImagesTable:getImage(idleFrames[frameAt]))
  end

  -- add thrust up when nearing end of surge animation
  if self.surging == 20 then
    self.thrust = 1.2 + random(8)*0.10
    -- make sure we're surging up
    if self.velocity.y>0 then
      self.velocity.y = -self.velocity.y
    end
    -- emit some bubbles
    for i=1,random(1,3) do
      local x = self.x + (rnd(2)-1)*random(5,10)
      local y = self.y + 10 + (rnd(2)-1)*random(5,10)
      addEnemyBullet(x, y, rad(90), -rnd(1)-0.5, 2)
      bubbleSfx:play()
    end
  end

  -- start surging?
  if self.surging == 0 and isVisible(self.x,self.y,self.width,self.height) and random(1000)>995 then
    self.surging = #surgingFrames
  end

  -- move it
  self.position += self.velocity
  self:moveTo(self.position)

  -- decrease surging counter
  if self.surging > 0 then
    self.surging -= 1
  end

  -- decrease thrust if > 1
  if self.thrust > 1 then
    self.thrust = self.thrust*0.91
    self.velocity.y = self.velocity.y * self.thrust;
  end

  -- at bottom, left or right? reverse
  if self.position.y > enemyMaxY then
    self.velocity.y = clamp(-self.velocity.y*1.15, -1, -2);
  end
  if self.position.x < enemyMinX or self.position.x > enemyMaxX then
    self.velocity.x = -self.velocity.x*1.25;
  end

    -- too high? remove
  if self.position.y < -cameraY - 50 then
    del(jellyfish, self)
    removeJellyfish(self)
  end

end
