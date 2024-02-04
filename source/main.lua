import 'CoreLibs/frameTimer'
import 'CoreLibs/graphics'
import 'utility'
import 'player'
import 'bullet'
import 'enemy'
import 'animations'
import 'levels/city'
-- import 'level'

-- betterize random
math.randomseed(playdate.getSecondsSinceEpoch())

local gfx <const> = playdate.graphics
local frameTimer <const> = playdate.frameTimer
local font <const> = gfx.font.new('images/font/Sasser-Slab-Bold')
local point <const> = playdate.geometry.point

local enemies = {}
local maxEnemies = 5
local cameraY = 0

function status_bar()
  local status = gfx.sprite:new()
  status:setIgnoresDrawOffset(true)
  status:setZIndex(1000)
  status:moveTo(0,0)
  status:setCenter(0, 0) -- set center point to left bottom
  status:setSize(400,25)
  status:add()
  function status:draw()
    -- gfx.fillRect(0,0,400,25)
    gfx.setFont(font)
    gfx.drawText('FUEL: '..player.fuel, 5, 5)
    gfx.drawTextAligned('SCORE: '..player.score, 200, 5, kTextAlignment.center)
    local heart = gfx.image.new('images/heart')
    for i=1,player.life do
      heart:draw(395-i*15,6)
    end
  end
  return status
end

function setup()
  player = Player()
  player:addSprite()
  city = City()
  status_bar()
  animations = Animations()
  mode = "game"
end

function check_enemy_spawn()
  if (#enemies < maxEnemies and rnd()>0.95) then
    local enemy = Enemy(point.new(rnd(400), -cameraY ))
    enemy:addSprite()
    table.insert(enemies, enemy)
  end
end
function remove_enemy(e)
  print('before',#enemies,table.indexOfElement(enemies,e))
  del(enemies, e)
  print('after',#enemies,table.indexOfElement(enemies,e))
  e:remove()
end

function player_respawn()
  player:respawn()
end
function new_explosion(x,y)
  animations:explosion(x,y)
end

function score(n)
  player.score += n
end

setup()

function playdate.update()
  gfx.sprite.update()
  gfx.setDrawOffset(0,cameraY)

  if mode == "game" then

    player.fuel -= 1
    check_enemy_spawn()
    if player.position.y < 120 then
      city:setY(-240 - player.position.y + 120)
      cameraY = 120-player.position.y
    end

  end

  frameTimer.updateTimers()
end
