-- HD2-Addon: mods/codex/third_person_aim_circle
-- Third-Person Aim Circle: the game's small aim circle for the rifles it gives none in third person (APW-1 Anti-Materiel
-- Rifle, AMW-20 Apex, R-40 Sightliner), where the round is going. Cut from Universal Trajectory Indicator 1.2.0's aim
-- circle (CROSSHAIR_AIM_FINDINGS.md there); uses the same numbers. It reads the game and draws one ring on the screen:
-- no game files, no textures, no shared line object, so nothing another mod could collide with.
-- Made to outlast small game updates: no check of the game's version, every engine call guarded, a network field read
-- only when the game declares it for that type now, and each step falls back to the next: my helldiver's aim field, the
-- animation's aim target, the middle of the view. Weapons renamed by an update just get no circle.
-- Network names are stand-ins with the same 32-bit hash as the real ones; reading the avatar this way is NarrowHUD's
-- (luka189, Nexus 17882).
local chef = ...
local M = {}
local VERSION = '1.0.0'

if chef.has and chef.has('own_log') then chef.own_log('third_person_aim_circle') end
local function log(fmt, ...) chef.log(fmt, ...) end
local function now() return chef.time() end

local PLAYER_KIND = '4d1c334d294dfa97'
-- The rifles' units. The APW-1's is sure (HD2Runtime), the R-40's seen in play, the Apex's taken from filediver's
-- sniper_rifle_duo (a backpack weapon, as the Apex): not seen yet.
local RIFLES = { ['89c5493e08ca4207'] = 'APW-1', b814eece17533bc4 = 'AMW-20', ['41f2def484634b59'] = 'R-40' }
local VEHICLES = { cc21c7ffd3ebefb9 = true, ['2d85bfe3d8717fe5'] = true, ['9b2140378640432e'] = true,
                   ['16474112801385b6'] = true, b0c9faf4af8903f9 = true, ['79e4b3d2da5e45e3'] = true }
local FRVS = { cc21c7ffd3ebefb9 = true, ['2d85bfe3d8717fe5'] = true, ['9b2140378640432e'] = true }
local THROWABLE_POSE = { [40] = true, [41] = true, [42] = true }
local HAND_NEAR, HELD_ALONG, HELD_NEAR, HELD_HAND = 0.35, 0.95, 2.5, 1   -- m, dot with the camera, m, m
local VEHICLE_NEAR, VEHICLE_SEAT, VEHICLE_UP, FRV_RAISED = 1.2, 4.5, 0.35, 0.7
local FIRST_PERSON, SIGHT_NEAR = 0.9, 0.35
local FAR_CAMERA = 12            -- m from the muzzle: the hellpod's view (28-37 m; on foot at most 6, seated about 7)
local MUZZLE_AHEAD, FAR_POINT = 0.45, 100
local LOOK, RETRY = 0.2, 5       -- s: for the rifle in hand, not aiming; before asking again for what wasn't there

local on = true
if chef.has and chef.has('menu') then
  chef.title('Third-Person Aim Circle')
  on = chef.option('on', { type = 'toggle', label = 'Aim circle', default = true }) ~= false
  chef.on_change('on', function(v) on = v ~= false end)
end

local players = chef.watch and chef.watch({ [PLAYER_KIND] = true }, 2)
local rifles = chef.watch and chef.watch(RIFLES, 0.5)
local vehicles = chef.watch and chef.watch(VEHICLES, 0.5)

-- ------------------------------------------------------------------ my helldiver
local mine, me = nil, nil        -- its unit; { x, y, z } of its feet

local function update_me(c)
  me = nil
  if mine and chef.unit_alive(mine) then
    local x, y, z = chef.unit_position(mine)
    if x and (x - c.x) ^ 2 + (y - c.y) ^ 2 < 225 then me = { x, y, z } return end
  end
  mine = nil
  if not players then return end
  local best
  for _, it in ipairs(players.items) do
    if chef.unit_alive(it.unit) then
      local x, y, z = chef.unit_position(it.unit)
      if x then
        local d = (x - c.x) ^ 2 + (y - c.y) ^ 2
        if d < 36 and (not best or d < best) then best, mine, me = d, it.unit, { x, y, z } end
      end
    end
  end
