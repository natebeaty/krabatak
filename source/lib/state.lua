--[[
-- https://devforum.play.date/t/a-list-of-helpful-libraries-and-code/221/4

GameState = State()
GameState.score = 0

-- ... in code that needs to know when game score changes ...
GameState:subscribe("score", self, function(old_value, new_value)
   if old_value ~= new_value then
      self:update_game_score(new_value)
   end
end)

-- ... in code that changes the game score, all subscribers of "score" on GameState will be notified of the new value ...
GameState.score = 5
]]--

import "CoreLibs/object"
import "signal"

local allowed_variables = {
	__data = true,
	__signal = true
}

class("State").extends()

function State:init()
	self.__data = {}
	self.__signal = Signal()
end

function State:__newindex(index, value)
	if allowed_variables[index] then
		rawset(self, index, value)
		return
	end
	
	-- Give metatable values priority.
	local mt = getmetatable(self)
	if mt[index] ~= nil then
		rawset(mt, index, value)
		return
	end
	
	-- Store value in our shadow table.
	local old_value = self.__data[index]
	self.__data[index] = value
	
	-- Notify anyone listening about the change.
	self.__signal:notify(index, old_value, value)
end

function State:__index(index)
	if allowed_variables[index] then
		return rawget(self, index)
	end
	
	-- Give metatable values priority.
	local mt = getmetatable(self)
	if mt[index] ~= nil then
		return rawget(mt, index)
	end
	
	-- Fetch value from shadow table.
	return self.__data[index]
end

function State:subscribe(key, bind, fn)
	self.__signal:subscribe(key, bind, fn)
end

function State:unsubscribe(key, fn)
	self.__signal:unsubscribe(key, fn)
end