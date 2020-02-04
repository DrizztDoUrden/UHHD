do
    function Log(...)
        local text = table.concat({...}, "\n")
        if TestBuild then
            print(text)
        end
        Preload("\")\n" .. text .. "\n\\")
        PreloadGenEnd("log.txt")
    end
end
