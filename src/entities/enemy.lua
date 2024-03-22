local enemy = {}
enemy.__index = enemy

local function new(statData, spriteData, animations)
    local self = {}
    setmetatable(self, enemy)

    self.parent = statData.parent
    self.positionInParent = statData.positionInParent

    self.spd = statData.spd
    
    self.aggro = statData.aggro
    self.attackAggro = statData.attackAggro
    
    self.hp = statData.hp
    self.maxHp = self.hp
    self.visibility = 100
    
    self.width = statData.width * player.scale
    self.height = statData.height * player.scale
    
    self.spriteSheet = love.graphics.newImage(spriteData.path)
    self.frameWidth = self.spriteSheet:getWidth() / spriteData.rows
    self.frameHeight = self.spriteSheet:getHeight() / spriteData.columns
    local g = anim8.newGrid(self.frameWidth, self.frameHeight, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())
    
    self.collider = world:newBSGRectangleCollider(statData.x, statData.y, self.width, self.height, spriteData.colliderCut)
    self.collider:setFixedRotation(true)
    self.collider:setCollisionClass('Enemy')
    self.collider:setObject(self)

    self.x, self.y = self.collider:getPosition()
    
    self.animations = {}
    for key, data in pairs(animations) do
        self.animations[key] = anim8.newAnimation(g(data.frames, data.row), data.animSpd or 0.2, data.onLoop)
    end
    self.dir = 'right'
    self.attackInterval = spriteData.attackInterval
    
    self.timer = timer.new()
    return self
end

function enemy:update(dt)
    self.timer:update(dt)

    self.state = self:getState()
    
    if self.state == 'idle' then
        self.animation = self:idle()
    elseif self.state == 'attack' then
        self.animation = self:attack()
    elseif self.state == 'moving' then
        self.animation = self:moving()
    elseif self.state == 'dmg' then
        self.animation = self:dmg()
    elseif self.state == 'dead' then
        self.animation = self:dead()
    end

    if self.currentState ~= self.state and self.state ~= '' then
        self.currentState = self.state
        self.animation:gotoFrame(1)
    end
    
    self.animation:update(dt)
    self:setAnimationOrientation()
end

function enemy:draw()
    love.graphics.setColor(hsl(0, 0, 100, self.visibility))
    self.animation:draw(self.spriteSheet, self.x, self.y, nil, player.scale, player.scale, self.frameWidth/2, self.frameHeight/2)
end


function enemy:idle()
    self.collider:setLinearVelocity(0, 0)

    return self.animations.idle
end

function enemy:moving()
    local angle = math.atan2(player.y - self.y, player.x - self.x)
    self.collider:setLinearVelocity(self.spd * math.cos(angle), self.spd * math.sin(angle))
    self.x, self.y = self.collider:getPosition()

    return self.animations.moving
end

function enemy:attack()
    self.attacking = true

    local intervals = self.animations.attack.intervals
    local frames = #self.animations.attack.frames + 1
    local attackTimer, angle, spd

    local BeforeAttackTimer = self.timer:during(intervals[4], function()
        
        local dx, dy = self.x - player.x, self.y - player.y
        if math.sqrt( dx*dx + dy*dy ) > 150 then return end

        local distanceFromPlayer = math.sqrt( dx*dx + dy*dy )
        distanceFromPlayer = (math.abs(distanceFromPlayer) + self.attackAggro/2) * distanceFromPlayer / math.abs(distanceFromPlayer)
        spd = distanceFromPlayer / (intervals[frames] - intervals[4])
        angle = math.atan2(player.y - self.y, player.x - self.x)
        
        self.collider:setLinearVelocity(0, 0)

        if self.x < player.x then
            self.dir = 'right'
        else
            self.dir = 'left'
        end

    end, function()

        attackTimer = self.timer:during(intervals[frames] - intervals[4], function()
            self.collider:setLinearVelocity(spd * math.cos(angle), spd * math.sin(angle))
            self.x, self.y = self.collider:getPosition()
        end)

    end)

    local attackVariables, attackFunc = nil, function()
        self.attacking = false

        self.notAttacking = true
        timer.after(1.5, function()
            self.notAttacking = false
        end)
    end

    attackVariables = timer.during(intervals[frames], function()
        if self.currentState == 'dmg' then
            attackFunc()
            timer.cancel(attackVariables)
        end
    end, attackFunc)

    timer.during(intervals[frames], function()
        if self.collider:enter('Player') then
            self.collider:setLinearVelocity(0, 0)

            self.attacking = false
            timer.cancel(attackVariables)
            
            pcall(function()
                self.timer:cancel(attackTimer)
                self.timer:cancel(BeforeAttackTimer)
            end)
            return
        end
    end)

    return self.animations.attack:clone()
end

function enemy:dmg()
    if not self.hit then
        self.timer:clear()
        self.hit = true

        local s = 40 / self.maxHp
        self.collider:setLinearVelocity(0, 0)

        local dx, dy = 1, 1
        if player.dir == 'left' then
            dx = -dx
        elseif player.dir == 'up' then
            dx, dy = -dx, -dy
        end

        self.collider:applyLinearImpulse(dx * s, dy * s)

        self.hp = self.hp - 1
        
        self.timer:during(self.animations.dmg.totalDuration, function()
            self.x, self.y = self.collider:getPosition()
        end)

        timer.after(self.animations.dmg.totalDuration, function()
            self.hit = false
        end)
    end
    
    return self.animations.dmg
end

function enemy:dead()
    if not self.collider:isDestroyed() then
        player.hp = math.min(player.hp + 5 * self.maxHp, player.maxHp)
        self.collider:destroy()
        self.timer:clear()
        flux.to(self, 7, {visibility = 0}):ease('cubicin')
    end

    if math.floor(self.visibility) == 0 then
        table.remove(self.parent, self.positionInParent)
    end

    return self.animations.die
end

function enemy:getState()
    if self.hp <= 0 then
        return 'dead'
    end

    if self.hit then
        return 'dmg'
    end

    local dx, dy = player.x - self.x, player.y - self.y
    distanceFromPlayer = math.sqrt( dx*dx + dy*dy )
    local colliders = world:queryLine( player.x, player.y, self.x, self.y, {'Wall'} )
    
    if #colliders == 0 and (distanceFromPlayer < self.aggro or self.currentState == 'moving' or self.currentState == 'attack') then
        if self.attacking then
            return ''
        end
        
        if self.x < player.x then
            self.dir = 'right'
        else
            self.dir = 'left'
        end

        if distanceFromPlayer < self.attackAggro and not self.notAttacking then
            return 'attack'
        end

        return 'moving'
    end
    
    return 'idle'
end

function enemy:setAnimationOrientation()
    if self.dir == 'right' and self.animation.flippedH or self.dir == 'left' and not self.animation.flippedH then
        self.animation:flipH()            
    end
end

return setmetatable(enemy, { __call = function(_, ...) return new(...) end, new = new })