function create_player()
  local player = {}
  player.width=40
  player.height=40
  player.startX=4
  player.startY=113
  player.x=player.startX
  player.y=player.startY
  player.dx=0
  player.dy=0
  player.fuel=999
  player.lowfuel=300
  player.life=3
  player.score=0
  player.extralife=0
  player.dying=0
  player.mode="plane"
  player.dir="n"
  player.boxes = {}
  player.boxes["man"]={x1=0,y1=0,x2=40,y2=40}
  player.boxes["plane"]={x1=0,y1=0,x2=40,y2=40}
  player.mode_stats = {
    man={
      maxspd=2,
      minspd=1,
      drg=0.4,
      a=0.25
    },
    plane={
      maxspd=2.5,
      minspd=1,
      drg=0.95,
      a=0.25
    }
  }
  player.smokes={{x=0,y=0},{x=0,y=0},{x=0,y=0},{x=0,y=0}}
  player.imagemapDirections={
    nw=1,
    n=2,
    ne=3,
    w=4,
    e=6,
    sw=7,
    s=8,
    se=9
  }
  player.box=player.boxes[player.mode]
  player.maxspd=player.mode_stats[player.mode]['maxspd'] --max speed
  player.minspd=player.mode_stats[player.mode]['minspd'] --min speed
  player.a=player.mode_stats[player.mode]['a'] --acceleration
  player.drg=player.mode_stats[player.mode]['drg'] --friction (1=none,0=instant)

  player.sprite=gfx.sprite.new()
  player.sprite.images=gfx.imagetable.new("images/player")
  player.sprite:setCollideRect(player.box['x1'],player.box['y1'],player.box['x2'],player.box['x2'])
  player.sprite:moveTo(player.x,player.y)
  player.sprite:setZIndex(1000)
  player.sprite:add()


  function player:collisionResponse(other)
    return gfx.sprite.kCollisionTypeOverlap
  end

  function player:resupply()
    player.fuel+=400
    if (player.fuel>999) then player.fuel=999 end
  end

  function player:reset()
    player.fuel=999
    player.mode="man"
    player.score=0
    player.extralife=0
    player.life=3
  end

  function player:scored(points)
    player.score+=points
    player.extralife+=points
    -- extra life?
    if player.extralife>=100 then
      player.extralife=0
      if (player.life<5) then
        sfx(15)
        player.life+=1
      end
    end
  end

  function player:die()
    new_explosion(player.x,player.y)
    -- if player.mode=="plane" then
    --   sfx(01)
    -- else
    --   sfx(14)
    -- end
    player.life-=1
    if (player.life==0) then
      game_over()
    else
      player.dying=10
      player.dx=0
      player.dy=0
    end
  end

  function player:switch_modes(mode)
    player.mode=mode
    player.box=player.boxes[player.mode]
    player.maxspd=player.mode_stats[player.mode]['maxspd'] --max speed
    player.minspd=player.mode_stats[player.mode]['minspd'] --min speed
    player.a=player.mode_stats[player.mode]['a'] --acceleration
    player.drg=player.mode_stats[player.mode]['drg'] --friction (1=none,0=instant)
  end

  function player:respawn()
    player.fuel=999
    player.mode="man"
    player.x=player.startX
    player.y=player.startY
    player.dx=0
    player.dy=0
  end

  --smoke from back of plane (this is a mess! but it works?)
  function player:smoke()
    if player.dir=="n" then
      player.smokes[t%#player.smokes]={x=player.x+3,y=player.y-player.dy*1.5+rnd(2)+6}
    elseif player.dir=="s" then
      player.smokes[t%#player.smokes]={x=player.x+3,y=player.y-player.dy*1.5-rnd(2)-1}
    elseif player.dir=="w" then
      player.smokes[t%#player.smokes]={x=player.x-player.dx*1.5+rnd(2)+4,y=player.y+4}
    elseif player.dir=="e" then
      player.smokes[t%#player.smokes]={x=player.x-player.dx*1.5-rnd(2)+2,y=player.y+4}
    elseif player.dir=="se" then
      player.smokes[t%#player.smokes]={x=player.x-player.dx*1.5-rnd(2),y=player.y-player.dy*1.5-rnd(2)}
    elseif player.dir=="sw" then
      player.smokes[t%#player.smokes]={x=player.x+player.dx*1.5+8+rnd(2),y=player.y-player.dy*1.5+2-rnd(2)}
    elseif player.dir=="nw" then
      player.smokes[t%#player.smokes]={x=player.x+player.dx*1.5+8+rnd(2),y=player.y-player.dy*1.5+6-rnd(2)}
    elseif player.dir=="ne" then
      player.smokes[t%#player.smokes]={x=player.x-player.dx*1.5-rnd(2),y=player.y-player.dy*1.5+6+rnd(2)}
    end
  end

  --player update
  function player:update()
    local t=playdate.timer.currentTime

    --wait a spell before respawn
    if (player.dying>0) then

      player.dying-=1
      if player.dying==0 then
        player:respawn()
      end

    else

      --switch between man/plane?
      if player.mode=="man" and player.y<112 then
        player:switch_modes('plane')
        sfx(10)
      elseif player.mode=="plane" and player.y>104 then
        if player.x>16 then
          player:die()
        else
          player:switch_modes('man')
          sfx(10)
        end
      end

      --fuel check
      if (t%2==0) then
        if player.mode=="man" then
          --manfuel
          player.fuel-=0.1
        else
          --planefuel (empties faster based on velocity)
          if (player.dy~=0 or player.dx~=0) then player.fuel-=(abs(player.dx)+abs(player.dy)) else player.fuel-=0.5 end
        end
        --low fuel klaxon
        -- if (player.fuel<player.lowfuel and t%40==0) sfx(13)
        player.fuel=max(player.fuel,0)
        --out of fuel!
        if (player.fuel==0) then player:die() end
      end

      if playdate.buttonIsPressed("UP") then
        player.dy-=player.a
      elseif playdate.buttonIsPressed("DOWN") then
        player.dy+=player.a
      end
      if playdate.buttonIsPressed("LEFT") then
        player.dx-=player.a
      elseif playdate.buttonIsPressed("RIGHT") then
        player.dx+=player.a
      end

      --pewpew
      -- if playdate.buttonJustPressed("B") or playdate.buttonJustPressed("A") then
      --   if mode=="game" and (player.mode=="man" or abs(player.dx)~=0 or abs(player.dy)~=0) then
      --     sfx(00)
      --     local dx=player.dx
      --     local dy=player.dy
      --     -- support for quick turn and shoots (should this just rely on player.dir?)
      --     if player.dy==0 and (player.dir=="w" and player.dx>0) or (player.dir=="e" and player.dx<0)) then dx=player.dx*-1 end
      --     if player.dx==0 and ((player.flipy and player.dy<0) or (not player.flipy and player.dy>0)) then dy=player.dy*-1 end
      --     if player.mode=="plane" then
      --       add(bullets,new_bullet(player.x+3,player.y+4,dx,dy))
      --     else
      --       add(bullets,new_man_bullet(player.x+3,player.y+4,dx,dy))
      --     end
      --   end
      -- end

      --limit to max speed
      player.dx=mid(-player.maxspd,player.dx,player.maxspd)
      player.dy=mid(-player.maxspd,player.dy,player.maxspd)
      if (player.dx>0 and player.dx<player.minspd) then player.dx=-0.1 end
      if (player.dx<0 and abs(player.dx)<player.minspd) then player.dx=0.1 end

      --check if next to wall
      -- wall_check(p)

      -- check_building_hit(p,"player")

      --can move?
      -- if (can_move(p,player.dx,player.dy)) then
        -- player.x+=player.dx
        -- player.y+=player.dy

        local actualX, actualY, collisions, length = plane:moveWithCollisions(player.x+player.dx,player.y+player.dy)
        -- for i = 1, length do
        --   local collision = collisions[i]
        --   if collision.other.isEnemy == true then -- crashed into enemy plane
        --     destroyEnemyPlane(collision.other)
        --     collision.other:remove()
        --     score -= 1
        --   end
        -- end

        -- player:smoke()
        player.sprite:setImage(plane.images:getImage(playerDirections[player.dir]))
      -- else
      --   player.dx=0
      --   player.dy=0
      -- end

      --add drag
      if (abs(player.dx)>0) then player.dx*=player.drg end
      if (abs(player.dy)>0) then player.dy*=player.drg end

      --make sure they don't drop below min speed
      if player.mode=="plane" then
        player.dx=minspeed(player.dx,player.minspd)
        player.dy=minspeed(player.dy,player.minspd)
      end

    end
  end

  --player draw
  -- function player:draw()
  --   if player.dying==0 then
  --     if player.mode=="man" then
  --       spr(0,player.x,player.y,1,1,player.flipx)
  --       --draw docked plane if man
  --       spr(18,4,104)
  --     else
  --       if abs(player.dx)>0 or abs(player.dy)>0 then
  --         for i=1,3 do
  --           pset(player.smokes[i].x+rnd(2),player.smokes[i].y+rnd(2),6)
  --         end
  --       end
  --       spr(player.sprite,player.x,player.y,1,1,player.flipx,player.flipy)
  --     end
  --   end
  -- end

  return player
end
