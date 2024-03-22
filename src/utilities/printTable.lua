return function(t)
    if type(t) == 'table' then
        for key, value in pairs(t) do
            print(string.format("%s : %s", key, value))
        end
    else
        error( string.format("The input provided was of type %s", type(t)) )
    end
end