-- things to try to get better graphics:
-- bigger and fewer chunks
-- smaller and more chunks
-- don't draw chunk edges
-- reduce shader complexity
-- adjust terrain gen for less overdraw

--    █           █    
--    █ ▄▀▄ ▄▀█ ▄▀█    
--    █ ▀▄▀ ▀▄█ ▀▄█    

print('🐤 load')
-- NO_GRAVITY = true
print(lovr.getVersion())

PROF_NOCAPTURE = true
prof = require('jprof')

local player = require('player-library').new(
    lovr.physics.newWorld(), 
    lovr.math.newVec3(10, 13, 10)
)

-- marching cubes
sizeOverride = 5 -- global var used to pass a parameter into cubes ^^;
local cubes = require("cubes-library")

local chunkSize = sizeOverride
local chunkList = {}
local chunkDraw = {}

-- local key = 0 ..','.. 0 ..','.. 0
-- chunkList[key] = cubes.new(player.world, 0,0,0, player.biped.terrainColliders, chunkDraw)
-- table.insert(chunkDraw, chunkList[key])

-- collectables/punchables
local doodads = {}
local rand = lovr.math.random

--              █      ▄         
--    █ █ █▀▄ ▄▀█ ▄▀█ ▀█▀ ▄▀▄    
--    ▀▄█ █▄▀ ▀▄█ ▀▄█  ▀▄ ▀█▄    
--        █                      
-- prof.push 'frame'

function lovr.update(deltaTime)
    -- if lovr.headset.isDown('right', 'a') then
    --     prof.enabled(true)
    -- else
    --     prof.enabled(false)
    -- end
    prof.pushFrame(string.format('%.2fs', deltaTime))
    prof.push 'update'


    -- generate terrain as you walk
    prof.push 'crawl terrain'
    player.biped.terrainShapes = {}
    local x, y, z  = player.biped.head.pos:unpack()
    local range = 1
    local size = chunkSize
    for ix = -range, range do
        for iy = -range, 0 do
            for iz = -range, range do
                local cx,cy,cz = 
                  x - x%size + ix*size, 
                  y - y%size + iy*size, 
                  z - z%size + iz*size
                local key = cx..','..cy..','..cz

                if chunkList[key] then 
                    -- print('chunk already exists') 
                else 
                    -- print('🧊 creating chunk at', vec3(cx, cy, cz)) 
                end
                -- if not chunkList[key] then
                    -- add chunk
                    chunkList[key] = cubes.new(player.world, cx,cy,cz, {}, chunkDraw)
                    if chunkList[key].collider then
                        table.insert(player.biped.terrainShapes,    chunkList[key].collider:getShapes()[1])
                    end
                    -- table.insert(chunkDraw, chunkList[key])

                    -- -- add doodads
                    -- for i = 0, rand()*10 do
                    --     table.insert(doodads, {
                    --         pos = lovr.math.newVec3(
                    --             cx + chunkSize*rand(),
                    --             cy + chunkSize*rand(),
                    --             cz + chunkSize*rand()
                    --         )
                    --     })
                    -- end
                -- end
            end
        end
    end
    prof.pop 'crawl terrain'
    -- print('that took seconds:', lovr.timer.getTime() - time)

    -- respawn
    if player.biped.head.pos.y < -200 or lovr.headset.wasPressed('left', 'x') or lovr.system.isKeyDown('r') then
        player:respawn()
    end

    prof.push 'update player'
    player:update(deltaTime)
    prof.pop 'update player'

    prof.pop 'update'
end







--      █                  
--    ▄▀█ █▄▀ ▄▀█ █ █ █    
--    ▀▄█ █   ▀▄█  █ █     


local function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

lovr.headset.setRefreshRate(120)
lovr.graphics.setBackgroundColor(1, .75, 1)
local frame = 0

function lovr.draw(pass)
    prof.push 'draw'
    prof.push 'ui'
    frame = frame + 1





    --    █ █ ▀█▀    
    --    █ █  █     
    --    ▀▄▀ ▄█▄    


    -- FPS counter in the top left
    pass:setColor(0, 0, 0)
    pass:text(
        'chunks:' .. getTableSize(chunkList) .. '\n' ..
        'vertices:' .. cubes.totalVertices .. '\n' ..
        'fps:' .. lovr.timer.getFPS(),
        mat4(lovr.headset.getPose('head'))
            :translate(-.17, .2, -.3)
            :scale(.03),
        nil, 'left', 'top'
    )
    prof.pop 'ui'




    prof.push 'drawDebug'
    player:drawDebug(pass)
    prof.pop 'drawDebug'

    player:lookThroughEyes(pass)

    local headsetPos = vec3(lovr.headset.getPosition())
    prof.push 'distanceFromCamera'
    if frame % 100 == 0 then
        for i,v in ipairs(chunkDraw) do
            v.distanceFromCamera = (player.biped.rugPos + headsetPos):distance(v.x,v.y,v.z)
        end
    end
    prof.pop 'distanceFromCamera'

    prof.push 'sort chunks'
    if frame % 100 == 1 then
        table.sort( chunkDraw, function(a,b) return a.distanceFromCamera < b.distanceFromCamera end )
    end
    prof.pop 'sort chunks'

    prof.push 'draw chunks'
    for i,chunk in ipairs(chunkDraw) do
        if chunk.distanceFromCamera < 100 then
            chunk:draw(pass)
        end
    end
    prof.pop 'draw chunks'

    prof.push 'limbs'
    -- left hand
    local x, y, z = player.biped.left.pos:unpack()
    local r = .05
    -- shadow
    pass:setDepthTest('none')
    pass:setColor(.125, .375, .5, .5)
    pass:circle(x, 0, z, r, math.pi/2, 1, 0, 0)
    -- hand
    pass:setDepthTest('gequal')
    pass:setMaterial()
    player:drawHands(pass)
    prof.pop 'limbs'

    prof.pop 'draw'
    prof.popFrame(pass)
end

lovr.focus = function(focused)
    if focused == false then
        prof.write 'prof.mpack'
    end
end

lovr.quit = function()
    prof.write 'prof.mpack'
end