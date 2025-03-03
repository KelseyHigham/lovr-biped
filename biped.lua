-- based on the open-source Gorilla Tag locomotion system:
-- https://github.com/Another-Axiom/GorillaLocomotion
-- controls are handled in player-library.lua

local bipedClass = {}
local limbClass = {}

bipedClass.new = function(args)
    local biped = {}
    setmetatable(biped, {__index = bipedClass})

    -- rug: the play area floor center's position in the virtual world. this is what jumps when you jump.
    biped.spawnPoint         = args.spawnPoint or lovr.math.newVec3()
    biped.rugPos             = lovr.math.newVec3(biped.spawnPoint)
    biped.rugLastPos         = lovr.math.newVec3(biped.spawnPoint)
    biped.rugVel             = lovr.math.newVec3()
    biped.rugLastVel         = lovr.math.newVec3()
    biped.rugOrientation     = lovr.math.newQuat()
    biped.rugLastOrientation = lovr.math.newQuat()
    biped.getRugTransform = function()
        return mat4(biped.rugPos, biped.rugOrientation)
    end
    biped.getRugLastTransform = function()
        return mat4(biped.rugLastPos, biped.rugLastOrientation)
    end

    -- colliders
    biped.world = args.world or lovr.physics.newWorld()
    biped.terrainShapes = {}

    -- left hand
    biped.left = {}
    setmetatable(biped.left, {__index = limbClass})
    local l = biped.left
    l.pos              = lovr.math.newVec3(biped.rugPos + args.leftPos)
    l.lastPos          = lovr.math.newVec3(l.pos)
    l.collider         = biped.world:newSphereCollider(l.lastPos, .05)
    l.shape            = l.collider:getShapes()[1] -- unused?
    l.biped            = biped
    l.contacts = {} -- rename later? or just for debug?

    -- right hand
    biped.right = {}
    setmetatable(biped.right, {__index = limbClass})
    local r = biped.right
    r.pos              = lovr.math.newVec3(biped.rugPos + args.rightPos)
    r.lastPos          = lovr.math.newVec3(r.pos)
    r.collider         = biped.world:newSphereCollider(r.lastPos, .05)
    r.shape            = r.collider:getShapes()[1]
    r.biped            = biped
    r.contacts = {}

    -- head
    biped.head = {}
    setmetatable(biped.head, {__index = limbClass})
    local h         = biped.head
    h.pos           = lovr.math.newVec3(biped.rugPos + args.headPos)
    h.lastPos       = lovr.math.newVec3(h.pos)
    h.collider      = biped.world:newSphereCollider(h.pos, .05)
    h.shape         = h.collider:getShapes()[1]
    h.biped         = biped

    -- jump based on average displacement
    biped.displacements = {}
    for i = 1, 7 do
        table.insert(biped.displacements, lovr.math.newVec3())
    end
    biped.deltaTimes = {}
    for i = 1, 7 do
        table.insert(biped.deltaTimes, 0)
    end

    return biped
end




--     ▄      █                  ▄     
--    ▀█▀ ▄▀▄ █ ▄▀▄ █▀▄ ▄▀▄ █▄▀ ▀█▀    
--     ▀▄ ▀█▄ █ ▀█▄ █▄▀ ▀▄▀ █    ▀▄    
--                  █                  
bipedClass.teleport = function(biped, spawnPoint, leftConPos, rightConPos, headConPos)
    print('teleported!')
    biped.rugVel:set() -- more fun if it's commented out tbh
    biped.rugPos:set(spawnPoint)

    local leftConPos = leftConPos or vec3()
    biped.left.lastPos:set(biped.rugPos + leftConPos)
    biped.left.pos:set(biped.left.lastPos)

    local rightConPos = rightConPos or vec3()
    biped.right.lastPos:set(biped.rugPos + rightConPos)
    biped.right.pos:set(biped.right.lastPos)

    local headConPos = headConPos or vec3()
    biped.head.pos:set(biped.rugPos + headConPos)
end


















local frameNum = 0


