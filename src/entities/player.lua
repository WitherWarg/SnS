local player = {}

local function new(x, y)
    local self = player

    self.scale = 1.5
    self.x, self.y = x or WIDTH/2, y or HEIGHT/2
    
    self.maxSpd = 130
    self.spd = 0
    self.acceleration = self.maxSpd / 0.3

    self.width = 7 * self.scale
    self.height = 5 * self.scale

    self.hp = 100
    self.maxHp, self.currentHp = self.hp, self.hp

    self.spriteSheet = love.graphics.newImage('/sprites/mystic_woods/sprites/characters/player.png')
    self.frameWidth, self.frameHeight = self.spriteSheet:getWidth()/6, self.spriteSheet:getHeight()/10
    local g = anim8.newGrid(self.frameWidth, self.frameHeight, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())
    
    local animations = {
        move = {
            frames = '1-6',
            downRow = 4,
            upRow = 6,
            horizontalRow = 5
        },
        idle = {
            frames = '1-6',
            downRow = 1,
            upRow = 3,
            horizontalRow = 2
        },
        strike = {
            frames = '1-4',
            downRow = 7,
            upRow = 9,
            horizontalRow = 8
        },
        dead = {
            frames = '1-3',
            onLoop = 'pauseAtEnd',
            animSpd = 0.8,
            horizontalRow = 10
        }
    }

    self.animations = {}
    for key, anim in pairs(animations) do
        if anim.downRow then
            self.animations[key .. '_down'] = anim8.newAnimation(g(anim.frames, anim.downRow), anim.animSpd or 0.2, anim.onLoop)
        end

        if anim.upRow then
            self.animations[key .. '_up'] = anim8.newAnimation(g(anim.frames, anim.upRow), anim.animSpd or 0.2, anim.onLoop)
        end

        if anim.horizontalRow then
            self.animations[key .. '_right'] = anim8.newAnimation(g(anim.frames, anim.horizontalRow), anim.animSpd or 0.2, anim.onLoop)
            self.animations[key .. '_left'] = self.animations[key .. '_right']:clone():flipH()
        end
    end

    self.dir = 'down'

    self.collider = world:newBSGRectangleCollider(self.x, self.y, self.width, self.height, 2.5)
    self.collider:setCollisionClass('Player')
    self.collider:setFixedRotation(true)
end

function player:update(dt)
    local dx, dy
    if self.state == 'strike' then
        dx, dy = self:getStrikeVectors(cam:mousePosition())
    else
        dx, dy = self:getVectors()
    end

    self:updateState(dx, dy)

    local state = nil
    if self.state == 'dead' and world then
        state = game_over
    elseif self.state == 'win' then
        state = game_won
    end

    if state then return Gamestate.switch(state) end

    local vx, vy = self:getVectors(0, 0)
    self:updateSpd(dt, vx, vy)

    self.collider:setLinearVelocity(self.spd * vx, self.spd * vy)
    self.x, self.y = self.collider:getPosition()

    self:updateSpd(dt, vx, vy)

    self:checkEnemyDmg()

    self:updateDir(dx, dy)
    self.animation = self:getAnimation()

    if self.state ~= self.currentState then
        self.animation:gotoFrame(1)
        self.currentState = self.state
    end

    self.animation:update(dt)
end

function player:draw()
    love.graphics.setColor(hsl(0, 0, 100))
    self.animation:draw(self.spriteSheet, self.x, self.y, nil, player.scale, player.scale, self.frameWidth/2, self.frameHeight/2)
end

function player:mousepressed(mx, my)
    if self.state == 'strike' then
        timer.during(0.5, function()
            if self.state ~= 'strike' then self:mousepressed(mx, my) end
        end)

        return
    end
    
    self.state = 'strike'

    timer.script(function(wait)
        local anim = self.animations.strike_down

        wait(anim.intervals[2])

        timer.during(anim.intervals[#anim.frames - 1] - anim.intervals[2] - 0.005, function()
            self:queryForEnemies(self:getStrikeVectors(mx, my))
        end)

        wait(anim.totalDuration - anim.intervals[2] - 0.005)

        self.state = ''
        self.strike = false
    end)
end


function player:getStrikeVectors(mx, my)
    local vec2 = vector(self.x - mx, self.y - my)
    vec2:rotateInplace(math.pi / 4)

    return vec2:unpack()
end

function player:queryForEnemies(dx, dy)
    local triangleVectors = {
        vector(0, 27),
        vector(12, 0),
        vector(-12, 0)
    }
    local triangle = {}

    local angle = math.atan2(dy, dx) + math.pi / 4
    for _, vec2 in ipairs(triangleVectors) do
        vec2 = vec2:rotated(angle) + vector(player.x, player.y)
        table.insert(triangle, vec2.x)
        table.insert(triangle, vec2.y)
    end

    local enemies = world:queryPolygonArea(triangle, {'Enemy'})

    for i, enemy in ipairs(enemies) do
        enemy:getObject():dmg()
    end
end

function player:getVectors(dx, dy)
    local dx, dy = 0, 0

    if love.keyboard.isDown('d') then dx = 1
    elseif love.keyboard.isDown('a') then dx = -1 end
    if love.keyboard.isDown('s') then dy = 1
    elseif love.keyboard.isDown('w') then dy = -1 end
    
    local length = math.sqrt(dx*dx + dy*dy)
    if length ~= 0 then
        dx, dy = dx/length, dy/length
    end

    return dx, dy
end

function player:updateState(dx, dy)
    if self.hp <= 0 then
        self.state = 'dead'
    elseif self.collider:enter('Door') then
        self.state = 'win'
    elseif self.state == 'strike' then
        self.state = 'strike'
    elseif dx == 0 and dy == 0 then
        self.state = 'idle'
    else
        self.state = 'move'
    end
end

function player:updateDir(dx, dy)
    dx, dy = dx / math.abs(dx), dy / math.abs(dy)

    if self.state == 'strike' and not self.strike then
        self.strike = true

        if dx == 1 and dy == -1 then self.dir = 'down'
        elseif dx == -1 and dy == 1 then self.dir = 'up'
        elseif dx == -1 and dy == -1 then self.dir = 'right'
        elseif dx == 1 and dy == 1 then self.dir = 'left' end
    elseif self.state ~= 'strike' then
        if dy == 1 then self.dir = 'down'
        elseif dy == -1 then self.dir = 'up'
        elseif dx == 1 then self.dir = 'right'
        elseif dx == -1 then self.dir = 'left' end
    end
end

function player:updateSpd(dt, dx, dy)
    if self.state == 'strike' then
        self.spd = self.spd
    elseif self.state == 'idle' then
        self.spd = math.max(self.spd - self.acceleration / 2 * dt, 0)
    elseif self.state == 'move' then
        self.spd = math.min(self.spd + self.acceleration / 2 * dt, self.maxSpd)
    end
end

function player:getAnimation()
    return self.animations[self.state .. '_' .. self.dir]
end

function player:checkEnemyDmg()
    if self.collider:enter('Enemy') then
        local collision_data = self.collider:getEnterCollisionData('Enemy')
        
        local enemy = collision_data.collider:getObject()
        if not enemy.attacking then return end

        local dx, dy = collision_data.contact:getNormal()
        local s = -50

        timer.during(love.timer.getAverageDelta() * 10, function()
            self.collider:applyLinearImpulse(dx * s, dy * s)
            self.x, self.y = self.collider:getPosition()
        end)

        self.hp = self.hp - enemy.maxHp * 5
    end
end

return setmetatable(player, { __call = function(_, ...) return new(...) end, new = new })