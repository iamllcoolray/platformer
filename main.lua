anim8 = require("libraries.anim8.anim8")
sti = require("libraries.Simple-Tiled-Implementation.sti")
cameraFile = require("libraries.hump.camera")
wf = require("libraries.windfield.windfield")

function love.load()
    cam = cameraFile()

    sounds = {
        jump = love.audio.newSource("assets/audio/jump.wav", "static"),
        music = love.audio.newSource("assets/audio/music.mp3", "stream"),
    }

    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    sounds.music:play()

    sprites = {
        playerSheet = love.graphics.newImage("assets/sprites/player/playerSheet.png"),
        enemySheet = love.graphics.newImage("assets/sprites/enemy/enemySheet.png"),
        background = love.graphics.newImage("assets/sprites/background.png")
    }

    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations = {
        idle = anim8.newAnimation(grid("1-15", 1), 0.05),
        jump = anim8.newAnimation(grid("1-7", 2), 0.05),
        run = anim8.newAnimation(grid("1-15", 3), 0.05),
        enemy = anim8.newAnimation(enemyGrid("1-2", 1), 0.03)
    }

    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass("Platform")
    world:addCollisionClass("Player" --[[, { ignores = { "Platform" } }]])
    world:addCollisionClass("Danger")

    require("player")
    require("enemy")
    require("libraries.show")

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, { collision_class = "Danger" })
    dangerZone:setType("static")

    platforms = {}

    flagX = 0
    flagY = 0

    saveData = {
        currentLevel = "level1",
    }

    if love.filesystem.getInfo("data.lua") then
        local data = love.filesystem.load("data.lua")
        data()
    end

    loadMap(saveData.currentLevel)
end

function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt)
    enemiesUpdate(dt)

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight() / 2)

    local colliders = world:queryCircleArea(flagX, flagY, 10, { "Player" })
    if #colliders > 0 then
        if saveData.currentLevel == "level1" then
            loadMap("level2")
        elseif saveData.currentLevel == "level2" then
            loadMap("level3")
        elseif saveData.currentLevel == "level3" then
            loadMap("level1")
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    cam:attach()
    gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
    playerDraw()
    enemiesDraw()
    cam:detach()
end

function love.keypressed(key)
    if key == "up" then
        if player.grounded then
            player:applyLinearImpulse(0, -4000)
            sounds.jump:play()
        end
    end
    if key == "r" then
        loadMap("level2")
    end
end

function spawnPlatform(x, y, width, height)
    if width > 0 and height > 0 then
        local platform = world:newRectangleCollider(x, y, width, height, { collision_class = "Platform" })
        platform:setType("static")
        table.insert(platforms, platform)
    end
end

function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i - 1
    end
    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i - 1
    end
end

function loadMap(mapName)
    saveData.currentLevel = mapName
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
    destroyAll()
    gameMap = sti("assets/maps/" .. mapName .. ".lua")
    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x
        playerStartY = obj.y
    end
    player:setPosition(playerStartX, playerStartY)
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end