--              █      ▄         
--    █ █ █▀▄ ▄▀█ ▄▀█ ▀█▀ ▄▀▄    
--    ▀▄█ █▄▀ ▀▄█ ▀▄█  ▀▄ ▀█▄    
--        █                          -- controller
bipedClass.update = function(biped, dt, leftConPos, rightConPos, headConPos)
    frameNum = frameNum + 1

    -- convenience
    local rugPos          = biped.rugPos
    local rugVel          = biped.rugVel
    local rugOrientation  = biped.rugOrientation
    local getRugTransform = biped.getRugTransform
    local left            = biped.left
    local right           = biped.right
    local head            = biped.head

    -- previous frame
     left.lastPos:set( left.pos)
    right.lastPos:set(right.pos)
     head.lastPos:set( head.pos)
    biped.rugLastPos:set(rugPos)
    biped.rugLastVel:set(rugVel)
    biped.rugLastOrientation:set(rugOrientation)

    -- apply velocity
    rugPos:set(rugPos + rugVel*dt)


    --            █        █   ▄▀▄   █▀▄                █      
    --    ▄▀▀ ▄▀█ █ ▄▀▀    █   ▄▀▄ ▄ █▄▀    █▀▄ █ █ ▄▀▀ █▀▄    
    --    ▀▄▄ ▀▄█ █ ▀▄▄    █▄▄ ▀▄▄▀▄ █ █    █▄▀ ▀▄█ ▄█▀ █ █    
    --                                      █                  
    prof.push 'push'
    local  leftIntendedPos = getRugTransform() *  leftConPos
    local rightIntendedPos = getRugTransform() * rightConPos
    -- try to go a bit below floor level, for extra stickiness
    local  leftIntendedPosSticky =  leftIntendedPos + vec3(0, 2 * -9.8*dt*dt, 0)
    local rightIntendedPosSticky = rightIntendedPos + vec3(0, 2 * -9.8*dt*dt, 0)
    prof.push 'hand cast'
    local  leftPushCast  = left:shapeCast( left.lastPos,  leftIntendedPosSticky)
    local rightPushCast = right:shapeCast(right.lastPos, rightIntendedPosSticky)
    prof.pop 'hand cast'
    -- maybe i should adjust for gravity slip? if collided two frames in a row, then calc from left.lastPos, not leftPushCast.farthestValidPos
    local  leftPush = vec3( leftPushCast.farthestValidPos -  leftIntendedPos)
    local rightPush = vec3(rightPushCast.farthestValidPos - rightIntendedPos)



    --                  █   ▀                        █          █            
    --    ▄▀▀ ▄▀▄ █▀▄▀▄ █▀▄ █ █▀▄ ▄▀▄    █▀▄ █ █ ▄▀▀ █▀▄    █▀▄ █ ▄▀█ █▀▄    
    --    ▀▄▄ ▀▄▀ █ █ █ █▄▀ █ █ █ ▀█▄    █▄▀ ▀▄█ ▄█▀ █ █    █▄▀ █ ▀▄█ █ █    
    --                                   █                  █                
    local int = function(bool)
        if bool then return 1 else return 0 end
    end
    local numCollidingLimbs = int(leftPushCast.collided) + int(rightPushCast.collided) 
    local pushPlan = vec3()
    if numCollidingLimbs > 0 then
        rugVel:set()
        pushPlan = (leftPush + rightPush) / numCollidingLimbs
    end



    --            █ ▀   █      ▄                     █          █            
    --    █ █ ▄▀█ █ █ ▄▀█ ▄▀█ ▀█▀ ▄▀▄    █▀▄ █ █ ▄▀▀ █▀▄    █▀▄ █ ▄▀█ █▀▄    
    --     █  ▀▄█ █ █ ▀▄█ ▀▄█  ▀▄ ▀█▄    █▄▀ ▀▄█ ▄█▀ █ █    █▄▀ █ ▀▄█ █ █    
    --                                   █                  █                
    -- override pushPlan if head clips
    local headIntendedPos = getRugTransform() * headConPos + pushPlan
    local headMov = headIntendedPos - head.lastPos
    -- horizontal component: slide
    prof.push 'head horiz slippycast'
    local headCheckCastXZ = head:slipperyShapeCast(
        head.lastPos, 
        head.lastPos + vec3(headMov.x, 0, headMov.z), 
        1
    )
    prof.pop 'head horiz slippycast'
    -- vertical component: don't slide, so we don't slide down slopes
    prof.push 'head vert cast'
    local headCheckCastY = head:shapeCast(
        headCheckCastXZ.farthestValidPos, 
        headCheckCastXZ.farthestValidPos + vec3(0, headMov.y, 0)
    )
    prof.pop 'head vert cast'
    if headCheckCastXZ.collided or headCheckCastY.collided then
        rugVel:set()
        local headValidPush = vec3(headCheckCastY.farthestValidPos - headIntendedPos)
        pushPlan:set(pushPlan+headValidPush)
    end
    head.pos:set(headCheckCastY.farthestValidPos)



    --                █      
    --    █▀▄ █ █ ▄▀▀ █▀▄    
    --    █▄▀ ▀▄█ ▄█▀ █ █    
    --    █                  
    -- this is where the camera position is decided
    rugPos:set(rugPos+pushPlan)
    prof.pop 'push'


    --                                   █        █ ▀   █        █             █        
    --    █▀▄▀▄ ▄▀▄ █ █ ▄▀▄    ▄▀█ █▀▄ ▄▀█    ▄▀▀ █ █ ▄▀█ ▄▀▄    █▀▄ ▄▀█ █▀▄ ▄▀█ ▄▀▀    
    --    █ █ █ ▀▄▀  █  ▀█▄    ▀▄█ █ █ ▀▄█    ▄█▀ █ █ ▀▄█ ▀█▄    █ █ ▀▄█ █ █ ▀▄█ ▄█▀    

    -- slide limbs, to make two-handed grabbing feel nicer
    prof.push 'slide'
    -- left push can move right hand, and vice-versa, within the push frame
    -- this code is to get rid of that visual artifact
    -- as a consequence, this is where the final hand position actually gets set
     leftIntendedPos = getRugTransform() *  leftConPos
    rightIntendedPos = getRugTransform() * rightConPos
    prof.push 'hand slippycast'
     leftMoveCast =  left:slipperyShapeCast( leftPushCast.farthestValidPos,  leftIntendedPos, .03)
    rightMoveCast = right:slipperyShapeCast(rightPushCast.farthestValidPos, rightIntendedPos, .03)
    prof.pop 'hand slippycast'

     left.collided =  leftPushCast.collided or  leftMoveCast.collided
    right.collided = rightPushCast.collided or rightMoveCast.collided
    prof.pop 'slide'


    --                    ▀  ▄         
    --    ▄▀█ █▄▀ ▄▀█ █ █ █ ▀█▀ █ █    
    --    ▀▄█ █   ▀▄█  █  █  ▀▄ ▀▄█    
    --    ▄▄▀                   ▄▄▀    

    if not NO_GRAVITY then
        rugVel:set(rugVel+vec3(0, -9.8*dt, 0))
    end



    --     ▀                  
    --     █ █ █ █▀▄▀▄ █▀▄    
    --     █ ▀▄█ █ █ █ █▄▀    
    --    ▄▀           █      
    -- not robust against frame drops
    prof.push 'jump'
    -- populate displacements[]
    local displacements = biped.displacements
    displacements[1]:set(rugPos - biped.rugLastPos)      -- reuse oldest permanent vector
    displacements[#displacements + 1] = displacements[1] -- copy the reference to the end
    table.remove(displacements, 1)                       -- remove the reference from the beginning

    if left.collided or right.collided then
        local average_displacement = vec3()
        for i = 1, #displacements do
            average_displacement:set(average_displacement+displacements[i])
        end
        average_displacement:div(#displacements)

        -- if we go fast enough, add it to our velocity
        local fps = lovr.headset.getRefreshRate() or 60
        if (average_displacement:length() > 0.4 / fps) then
            print ("🐰 jumped!", lovr.math.random())
            -- rugVel:set(average_displacement * 1.1)
            rugVel:set(average_displacement/dt * 1.1)
        end
    end
    prof.pop 'jump'
















--                       ▄▀                         ▄     ▄▀                      
--    █▀▄ █▄▀ ▄▀▄ █▀▄    █▀ ▄▀▄ █▄▀    █▀▄ ▄▀▄ ▀▄▀ ▀█▀    █▀ █▄▀ ▄▀█ █▀▄▀▄ ▄▀▄    
--    █▄▀ █   ▀█▄ █▄▀    █  ▀▄▀ █      █ █ ▀█▄ ▄▀▄  ▀▄    █  █   ▀▄█ █ █ █ ▀█▄    
--    █           █                                                               
    -- prep for next frame
     left.pos:set( leftMoveCast.farthestValidPos)
    right.pos:set(rightMoveCast.farthestValidPos)

    if rugPos:equals(biped.rugLastPos) == false
    or rugVel:equals(biped.rugLastVel) == false then
        -- print('rugPos', rugPos)
        -- print('rugVel', rugVel)
    end
end



















--    █ ▀       █             █ █ ▀   █ ▀         ▄▀▄  ▄     
--    █ █ █▀▄▀▄ █▀▄ ▀ ▄▀▀ ▄▀▄ █ █ █ ▄▀█ █ █▀▄ ▄▀█ █▄█ ▀█▀    
--    █ █ █ █ █ █▄▀ ▄ ▀▄▄ ▀▄▀ █ █ █ ▀▄█ █ █ █ ▀▄█ █ █  ▀▄    
--                                            ▄▄▀            
limbClass.getContacts = function(limb, lastPosition, intendedPosition, distanceFraction)
    -- move collider, then check collision
    -- collider is only used in this function, so we don't bother putting it back
    local destination = vec3(lastPosition):lerp(intendedPosition, distanceFraction)
    limb.collider:setPosition(destination:unpack())
    for _, terrainShape in ipairs(limb.biped.terrainShapes) do
        local contacts = limb.biped.world:getContacts(limb.shape, terrainShape)
        if #contacts > 0 then
            return contacts
        end
    end
    return false
end
limbClass.collidingAt = function(limb, lastPosition, intendedPosition, distanceFraction)
    -- move collider, then check collision
    -- collider is only used in this function, so we don't bother putting it back
    local destination = vec3(lastPosition):lerp(intendedPosition, distanceFraction)
    limb.collider:setPosition(destination:unpack())
    for _, terrainShape in ipairs(limb.biped.terrainShapes) do
        if limb.biped.world:collide(limb.shape, terrainShape) then
            return true 
        end
    end
    return false
end





--    █ ▀       █         █               ▄▀▀          ▄     
--    █ █ █▀▄▀▄ █▀▄ ▀ ▄▀▀ █▀▄ ▄▀█ █▀▄ ▄▀▄ █   ▄▀█ ▄▀▀ ▀█▀    
--    █ █ █ █ █ █▄▀ ▄ ▄█▀ █ █ ▀▄█ █▄▀ ▀█▄ ▀▄▄ ▀▄█ ▄█▀  ▀▄    
--                                █                          
-- returns {vec3 farthestValidPos, bool collided, float validPercentage, table contacts}
limbClass.shapeCast = function(limb, lastPosition, intendedPosition)
    prof.push 'ghost'
    if limb:collidingAt(lastPosition, intendedPosition, 0) then
        prof.pop 'ghost'
        print(frameNum, '👻 error: we spawned inside the floor')
        return {
            farthestValidPos = intendedPosition,
            collided = false, -- lie and fall through the floor
            validPercentage = 1,
            contacts = nil
        }
    else
        prof.pop 'ghost'
        prof.push 'turtle'
        local distance = intendedPosition:distance(lastPosition)
        local collided = false

        --    ▀█▀ █ █ █▀▄ ▀█▀ █   ██▀    
        --     █  █▄█ █▀▄  █  █▄▄ █▄▄    
        -- a Shape only reports collision while its center is outside a mesh
            -- (due to an ODE design decision)
        -- advance a sphere by radius/2 until it hits something, *then* start binary search
        local step = .025 / distance
        if step < .0001 then
            step = .0001 -- avoid running out of vector space
            print('🐢 error: might clip into geometry')
        end
        local turtlestart = 0
        local turtleend = 1
        for turtle = 0, 1, step do
            if limb:collidingAt(lastPosition, intendedPosition, turtle) then
                turtleend = turtle
                collided = true
                break
            end
            turtlestart = turtle
        end
        prof.pop 'turtle'

        prof.push 'binary search'
        --    ██▄ █ █▀▄ ▄▀▄ █▀▄ ▀▄▀   ▄▀▀ ██▀ ▄▀▄ █▀▄ ▄▀▀ █▄█    
        --    █▄█ █ █ █ █▀█ █▀▄  █    ▄█▀ █▄▄ █▀█ █▀▄ ▀▄▄ █ █    
        -- get the limb within .0001m of the terrain
        local nearest, middle, farthest = turtlestart, (turtlestart+turtleend)/2, turtleend
        local mostRecentCollision = 1
        while true do
            if limb:collidingAt(lastPosition, intendedPosition, middle) then
                mostRecentCollision = middle
                collided = true
                -- if we're within .1mm of the wall
                if (farthest-nearest) * distance < .0001 then
                    prof.pop 'binary search'
                    return {
                        farthestValidPos = vec3(lastPosition):lerp(intendedPosition, nearest),
                        collided = true,
                        validPercentage = nearest,
                        contacts = limb:getContacts(lastPosition, intendedPosition, mostRecentCollision)
                    }
                else
                    nearest, middle, farthest = nearest, (nearest+middle)/2, middle
                end
            elseif (farthest-nearest) * distance < .0001 then
                prof.pop 'binary search'
                return {
                    farthestValidPos = vec3(lastPosition):lerp(intendedPosition, middle),
                    collided = collided,
                    validPercentage = middle,
                    contacts = collided and limb:getContacts(lastPosition, intendedPosition, mostRecentCollision)
                }
            else
                nearest, middle, farthest = middle, (middle+farthest)/2, farthest
            end
        end -- binary search

    end
end





--                 ▀          ▄              ▄             █                
--    █▀▄ █▄▀ ▄▀▄  █ ▄▀▄ ▄▀▀ ▀█▀    ▄▀▄ █▀▄ ▀█▀ ▄▀▄    █▀▄ █ ▄▀█ █▀▄ ▄▀▄    
--    █▄▀ █   ▀▄▀  █ ▀█▄ ▀▄▄  ▀▄    ▀▄▀ █ █  ▀▄ ▀▄▀    █▄▀ █ ▀▄█ █ █ ▀█▄    
--    █           ▄▀                                   █                    
local projectOntoPlane = function(limbPos, planePos, planeNormal)
    local planePosToLimb = limbPos - planePos
    local distanceLimbToPlane = planePosToLimb:dot(planeNormal)
    local projectedPoint = limbPos - planeNormal*distanceLimbToPlane
    return projectedPoint
end





--    █ ▀       █         █ ▀                     ▄▀▀ █               ▄▀▀          ▄     
--    █ █ █▀▄▀▄ █▀▄ ▀ ▄▀▀ █ █ █▀▄ █▀▄ ▄▀▄ █▄▀ █ █  ▀▄ █▀▄ ▄▀█ █▀▄ ▄▀▄ █   ▄▀█ ▄▀▀ ▀█▀    
--    █ █ █ █ █ █▄▀ ▄ ▄█▀ █ █ █▄▀ █▄▀ ▀█▄ █   ▀▄█ ▄▄▀ █ █ ▀▄█ █▄▀ ▀█▄ ▀▄▄ ▀▄█ ▄█▀  ▀▄    
--                            █   █           ▄▄▀             █                          
limbClass.slipperyShapeCast = function(limb, lastPosition, intendedPosition, slipFraction)
    local cast1 = limb:shapeCast(lastPosition, intendedPosition)
    if cast1.collided then
        local slipFraction   = slipFraction or 1
        local c              = cast1.contacts[1]
        local planePos       = vec3(c[1], c[2], c[3])
        local planeNormal    = vec3(c[4], c[5], c[6])
        local projectedPoint = projectOntoPlane(
            intendedPosition, 
            cast1.farthestValidPos, -- project onto the plane that's sphereradius away from the wall
            planeNormal
        )
        local slipDestination = vec3(cast1.farthestValidPos):lerp(projectedPoint, slipFraction)
        local cast2 = limb:shapeCast(cast1.farthestValidPos, slipDestination)
        cast2.collided = true -- cast1 collided, so we return collided=true
        return cast2
    else
        return cast1
    end
end




-- quantize to the nearest millimeter; mutates
mm = function(v)
    local newV = vec3()
    newV.x = v.x - v.x % 1/1024
    newV.y = v.y - v.y % 1/1024
    newV.z = v.z - v.z % 1/1024
    return newV
end




--     ▄                 
--    ▀█▀ █ █ █▄▀ █▀▄    
--     ▀▄ ▀▄█ █   █ █    

bipedClass.turn = function (biped, angle)
    -- as described in this page, turning works best if it moves the rug:
    -- https://www.makuxr.com/blog/snap-turn
    local limb = mat4(biped.head.pos)
    if biped.left.collided then
        limb = mat4(biped.left.pos)
    elseif biped.right.collided then
        limb = mat4(biped.right.pos)
    end
    local inverseLimb = mat4(limb):invert()
    biped.rugPos:set(
        mat4()
        :mul(limb) -- headspace to worldspace
        :rotate(angle, 0, 1, 0)
        :mul(inverseLimb) -- worldspace to headspace
        :mul(biped.getRugTransform())
    )
    biped.rugOrientation:set(quat(angle, 0, 1, 0) * biped.rugOrientation)
end







return bipedClass