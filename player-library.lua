-- player: handles biped walk/jump and wing flapping
-- biped: handles biped math, but not controller input

--[[
character controller making use of the complex gorilla library

make this very specific and inelegent
this class exists so that gorilla-locomotion can be ONLY MATH
and so it can be dropped into other projects with zero effort
and can be controlled by a computer
]]

-- run biped first or second, it doesn't actually make a difference.
-- regardless, run flapping based on biped.left.pos and biped.left.lastPos
-- and feed the result into biped.rugVel

prof = prof or {push = function() end, pop = function() end}




local playerfunctions = {}


--    █▀▄ ▄▀▄ █ █ █    
--    █ █ ▀█▄  █ █     

playerfunctions.new = function(world, spawnPoint)
  local player = {}
  setmetatable(player, {__index = playerfunctions})
  player.world = world or lovr.physics.newWorld()
  player.spawnPoint = spawnPoint or lovr.math.newVec3(0,0,0)
  player.biped = require("biped").new{
    world      = player.world,
    spawnPoint = player.spawnPoint,
    leftPos    = vec3(lovr.headset.getPosition('left')),
    rightPos   = vec3(lovr.headset.getPosition('right')),
    headPos    = vec3(lovr.headset.getPosition('head'))
  }
  player.terrainShapes      = player.biped.terrainShapes
  player.thumbstickCooldown = 0

  playerReferenceForKeyboardTurn = player

  player.noFlap = false

  return player
end





--                █       █ █▀▄         ▀         █▀▄         ▀  ▄  ▀            
--    ▄▀▀ ▄▀▀ ▄▀█ █ ▄▀▄ ▄▀█ █ █ ▄▀▄ █ █ █ ▄▀▀ ▄▀▄ █▄▀ ▄▀▄ ▄▀▀ █ ▀█▀ █ ▄▀▄ █▀▄    
--    ▄█▀ ▀▄▄ ▀▄█ █ ▀█▄ ▀▄█ █▄▀ ▀█▄  █  █ ▀▄▄ ▀█▄ █   ▀▄▀ ▄█▀ █  ▀▄ █ ▀▄▀ █ █    

local mostRecentTrackedPosition = { -- workaround for https://github.com/bjornbytes/lovr/pull/677#issuecomment-1618242963
  head = lovr.math.newVec3(),
  left = lovr.math.newVec3(),
  right = lovr.math.newVec3()
}
local desktop = lovr.headset.getDriver() == 'desktop'
local headset = lovr.headset
local scaledDevicePosition = function (limbName)
  local limbName = limbName
  -- bed mode
  -- if the trigger is held, then double hand movements, relative to the head
  prof.push 'bed mode'
  local trigger = headset.getAxis(limbName, 'trigger')
  if desktop then 
    trigger = (headset.isDown(limbName, 'trigger') and 1 or 0)
  end
  prof.pop 'bed mode'

  prof.push 'head pose'
  local head = mat4(headset.getPose('head'))
  local inverseHead = mat4():set(head):invert()
  prof.pop 'head pose'
  prof.push 'tracking loss'
  local controllerPosition = nil
  if headset.isTracked(limbName) then
    mostRecentTrackedPosition[limbName]:set(vec3(headset.getPosition(limbName)))
    controllerPosition = vec3(headset.getPosition(limbName))
  else
    controllerPosition = mostRecentTrackedPosition[limbName]
  end
  prof.pop 'tracking loss'
  prof.push 'mathy'
  local scaledDevicePosition = vec3(
    mat4()
    :mul(head)
    :scale(1 + trigger)
    :mul(inverseHead)
    :mul(controllerPosition)
  )
  prof.pop 'mathy'
  return scaledDevicePosition
end







