return function()
    world:addCollisionClass('Player')
    world:addCollisionClass('Enemy')
    world:addCollisionClass('Wall')
    world:addCollisionClass('Door', {ignores = {'Player'}})
    world:addCollisionClass('Dead', {ignores = {'All'}})
end