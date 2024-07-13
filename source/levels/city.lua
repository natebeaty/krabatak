import "CoreLibs/sprites"

class("City").extends()

local gfx <const> = playdate.graphics
local bgCloudGfx = gfx.image.new("images/bg-clouds-tall")
local bgDuskGfx = gfx.image.new("images/bg-dusk-tall")
local bgNightGfx = gfx.image.new("images/bg-night-tall")
local bgGfx = bgCloudGfx
local currentBg
local cityY

local function addCollisionBox(x,y,w,h,boundaryName)
  local box = gfx.sprite:new()
  -- box:setIgnoresDrawOffset(true)
  box:setZIndex(1000)
  box:moveTo(x,y)
  box:setCenter(0,0) -- set center point to left bottom
  box:setSize(w,h)
  box:setCollideRect(0,0,w,h)
  box:setGroups({1})
  box:setCollidesWithGroups({1})
  box:add()
  -- flag used for collision behavior
  box.boundaryName = boundaryName or "wall"
end

function City.init()
  -- screen borders (these were just causing problems with sprites getting confused & stuck outside bounds)
  -- addCollisionBox(-5,0,5,240)
  -- addCollisionBox(400,0,5,240)
  -- addCollisionBox(0,0,400,25)

  -- floor borders
  addCollisionBox(24,203,7,19)
  addCollisionBox(30,216,339,6)
  addCollisionBox(369,203,7,19)

  -- man/plane changes
  addCollisionBox(0,201,31,5,"playerModeSwitch")
  addCollisionBox(370,201,31,5,"playerModeSwitch")

  currentBg = "day"
  cityY = -120
  local citySprite = gfx.sprite.setBackgroundDrawingCallback(
    function(x, y, width, height)
      -- if mode == "title" then
        -- bgGfx.draw(0, 0)
      -- else
      bgGfx:draw(0, cityY)
      -- end
    end
  )
end

function City.setY(y)
  cityY = y
  gfx.sprite.redrawBackground()
  -- gfx.setDrawOffset(0, y)
end

function City.changeBg(bg)
  if bg == "night" then
    bgGfx = bgNightGfx
  elseif bg == "dusk" then
    bgGfx = bgDuskGfx
  else
    bgGfx = bgCloudGfx
  end
  bg = bg
  gfx.sprite.redrawBackground()
end