--              █      ▄         
--    █ █ █▀▄ ▄▀█ ▄▀█ ▀█▀ ▄▀▄    
--    ▀▄█ █▄▀ ▀▄█ ▀▄█  ▀▄ ▀█▄    
--        █                      
playerfunctions.update = function(self, deltaTime)
  self.noFlap = false
  prof.push 'not biped'
  prof.push 'little things'
  prof.push 'cdt'
  local cappedDeltaTime = math.min(deltaTime, 24/(lovr.headset.getRefreshRate() or 60))
  prof.pop 'cdt'
  -- cappedDeltaTime = 1/(lovr.headset.getRefreshRate() or 60)
  -- cappedDeltaTime = deltaTime

  prof.push 'getPosition'
  local head  = vec3(lovr.headset.getPosition('head'))
  prof.pop 'getPosition'
  prof.push 'scaledDevicePosition'
  local left  = scaledDevicePosition('left')
  local right = scaledDevicePosition('right')
  prof.pop 'scaledDevicePosition'

  if desktop then
    right = left
  end

  local pb = self.biped
  prof.pop 'little things'

  prof.push 'buttons'
  --            ▀      ▄     █        ▄   ▄                 
  --    █▀▄ █▄▀ █ █▀▄ ▀█▀    █▀▄ █ █ ▀█▀ ▀█▀ ▄▀▄ █▀▄ ▄▀▀    
  --    █▄▀ █   █ █ █  ▀▄    █▄▀ ▀▄█  ▀▄  ▀▄ ▀▄▀ █ █ ▄█▀    
  --    █                                                   
  -- debug purposes: mash A
  if lovr.headset.wasPressed('right', 'a') then
    print('🅰️')
  end
  if lovr.headset.wasPressed('right', 'b') then
    print('🅱️')
  end
  if lovr.headset.wasPressed('left',  'x') then
    print('❎')
  end
  if lovr.headset.wasPressed('left',  'y') then
    print('💹')
  end


  --      █          ▄  █          █                
  --    ▄▀█ ▄▀▄ ▄▀█ ▀█▀ █▀▄    █▀▄ █ ▄▀█ █▀▄ ▄▀▄    
  --    ▀▄█ ▀█▄ ▀▄█  ▀▄ █ █    █▄▀ █ ▀▄█ █ █ ▀█▄    
  --                           █                    
  if pb.head.pos.y < -100 then
    self:respawn()
  end


  local turnedThisFrame = false

  --    █        ▄   ▄              ▄                 
  --    █▀▄ █ █ ▀█▀ ▀█▀ ▄▀▄ █▀▄    ▀█▀ █ █ █▄▀ █▀▄    
  --    █▄▀ ▀▄█  ▀▄  ▀▄ ▀▄▀ █ █     ▀▄ ▀▄█ █   █ █    

  if lovr.headset.wasPressed('left',  'y') then
    self.biped:turn( 2*math.pi / 8)
    turnedThisFrame = true
  end
  if lovr.headset.wasPressed('right', 'b') then
    self.biped:turn(-2*math.pi / 8)
    turnedThisFrame = true
  end


  --         ▄  ▀     █       ▄                 
  --    ▄▀▀ ▀█▀ █ ▄▀▀ █▄▀    ▀█▀ █ █ █▄▀ █▀▄    
  --    ▄█▀  ▀▄ █ ▀▄▄ █ █     ▀▄ ▀▄█ █   █ █    
  -- Snap horizontal turning

  -- if lovr.headset.isTracked('right') then
    local x, _ = lovr.headset.getAxis('right', 'thumbstick')
    if math.abs(x) > .5 then
      if self.thumbstickCooldown < 0 then
        local angle = -x / math.abs(x) * 2*math.pi/8
        self.biped:turn(angle, 0, 1, 0)
        turnedThisFrame = true
        self.thumbstickCooldown = .25
      end
    else
      -- thumbstickCooldown = 0
    end
    self.thumbstickCooldown = self.thumbstickCooldown - deltaTime
  -- end
  prof.pop 'buttons'


  prof.push 'bird'
  --    █   ▀       █    
  --    █▀▄ █ █▄▀ ▄▀█    
  --    █▄▀ █ █   ▀▄█    

  -- left controller in room space
  -- calculated from actual arm position so that
  -- - if your arms+head get stuck in VR space, you can't flap
  -- - flapping is modulated by scaledDevicePosition
  -- - flapping is oriented correctly after snap turn
  roomLeft      = pb.getRugTransform()    :invert() * pb.left.pos
  roomRight     = pb.getRugTransform()    :invert() * pb.right.pos
  roomLastLeft  = pb.getRugLastTransform():invert() * pb.left.lastPos
  roomLastRight = pb.getRugLastTransform():invert() * pb.right.lastPos
  local flapLeftVel  = (roomLeft  - roomLastLeft ) / deltaTime
  local flapRightVel = (roomRight - roomLastRight) / deltaTime
  local flap = (flapLeftVel + flapRightVel) / 2
  if flap.y < -1 and flapLeftVel.y < -.5 and flapRightVel.y < -.5 and not turnedThisFrame then
    local scaledFlap = pb.rugOrientation * vec3(
      -flap.x * 4 * deltaTime,
      -flap.y * 8 * deltaTime,
      -flap.z * 4 * deltaTime
    )
    if not NO_GRAVITY and not self.noFlap then
      pb.rugVel:set(pb.rugVel+scaledFlap)
      io.write('🪶')
    end
  end
  prof.pop 'bird'


  prof.pop 'not biped'


  --                ▀ █ █        
  --    ▄▀█ ▄▀▄ █▄▀ █ █ █ ▄▀█    
  --    ▀▄█ ▀▄▀ █   █ █ █ ▀▄█    
  --    ▄▄▀                      

  -- keep this last, so we know we're drawing something with resolved collision
  prof.push 'biped'
  pb:update(cappedDeltaTime, left, right, head) 
  prof.pop 'biped'

