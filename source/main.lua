import "CoreLibs/frameTimer"
import "CoreLibs/graphics"
import "lib/state"
import "utility"
import "player"
import "bullet"
import "building"
import "supply"
import "train"
import "enemy"
import "animations"
import "levels/city"
-- import "level"

-- groups
-- player (1) -> enemy,block,supply,balloon
-- bullet -> enemy,block,supply,balloon
-- enemy -> bullet,player,supply,balloon
-- supply -> player,bullet,enemy
-- balloon -> player,bullet,enemy,block
--
-- 1 = player, enemies, building
-- 2 = broken blocks (no collisions)
-- 3 = supply, balloon
-- 4 = floor borders
-- 5 = change man/plane trigger blocks

-- betterize random
math.randomseed(playdate.getSecondsSinceEpoch())

local gfx <const> = playdate.graphics
local frameTimer <const> = playdate.frameTimer
local font <const> = gfx.font.new("images/font/Sasser-Slab-Bold")
local point <const> = playdate.geometry.point

cameraY = 0
shakeit = 0

--ye olde screen rattle
function shakeItNow()
  local fade = 0.95
  local offset_x=16-rnd(32)
  local offset_y=16-rnd(32)
  offset_x*=shakeit
  offset_y*=shakeit

  playdate.display.setOffset(offset_x, offset_y)
  shakeit *= fade
  if shakeit < 0.05 then
    shakeit = 0
  end
end


function setupStatusBar()
  local status = gfx.sprite:new()
  status:setIgnoresDrawOffset(true)
  status:setZIndex(1000)
  status:moveTo(0,0)
  status:setCenter(0, 0) -- set center point to left bottom
  status:setSize(400,25)
  status:add()
  function status:update()
    -- fuel update area
    self.addDirtyRect(0, 0, 125, 25)
  end
  function status:draw()
    gfx.fillRect(0,0,400,25)
    -- gfx.setColor(gfx.kColorWhite)
    gfx.setImageDrawMode("NXOR")
    gfx.setFont(font)
    gfx.drawText("FUEL: "..math.ceil(player.fuel), 5, 5)
    gfx.drawTextAligned("SCORE: "..player.score, 200, 5, kTextAlignment.center)
    local heart = gfx.image.new("images/heart")
    for i=1,player.life do
      heart:draw(395-i*15,6)
    end
  end
  return status
end

function setup()
  gameState = State()
  gameState.level = 1
  player = Player()
  player:addSprite()
  city = City()
  supply = Supply()
  train = Train()
  building = Building()
  building:makeBuildings()
  statusBar = setupStatusBar()
  animations = Animations()
  mode = "game"
end

function setCameraY(y)
  y = y or -240
  cameraY = 0
  city:setY(y)
end

setup()

function playdate.update()
  gfx.sprite.update()

  if mode == "game" then

    shakeItNow()
    Crab:checkSpawn()
    -- if player.position.y < 120 then
    --   city:setY(-240 - player.position.y + 120)
    --   cameraY = 120-player.position.y
    -- end

  end

  gfx.setDrawOffset(0,cameraY)
  frameTimer.updateTimers()
  -- playdate.drawFPS(2, 224)

end
