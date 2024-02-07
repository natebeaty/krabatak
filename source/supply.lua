import "CoreLibs/sprites"
import "lib/AnimatedSprite.lua"
import "lib/state"

local gfx <const> = playdate.graphics
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D

class("Supply").extends(gfx.sprite)

local animTimer = playdate.frameTimer.new(6)
animTimer.repeats = true
local launchTimer = playdate.frameTimer.new(200)
launchTimer.repeats = true

local minXPosition = -100
local maxXPosition = 500
local minYPosition = -230
local maxYPosition = 260

local supplyImagesTable = gfx.imagetable.new("images/supply")
local balloonImagesTable = gfx.imagetable.new("images/balloon")

local gameState = State()
local screenWidth <const>, _ = playdate.display.getSize()

function Supply:init()
  Supply.super.init(self)

  self.imagesTable = supplyImagesTable
  self:setImage(self.imagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(5, 5, 46, 10)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.position = point.new(-200,0)
  self:moveTo(self.position)

  self.launched = false
  self.deployed = false
  self:addSprite()
end

function Supply:update()
  if self.launched then
    self.position += self.velocity
    -- print("supply pos", self.position, self.velocity)
    local x,y,c,l = self:moveWithCollisions(self.position)

    -- animate jet
    self:setImage(self.imagesTable:getImage(animTimer.frame < 2 and 1 or 2), self.velocity.x < 0 and '' or 'flipX')

    if self.position.x < minXPosition or self.position.x > maxXPosition then
      self.launched = false
    end

    -- emit balloon? check position across screen
    local screen_pos = self.velocity.x<1 and self.position.x/screenWidth or (screenWidth-self.position.x)/screenWidth
    if (screen_pos>0.2 and screen_pos<0.8 and rnd()>0.96) then
      local balloon = AnimatedSprite.new(balloonImagesTable)
      balloon.position = self.position
      balloon.velocity = vector2D.new(self.position.x < 0 and 1 or -1, 1)
      balloon:setCollideRect(0,0,balloonImagesTable:getImage(1):getSize())
      balloon:setGroups({1})
      balloon:setCollidesWithGroups({1})
      balloon.collisionResponse = gfx.sprite.kCollisionTypeOverlap
      balloon:addState("open", 3, 4, { tickStep = 2 })
      balloon:addState("parachute", 1, 2, { tickStep = 2, loop = 5, nextAnimation = "open" }).asDefault()
      balloon.states["parachute"].onAnimationEndEvent = function()
        balloon.velocity.x = 0
      end
      balloon:playAnimation()
      function balloon:update()
        self.position += self.velocity
        local x,y,c,l = self:moveWithCollisions(self.position)
        if l > 1 then
          self:die()
        end
        self:updateAnimation()
      end
      function balloon:die()
        new_explosion(self.position.x, self.position.y)
        self:remove()
      end
    end

  else
    self:checkLaunch()
  end

  -- offscreen?
  -- if (is_offstage(this,10)) del(supply,this)
end

function Supply:checkLaunch()
  if (not self.launched and not self.deployed and rnd()>0.99) then
    self:launch()
  end
end

function Supply:launch()
  print("launch supply")

  -- todo: honor cameraY (gameState?)
  self.position = point.new(rnd(1)>0.35 and -40 or screenWidth + 40, 30+(math.random(20)))
  self.velocity = vector2D.new(self.position.x < 0 and 2 or -2, 0)
  self:moveTo(self.position)

  self.launched = true
  self.deployed = false
end

--[[

-- spawn supply in update function
function check_supply_spawn()
  if (#supply<1 and #balloon<1 and t%3==0 and rnd()>0.99) add(supply,new_supply())
end
function check_train_spawn()
  if (#trains<1 and t%3==0 and rnd()>0.9) add(trains,new_train())
end
function check_balloon_spawn(obj)
  if (not obj.has_deployed and rnd()>0.96) add(balloon,new_balloon(obj))
end

-- new balloon!
function new_balloon(supply)
  supply.has_deployed=true
  local obj={x=supply.x,y=supply.y,dx=supply.dx,dy=1,sprite=37,t=0}
  obj.box={x1=0,y1=3,x2=8,y2=8}
  sfx(09)

  obj.update=function(this)
    self.t+=1
    -- hitting player?
    if (coll(this,p)) then
      sfx(10)
      p.resupply()
      balloon={}
    end

    -- check for collisions with enemies
    for grp in all({enemies,gremlins}) do
      for obj in all(grp) do
        if (coll(this,obj)) then
          obj.die(obj)
          self.die(this)
        end
      end
    end

    -- parachute open?
    if self.t < 20 then
      if t%4<2 then self.sprite=37 else self.sprite=38 end
    else
      self.dx=0
      self.dy=0.5
      if t%4<2 then self.sprite=39 else self.sprite=40 end
    end

    -- check for collisions with building
    check_building_hit(this,balloon)

    -- bottom of stage? pop balloon
    if (self.y>104) self.die(this)

    --move it
    self.x += self.dx
    self.y += self.dy

    -- offscreen?
    if (self.x<-10 or self.x>138 or self.y>138) del(balloon,this)
  end

  obj.draw=function(this)
    spr(self.sprite,self.x,self.y)
  end

  --bye bye
  obj.die=function(this)
    sfx(02)
    new_explosion(self.x,self.y)
    del(balloon,this)
  end

  --return the supply
  return obj
end

-- new supply!
function new_supply()
  local obj={x=0,y=10+(rnd(15)),dx=1,dy=0,sprite=35,flipx=false,t=0,has_deployed=false}
  -- which side of screen to spawn from?
  if rnd(1)>0.35 then
    obj.x=128
    obj.dx=-1
  end
  obj.box={x1=0,y1=2,x2=9,y2=9}

  obj.die=function(this)
    sfx(02)
    new_explosion(self.x,self.y)
    del(supply,this)
  end

  --return the supply
  return obj
end



-- new train!
-- function new_train()
--   local obj={x=-24,y=119,dx=1,dy=0,sprite=55,t=0,express=false}
--   -- which side of screen to spawn from?
--   if rnd()>0.3 then
--     obj.x=130
--     obj.dx=-1
--   end
--   if (rnd()>0.8) obj.express=true
--   obj.box={x1=0,y1=2,x2=22,y2=6}

--   obj.update=function(this)
--     self.t+=1

--     -- hitting player?
--     if (mode=="game" and p.dying==0 and coll(this,p)) then
--       p.die()
--     end

--     --move it!
--     if self.express then self.x+=self.dx*2 else self.x+=self.dx end
--     self.y += self.dy

--     -- offscreen?
--     if (is_offstage(this,40)) del(trains,this)
--   end

--   obj.draw=function(this)
--     -- make red if express
--     if (self.express) pal(9,8)
--     -- draw train cars
--     spr(self.sprite,self.x,self.y)
--     spr(self.sprite,self.x+8,self.y,1,1,true)
--     spr(self.sprite,self.x+16,self.y,1,1,true)
--     pal()
--   end

--   return obj
-- end

]]--