end







--    █                                     █    
--    █▄▀ ▄▀▄ █ █ █▀▄ █▄▀ ▄▀▄ ▄▀▀ ▄▀▀ ▄▀▄ ▄▀█    
--    █ █ ▀█▄ ▀▄█ █▄▀ █   ▀█▄ ▄█▀ ▄█▀ ▀█▄ ▀▄█    
--            ▄▄▀ █                              
function lovr.keypressed(key)
  if key == 'space' then
    -- respawn()
  end
  if key == 'z' then
    playerReferenceForKeyboardTurn.biped:turn( 2*math.pi / 8)
  end
  if key == 'x' then
    playerReferenceForKeyboardTurn.biped:turn(-2*math.pi / 8)
  end
end





--    █▄▀ ▄▀▄ ▄▀▀ █▀▄ ▄▀█ █ █ █ █▀▄    
--    █   ▀█▄ ▄█▀ █▄▀ ▀▄█  █ █  █ █    
--                █                    
playerfunctions.respawn = function(self)
  self.biped:teleport(self.spawnPoint)
  -- self.noFlap = true
end





--      █                  
--    ▄▀█ █▄▀ ▄▀█ █ █ █    
--    ▀▄█ █   ▀▄█  █ █     
-- unused
playerfunctions.draw = function(self, pass)
  local pb    = self.biped
  local left  = self.biped.left
  local right = self.biped.right

  pass:setColor(1,1,1)
  if pb.left.collided then pass:setColor(.8,.8,.8) end
  pass:sphere(pb.left.pos, .1)

  pass:setColor(1,1,1)
  if pb.right.collided then pass:setColor(.8,.8,.8) end
  pass:sphere(pb.right.pos, .1)

  -- eyes
  for i = 1, pass:getViewCount() do
      pass:setViewPose(i, mat4(pb.rugPos) * mat4(pass:getViewPose(i)))
  end
end





--    █         █   ▀█▀ █                   █   █▀▀                
--    █ ▄▀▄ ▄▀▄ █▄▀  █  █▀▄ █▄▀ ▄▀▄ █ █ ▄▀█ █▀▄ █▀  █ █ ▄▀▄ ▄▀▀    
--    █ ▀▄▀ ▀▄▀ █ █  █  █ █ █   ▀▄▀ ▀▄█ ▀▄█ █ █ █▄▄ ▀▄█ ▀█▄ ▄█▀    
--                                      ▄▄▀         ▄▄▀            
playerfunctions.lookThroughEyes = function(self, pass)
  for i = 1, pass:getViewCount() do
      pass:setViewPose(i, self.biped.getRugTransform() * mat4(pass:getViewPose(i)))
  end
end





--      █               █ █           █        
--    ▄▀█ █▄▀ ▄▀█ █ █ █ █▀█ ▄▀█ █▀▄ ▄▀█ ▄▀▀    
--    ▀▄█ █   ▀▄█  █ █  █ █ ▀▄█ █ █ ▀▄█ ▄█▀    

playerfunctions.drawHands = function(self, pass)
  local pb    = self.biped
  local left  = self.biped.left
  local right = self.biped.right
  local head  = self.biped.head

  -- left
  pass:setColor(1,1,1)
  if pb.left.collided then pass:setColor(1,.5,.5) end
  pass:sphere(pb.left.pos, .05)

  -- hand
  pass:setColor(1,1,1)
  if pb.right.collided then pass:setColor(1,.5,.5) end
  pass:sphere(pb.right.pos, .05)
end





--      █               █▀▄     █              
--    ▄▀█ █▄▀ ▄▀█ █ █ █ █ █ ▄▀▄ █▀▄ █ █ ▄▀█    
--    ▀▄█ █   ▀▄█  █ █  █▄▀ ▀█▄ █▄▀ ▀▄█ ▀▄█    
--                                      ▄▄▀    
playerfunctions.drawDebug = function(self, pass)
  pass:setWireframe(true)
  pass:setColor(0,0,0)
  pass:sphere(roomLeft,  .05)
  pass:setColor(0,0,0)
  pass:sphere(roomRight, .05)
  pass:setColor(1,0,0)
  pass:sphere(roomLastLeft,  .05)
  pass:setColor(1,0,0)
  pass:sphere(roomLastRight, .05)
  pass:setWireframe(false)
end









return playerfunctions