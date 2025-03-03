-- move helper functions to the bottom
  -- i can do this after i wrap cubes.new() in a function
-- add example "uses-cubes-library.lua" line of code after every heading
-- load(), new(), draw()
-- init() might be more clear than load()

-- either settle on a size of 16, or make it a per-chunk variable

-- used by:
--     (figure out grep so i can be exhaustive)
--     grep -l "require(\"cubes-library\")" *
-- uses-cubes-library.lua
-- fly.lua
-- uses-player-library.lua
-- gorilla405-friend.lua
-- uses-gorilla-library.lua


prof = prof or {push = function() end, pop = function() end}

local marching = require "marching"

local cubes = {
  chunks = {},
  totalVertices = 0
}
cubes.__index = cubes

local size = sizeOverride or 16 -- 0 to size

local seed = lovr.math.random() * 100000
seed = 0
















--      █           █                           
--      █▀▀▄  ▄▀▀▄  █  █▀▀▄  ▄▀▀▄  █▄▀  ▄▀▀▄    
--      █  █  █▄▄█  █  █  █  █▄▄█  █     ▀▄    
--      █  █  ▀▄▄   █  █▄▄▀  ▀▄▄   █    ▀▄▄▀    
--                     █                        



--            ▀            ▄▀              ▄  ▀                
--    █▀▄ ▄▀▄ █ ▄▀▀ ▄▀▄    █▀ █ █ █▀▄ ▄▀▀ ▀█▀ █ ▄▀▄ █▀▄ ▄▀▀    
--    █ █ ▀▄▀ █ ▄█▀ ▀█▄    █  ▀▄█ █ █ ▀▄▄  ▀▄ █ ▀▄▀ █ █ ▄█▀    



local function round(value)
  if (value > .5) then
    return 1
  else
    return 0
  end
end


local n = lovr.math.noise

local function fancyNoise(x,y,z)
  local height = (y-3)/20 -- originally size
  local heightWeight = (1-height)^2
  -- heightWeight = 1
  local scale = .2
  -- scale = 1

  -- n(x+4, y+4,z+5)
  -- n(x*12+43,y*86+34,z*24+2)
  -- return heightWeight * 
    -- n(x*scale + seed, y*scale, z*scale)*.3 +
    -- n(x+4, y+4,z+4)*.3 +
    -- n(x*12+43,y*85+34,z*24+2)*.3

  -- return lovr.math.noise(x,y,z)

  return heightWeight * n(x*scale + seed, y*scale - seed, z*scale + seed)
end



local noiseCache = {}

-- remember, don't cache noise that's gonna generate new values for every lookup
-- e.g. fancier AO
local function noise(x,y,z)
  local worldSize = 1e4 -- affects the size of distant mountains...
  local key = (x + worldSize/2) +
              (y + worldSize/2) * worldSize +
              (z + worldSize/2) * worldSize * worldSize
  if noiseCache[key] then
    return noiseCache[key]
  else
    noiseCache[key] = fancyNoise(x,y,z)
    return noiseCache[key]
  end
  return fancyNoise(x,y,z)
end

local function collisionNoise(x,y,z, chunkx,chunky,chunkz)
  if 
    x < chunkx or x > chunkx + size+1 or
    y < chunky or y > chunky + size+1 or
    z < chunkz or z > chunkz + size+1
  then
    return 0
  end
  return noise(x,y,z)
end



--                  █                     
--    █▀▄▀▄ ▄▀▄ ▄▀▀ █▀▄    ▄▀█ ▄▀▄ █▀▄    
--    █ █ █ ▀█▄ ▄█▀ █ █    ▀▄█ ▀█▄ █ █    
--                         ▄▄▀            

local vertexFormat = {
  {name = 'VertexPosition'  , type = 'vec3'},
  {name = 'VertexNormal'    , type = 'vec3'},
  {name = 'VertexAmbient'   , type = 'vec4'},
  {name = 'VertexShadowMask', type = 'vec4'}
}
local indexFormat = {
  {name = 'IndexPosition', type = 'index16'}
}

























