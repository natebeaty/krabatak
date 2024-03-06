local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound

-- local cos, sin <const> = math.cos, math,sin

-- local bullet = {}
--
-- function bullet.shoot( start_x, start_y, mouse_x, mouse_y, speed )
--     local speed = speed or 200
--     local dir = math.atan2(( mouse_y - start_y ), ( mouse_x - start_x ))
--     local dx, dy = speed * math.cos(dir), speed * math.sin(dir)
--     table.insert( bullet, { x = start_x, y = start_y, dx = dx, dy = dy } )
-- end
--
-- function bullet.update(dt)
--     for i, v in ipairs( bullet ) do
--         v.x = v.x + v.dx * dt
--         v.y = v.y + v.dy * dt
--     end
-- end


-- https://love2d.org/forums/viewtopic.php?t=81518
-- Note: when you see frame, i'm actually talking about ticks, or the update rate; how fast one renders to the screen would be the framerate, and it should be separated from the update speed for various reasons, but ultimately for consistent gameplay; the default love.run game loop doesn't separate them, caveat emptor.

-- Just a simple function
-- function boss:update(frame) -- not dt, we want to be deterministic!
--   --start the boss at the top of the playfield
--   if frame == 1 then
--     self.position.x, self.position.y = playfield.width / 2, 0
--   end
--   -- every 5*60th frame (or five seconds) shoot a bullet pattern
--   -- could be done a dozen other ways too, like patterns not being in the boss char itself, but this will do
--   if frame % 60 == 0 then
--     self:shoot(self.bullet)
--   end
-- end
--
-- -- Now, for the pattern
-- bullet = {
--   -- position
--   x = 0,
--   y = 0,
--   -- velocity
--   r = 1, -- magnitude
--   a = 0, -- angle
--   -- inheritance
--   --parent   -- the boss id set at spawn, or other bullet ids depending on behaviour
--   --chilren  -- other bullets or even enemies, bullets firing bullets!
-- }
--
-- bullet:update(frame)
--   -- for each frame, calculate the next position using the velocity vector
--   local dx, dy = self.r * math.cos(self.a), self.r * math.sin(self.a)
--   self.x, self.y = self.x + dx, self.y + dy
--   -- now, you can either make such bullet scripts by having a bigger pattern object, that creates things with methods
--   -- (in which case, you needn't do anything else here)
--   -- or you could have each bullet have a script... a function inside them
--   self.script:update(frame)
--   -- that would create other bullets and set their parent to this bullet
-- end


class("BossBullet").extends(playdate.graphics.sprite)

local collisionSize = 3
local minXPosition = -40
local maxXPosition = 440
local minYPosition = -250
local maxYPosition = 250

local bulletGfx = gfx.imagetable.new("images/bullet-blorb")
local bulletGfx2 = gfx.imagetable.new("images/bullet-spinner")
local bulletSfx = sound.sampleplayer.new("sounds/boss-bullet")
local bulletSfx2 = sound.sampleplayer.new("sounds/boss-bullet2")
local bulletCache = {}

function addBossBullet(type, x, y, a, v)
  -- print("abb", type, x, y, a, v)
  local bullet = nil
  if #bulletCache > 0 then
    bullet = table.remove(bulletCache)
    bullet:setBulletType(type)
  else
    bullet = BossBullet(type)
  end

  bullet:moveTo(x, y)
  bullet:setAngle(a, v)
  bullet:add()
  bullet:sfx()
end

function removeBossBullet(bullet)
  bullet:remove()
  bulletCache[#bulletCache+1] = bullet
end

function BossBullet:init(type)
  BossBullet.super.init(self)

  self:setBulletType(type)
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  self:setZIndex(1001)
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
  self.t = 0

  return self
end

-- play sfx for bullet type
function BossBullet:sfx()
  if self.type == "lg" then
    bulletSfx2:play()
  else
    bulletSfx:play()
  end
end

-- update bullet type
function BossBullet:setBulletType(type)
  self.type = type
  local bullet = bulletGfx:getImage(1)
  if type == "lg" then
    bullet = bulletGfx2:getImage(1)
  end
  self:setImage(bullet)
  self:setCollideRect(0, 0, bullet:getSize())
end

-- set bullet velocity after init
function BossBullet:setAngle(a, v)
  self.a = a
  self.v = v
end

function BossBullet:update()
  self.t += 1
  local dx, dy = self.v * math.cos(self.a), self.v * math.sin(self.a)
  self.x, self.y = self.x + dx, self.y + dy
  local x,y,c,l = self:moveWithCollisions(self.x, self.y)

  local i = self.t % 4 == 0 and 1 or 2
  -- print("bb", self.t, self.t % 4i, dx, dy, x, y, l)
  if self.type == "lg" then
    self:setImage(bulletGfx:getImage(i))
  else
    self:setImage(bulletGfx2:getImage(i))
  end

  for i=1,l do
    local other = c[i].other
    if other:isa(Player) and not player.dying then
      player:die()
    end
    -- removeBossBullet(self)
  end

  if self.x < minXPosition or self.x > maxXPosition or self.y < minYPosition or self.y > maxYPosition or self.removeme then
    removeBossBullet(self)
  end
end