end

local pose_of = (function()
  local unit, index, retry
  return function()
    if not (mine and chef.unit_alive(mine)) then return nil end
    if unit ~= mine then unit, index, retry = mine, nil, 0 end
    if not index then
      if now() < retry then return nil end
      retry = now() + RETRY
      if chef.call_kind('Unit.has_animation_state_machine', PLAYER_KIND, mine) ~= true
         or chef.call_kind('Unit.animation_has_variable', PLAYER_KIND, mine, 'weapon_selected') ~= true then return nil end
      local i = chef.call_kind('Unit.animation_find_variable', PLAYER_KIND, mine, 'weapon_selected')
      if type(i) ~= 'number' then return nil end
      index = i
    end
    local v = chef.call_kind('Unit.animation_get_variable', PLAYER_KIND, mine, index)
    return type(v) == 'number' and math.floor(v + 0.5) or nil
  end
end)()

local hand_of = (function()
  local unit, node, retry
  return function()
    if not (mine and chef.unit_node) then return nil end
    if unit ~= mine then unit, node, retry = mine, nil, 0 end
    if not node and now() >= retry then node, retry = chef.unit_node(mine, 'attach_hand_r'), now() + RETRY end
    if not node then return nil end
    local x, y, z = chef.unit_position(mine, node)
    return x and { x, y, z } or nil
  end
end)()

-- ------------------------------------------------------------------ the aim button: right mouse, a controller's left trigger
local pad = { button = nil, aim = nil, n = nil, next = 0 }
local function find_pad()
  if pad.n then
    local p = 'Pad' .. pad.n
    if chef.call(p .. '.active') == true or chef.call(p .. '.connected') == true then return end
    pad.n, pad.button, pad.aim = nil, nil, nil
  end
  for n = 1, 8 do
    local p = 'Pad' .. n
    if chef.call(p .. '.active') == true or chef.call(p .. '.connected') == true then
      local count = chef.call(p .. '.num_buttons')
      pad.n, pad.button = n, p .. '.button'
      if type(count) == 'number' and count > 0 and count <= 64 then
        for i = 0, count - 1 do
          local name = chef.call(p .. '.button_name', i)
          if type(name) == 'string' and (name:lower() == 'left_trigger' or name:lower() == 'l2') then pad.aim = i end
        end
      end
      return
    end
  end
end

local function aiming()
  if chef.mouse_down('right') == true then return true end
  if now() >= pad.next then
    pad.next = now() + 1
    find_pad()
  end
  if not (pad.button and pad.aim) then return false end
  local v = chef.call(pad.button, pad.aim)
  return type(v) == 'number' and v > 0.5
end

-- ------------------------------------------------------------------ the rifle in my hand
-- whether I sit in a vehicle: seated, its kind, how far above its root I am
local function seated()
  if not (vehicles and me) then return false end
  local best, up, kind
  for _, it in ipairs(vehicles.items) do
    if chef.unit_alive(it.unit) then
      local x, y, z = chef.unit_position(it.unit)
      if x then
        local across = math.sqrt((x - me[1]) ^ 2 + (y - me[2]) ^ 2)
        if not best or across < best then best, up, kind = across, me[3] - z, it.kind end
      end
    end
  end
  return best ~= nil and (best < VEHICLE_NEAR or (best < VEHICLE_SEAT and up >= VEHICLE_UP)), kind, up
end

