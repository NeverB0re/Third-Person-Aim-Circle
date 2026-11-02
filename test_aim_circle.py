"""Third-Person Aim Circle on PUC Lua 5.1 (lupa) against a fake Chef Shared Loader:  python test_aim_circle.py"""
import os
import unittest

import lupa.lua51 as lua51

HERE = os.path.dirname(os.path.abspath(__file__))
APW = "89c5493e08ca4207"

FAKE = r"""
local fake = { t = 0, logs = {}, mouse = {}, rings = {}, shots = {}, crashes = {}, pose = 1, mission = true,
               field = {}, reads = {}, cam = { x = 0, y = -2, z = 1.8, fx = 0, fy = 1, fz = 0, fov = 0.96 } }
local function ud(t, fields)
  fields = fields or {}; fields.__t = t
  local p = newproxy(true)
  getmetatable(p).__index = fields
  return p
end
fake.Vector3 = function(x, y, z) return ud('Vector3', { x = x, y = y, z = z }) end
local PLAYER = '4d1c334d294dfa97'
fake.me = { kind = PLAYER, x = 0, y = 0, z = 0 }
fake.rifle = { kind = '89c5493e08ca4207', x = 0.3, y = 0.3, z = 1.3, f = { 0, 1, 0 } }
fake.units = { fake.me, fake.rifle }
fake.info = {
  un6y1d = { fields = { { id = '0f27c68e' } } },
  vvhx8ga = { fields = { { id = 'bdc1cb8a' }, { id = 'af97ede7' }, { id = '98b4aaf0' } } },
}
local function crash(why) fake.crashes[#fake.crashes + 1] = why; error('NATIVE CRASH: ' .. why) end
local E = {
  ['Script.type_name'] = function(v) return v.__t end,
  ['Vector3.to_elements'] = function(v)
    if type(v) ~= 'userdata' or v.__t ~= 'Vector3' then crash('Vector3 asked of something else') end
    return v.x, v.y, v.z
  end,
  ['Matrix4x4.translation'] = function(m) return fake.Vector3(m.x, m.y, m.z) end,
  ['Network.game_session'] = function() return 'gs' end,
  ['Network.peer_id'] = function() return 'me' end,
  ['Network.object_info'] = function(t) return fake.info[t] end,
  ['GameSession.objects_owned_by'] = function() return { 11, 7 } end,
  ['GameSession.game_object_exists'] = function(gs, g) return g == 11 or g == 7 end,
  ['GameSession.game_object_is_type'] = function(gs, g, t) return (g == 11 and t == 'un6y1d') or (g == 7 and t == 'vvhx8ga') end,
  ['GameSession.game_object_owner'] = function() return 'me' end,
  ['GameSession.game_object_field'] = function(gs, g, name)
    fake.reads[#fake.reads + 1] = name
    if g == 11 and name == 'u4d1h9a' then return 7 end
    if g == 7 and fake.field[name] ~= nil then return fake.field[name] end
    if g == 7 and (name == 'rm_qp0d' or name == 'x4joxek') then return nil end
    crash('an undeclared field: ' .. tostring(name))
  end,
  ['Unit.has_animation_state_machine'] = function(u) return u == fake.me end,
  ['Unit.animation_has_variable'] = function() return true end,
  ['Unit.animation_find_variable'] = function() return 3 end,
  ['Unit.animation_get_variable'] = function() return fake.pose end,
  ['Unit.animation_has_constraint_target'] = function() return fake.target ~= nil end,
  ['Unit.animation_find_constraint_target'] = function() return 2 end,
  ['Unit.animation_get_constraint_target'] = function() return fake.target end,
}
local function call(name, ...)
  local f = E[name]
  if not f then return nil, 'missing' end
  local r = { pcall(f, ...) }
  if not r[1] then return nil, 'error: ' .. tostring(r[2]) end
  return r[2], r[3], r[4], r[5]
end
fake.watches = {}
chef = {
  api = 3, loader_version = '1.4.1', TOP = 100000,
  has = function() return true end, own_log = function() return true end,
  log = function(fmt, ...) fake.logs[#fake.logs + 1] = string.format(fmt, ...) end,
  time = function() return fake.t end,
  call = call, call_kind = function(name, kind, ...) return call(name, ...) end,
  world = function() return {} end, world_id = function() return 4 end,
  in_mission = function() return fake.mission end,
  camera = function() return fake.cam end,
  watch = function(kinds)
    local w = { items = {}, kinds = kinds }
    function w.stop() end
    fake.watches[#fake.watches + 1] = w
    return w
  end,
  unit_alive = function(u) return true end,
  unit_position = function(u, node)
    if node == 'hand' then return 0.3, 0.3, 1.3 end
    if node == 'muzzle' then return u.x, u.y + 1, u.z end
    if node == 'sight' then return fake.sight_x or u.x, u.y, u.z + 0.1 end
    return u.x, u.y, u.z
  end,
  unit_rotation = function(u) local f = u.f or { 1, 0, 0 }; return f[1], f[2], f[3], 0 end,
  unit_node = function(u, name)
    if name == 'attach_hand_r' then return 'hand' end
    if name == 'attach_muzzle' then return 'muzzle' end
    if name == 'sight' then return 'sight' end
  end,
  mouse_down = function(b) return fake.mouse[b] == true end,
  world_to_screen = function(x, y, z) return x, y end,
  screen = function() return 1920, 1200 end,
  color = function(r, g, b, a) return { r, g, b, a } end,
  ring = function(x, y, r0, r1, c, layer)
    fake.rings[#fake.rings + 1] = { x = x, y = y, r0 = r0, r1 = r1, alpha = c[4], layer = layer }
  end,
  title = function() end,
  option = function(id, spec) return spec.default end,
  on_change = function(id, fn) fake.changed = fn end,
}
function fake.frame(M, dt)
  fake.t = fake.t + dt
  for _, w in ipairs(fake.watches) do
    w.items = {}
    for _, u in ipairs(fake.units) do if w.kinds[u.kind] then w.items[#w.items + 1] = { unit = u, kind = u.kind } end end
  end
  fake.rings = {}
  M.update()
end
function fake.place(u, x, y, z) u.x, u.y, u.z = x, y, z end
function fake.add(kind, x, y, z) fake.units[#fake.units + 1] = { kind = kind, x = x, y = y, z = z } end
function fake.matrix(x, y, z) fake.target = ud('Matrix4x4', { x = x, y = y, z = z }) end
function fake.odd() return ud('Quaternion') end
return fake
"""


