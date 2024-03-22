return function(...)
    local args = {...}

    if #args == 0 then
        return
    end

    for i, value in ipairs(args) do
        args[i] = tostring(value)
    end

    local inputString = '%s'
    for i=2, #args do
        inputString = inputString .. '\n' .. '%s'
    end

    love.graphics.push()
        local font = love.graphics.newFont(30)
        love.graphics.setFont(font)
        love.graphics.print( string.format( inputString, ... ), 10, 10 )
    love.graphics.pop()
end