-- A rifle's root is at its grip: the one at my hand. While aiming, also one pointing the way I look: a prone or lagging
-- one (a slung one points elsewhere).
local function rifle_in_hand(c, aimed)
  if not (rifles and me) or THROWABLE_POSE[pose_of()] then return nil end
  local hand = hand_of()
  local best, best_d, along, along_a
  for _, it in ipairs(rifles.items) do
    if chef.unit_alive(it.unit) then
      local x, y, z = chef.unit_position(it.unit)
      if x and (x - me[1]) ^ 2 + (y - me[2]) ^ 2 < HELD_NEAR * HELD_NEAR then
        local d = hand and (x - hand[1]) ^ 2 + (y - hand[2]) ^ 2 + (z - hand[3]) ^ 2
        if d and d <= HAND_NEAR * HAND_NEAR and (not best or d < best_d) then best, best_d = it, d end
        if aimed and (not d or d <= HELD_HAND * HELD_HAND) then
          local fx, fy, fz = chef.unit_rotation(it.unit)
          local a = type(fx) == 'number' and fx * c.fx + fy * c.fy + fz * c.fz
          if a and a >= HELD_ALONG and (not along or a > along_a) then along, along_a = it, a end
        end
      end
    end
  end
  return best or along
end

-- ------------------------------------------------------------------ where the round is going
local function finite(x, y, z)
  return type(x) == 'number' and type(y) == 'number' and type(z) == 'number' and x == x and y == y and z == z
end

-- Only a value that says it is one is handed back to the engine: some avatar fields are Lua tables, and passing one to a
-- Vector3 call has ended the game.
local function vector_elements(v, tag)
  if type(v) ~= 'userdata' or chef.call_kind('Script.type_name', tag, v) ~= 'Vector3' then return nil end
  local x, y, z = chef.call_kind('Vector3.to_elements', tag, v)
  if finite(x, y, z) then return x, y, z end
  return nil
end

local declared = {}              -- network type -> { [field id, lower-case hex, no leading zeros] = true } or false
local function read_field(gs, goid, type_name, field, id)
  local set = declared[type_name]
  if set == nil then
    local info = chef.call_kind('Network.object_info', 'info ' .. type_name, type_name)
    set = false
    if type(info) == 'table' and type(info.fields) == 'table' then
      set = {}
      for _, f in ipairs(info.fields) do
        local i = type(f) == 'table' and f.id
        if type(i) == 'number' then i = string.format('%x', i) end
        if type(i) == 'string' then set[(string.gsub(string.lower(i), '^0+', ''))] = true end
      end
    end
    declared[type_name] = set
    if not set then log('no field info for type %s: its fields are not read', type_name) end
  end
  if not (set and set[id]) then return nil end
  return chef.call_kind('GameSession.game_object_field', 'field ' .. field, gs, goid, field)
end

