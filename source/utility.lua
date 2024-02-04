local abs = math.abs

--ensure min velocity, pos or neg
function minVelocity(spd,minV)
  if (abs(spd)~=0 and abs(spd)<minV) then
    if spd<0 then spd=-minV else spd=minV end
  end
  return spd
end

--ensure max velocity, pos or neg
function maxVelocity(spd,maxV)
  if (abs(spd)>maxV) then
    if spd<0 then spd=-maxV else spd=maxV end
  end
  return spd
end

-- mimic pico-8s rnd()
function rnd(n)
  n = n or 1
  return (math.random(n)-1 + math.random(1000)/1000)
end

--zero pad a number
function pad(string, length)
  string=""..string
  if (#string == length) then return string end
  return "0"..pad(string, length-1)
end

-- mimic pico-8s del()
function del(t, el)
  local i = table.indexOfElement(t,el)
  if i then
    table.remove(t,i)
  end
end
