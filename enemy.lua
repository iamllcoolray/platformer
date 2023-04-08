enemies = {}

function spawnEnemy(x, y)
    local enemy = world:newRectangleCollider(x, y, 70, 90, { collision_class = "Danger" })
    enemy.direction = 1
    enemy.speed = 200
    enemy.animations = animations.enemy
    table.insert(enemies, enemy)
end

function enemiesUpdate(dt)
    for i, e in ipairs(enemies) do
        e.animations:update(dt)
        local ex, ey = e:getPosition()

        local colliders = world:queryRectangleArea(ex + (40 * e.direction), ey + 40, 10, 10, { "Platform" })

        if #colliders == 0 then
            e.direction = e.direction * -1
        end

        e:setX(ex + e.speed * dt * e.direction)
    end
end

function enemiesDraw()
    for i, e in ipairs(enemies) do
        local ex, ey = e:getPosition()
        e.animations:draw(sprites.enemySheet, ex, ey, nil, e.direction, 1, 50, 65)
    end
end
