local slime = {}

local function new(x, y)
    local statData = { x = x, y = y, aggro = 150, attackAggro = 50, hp = 2, spd = 50, width = 14, height = 11, parent = slime, positionInParent = #slime + 1 }

    local spriteData = { path = '/sprites/mystic_woods/sprites/characters/slime.png', rows = 7, columns = 5, colliderCut = 5, attackInterval = 4 }
    local animations = {
        moving = { frames = '1-6', row = 2, animSpd = 0.13 },
        idle = { frames = '1-4', row = 1 },
        die = { frames = '1-5', row = 5, onLoop = 'pauseAtEnd', animSpd = 0.5 },
        dmg = { frames = '1-3', row = 4 },
        attack = { frames = '1-7', row = 3, animSpd = { ['1-2']=0.25, ['3-5']=0.15, ['6-7']=0.2 } }
    }
    table.insert(slime, enemy(statData, spriteData, animations))
end

return setmetatable(slime, { __call = function(_, ...) new(...) end, new = new })