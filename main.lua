function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    require('/src/load/require')

    cam = camera()
    cam:zoomTo(2.5)

    WIDTH, HEIGHT = love.graphics.getWidth() / cam.scale, love.graphics.getHeight() / cam.scale
    
    hud = camera()
    hud:zoomTo(cam.scale)
    hud:lookAt(WIDTH / 2, HEIGHT / 2)

    Gamestate.registerEvents()
    Gamestate.switch(demo_level)
end

function love.resize(w, h)
    cam:zoom(w / WIDTH / cam.scale)
    
    WIDTH, HEIGHT = w/cam.scale, h/cam.scale

    hud:zoomTo(cam.scale)
    hud:lookAt(WIDTH / 2, HEIGHT / 2)
end