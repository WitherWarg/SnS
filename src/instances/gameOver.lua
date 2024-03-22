local drawText = function()
    if player.animation.position == #player.animation.frames then
        love.graphics.push()
        love.graphics.translate(0, -25)

        local font = game_over.font
        love.graphics.setFont(font)
        love.graphics.setColor(0,0,0)

        local text = 'Game Over'
        for i=1, 10 do
            love.graphics.print(text, player.x, player.y, nil, 1, 1, font:getWidth(text)/2, font:getHeight()/2)
        end
        
        if math.floor(love.timer.getTime()/0.5) % 2 == 0 then
            text = 'Press any button to restart'
            local w, h = font:getWidth(text), font:getHeight()
            love.graphics.print(text, player.x, player.y + h/2 + player.height, nil, 1/3, 1/3, w/2, h/2)
        end

        love.graphics.pop()
    end
end

local game_over = {}

function game_over:enter(previous)
    self.previous = previous
    timer.clear()

    for _, entity in ipairs( {slime, skeleton} ) do
        for i=#entity, 1, -1 do
            local e = entity[i]
            e.timer:clear()
            table.remove(entity, i)
        end
    end

    world:destroy()
    world = nil

    if player.dir == 'up' then
        player.dir = 'right'
    elseif player.dir == 'down' then
        player.dir = 'left'
    end

    player.animation = player:getAnimation()

    self.font = love.graphics.newFont('/font/game_over.ttf', 90)
end

function game_over:update(dt)
    player.animation:update(dt)
    cam:lookAt(player.x, player.y)
end

function game_over:draw()
    cam:attach()
        love.graphics.setColor(hsl(20, 50, 39))
        love.graphics.rectangle("fill", player.x - WIDTH/2, player.y - HEIGHT/2, WIDTH, HEIGHT)
        
        drawText()

        player:draw()
    cam:detach()
end

function game_over:mousepressed()
    game_over:keypressed()
end

function game_over:keypressed()
    if player.animation.position == #player.animation.frames then
        Gamestate.switch(self.previous)
    end
end

return game_over