--                                   █                 █       
--     █▀▀▄  ▄▀▀▄  █   █       ▄▀▀▄  █▀▀▄  █  █  █▀▀▄  █ ▄▀    
--     █  █  █▄▄█  █ █ █       █     █  █  █  █  █  █  █▀▄     
--     █  █  ▀▄▄    █ █        ▀▄▄▀  █  █  ▀▄▄█  █  █  █  █    


local chunkCache = {}


function cubes.new(world, chunkx,chunky,chunkz, terrainColliderList, chunkDrawArray)
  
  local key = chunkx .. ',' .. chunky .. ',' .. chunkz

  if chunkCache[key] then
    return chunkCache[key]
  else
    prof.push('new chunk', 'y=' .. chunky)
    local time = lovr.timer.getTime()

    local world = world or lovr.physics.newWorld()
    chunkx, chunky, chunkz = chunkx or 0, chunky or 0, chunkz or 0
    local chunk = {
      world = world,
      x = chunkx,
      y = chunky,
      z = chunkz,
      distanceFromCamera = 0
    }
    setmetatable(chunk, cubes)

    chunk.vertices = {}
    chunk.collisionVertices = {}
    chunk.drawVertices = {}
    local vertices = chunk.vertices
    local collisionVertices = chunk.collisionVertices

    local indices  = {}
    local posToVertex = {} -- for caching vertices. should be longer than the vertices table, right...?





    --          █   █ █   █          ▄             
    --    ▄▀█ ▄▀█ ▄▀█  █ █  ▄▀▄ █▄▀ ▀█▀ ▄▀▄ ▀▄▀    
    --    ▀▄█ ▀▄█ ▀▄█   █   ▀█▄ █    ▀▄ ▀█▄ ▄▀▄    

    local function addVertex(loc, qloc,     qlocA, qlocB) -- location, quantized location; noise sample extents
      local worldSize = 1e4
      local key = (qloc.x * worldSize/2) +
                  (qloc.y * worldSize/2) * worldSize +
                  (qloc.z * worldSize/2) * worldSize * worldSize
      local  locx,  locy,  locz =  loc.x,  loc.y,  loc.z
      local qlocx, qlocy, qlocz = qloc.x, qloc.y, qloc.z
      if posToVertex[key] then
        table.insert(indices, posToVertex[key])
      else

        -- normals
        local ss = 1 -- sample scale
        local nx = noise(qlocx-ss, qlocy,    qlocz   ) - noise(qlocx+ss, qlocy,    qlocz   )
        local ny = noise(qlocx,    qlocy-ss, qlocz   ) - noise(qlocx,    qlocy+ss, qlocz   )
        local nz = noise(qlocx,    qlocy,    qlocz-ss) - noise(qlocx,    qlocy,    qlocz+ss)
        local normal = vec3(nx, ny, nz):normalize()





        local qlocAx = qlocA.x
        local qlocAy = qlocA.y
        local qlocAz = qlocA.z

        local qlocBx = qlocB.x
        local qlocBy = qlocB.y
        local qlocBz = qlocB.z





        -- ambient occlusion
        local ambient = 1
        local range = 5
        for z = -1, 1 do
          for y = -1, 1 do
            for x = -1, 1 do
              if not (z == 0 and y == 0 and x == 0) then
                for i = 1, range do
                  local sampleSample = vec3(x*i,y*i,z*i)
                  local sampleVisibility = sampleSample:dot(normal)
                  if sampleVisibility > .0001 then

                    -- -- when the noise function gets significantly heavier, 
                    -- -- it might be more efficient to just interpolate
                    -- -- neighboring values for AO
                    -- local interpolatedNoise = (
                      -- noise(x+qlocAx, y+qlocAy, z+qlocAz) +
                      -- noise(x+qlocBx, y+qlocBy, z+qlocBz)
                    -- ) / 2
                    -- if interpolatedNoise > .5 then

                    -- -- using loc instead of qloc adds like 10% generation time
                    -- -- but the AO looks way better
                    -- -- surprising that it's not slower...
                    if noise(x+ locx, y+ locy, z+ locz) > .5 then
                      local distToSample = sampleSample:length()
                      local sampleInfluence = sampleVisibility * (1/distToSample)^2
                      ambient = ambient - sampleInfluence*.25
                      break
                    end
                  end
                end

              end
            end
          end
        end

        -- -- shadows by Gavin
        -- local direct = 1
        -- local raydir = vec3(0, 1, 0)
        -- local contiguous = true
        -- for distance = 1, 20, .5 do
        --   local p = raydir*distance + qloc 
        --   local px,py,pz = p.x,p.y,p.z
        --   if noise(p.x, p.y, p.z) > .5 and not contiguous then
        --     direct = 0
        --     break
        --   else
        --     contiguous = false
        --   end
        -- end

        -- hardcoded y-down shadows
        -- cuts a third of terrain gen time?!
        -- is it because of the table lookups...?
        local direct = 1 -- direct light
        local wall = true
        for distance = 1, 20, .5 do
          if noise(qlocx, qlocy+distance, qlocz) > .5 and not wall then
            direct = 0
            break -- this break doesn't seem to give much perf
                  -- suggesting that cellular automaton cave lighting would work
          else
            wall = false
          end
        end

        -- -- height light
        -- heightLight = loc.y * 4 / size
        -- direct = direct * heightLight

        table.insert(vertices, {
          loc.x,     loc.y,     loc.z,  
          normal.x,  normal.y,  normal.z,  
          ambient^2, ambient^2, ambient^2, 1,  
          direct,    direct,    direct,    1})
        posToVertex[key] = #vertices
        table.insert(indices, posToVertex[key])
      end
    end








    --                             ▄                      ▄  ▀                
    --    ▄▀█ ▄▀▄ █▀▄ ▄▀▄ █▄▀ ▄▀█ ▀█▀ ▄▀▄    █ █ ▄▀▄ █▄▀ ▀█▀ █ ▄▀▀ ▄▀▄ ▄▀▀    
    --    ▀▄█ ▀█▄ █ █ ▀█▄ █   ▀▄█  ▀▄ ▀█▄     █  ▀█▄ █    ▀▄ █ ▀▄▄ ▀█▄ ▄█▀    
    --    ▄▄▀                                                                 
    local generateVertices = function(watertight)
      local cornerPosAFromEdge = marching.cornerPosAFromEdge
      local cornerPosBFromEdge = marching.cornerPosBFromEdge
      local noiseFunction = noise

      local b = 0
      if watertight then 
        b = 1 
        noiseFunction = collisionNoise
      end

      -- 4 frames on macOS
      for z = chunkz - b, chunkz + size+b do
        for y = chunky - b, chunky + size+b do
          for x = chunkx - b, chunkx + size+b do

            -- index for 256-big marching cubes table
            local cubeIndex =
              1 * round(noiseFunction(x,   y,   z  , chunkx,chunky,chunkz)) +   -- vertex 0
              2 * round(noiseFunction(x+1, y,   z  , chunkx,chunky,chunkz)) +   -- vertex 1
              4 * round(noiseFunction(x+1, y,   z+1, chunkx,chunky,chunkz)) +   -- vertex 2
              8 * round(noiseFunction(x,   y,   z+1, chunkx,chunky,chunkz)) +   -- vertex 3
             16 * round(noiseFunction(x,   y+1, z  , chunkx,chunky,chunkz)) +   -- vertex 4
             32 * round(noiseFunction(x+1, y+1, z  , chunkx,chunky,chunkz)) +   -- vertex 5
             64 * round(noiseFunction(x+1, y+1, z+1, chunkx,chunky,chunkz)) +   -- vertex 6
            128 * round(noiseFunction(x,   y+1, z+1, chunkx,chunky,chunkz)) + 1 -- vertex 7

            -- create all the triangles for this cube
            local i = 1
            local edges = marching.cubes[cubeIndex] -- look up 
            while (edges[i] ~= -1) do

              local cornerA = cornerPosAFromEdge[edges[i]+1]
              local cornerAX, cornerAY, cornerAZ = (vec3(x,y,z)+cornerA):unpack()
              local valueAtCornerA = noiseFunction(cornerAX,cornerAY,cornerAZ, chunkx,chunky,chunkz)

              local cornerB = cornerPosBFromEdge[edges[i]+1]
              local cornerBX, cornerBY, cornerBZ = (vec3(x,y,z)+cornerB):unpack()
              local valueAtCornerB = noiseFunction(cornerBX,cornerBY,cornerBZ, chunkx,chunky,chunkz)

              local total = (valueAtCornerA + valueAtCornerB)
              local interpolatedPosition   = vec3(cornerA):lerp(cornerB, valueAtCornerB/total)
              local unInterpolatedPosition = vec3(cornerA):lerp(cornerB, .5)
              addVertex(vec3(x,y,z) + interpolatedPosition, 
                        vec3(x,y,z) + unInterpolatedPosition, 
                        vec3(x,y,z) + cornerA,
                        vec3(x,y,z) + cornerB)

              i = i + 1
            end

            -- lovr.math.drain()

          end
        end
      end
    end
    generateVertices(true)

    -- print('#vertices', #vertices)
    cubes.totalVertices = cubes.totalVertices + #vertices
    -- print('totalVertices', cubes.totalVertices)
    -- print('#indices', #indices)



    --                  █              █           █ ▀            
    --    █▀▄▀▄ ▄▀▄ ▄▀▀ █▀▄    █ █ █▀▄ █ ▄▀▄ ▄▀█ ▄▀█ █ █▀▄ ▄▀█    
    --    █ █ █ ▀█▄ ▄█▀ █ █    ▀▄█ █▄▀ █ ▀▄▀ ▀▄█ ▀▄█ █ █ █ ▀▄█    
    --                             █                       ▄▄▀    



    -- 5% of a frame on macOS
    chunk.vertexBuffer = lovr.graphics.newBuffer(vertexFormat, vertices)
    chunk.indexBuffer = lovr.graphics.newBuffer(indexFormat, indices)

    -- 1 frame on macOS
    if #vertices > 0 then -- is this a given?
      chunk.collider = world:newMeshCollider(vertices, indices)
      if terrainColliderList then
        table.insert(terrainColliderList, chunk.collider)
      end
      chunk.collider:setPosition(chunkx,chunky,chunkz)
      chunk.collider:setPosition(0,0,0)
      print('🧊 chunk at ' .. tostring(vec3(chunkx,chunky,chunkz)), ('took %.3fs'):format(lovr.timer.getTime() - time), '(' .. #vertices .. ' vertices)')
      chunk.collider:setKinematic(true)
      chunk.hasMesh = true
    else
      chunk.hasMesh = false
      time = lovr.timer.getTime() - time
      if time < .0005 then
        -- print('   air at ' .. tostring(vec3(chunkx,chunky,chunkz)), ('took %.4fs'):format(time))
      else
        -- print('🚨 air at ' .. tostring(vec3(chunkx,chunky,chunkz)), ('took %.4fs'):format(time))
      end
    end

    local count = 0
    for _,_ in pairs(noiseCache) do
      count = count + 1
    end
    -- print('noiseCache', count)

    chunkCache[key] = chunk
    if chunkDrawArray then
      table.insert(chunkDrawArray, chunk)
    end

    prof.pop 'new chunk'
    return chunk
  end



end



























--                            █     ▀               
--     ▄▀▀█  █▄▀▀  ▀▀▄  █▀▀▄  █▀▀▄ ▀█  ▄▀▀▄ ▄▀▀▄    
--     █  █  █    ▄▀▀█  █  █  █  █  █  █     ▀▀▄    
--     ▀▄▄█  █    ▀▄▄█  █▄▄▀  █  █  █  ▀▄▄▀ ▀▄▄▀    
--      ▄▄▀             █                           



--        █         █                
--    ▄▀▀ █▀▄ ▄▀█ ▄▀█ ▄▀▄ █▄▀ ▄▀▀    
--    ▄█▀ █ █ ▀▄█ ▀▄█ ▀█▄ █   ▄█▀    



local depthShader = lovr.graphics.newShader('unlit', [[
  vec4 lovrmain() {
    float d = clamp(1-distance(CameraPositionWorld, PositionWorld)/20, .1, 1);
    return Color * vec4(d,d,d,1);
  }
]])

cubes.triplanarShader = lovr.graphics.newShader([[//glsl
  layout(location = 0) in  vec4 VertexAmbient;
  layout(location = 0) out vec4 Ambient;

  layout(location = 1) in  vec4 VertexShadowMask;
  layout(location = 1) out vec4 ShadowMask;

  layout(location = 2) out vec4 VertexGouraudDiffuse;

  vec4 lovrmain() {
    Ambient = VertexAmbient;
    ShadowMask = VertexShadowMask;
    float d = (dot(VertexNormal, vec3(0, 1, 0)));
    VertexGouraudDiffuse = clamp(vec4(d,d,d,1), 0, 1);
    return DefaultPosition;
  }
  ]], [[//glsl
  layout(location = 0) in vec4 Ambient;
  layout(location = 1) in vec4 ShadowMask;
  layout(location = 2) in vec4 GouraudDiffuse;
  vec4 lovrmain() {
    // the closer the lighter
    float d = clamp(1-distance(CameraPositionWorld, PositionWorld)/20, .1, 1);
    vec4 depthBrightness = vec4(d,d,d,1);

    // triplanar blend of 3 textures
    // doesn't require vertex normals
    vec3 computedNormal = normalize(cross(dFdy(PositionWorld), dFdx(PositionWorld)));
    vec3 blend = abs(computedNormal);
    blend = blend / (blend.x + blend.y + blend.z); // so that b.x + b.y + b.z = 1

    // nice normal colors, from my friend
    vec4 normalColor = vec4(normalize(Normal), 1);
    vec4 baseColor = vec4(0.5, 0.5, 0.5, .25); // originally alpha .25
    vec3 xColor = vec3(1, 0, 0);
    vec3 yColor = vec3(0, 1, 0);
    vec3 zColor = vec3(0, 0, 1);
    vec3 combinedColor = (xColor * (normalColor.x + 1) / 2) + (yColor * (normalColor.y + 1) / 2) + (zColor * (normalColor.z + 1) / 2) ;
    vec3 finalColor = (combinedColor * (1 - baseColor.w)) + (vec3(baseColor) * baseColor.w);
    vec4 angleColor = vec4(finalColor, 1);

    // cheap diffuse
    d = (dot(Normal, vec3(0, 1, 0)));
    vec4 diffuse = clamp(vec4(d,d,d,1), 0, 1);

    // sharp diffuse
    d = dot(computedNormal, vec3(0, 1, 0));
    vec4 sharpDiffuse = clamp(vec4(d,d,d,1), 0, 1);

    vec4 skyBlue = vec4(.75, .75, 1, 1);

    vec4 normals = vec4(Normal/2 + .5, 1);
    vec4 sharpNormals = vec4(computedNormal/2 + .5, 1);

    return 
      (
        // direct
        vec4(.5,.5,.5,1) * (ShadowMask * diffuse)
        +
        // ambient
        vec4(.5,.5,.5,1) * (skyBlue * clamp(sqrt(Ambient),0,1))
      ) *
      // (sharpNormals*.5 + vec4(1)*.5) *
      Color * 
      (
        blend.x * getPixel(ColorTexture, PositionWorld.yz) +
        blend.y * getPixel(ColorTexture, PositionWorld.xz) +
        blend.z * getPixel(ColorTexture, PositionWorld.xy)
      );
  }
]])



local triplanarShaderBackup = lovr.graphics.newShader('unlit', [[

  vec4 lovrmain() {

    // the closer the lighter
    float d = clamp(1-distance(CameraPositionWorld, PositionWorld)/20, .1, 1);
    vec4 depthBrightness = vec4(d,d,d,1);

    // triplanar blend of 3 textures
    // doesn't require vertex normals
    vec3 computedNormal = cross(dFdx(PositionWorld), dFdy(PositionWorld));
    vec3 blend = abs(computedNormal);

    // nice color
    vec4 normalColor = vec4(normalize(computedNormal), 1);
    vec4 friendsCoolColor = (normalColor + vec4(1,1,1,1)) / 2;

    // requires vertex normals
    // vec3 blend = abs(Normal);
    blend = blend / (blend.x + blend.y + blend.z);

    return Color * depthBrightness * friendsCoolColor * (
      blend.x * getPixel(ColorTexture, PositionWorld.yz) +
      blend.y * getPixel(ColorTexture, PositionWorld.xz) +
      blend.z * getPixel(ColorTexture, PositionWorld.xy)
    );
  }
]])







--                            ▄           ▄                 
--    ▄▀█ █▄▀ ▄▀█ ▄▀▀ ▄▀▀    ▀█▀ ▄▀▄ ▀▄▀ ▀█▀ █ █ █▄▀ ▄▀▄    
--    ▀▄█ █   ▀▄█ ▄█▀ ▄█▀     ▀▄ ▀█▄ ▄▀▄  ▀▄ ▀▄█ █   ▀█▄    
--    ▄▄▀                                                   


local function randomColor(r1,r2,g1,g2,b1,b2)
  return {
    r1 + (r2-r1) * lovr.math.random(),
    g1 + (g2-g1) * lovr.math.random(),
    b1 + (b2-b1) * lovr.math.random()
  }
end

-- floor
local grassColor = randomColor(
  0.5,  1,
  0.5,  1,
  0,    0.5
)

-- grass texture
local grassTextureWidth = 16
local grassImage = lovr.data.newImage(grassTextureWidth, grassTextureWidth)
for x = 0, grassTextureWidth - 1 do
  for y = 0, grassTextureWidth - 1 do
    grassImage:setPixel(x, y,
      lovr.math.noise(x + .5, y + .5 +  0) * .25 + .75,
      lovr.math.noise(x + .5, y + .5 + 16) * .25 + .75,
      lovr.math.noise(x + .5, y + .5 + 32) * .25 + .75
    )
  end
end
cubes.grassTexture = lovr.graphics.newTexture(grassImage)







--      █     █                  ▀         
--    ▄▀█ ▄▀▄ █▀▄ █ █ ▄▀█    █ █ █ ▀▀█▀    
--    ▀▄█ ▀█▄ █▄▀ ▀▄█ ▀▄█     █  █ ▄█▄▄    
--                    ▄▄▀                  


function cubes:viz(pass, cx,cy,cz)
  for x=self.x,self.x+size+1 do
    for y=self.y,self.y+size+1 do
      for z=self.z,self.z+size+1 do
        local sample = noise(x,y,z)
        local light = 1-v(lovr.headset.getPosition()):distance(v(x,y,z))/100      
        pass:setColor(light, light, light)
        pass:sphere(x,y,z,sample/16)
        if sample > .5 then
          pass:setColor(light, light/8, light/8, 1)
          pass:sphere(x,y,z,sample/16)
          pass:setColor(light, light/2, light/2, .5)
          -- pass:cube(x,y,z)
        end
      end
      -- lovr.math.drain()
    end
  end
  -- for i = 1, #self.vertices do
  --   local v = self.vertices[i]
  --   pass:setColor(
  --     v[4]/2+.5,
  --     v[5]/2+.5,
  --     v[6]/2+.5,
  --     1
  --   )
  --   pass:setColor(1,1,1,1)
  --   pass:line(
  --     v[1],         v[2],         v[3],
  --     v[1]+v[4]*1., v[2]+v[5]*1., v[3]+v[6]*1.
  --   )
  -- end
end







--      █                  
--    ▄▀█ █▄▀ ▄▀█ █ █ █    
--    ▀▄█ █   ▀▄█  █ █     


function cubes:draw(pass)
  -- pass:setBlendMode()
  pass:setShader(cubes.triplanarShader)
  pass:setMaterial(cubes.grassTexture)
  -- pass:setMaterial()
  pass:setColor(grassColor)
  -- pass:setColor(1,1,1)
  pass:setSampler('nearest')
  -- pass:setCullMode('back')
  pass:setColor(.65,1,.25)
  if self.hasMesh then
    local location = vec3(self.collider:getPosition())
    pass:mesh(self.vertexBuffer, self.indexBuffer, location)
  end
  pass:setShader()
  pass:setMaterial()
  -- if lovr.system.isKeyDown('space') or lovr.headset.isDown('right', 'grip') then
  --   self:viz(pass)
  -- end
  pass:text('---->', 0, 1.7, -3, 1, -math.pi/4, 0, 1, 0)
end




--anyway,
return cubes