do
    function Log(...)
        for _, text in pairs({...}) do
            for id = 0, 23 do
                DisplayTimedTextToPlayer(Player(id), 0, 0, 30, text)
            end
            Preload("\") \n" .. text .. "\n\\")
            PreloadGenEnd("log.txt")
        end
    end
end