-- my helldiver's network object: my player object's avatar field, 200 objects a frame (as host I own thousands)
local avatar_of = (function()
  local PLAYER, AVATAR, AVATAR_OF, AVATAR_ID, BATCH, AGAIN = 'un6y1d', 'vvhx8ga', 'u4d1h9a', 'f27c68e', 200, 2
  local unit, world, avatar, scan, next_look
  local function is_a(gs, g, type_name)
    return chef.call_kind('GameSession.game_object_exists', 'exists', gs, g) == true
       and chef.call_kind('GameSession.game_object_is_type', 'type', gs, g, type_name) == true
  end
  return function(gs)
    local w = chef.world_id()
    if unit ~= mine or world ~= w then unit, world, avatar, scan, next_look = mine, w, nil, nil, 0 end
    if avatar then
      if is_a(gs, avatar, AVATAR) then return avatar end
      avatar = nil
    end
    local peer = chef.call_kind('Network.peer_id', 'peer')
    if not peer then return nil end
    if not scan then
      if now() < next_look then return nil end
      next_look = now() + AGAIN
      local list = chef.call_kind('GameSession.objects_owned_by', 'owned', gs, peer)
      if type(list) ~= 'table' then return nil end
      scan = { at = 1 }
      for _, g in pairs(list) do scan[#scan + 1] = g end
    end
    for i = scan.at, math.min(scan.at + BATCH - 1, #scan) do
      local g = scan[i]
      if is_a(gs, g, PLAYER) and chef.call_kind('GameSession.game_object_owner', 'owner', gs, g) == peer then
        local a = read_field(gs, g, PLAYER, AVATAR_OF, AVATAR_ID)
        if type(a) == 'number' and is_a(gs, a, AVATAR) then
          avatar, scan = a, nil
          return a
        end
      end
    end
    scan.at = scan.at + BATCH
    if scan.at > #scan then scan = nil end
    return nil
  end
end)()

local function field_point(field, id)
  local gs = chef.call_kind('Network.game_session', 'session')
  local avatar = gs and avatar_of(gs)
  if not avatar then return nil end
  return vector_elements(read_field(gs, avatar, 'vvhx8ga', field, id), 'field vector')
end

-- the animation's aim target, about 100 m out, carrying the same lag
local target_point = (function()
  local NAME = 'aim_constraint_target'
  local unit, world, index, retry
  return function()
    if not (mine and chef.unit_alive(mine)) then return nil end
    local w = chef.world_id()
    if unit ~= mine or world ~= w then unit, world, index, retry = mine, w, nil, 0 end
    if not index then
      if now() < retry then return nil end
      retry = now() + RETRY
      if chef.call_kind('Unit.animation_has_constraint_target', 'target', mine, NAME) ~= true then return nil end
      index = chef.call_kind('Unit.animation_find_constraint_target', 'target', mine, NAME)
      if type(index) ~= 'number' then index = nil return nil end
    end
    local m = chef.call_kind('Unit.animation_get_constraint_target', 'target', mine, index)
    if type(m) ~= 'userdata' or chef.call_kind('Script.type_name', 'target', m) ~= 'Matrix4x4' then return nil end
    return vector_elements(chef.call_kind('Matrix4x4.translation', 'target', m), 'target vector')
  end
end)()

-- a point the round could be going for: far enough to give a direction, not behind the view (a fast turn can leave it far off)
local function usable(c, muzzle, nearest, farthest, x, y, z)
  if not x then return false end
  local dx, dy, dz = x - muzzle[1], y - muzzle[2], z - muzzle[3]
  local d = math.sqrt(dx * dx + dy * dy + dz * dz)
  return d >= nearest and d <= farthest and (dx * c.fx + dy * c.fy + dz * c.fz) / d > 0.3
end

local said_source = nil
local function aim_point(c, muzzle)
  local x, y, z = field_point('rm_qp0d', 'bdc1cb8a')
  local source = 'the aim field'
  if not usable(c, muzzle, 1.5, 2000, x, y, z) then
    x, y, z = target_point()
    source = 'the aim target'
    if not usable(c, muzzle, 20, 200, x, y, z) then
      x, y, z = c.x + c.fx * FAR_POINT, c.y + c.fy * FAR_POINT, c.z + c.fz * FAR_POINT
      source = 'the middle of the view'
    end
  end
  if source ~= said_source then
    said_source = source
    log('aim circle from %s', source)
  end
  return x, y, z
end

local nodes_of = (function()
  local cache, world = setmetatable({}, { __mode = 'k' }), nil
  return function(u)
    if world ~= chef.world_id() then cache, world = setmetatable({}, { __mode = 'k' }), chef.world_id() end
    local row = cache[u]
    if not row then
      row = { next = 0 }
      cache[u] = row
    end
    if chef.unit_node and now() >= row.next and not (row.muzzle and row.sight) then
      row.next = now() + RETRY
      row.muzzle = row.muzzle or chef.unit_node(u, 'attach_muzzle')
      row.sight = row.sight or chef.unit_node(u, 'sight')
    end
    return row
  end
end)()

local function muzzle_of(u)
  local x, y, z = chef.unit_position(u)
  if not x then return nil end
  local node = nodes_of(u).muzzle
  if node then
    local mx, my, mz = chef.unit_position(u, node)
    if finite(mx, my, mz) and (mx - x) ^ 2 + (my - y) ^ 2 + (mz - z) ^ 2 <= 9 then return { mx, my, mz } end
  end
  local fx, fy, fz = chef.unit_rotation(u)
  if type(fx) ~= 'number' then return { x, y, z } end
  return { x + fx * MUZZLE_AHEAD, y + fy * MUZZLE_AHEAD, z + fz * MUZZLE_AHEAD }
end

local function first_person(c, u)
  local x, y, z = chef.unit_position(u)
  if not x or (x - c.x) ^ 2 + (y - c.y) ^ 2 + (z - c.z) ^ 2 >= FIRST_PERSON * FIRST_PERSON then return false end
  local node = nodes_of(u).sight
  if node then
    local sx, sy, sz = chef.unit_position(u, node)
    if sx and (sx - x) ^ 2 + (sy - y) ^ 2 + (sz - z) ^ 2 <= 9 then
      return (sx - c.x) ^ 2 + (sy - c.y) ^ 2 + (sz - c.z) ^ 2 < SIGHT_NEAR * SIGHT_NEAR
    end
  end
  return true
end

-- Another mod's first-person camera: the game goes on aiming from its own, so the field on the real camera's line lies off
-- this one. Real cameras, held still, under 100 m: within 0.21 m. Off by 0.35 m for 30 still frames: it has been moved.
local camera_moved = (function()
  local OFF, LONG = 0.35, 30
  local moved, count, fx, fy, fz, world = false, 0, nil, nil, nil, nil
  return function(c)
    if world ~= chef.world_id() then world, moved, count, fx = chef.world_id(), false, 0, nil end
    local still = fx and fx * c.fx + fy * c.fy + fz * c.fz > 0.99999
    fx, fy, fz = c.fx, c.fy, c.fz
    if not still then return moved end
    local hx, hy, hz = field_point('x4joxek', 'af97ede7')
    if not hx then return moved end
    local dx, dy, dz = hx - c.x, hy - c.y, hz - c.z
    local along = dx * c.fx + dy * c.fy + dz * c.fz
    if along < 2 or along > 100 then return moved end
    local off = dx * dx + dy * dy + dz * dz - along * along > OFF * OFF
    count = math.max(0, math.min(LONG, count + (off and 1 or -1)))
    if count >= LONG then moved = true elseif count == 0 then moved = false end
    return moved
  end
end)()

-- ------------------------------------------------------------------ the frame
local rifle, next_look, world_said = nil, 0, nil

local function pick(c, aimed)
  if aimed or now() >= next_look then
    next_look = now() + LOOK
    rifle = rifle_in_hand(c, aimed)
    if rifle and not aimed and seated() then rifle = nil end        -- the game's crosshairs show seated only when aiming
    if rifle and aimed then
      local sit, kind, up = seated()
      if sit and FRVS[kind] and up and up >= VEHICLE_UP then        -- an FRV's driver doesn't raise it
        local _, _, z = chef.unit_position(rifle.unit)
        if z and z - me[3] < FRV_RAISED then rifle = nil end
      end
    end
  end
  return rifle
end

function M.update()
  if world_said == nil then
    world_said = false
    log('Third-Person Aim Circle %s, loader %s', VERSION, tostring(chef.loader_version))
  end
  if not (on and chef.ring and chef.world_to_screen) then return end
  if chef.in_mission and chef.in_mission() == false then return end        -- none on the ship
  local c = chef.camera()
  if not (chef.world() and c) then return end
  if world_said ~= chef.world_id() then
    world_said = chef.world_id()
    mine, me, rifle, next_look = nil, nil, nil, 0
  end
  update_me(c)
  if not me then return end
  local it = pick(c, aiming())
  if not (it and chef.unit_alive(it.unit)) then return end
  if first_person(c, it.unit) and not camera_moved(c) then return end
  local muzzle = muzzle_of(it.unit)
  if not muzzle or (muzzle[1] - c.x) ^ 2 + (muzzle[2] - c.y) ^ 2 + (muzzle[3] - c.z) ^ 2 >= FAR_CAMERA * FAR_CAMERA then return end
  local sx, sy = chef.world_to_screen(aim_point(c, muzzle))
  if not sx then return end
  -- as the game draws it for other weapons (screenshots at 1200 lines): a white ring 6.3 to 8.5 px, half see-through
  local _, h = chef.screen()
  chef.ring(sx, sy, h * 6.3 / 1200, h * 8.5 / 1200, chef.color(255, 255, 255, 128), (chef.TOP or 0) + 1100)
end

function M.shutdown()
  if players then players.stop() end
  if rifles then rifles.stop() end
  if vehicles then vehicles.stop() end
end

return M