class AimCircleTest(unittest.TestCase):
    def setUp(self):
        self.lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.fake = self.lua.execute(FAKE)
        with open(os.path.join(HERE, "aim_circle.lua"), encoding="utf-8") as f:
            self.M = self.lua.execute(f.read(), self.lua.globals().chef)

    def frames(self, n=20):
        for _ in range(n):
            self.fake.frame(self.M, 1 / 60)

    def rings(self):
        return list(self.fake.rings.values())

    def ring(self):
        rings = self.rings()
        self.assertEqual(len(rings), 1)
        return rings[0]

    def logs(self):
        return "\n".join(self.fake.logs.values())

    def tearDown(self):
        self.assertEqual(list(self.fake.crashes.values()), [])

    def test_the_ring_is_where_the_aim_field_says_as_the_games(self):
        self.fake.field["rm_qp0d"] = self.fake.Vector3(3, 40, 2)
        self.frames()
        r = self.ring()
        self.assertEqual((r.x, r.y), (3, 40))
        self.assertAlmostEqual(r.r0, 6.3)
        self.assertAlmostEqual(r.r1, 8.5)
        self.assertEqual(r.alpha, 128)
        self.assertEqual(r.layer, 101100)
        self.assertIn("aim circle from the aim field", self.logs())

    def test_without_the_field_the_animations_target(self):
        self.fake.info["vvhx8ga"] = self.lua.eval("{ fields = {} }")
        self.fake.matrix(5, 90, 3)
        self.frames()
        self.assertEqual((self.ring().x, self.ring().y), (5, 90))
        self.assertNotIn("rm_qp0d", list(self.fake.reads.values()))
        self.assertIn("aim circle from the aim target", self.logs())

    def test_with_nothing_readable_the_middle_of_the_view(self):
        self.fake.info["vvhx8ga"] = None
        self.fake.info["un6y1d"] = None
        self.frames()
        self.assertEqual((self.ring().x, self.ring().y), (0, 98))
        self.assertIn("aim circle from the middle of the view", self.logs())

    def test_a_field_that_isnt_a_vector_is_not_handed_to_the_engine(self):
        self.fake.field["rm_qp0d"] = self.lua.eval("{ 1, 2 }")
        self.frames()
        self.assertEqual((self.ring().x, self.ring().y), (0, 98))
        self.fake.field["rm_qp0d"] = self.fake.odd()
        self.frames()
        self.assertEqual((self.ring().x, self.ring().y), (0, 98))

    def test_no_ring_without_a_rifle_in_hand(self):
        self.lua.eval("function(f) f.place(f.rifle, -0.3, -0.3, 1.0) end")(self.fake)
        self.frames()
        self.assertEqual(self.rings(), [], "slung")

    def test_a_lagging_rifle_counts_while_aiming(self):
        self.lua.eval("function(f) f.place(f.rifle, -0.3, 0.3, 1.0) end")(self.fake)     # 0.67 m from the hand
        self.frames()
        self.assertEqual(self.rings(), [])
        self.fake["mouse"]["right"] = True
        self.frames()
        self.ring()

    def test_no_ring_with_a_throwable_out(self):
        self.fake.pose = 41
        self.frames()
        self.assertEqual(self.rings(), [])

    def test_seated_only_while_aiming(self):
        self.fake.add("16474112801385b6", 0.2, 0.2, -0.5)    # a tank's top seat
        self.frames()
        self.assertEqual(self.rings(), [])
        self.fake["mouse"]["right"] = True
        self.frames()
        self.ring()

    def test_an_frv_driver_not_raising_it(self):
        self.fake.add("cc21c7ffd3ebefb9", 0.2, 0.2, -0.5)
        self.lua.eval("function(f) f.place(f.rifle, 0.3, 0.3, 0.46) end")(self.fake)
        self.fake["mouse"]["right"] = True
        self.frames()
        self.assertEqual(self.rings(), [])

    def test_no_ring_in_first_person_nor_on_the_ship_nor_from_the_hellpods_view(self):
        self.frames()
        self.ring()
        self.fake.mission = False
        self.frames()
        self.assertEqual(self.rings(), [])
        self.fake.mission = True
        self.lua.eval("function(f) f.cam.x, f.cam.y, f.cam.z = 0.3, 0.3, 1.4 end")(self.fake)   # at the sight
        self.frames()
        self.assertEqual(self.rings(), [])
        self.lua.eval("function(f) f.cam.x, f.cam.y, f.cam.z = 0.3, -20, 6 end")(self.fake)
        self.fake.mouse["right"] = True
        self.frames()
        self.assertEqual(self.rings(), [])

    def test_another_mods_first_person_camera_keeps_the_ring(self):
        self.lua.eval("function(f) f.cam.x, f.cam.y, f.cam.z = 0.3, 0.3, 1.4 end")(self.fake)
        self.fake.field["x4joxek"] = self.fake.Vector3(3, 20, 1.4)    # 2.7 m off this camera's line
        self.fake.field["rm_qp0d"] = self.fake.Vector3(3, 40, 2)
        self.frames(40)
        self.ring()

    def test_turned_off(self):
        self.fake.changed(False)
        self.frames()
        self.assertEqual(self.rings(), [])


if __name__ == "__main__":
    unittest.main()
