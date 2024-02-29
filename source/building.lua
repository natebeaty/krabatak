import "CoreLibs/sprites"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local random = math.random

class("Building").extends()
class("Block").extends(gfx.sprite)

local blockImages = gfx.imagetable.new("images/block")

local buildingHitSfx = sound.sampleplayer.new("sounds/crash")
local buildingCollapseSfx = sound.sampleplayer.new("sounds/building-collapse")

local columnWidth <const>, columnHeight <const> = blockImages:getImage(1):getSize()
local maxBuildings <const> = 6
local maxColumns <const> = math.floor(310 / columnWidth)
local maxBuildingWidth <const> = 5

-- new building
function Building:init()
  self.buildings = {}
  self.buildingcrash = {}
  self.rumblingrows = {}
  self.peopleleft = 2
end

-- new block
function Block:init(x,y)
  Block.super.init(self)

  -- randomize window state
  self:setImage(blockImages:getImage(random(5)))
  self:setZIndex(900)
  self:setCollideRect(0, 0, blockImages:getImage(1):getSize())
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  -- self.collisionpΩResponse = gfx.sprite.kCollisionTypeOverlap
  self.x = x
  self.y = y
  self:moveTo(x,y)
  -- self.collapsing = 0
  -- self.chomping = 0
  -- self.broken = 0
end

-- block update loop
function Block:update()
  -- collapsing?
  if self.collapsing ~= nil then
    self:setImage(blockImages:getImage(8 + self.collapsing % 5))
    self.collapsing = self.collapsing + 1
    if self.collapsing > 15 then
      self:remove()
    end
  elseif self.broken == nil and ((blinkyBuildings ~= nil and random(100)>80) or random(1000)>999) then
    -- blink lights?
    if blinkyBuildings then
      self:setImage(blockImages:getImage(rnd() > 0.5 and 1 or 5))
    else
      self:setImage(blockImages:getImage(random(5)))
    end
  end
end

-- block was hit by object
function Block:hit()
  buildingHitSfx:play()
  self.broken = true
  self:setGroups({2})
  -- random broken block sprite
  self:setImage(blockImages:getImage(5 + random(4)))
  building:checkBuildingCollapse()
end

-- mark block as collapsing
function Block:collapse()
  buildingCollapseSfx:play()
  self.collapsing = 1
  self:setGroups({2})
  -- trigger screen shake
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

-- check for any building rows with all damaged blocks
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
        buildingCollapsing = buildingCollapsing or i-1
        -- mark all blocks in broken row as collapsing
        for j=1, self.buildings[b].floors[i].width do
          self.buildings[b].floors[i].blocks[j]:collapse()
        end
      end
    end
    -- reduce building height
    self.buildings[b].height = buildingCollapsing or self.buildings[b].height
  end
  return chk
end

-- bonus count: find next good block and set bonus
function Building:checkBonus()
  for b = 1, #self.buildings do
    for i = 1, self.buildings[b].height do
      for j=1, self.buildings[b].floors[i].width do
        local block = self.buildings[b].floors[i].blocks[j]
        if block.broken == nil and block.bonused == nil then
          block.bonused = true
          player:addScore(10)
          block:setImage(blockImages:getImage(1))
          animations:bonusYay(block.x, block.y)
          return true
        end
      end
    end
  end
  return false
end

-- find next good block and set bonus
function Building:resetBonus()
  for b = 1, #self.buildings do
    for i = 1, self.buildings[b].height do
      for j=1, self.buildings[b].floors[i].width do
        self.buildings[b].floors[i].blocks[j].bonused = nil
      end
    end
  end
end

-- clear all building blocks
function Building:clearAll()
  blinkyBuildings = nil
  for b = 1, #self.buildings do
    for i = 1, self.buildings[b].height do
      for j=1, self.buildings[b].floors[i].width do
        self.buildings[b].floors[i].blocks[j]:remove()
      end
    end
  end
end

-- clear all building blocks
function Building:reshuffle()
  for b = 1, #self.buildings do
    for i = 1, self.buildings[b].height do
      for j=1, self.buildings[b].floors[i].width do
        local block = self.buildings[b].floors[i].blocks[j]
        block:setImage(blockImages:getImage(random(5)))
      end
    end
  end
end
