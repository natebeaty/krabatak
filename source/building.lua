import "CoreLibs/sprites"

local gfx <const> = playdate.graphics
local random = math.random

class("Building").extends()
class("Block").extends(gfx.sprite)

local blockImagesTable = gfx.imagetable.new("images/block")
local blocksImagesTable = gfx.imagetable.new("images/block")
assert(blockImagesTable)

local columnWidth <const>, columnHeight <const> = blockImagesTable:getImage(1):getSize()
local maxBuildings <const> = 6
local maxColumns <const> = math.floor(310 / columnWidth)
local maxBuildingWidth <const> = 5

function Building:init()
  self.buildings = {}
  self.buildingcrash = {}
  self.rumblingrows = {}
  self.peopleleft = 2
end

function Block:init(x,y)
  Block.super.init(self)

  self.blockImages = blockImagesTable
  -- randomize window state
  self:setImage(self.blockImages:getImage(random(4)))
  self:setZIndex(900)
  self:setCollideRect(0, 0, self.blockImages:getImage(1):getSize())
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
  self.x = x
  self.y = y
  self:moveTo(x,y)
  -- self.collapsing = 0
  -- self.chomping = 0
  -- self.broken = 0
end

function Block:update()
  if self.collapsing ~= nil then
    self:setImage(self.blockImages:getImage(8 + self.collapsing % 5))
    self.collapsing = self.collapsing + 1
    if self.collapsing > 15 then
      self:remove()
    end
  elseif self.broken == nil and random(1000)>999 then
    self:setImage(self.blockImages:getImage(random(4)))
  end
end

function Block:hit()
  self.broken = true
  self:setGroups({2})
  -- random broken block sprite
  self:setImage(self.blockImages:getImage(4 + random(4)))
  building:checkBuildingCollapse()
end

function Block:collapse()
  self.collapsing = 1
  self:setGroups({2})
  shakeit = 0.2
end

--                          1
--           11            111
--  111      11            111
--  111     1111    11     111
-- 11111    1111   1111   11111
-- 11111   111111  1111   11111
-- 11111   111111  1111   11111

-- create randomized buildings
function Building:makeBuildings(maxHeight)
  maxHeight = maxHeight or 4

  -- clear buildings && rumbling rows
  self.buildings = {}
  self.rumblingrows = {}

  -- track people left (undamaged bricks)
  self.peopleleft = 3

  local lastX = 1
  local totalColumns = 1
  for i = 1, maxBuildings do
    if (totalColumns < maxColumns) then
      local building = {
        height = math.random(maxHeight) + 3,
        width = math.min(maxColumns - totalColumns, random(4) + maxBuildingWidth-3),
        floors = {},
        x = lastX
      }
      local gap = random(2)+1
      totalColumns += building.width + gap
      lastX = lastX + building.width + gap
      local lastFloorWidth = building.width
      for n = 1, building.height do
        -- support narrowing buildings as we ascend
        lastFloorWidth = lastFloorWidth>4 and rnd()>0.85 and lastFloorWidth - 2 or lastFloorWidth
        local floor = {
          blocks = {},
          width = lastFloorWidth
        }

        for x = 1, lastFloorWidth do
          local buildingLeftX = 40 + building.x*columnWidth
          local narrowingOffset = (building.width - lastFloorWidth)*columnWidth/2
          local block = Block(buildingLeftX + narrowingOffset + x*columnWidth, 224 - n * columnHeight)
          -- block.building = building
          block:addSprite()
          add(floor.blocks, block)
        end

        add(building.floors, floor)
      end
      -- self.peopleleft += building.height * building.width
      add(self.buildings, building)
    end
  end
end


-- check for any building rows with all damage
function Building:checkBuildingCollapse()
  for b = 1, #self.buildings do
    local buildingCollapsing = nil
    for i = 1, self.buildings[b].height do
      rowbusted = true
      for j=1, self.buildings[b].floors[i].width do
        local block = self.buildings[b].floors[i].blocks[j]
        if buildingCollapsing == nil and block.broken == nil then
          -- any undamaged pieces? row is not busted
          rowbusted = false
        end
      end
      if rowbusted then
        print("rowbusted", i)
        buildingCollapsing = buildingCollapsing or i-1
        -- mark all blocks in broken row as collapsing
        for j=1, self.buildings[b].floors[i].width do
          self.buildings[b].floors[i].blocks[j]:collapse()
        end
      end
    end
    -- reduce building height
    self.buildings[b].height = buildingCollapsing or self.buildings[b].height
    -- print("bh", self.buildings[b].height, buildingCollapsing)
  end
  return chk
end



-- buildings

--[[

-- randomly blink building lights
function building_blink(chk)
  if t%chk==0 then
    -- blink undamaged building lights
    for i=1,#buildings do
      for h=1,buildings[i].height do
        for w=1,buildings[i].width do
          local mx=buildings[i].x+w
          local my=13-buildings[i].height+h
          local map_sprite=mget(mx,my)
          if (chk==1 or rnd()>0.98) and fget(map_sprite,1) and not fget(map_sprite,2) then
            mset(mx,my,flr(rnd(5))+1)
          end
        end
      end
    end
  end
end

-- row to collapse
function new_rumblingrow(x,y,delay)
  local obj={x=x,y=y,delay=delay,t=0}
  obj.update=function(this)
    this.t+=1
    shakeit=0.05
    if (this.t > this.delay+15) then
      del(rumblingrows,this)
      camera(0,0)
    end
  end
  obj.draw=function(this)
    local sprite=24
    if (this.t>this.delay+6) then
      if this.t%3<2 then sprite=26 else sprite=27 end
    elseif (this.t>this.delay+3) then
      if this.t%3<2 then sprite=24 else sprite=25 end
    else
      if this.t%3<2 then sprite=22 else sprite=23 end
    end
    pset(this.x+rnd(10)-1,this.y+rnd(10)-1,1)
    pset(this.x+rnd(10)-1,this.y+rnd(10)-1,10)
    spr(sprite,this.x,this.y)
  end
  return obj
end

-- building update loop
function building_update()
  if #buildingcrash>0 then
    for obj in all(buildingcrash) do
      for i=1,obj.rowbusted do
        sfx(11)
        for j=1,obj.building.width do
          local mx=obj.building.x+j
          local my=13-obj.building.height+i
          mset(mx,my,8)
          add(rumblingrows,new_rumblingrow(mx*8,my*8,i*6))
        end
        -- any undamaged brick left?
        peopleleft-=obj.building.width
      end
      -- shorten building height
      obj.building.height-=obj.rowbusted
    end
    -- you killed picoville!
    if peopleleft<=0 then
      -- reset timer
      t=0
      if mode=="game" then
        game_over()
      end
    end
    buildingcrash={}
  end
  -- restart title stage if all buildings are destroyed
  if (t>150 and peopleleft<=0 and mode!="game") restart()
end

]]--
