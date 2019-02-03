pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- bee budz
-- global game jam 2019

local cam_x = 0
local cam_x_screen_limit = 48

local t = 0      -- current time
local p =              -- player
 { x = 64, y = 64, move_timer = 0,
   cycling = false, cycle_timer = 0,
   col = 8, mode = 1, point_right = true,
   r = 4,
   sprite="bee",
   carry_sprite=nil}
local bee_gravity = 0
local bee_gravity_carry = 1
local bee_speed = 1.75 -- 1.75
local bee_speed_carry = 1.5
local current_bee_speed = bee_speed
local bee_jank_skip_rate = 3
local bee_jank_factor_y = 1.25
local bee_jank_factor_x = .5
local normal_gravity = 4
local normal_flee_speed = 4
local is_day = false
local is_overcast = false
local is_rainy = true

-- the y position of the floor
local floor_y = 128 - 32
local hive_wall_thickness = 8

-- constants for the different screens
  map_screens = {
    hive = 1,
    blue_flowers_and_wasps = 2,
    spiders_and_trees = 3,
    houses_and_lake = 4,
    green_flowers = 5,
    pink_flowers_and_spiders = 6,
    houses_and_wasps = 7,
    open_space_variant_2 = 8,
    end_of_world = 9,
  }
  -- 1 = hive
  -- 2 = blue flowers & wasp
  -- 3 = spiders & two trees
  -- 4 = houses & lake?
  -- 5 = green flowers
  -- 6 = pink flowers + spiders
  -- 7 = houses with wasps
  -- 8 = (open space) tall grass?? (variant 2)
  -- 9 = end of world

-------------------------- util --

printh("overwritten", "b", true)
function log(text,val1,val2,val3,val4)
  if text == nil then text = "nil" end
  if val1 == nil then val1 = "nil" end
  if val2 == nil then val2 = "nil" end
  if val3 == nil then val3 = "nil" end
  if val4 == nil then val4 = "nil" end
  printh("["..t.."] "..text.."|"..val1.."|"..val2.."|"..val3.."|"..val4, "b")
end
function len(x,y)
 return sqrt(len2(x,y))
end

function len2(x,y)
 return x*x + y*y
end

function pow2(x)
 return x * x
end

function step(n, inc)
 return round(n/inc)*inc
end

function round(n)
 local mod = n % 1
 return mod > .5 and ceil(n) or flr(n)
end

function rnd_index(a)
 return flr(rnd(#a))+1
end

function cycle_arr(t, skips)
 if skips > #t then error"skip too large" end
 for i=1,skips do
  t[i],t[i+skips-1] = t[i+skips-1],t[i]
 end
end

function shuffle(t)
 if type(t) ~= "table" then error"shuffle only works on tables" end
 for i=#t,1,-1 do
  local j = rnd_index(i-1)
  t[i],t[j] = t[j],t[i]
 end
end

function for_xy(x1,x2, y1,y2, func)
 for x=x1,x2,sgn(x2-x1) do
  for y=y1,y2,sgn(y2-y1) do
   func(x,y)
  end
 end
end

function clone(input)
  local t = {}
  for key, value in pairs(input) do
    t[key] = value
  end
  return t
end


-- generate a rose function for entities
function euf_rose_xy(o)
  -- https://en.wikipedia.org/wiki/rose_(mathematics)
  o = {
    n = o.n and o.n or 1, -- the n value from wikipedia
    d = o.d and o.d or 1, -- the d value from wikipedia
    r = o.r and o.r or 16, -- the default radius
    f_cycle = o.f_cycle, -- the cycle time. 30fps
    f_offset = o.f_offset and o.f_offset or 0, -- the cycle offset
    x_r = o.x_r and o.x_r or o.r or 16, -- the x radius
    y_r = o.y_r and o.y_r or o.r or 16, -- the y radius
    rotate = o.rotate and o.rotate or 0, -- the tilt
    flip_x = o.flip_x and sgn(o.flip_x) or 1, -- flips x
    flip_y = o.flip_y and sgn(o.flip_y) or 1, -- flips y
  }

  local k = o.n / o.d
  log("rose1", o.n, o.d, o.r, o.f_cycle)
  log("rose2", o.f_offset, o.x_r, o.y_r, o.rotate)
  return function (entity, entities)
    local theta =
      ((t + o.f_offset) % (o.f_cycle * o.d)) / o.f_cycle
    -- theta = theta + o.rotate
    local offset_x = o.x_r * cos(k * theta) * cos(theta)
    local offset_y = o.y_r * cos(k * theta) * sin(theta)
    local xy_len = len(offset_x, offset_y)
    local angle = atan2(offset_x, offset_y) + o.rotate
    entity.x = entity.ox + xy_len * cos(angle) * o.flip_x
    entity.y = entity.oy + xy_len * sin(angle) * o.flip_y
  end
end


--------------------------------
----------------------- setup --
cls(); rect(0,0,127,127,1)


--------------------------------
------------ callback: update --

_b = {
 { count=0, isdown=false, used=false,
   sym="�", col= 8 }, -- left
 { count=0, isdown=false, used=false,
   sym="�", col= 9 }, -- right
 { count=0, isdown=false, used=false,
   sym="�", col=11 }, -- up
 { count=0, isdown=false, used=false,
   sym="�", col=12 }, -- down
 { count=0, isdown=false, used=false,
   sym="�", col=14 }, -- o
 { count=0, isdown=false, used=false,
   sym="�", col=15 }  -- x
}

function b(i)
 return _b[i+1]
end

function from_map_init_grass(entity)
  log("from_map_init_grass","x,y",entity.x,entity.y)
  local counter = 0
  entity.updates = {
    function(entity, entities)
      counter = max(counter - 1, 0)
      entity.type = counter > 0 and ("grass"..min(5,flr(counter/3))) or "grass0"
    end
  }
  entity.reactions = {
    function(entity, entities)
      current_bee_speed = current_bee_speed * 0.5
      counter = 15
    end
  }
end

-- sprite data
_s = {
  bee        = {n=  1, w=1, h=1, cx=4, cy=4, r=4},
  bee_green  = {n=  2, w=1, h=1, cx=4, cy=4, r=4},
  bee_blue   = {n= 17, w=1, h=1, cx=4, cy=4, r=4},
  bee_pink   = {n= 18, w=1, h=1, cx=4, cy=4, r=4},
  bee_busy   = {n= 41, w=1, h=1, cx=0, cy=0, r=1},
  bee_busier = {n= 57, w=1, h=1, cx=0, cy=0, r=1},

  food       = {n= 16, w=1, h=1, cx=4, cy=4, r=4, bouncy=true},
  food_green = {n= 32, w=1, h=1, cx=4, cy=4, r=4, bouncy=true},
  food_blue  = {n= 33, w=1, h=1, cx=4, cy=4, r=4, bouncy=true},
  food_pink  = {n= 34, w=1, h=1, cx=4, cy=4, r=4, bouncy=true},

  hive   =     {n=  3, w=2, h=2, cx=8, cy=8, r=8},
  exit   =     {n=  0, w=1, h=1, cx=8, cy=8, r=8},
  cloud  =     {n=  5, w=2, h=1, cx=8, cy=8, bouncy=true},
  cloud2 =     {n= 48, w=2, h=1, cx=8, cy=8},
  grass0 =     {n=101, w=1, h=1, cx=4, cy=4, r=4, bouncy=true, from_map_init=from_map_init_grass},
  grass1 =     {n=102, w=1, h=1, cx=4, cy=4, r=4, bouncy=false, from_map_init=from_map_init_grass},
  grass2 =     {n=103, w=1, h=1, cx=4, cy=4, r=4, bouncy=false, from_map_init=from_map_init_grass},
  grass3 =     {n=104, w=1, h=1, cx=4, cy=4, r=4, bouncy=false, from_map_init=from_map_init_grass},
  grass4 =     {n=105, w=1, h=1, cx=4, cy=4, r=4, bouncy=false, from_map_init=from_map_init_grass},
  grass5 =     {n=106, w=1, h=1, cx=4, cy=4, r=4, bouncy=false, from_map_init=from_map_init_grass},
  hill_top =   {n=100, w=1, h=1, cx=4, cy=4},
  hill_bottom =   {n=116, w=1, h=1, cx=4, cy=4},
  -- floor  =     {n=  7, w=2, h=1, cx=4, cy=4},
  speech =     {n=  8, w=2, h=2, cx=8, cy=8, bouncy=true},
  sun    =     {n= 14, w=2, h=2, cx=8, cy=8, bouncy=true},
  moon   =     {n= 72, w=2, h=2, cx=8, cy=8, bouncy=true},
  smoke_l=     {n= 50, w=1, h=1, cx=4, cy=4},
  smoke_s=     {n= 23, w=1, h=1, cx=4, cy=4},
  spider =     {n= 22, w=1, h=1, cx=4, cy=4, r=4},
  hornet =     {n= 21, w=1, h=1, cx=4, cy=4, r=4},

  heart     =  {n= 86, w=1, h=1, cx=4, cy=4, r=4, bouncy=true},

  honeycomb =  {n= 35, w=2, h=2, cx=8, cy=8, r=8},

  logo      =  {n=96, w=4, h=2, cx=16, cy=8},

  reed      =  {n=71, w=1, h=2, cx=4, cy=8},
  lilipad   =  {n=70, w=1, h=1, cx=4, cy=4},
  -- todo: tree.
}

_s_by_n = {}
for k,v in pairs(_s) do
  _s_by_n[v.n] = v
  v.name = k
end

_sfx = {
  beetalk    = 0,
  hurt       = 8,
  pickup     = 7,
  spider     = 6,
  hornet     = 6,
}

-- gathers spr parameters
function s(name, x, y, flip_x, flip_y)
  local sd = _s[name]
  return sd.n, x-sd.cx, y-sd.cy, sd.w, sd.h, flip_x, flip_y
end

-- gathers spr parameters
function sb(name, x, y, flip_x, flip_y)
  local sd = _s[name]
  local bounce = sd.bouncy and (t % 10 < 5) and 1 or 0
  return sd.n, x-sd.cx, y-sd.cy+bounce, sd.w, sd.h, flip_x, flip_y
end

-- entity reaction: delete
function er_delete(entity, entities)
  del(entities, entity)
end

-- entity reaction: carry
function er_carry(entity, entities)
  if p.carry_sprite ~= nil then return end
  if goals[entity.type] then return end
  p.carry_sprite = entity.type
  sfx(_sfx.pickup)
  del(entities, entity)
end

function erf_sound(sfx_id)
  return function(entity, entities)
    sfx(sfx_id)
  end
end

-- entity reaction: hurt
function er_hurt(entity, entities)
  local knockback = 10
  p.sprite = "bee_pink"
  sfx(_sfx.hurt)
  local theta = atan2(p.x-entity.x, p.y-entity.y)
  p.x = p.x + cos(theta) * knockback
  p.y = p.y + sin(theta) * knockback
end

-- entity reaction: drop
function er_drop(entity, entities)
  if p.carry_sprite == nil then return end
  add(
    entities,
    {
      type=p.carry_sprite,
      x=p.x,
      y=p.y + p.r + _s[p.carry_sprite].r + 2,
      updates={eu_fall},reactions={er_carry}})
  p.carry_sprite = nil
end

-- entity reaction: drop
function er_consume_carry(entity, entities)
  if p.carry_sprite == nil then return end
  p.carry_sprite = nil
end

function update_weather()
  if not has_been_night and goals["food_blue"] then
    is_day = false
    has_been_night = true
  else
    is_day = true
  end

  local completed_goals = 0
  for k,v in pairs(goals) do
    if v then
      completed_goals = completed_goals + 1
    end
  end
  is_rainy = completed_goals == 2
  all_goals = completed_goals >= 3
end

-- entity reaction factory: consume carry only one type
function erf_consume_carry_only(type)
  return function(entity, entities)
    if p.carry_sprite == nil then return end
    if p.carry_sprite ~= type then return end
    p.carry_sprite = nil

    sfx(_sfx.pickup)
    goals[type] = true
    update_weather()

    entity.post_draws = {
      function(entity, entities)
        if not goals[type] then return end
        -- log(type, entity.x, entity.y)
        local n, cx, cy, w, h, flip_x, flip_y = s(type, entity.x, entity.y)
        spr(n, cx, cy+1, w, h/2, flip_x, flip_y)
      end
    }

    -- log(type .. type, entity.x, entity.y)
  end
end

function epdf_lake(w,h, col)
  col = col and col or 12
  -- todo: fillp mask
  return function(entity, entities)
    circfill(entity.x, entity.y, h/2, col)
    circfill(entity.x+w, entity.y, h/2, col)
    rectfill(entity.x, entity.y-h/2, entity.x+w, entity.y+h/2, col)

    -- lines in water
    local lake_line_len = 30
    -- rectfill(entity.x, entity.y-h/4, entity.x+lake_line_len, entity.y-h/4, 7)
    -- rectfill(entity.x+w/2, entity.y, entity.x+w/2+lake_line_len, entity.y, 1)
    -- rectfill(entity.x+w/2, entity.y+h/4, entity.x+lake_line_len+w/2, entity.y+h/4+1, 9)
  end
end

-- entity post draw factory: speech icon
function epdf_speech_text(text)
  return function(entity, entities)
    local sprite = _s[entity.type]
    local bounce = sprite.bouncy and (t % 10 < 5) and 1 or 0
    print(text, entity.x-sprite.cx/2, entity.y-sprite.cy/2+bounce, 0)
  end
end

-- entity post draw factory: speech icon
function epdf_speech_icon(type)
  return function(entity, entities)
    spr(sb(type, entity.x, entity.y))
  end
end

goals = {
  food_blue  = false,
  food_green = false,
  food_pink  = false,
}

all_goals = false

-- entity post draw factory: goal
function epdf_speech_goal_indicator(goal)
  return function(entity, entities)
    if not goals[goal] then
      spr(sb(goal, entity.x, entity.y))
    else
      spr(sb("heart", entity.x, entity.y))
    end
  end
end

function update_buttons()
 for i=1,6 do
  local cur = _b[i]
  isdown = btn(i-1)
  cur.count = cur.count + 1
  if isdown != cur.isdown then
   cur.count = 0
   cur.used = false
  end
  cur.isdown = isdown
 end
end

function spaces(n)
 local space = ""
 for i=1,n do
  space = space .. " "
 end
 return space
end

function dump(name, v)
 _dump(name, v, 0)
end

-- todo: have this sort tables
function _dump(name, v, depth)
 local padding = spaces(depth*2)
 if depth > 10 then
  log(padding .. "depth limit reached")
  return
 end
 if type(v) == "table" then
  log(padding .. name .. " (table) len: " .. #v)
  for k2,v2 in pairs(v) do
   _dump(k2, v2, depth+1)
  end
 else
  if type(v) == "boolean" then
   v = v and "true" or "false"
  elseif v == nil then
   v = "nil"
 elseif type(v) == "function" then
   v = "function"
  end
  log(padding .. name .. " " .. v)
 end
end

function update_bee()
  p.sprite = "bee"
  local gravity = p.carry_sprite and bee_gravity_carry or bee_gravity
  p.y = p.y + gravity
  if t % bee_jank_skip_rate ~= 0 then
    local angle = rnd(1)
    local fx = cos(angle) * bee_jank_factor_x
    local fy = sin(angle) * bee_jank_factor_y
    p.x = p.x + fx
    p.y = p.y + fy
  end
end

function apply_floors(entities)
  if p.y < p.r then p.y = p.r end
  if p.y > floor_y then p.y = floor_y end
  local right_limit = get_screen_offset(#map_list_right)
  local left_limit = get_screen_offset(-#map_list_left + 1)
  if p.x > right_limit then p.x = right_limit end
  if p.x < left_limit then p.x = left_limit end
end

function apply_hive_walls(entities)
  if p.y > 128-hive_wall_thickness then p.y = 128-hive_wall_thickness end
  if p.x > 128-hive_wall_thickness then p.x = 128-hive_wall_thickness end
  if p.y < hive_wall_thickness then p.y = hive_wall_thickness end
  if p.x < hive_wall_thickness then p.x = hive_wall_thickness end
end

function control(entities)
  local used_speed = current_bee_speed
  -- left
  if b(0).isdown then
    p.x = p.x - used_speed
    p.point_right = false
  end
  -- right
  if b(1).isdown then
    p.x = p.x + used_speed
    p.point_right = true
  end
  -- up
  if b(2).isdown then p.y = p.y - bee_speed end
  -- down
  if b(3).isdown then p.y = p.y + bee_speed end

  if b(4).isdown then er_drop(null, entities) end

  
  current_bee_speed = p.carry_sprite and bee_speed_carry or bee_speed
end

-- determines which entities the bee is touching
function check_overlap(entities)
  local bee_r = _s[p.sprite].r
  for i=#entities,1,-1 do
    local e = entities[i]
    e.was_touched = e.is_touched
    e.is_touched = false
    local sprite = _s[e.type]
    local e_r = sprite.r
    if e_r ~= nil then
      local dx = e.x - p.x
      local dy = e.y - p.y
      if abs(dx) < 16 and abs(dy) < 16 then
        local d2 = len2(dx,dy)
        local d2_limit = pow2(bee_r + e_r)
        if d2 < d2_limit then
          e.is_touched = true
          -- log("colliding", e.type, bee_r, e_r)
          -- log("colliding", dx, dy)
          -- log("colliding", d2, d2_limit)
          -- log("colliding", e.x, e.y, p.x, p.y)
        end
      end
      e.first_touch = e.is_touched and not e.was_touched
    end
  end
end

-- reacts to the bee touching entities
function apply_overlap(entities)
  -- _s.bee.n = 1
  for i=#entities,1,-1 do
    local e = entities[i]
    if e.is_touched then
      -- _s.bee.n = 2
      local reactions = e.reactions
      if reactions ~= nil then
        -- log("#reactions", #reactions)
        for reaction in all(reactions) do
          reaction(e, entities)
        end
      end
    end
  end
end

function apply_entity_updates(entities)
  for i=#entities,1,-1 do
    local e = entities[i]
    local updates = e.updates
    if updates ~= nil then
      -- log("#updates", #updates)
      for update in all(updates) do
        update(e, entities)
      end
    end
  end
end

function update_camera()
  cam_x_right_limit = p.x - cam_x_screen_limit
  cam_x_left_limit = p.x - (128 - cam_x_screen_limit)

  if cam_x > cam_x_right_limit then cam_x = cam_x_right_limit end
  if cam_x < cam_x_left_limit then cam_x = cam_x_left_limit end
end

--------------------------------
-------------- callback: draw --

-- gets the (x,y) offset for rendering a screen worth of map (16,16)
function get_map_offset(map_number)
  local row = flr((map_number - 1) / 8)
  local column = (map_number - 1) % 8
  return column*16, row*16
end

-- gets the (sx,sy) offset for rendering a screen worth of
-- map a certain distance from home
-- 0 is home
-- 1 is "one screen right of home"
-- -1 is "one screen left of home"
function get_screen_offset(distance_from_home)
  local sx = 128 * distance_from_home
  local sy = 0
  return sx,sy
end

-- draws one map on the screen, offset appropriately
-- distance_from_home: 0 = origin; -1 = one screen left; +1 = one screen right
-- map_number: 1-indexed map id, starting from top left
function draw_screen(map_number, distance_from_home)
  map_x, map_y = get_map_offset(map_number)
  sx, sy = get_screen_offset(distance_from_home)
  -- rect(sx,sy, sx+128, sy+128)
  map(map_x,map_y, sx,sy, 16,16)
end

function get_screen(sx)
  return flr(sx / 128)
end

function pick_map_old()
  local i = rnd_index(available_maps)
  -- log("map", i, #available_maps)
  return available_maps[rnd_index(available_maps)]
end

function draw_entities(entities)
  for i=1,#entities do
    local e = entities[i]
    spr(sb(e.type, e.x, e.y))

    local post_draws = e.post_draws
    if post_draws ~= nil then
      -- log("#post_draws", #post_draws)
      for post_draw in all(post_draws) do
        post_draw(e, entities)
      end
    end
  end
end

-------------------------------
-- utilities
-------------------------------

_mon_ordered = {}
_mon = {}

function monf(what, on_off, scale, col)
 mon(what, on_off, scale*12, col)
end

function mon(what, on_off, scale, col)
 cur = _mon[what] or {}
 cur.what = what
 cur.on_off = on_off
 cur.scale = scale
 cur.col = on_off and col or 5

 if not _mon[what] then
  add(_mon_ordered, cur)
 end

 _mon[what] = cur
end

function mon_draw(sx,sy)
 rectfill(sx,sy-1,sx+8*#_mon_ordered+1,sy+8,7)
 for k,v in pairs(_mon_ordered) do
  color(v.col)
  x = sx + k*8 - 6
  print(v.what, x, sy)
  if v.scale > 0 then
   line(x,sy+6,x+min(6,v.scale),sy+6)
  end
  if v.scale > 6 then
   line(x,sy+7,x+mid(0,6,v.scale-6),sy+7)
  end
 end
end

--------------------------------
------------- mode: overworld --


home_maps = {1}
available_maps = {2,3,4,5,6,7,8}

home_map = 1
map_list_right = {pick_map_old(),pick_map_old(),pick_map_old(),pick_map_old(),pick_map_old(),pick_map_old()}
map_list_left = {pick_map_old(),pick_map_old(),pick_map_old(),pick_map_old(),pick_map_old()}

function _update_overworld()
  t = (t + 1) % 32767
  update_buttons()
  update_bee()
  control(overworld_entities)
  apply_floors(overworld_entities)
  apply_entity_updates(overworld_entities)
  check_overlap(overworld_entities)

  apply_overlap(overworld_entities)
  apply_map_updates(overworld_updates)

  update_camera()

  log("stats","mem",stat(0),"cpu",stat(1))
end

function apply_map_updates(updates)
  for u in all(updates) do
    u()
  end
end

function parallax_hills(seed, count, speed, scale, y_spread)
  local reseed = rnd(10000)
  srand(seed)

  local right_limit = get_screen_offset(#map_list_right)
  local left_limit = abs(get_screen_offset(-#map_list_left + 1))
  right_limit = right_limit / (speed * 2)
  left_limit = left_limit / (speed * 2)
  for i=1,count do
    local sx = rnd(right_limit + left_limit) - left_limit
    -- local sy = y + rnd(y_spread)
    sx = sx + (speed * -cam_x) - 1

    local hill_count = flr(rnd(3)) + 1
    local hill_y_pos = 92

    if hill_count == 1 then
      spr(s("hill_top", sx, hill_y_pos))
    end

    if hill_count == 2 then
      spr(s("hill_top", sx, hill_y_pos-8))
      spr(s("hill_bottom", sx, hill_y_pos))
    end

    if hill_count == 3 then
      spr(s("hill_top", sx, hill_y_pos-16))
      spr(s("hill_bottom", sx, hill_y_pos-8))
      spr(s("hill_bottom", sx, hill_y_pos))
    end
  end
  srand(reseed)
end

function parallax_clouds(seed, count, speed, scale, y, y_spread)
  local reseed = rnd(10000)
  srand(seed)
  local right_limit = get_screen_offset(#map_list_right)
  local left_limit = abs(get_screen_offset(-#map_list_left + 1))
  right_limit = right_limit / (speed * 2)
  left_limit = left_limit / (speed * 2)
  for i=1,count do
    local sx = rnd(right_limit + left_limit) - left_limit
    local sy = y + rnd(y_spread)
    sx = sx + speed * -cam_x
    spr(s("cloud", sx, sy))
  end
  srand(reseed)
end

function draw_rain(seed, count, y)
  local len = 5
  local angle = 0.666
  local y_spread = 128 + len + y + len
  local reseed = rnd(10000)
  srand(seed)
  local right_limit = get_screen_offset(#map_list_right+ 1)
  local left_limit = abs(get_screen_offset(-#map_list_left))
  right_limit = right_limit + y_spread * abs(cos(angle))
  for i=1,count do
    local sx = rnd(right_limit + left_limit) - left_limit
    local initial_progress = rnd(y_spread)

    local progress = (initial_progress + (t * 2)) % (128 + len + y + len)
    sx = sx + progress * cos(angle)
    local sy = y + progress * sin(angle)

    sx2 = sx + len * cos(angle)
    sy2 = sy + len * sin(angle)
    line(sx,sy, sx2,sy2, 13)
  end
  srand(reseed)
end

function _draw_overworld()
  local sky_color = is_day and 12 or 1
  cls(sky_color)

  camera(cam_x,0)
  local sky_sprite = is_day and "sun" or "moon"
  spr(sb(sky_sprite, cam_x + 112, 12))

  for i=1,8 do
    parallax_hills(100 * i, 50, 0.25, 1, 8)
  end

  parallax_clouds(100, 50, 0.25, 1, 16, 24)
  parallax_clouds(105, 50, 0.125, 1, 24, 24)
  if is_overcast then
    parallax_clouds(102, 2000, 0.0675, 1, 8, 32)
  end

  if is_rainy then
    draw_rain(102, 1000, -5)
  end

  local screen = get_screen(cam_x)
  rectfill(cam_x-64,floor_y, cam_x+128+64,128, 3)

  -- home
  draw_screen(home_map, 0)

  -- left
  for i=1,#map_list_left do
    local map = map_list_left[i]
    draw_screen(map, -i)
  end

  -- right
  for i=1,#map_list_right do
    local map = map_list_right[i]
    draw_screen(map, i)
  end

  -- entities
  draw_entities(overworld_entities)

  -- bee carry
  if p.carry_sprite ~= nil then
    local offset_y = _s[p.sprite].cy + _s[p.carry_sprite].cy
    spr(s(p.carry_sprite, p.x, p.y + offset_y))
  end

  -- bee
  spr(s(p.sprite, p.x, p.y, not p.point_right))
end

function go_to_overworld()
  if all_goals then return end
  music(6)
  _update = _update_overworld
  _draw = _draw_overworld
  cam_x = 0
  p.y = 52 + 8 + p.r + p.r
  p.x = 64
end

-- returns the map_id of an available map, probabilistically
function pick_map()
  local i = rnd_index(available_maps)
  log("map", i, #available_maps)
  return available_maps[rnd_index(available_maps)]
end

function init_overworld()
  -- 1 = hive
  -- *** 2 = blue flowers & wasp
  -- *** 3 = spiders & two trees
  -- *** 4 = houses & lake?
  -- *** 5 = green flowers
  -- *** 6 = pink flowers + spiders
  -- *** 7 = houses with wasps
  -- *** 8 = open space three trees bones
  -- 9 = end of world

  map_list_left = {
    map_screens.spiders_and_trees,
    map_screens.open_space_variant_2,
    map_screens.houses_and_wasps,
    map_screens.spiders_and_trees,
    map_screens.houses_and_lake,
    map_screens.open_space_variant_2,
    map_screens.green_flowers,
    map_screens.end_of_world,
  }

  map_list_right = {
    map_screens.open_space_variant_2,
    map_screens.blue_flowers_and_wasps,
    map_screens.open_space_variant_2,
    map_screens.houses_and_lake,
    map_screens.spiders_and_trees,
    map_screens.houses_and_wasps,
    map_screens.pink_flowers_and_spiders,
    map_screens.end_of_world,
  }

  overworld_entities = {}
  overworld_updates = {}
  init_map_data_all({map_screens.hive}, 0)
  init_map_data_all(map_list_left, -1)
  init_map_data_all(map_list_right, 1)
end

function init_map_data_all(map_ids, direction)
  for i=1,#map_ids do
    local map_id = map_ids[i]
    local map_data = map_setup[map_id]
    local distance_from_home = direction * i
    init_map_data_one(map_setup[map_id], map_id, distance_from_home)
  end
end

function init_map_data_one(map_data, map_id, distance_from_home)
  local screen_offset_x, _ = get_screen_offset(distance_from_home)
  if map_data.update ~= nil then
    local closure_object = {}
    add(overworld_updates, function()
      map_data.update(
        closure_object,
        map_data,
        distance_from_home,
        screen_offset_x)
    end)
  end

  log("init_map_data_one", map_id, distance_from_home, screen_offset_x, _)
  for entity in all(map_data.default_entities) do
    inject_entity(entity, screen_offset_x)
  end
end

--------------------------------
------------------ mode: hive --

function _update_hive()
  t = (t + 1) % 32767
  update_buttons()
  update_bee()
  control(hive_entities)

  apply_hive_walls(hive_entities)
  apply_entity_updates(hive_entities)
  check_overlap(hive_entities)
  apply_overlap(hive_entities)

  update_camera()

  log("stats","mem",stat(0),"cpu",stat(1))
end

function go_to_end()
  music(40)
  _update = _update_end
  _draw = _draw_end
end

function _draw_end()
  camera(0,0)
  too_many_hearts(hive_hearts, 0.5, 0, 0, 1000, true)
  sspr(0, 48, 32, 16, 10, 10, 108, 32)
  too_many_hearts(end_hearts, 1, 1, 11, 500, false)

  draw_entities(end_entities)

  -- -- bee
  -- spr(s(p.sprite, p.x, p.y, not p.point_right))
end

function _update_end()
  t = (t + 1) % 32767
  update_buttons()
  update_bee()
  control(hive_entities)
  -- for i=#hearts,1,-1 do
  --   if i % 10 > 5 then
  --     del(hearts, hearts[i])
  --   end
  -- end
end

function draw_busy_bees(sprite, count, seed, tx, ty)
  local reseed = rnd(1000)
  srand(seed)
  for i=1,count do
    local x = ((rnd(192) + t*tx) % 192) - 32
    local y = ((rnd(192) + t*ty) % 192) - 32
    spr(sprite.n, x,y, sprite.w,sprite.h)
  end
  srand(reseed)
end

function _draw_hive()
  camera(0,0)
  cls"15"
  draw_busy_bees(_s.bee_busy,   50, 100,  5, 1)
  draw_busy_bees(_s.bee_busier, 50, 101, -5, 1)
  draw_busy_bees(_s.bee_busy,   50, 102, -3, 2)
  draw_busy_bees(_s.bee_busier, 50, 103,  3, 2)

  map( 0,64-16, 0,0, 16,16)
  map(16,64-16, 0,0, 16,16)

  -- entities
  draw_entities(hive_entities)

  -- bee carry
  if p.carry_sprite ~= nil then
    local offset_y = _s[p.sprite].cy + _s[p.carry_sprite].cy
    spr(s(p.carry_sprite, p.x, p.y + offset_y))
  end
  -- bee
  spr(s(p.sprite, p.x, p.y, not p.point_right))

  if all_goals then
    too_many_hearts(hive_hearts, 0.5, 0, 6, 1000, true)

    if #hive_hearts > 750 then
      transition_counter = transition_counter + 1
      if transition_counter > 30 * 2 then
        go_to_end()
      end
    end
  end
end

end_hearts = {}
hive_hearts = {}
heart_rate = 1
transition_counter = 0
function too_many_hearts(hearts, rate, h_min, h_max, target, wrap)
  heart_rate = max(h_min, min(heart_rate + rate, h_max))
  if #hearts < target then
    for i=1,heart_rate do
      add(hearts, {x=rnd(128+64)-32, y=rnd(32)+128})
    end
  end

  for i=#hearts,1,-1 do
    h = hearts[i]
    if h.y < -16 then
      if wrap then h.y = 128+16 else del(hearts, h) end
    end
    h.y = h.y - 1
    local theta = (t + i) / 300
    h.x = h.x + cos(theta)
    spr(s("heart", h.x, h.y))
  end
end

function thin_hearts(rate, target)
  for i=1,rate do
    if #hearts > target then
      local index = flr(rnd(#hearts-1))+1
      del(hearts, hearts[i])
    end
  end
end

function go_to_hive()
  music(50)
  _update = _update_hive
  _draw = _draw_hive
  p.y = 128 - 8 - p.r - p.r
  p.x = 64
end

function go_to_title()
  music(50)
  _update = _update_title
  _draw = _draw_title
end

cardioid_loop = euf_rose_xy{n=1,d=3,r=38,r_x=38,f_cycle=-30*3,rotate=-0.25}

function _update_title()
  t = (t + 1) % 32767
  update_buttons()

  update_bee()
  p.ox = 64
  p.oy = 64
  cardioid_loop(p, nil)

  apply_hive_walls(title_entities)
  apply_entity_updates(title_entities)
  check_overlap(title_entities)
  apply_overlap(title_entities)

  if b(5).isdown then
    game_start()
  end

  if b(0).isdown and b(1).isdown then
    game_start()
    go_to_overworld()
  end
end

function _draw_title()
  cls(15)

  draw_busy_bees(_s.bee_busy,   50, 100,  5, 1)
  draw_busy_bees(_s.bee_busier, 50, 101, -5, 1)
  draw_busy_bees(_s.bee_busy,   50, 102, -3, 2)
  draw_busy_bees(_s.bee_busier, 50, 103,  3, 2)

  map( 0,64-16, 0,0, 16,16)
  map(32,64-16, 0,0, 16,16)

  sspr(0, 48, 32, 16, 10, 10, 108, 32)
  spr(46, 26, 58, 2, 2)

  -- entities
  draw_entities(title_entities)

  -- bee carry
  if p.carry_sprite ~= nil then
    local offset_y = _s[p.sprite].cy + _s[p.carry_sprite].cy
    spr(s(p.carry_sprite, p.x, p.y + offset_y))
  end
  -- bee
  spr(s(p.sprite, p.x, p.y, not p.point_right))

  -- title text
  print ("press x to begin", 32, 128-30)
end

-- go_to_hive()
-- go_to_overworld()
go_to_title()

-- the happy bee dance
eu_bee_jank = euf_rose_xy{n=1,d=6,r=5,f_cycle=15}
eu_bee_jank_45 = euf_rose_xy{n=1,d=6,r=5,f_cycle=15,x_r=2,rotate=0.125}

-- entity update: hornet roaming behavior
function eu_hornet_cycle(entity, entities)
  -- https://en.wikipedia.org/wiki/rose_(mathematics)
  local n = 4;
  local d = 6;
  local k = n / d -- petal count; doubled if even? see article
  local cycle_over_frames = 60 -- 20 -- flr(rnd(45) + 45)
  local theta = ((t + entity.petal_r_offset) % (cycle_over_frames * d)) / cycle_over_frames
  local offset_x = entity.petal_r * cos(k * theta) * cos(theta)
  local offset_y = entity.petal_r * cos(k * theta) * sin(theta)
  entity.x = entity.ox + offset_x
  entity.y = entity.oy + offset_y
end

-- entity update: fall (to ground)
function eu_fall(entity, entities)
  entity.y = entity.y + normal_gravity
  if entity.y > floor_y then entity.y = floor_y end
end

function eu_fall_n_run_off(entity, entities)
  entity.y = entity.y + normal_gravity
  if entity.y <= floor_y then return end
  entity.y = floor_y
  if entity.has_run_off then return end
  entity.has_run_off = true
  entity.run_off_speed = rnd(normal_flee_speed * 2) - normal_flee_speed
  if entity.run_off_speed < 1 then entity.run_off_speed = sgn(entity.run_off_speed) end
  add(entity.updates, eu_run_off)
end

function eu_run_off(entity, entities)
  if entity.run_off_speed == nil then return end

  entity.x = entity.x - entity.run_off_speed
  if abs(entity.x - p.x) > 128 then
    er_delete(entity, entities)
  end
end

-- entity update: fall (entirely offscreen)
function eu_fall_off(entity, entities)
  entity.y = entity.y + normal_gravity
  if entity.y < -16 then er_delete(entity, entities) end
end

function reset_goals()
  for k,v in pairs(goals) do
    goals[k] = false
  end
end

-- initializes and starts the game
function game_start(entity, entities)
  p.carry_sprite = nil
  reset_goals()
  update_weather()
  go_to_hive()
  has_been_night = false
  p.x = 64
  p.y = 80
end

function er_spawn_on_hit(entity, entities)
  if not entity.first_touch then return end
  for v in all(entity.spawn_on_hit) do
    add(entities, v)
  end
end

function epd_exit(entity, entities)
  print(
    "exit",
    entity.x-_s[entity.type].cx+1,
    entity.y-_s[entity.type].cy-6,
    8)
end

-- prep entities
function _init()
  -- music(0)
  overworld_updates = {}
  overworld_entities = {
    {type="food", x=136,y=floor_y,reactions={er_carry}}
  }

  title_entities = {
    {type="exit",      x=64,   y=112,
      spawn_on_hit={
        {type="food_blue", x=32,y=64,reactions={er_carry}},
      },
      reactions={er_spawn_on_hit, reset_goals}},
    {type="honeycomb", x=96,   y=70,    reactions={erf_consume_carry_only("food_blue")}},
    {type="bee_blue",  x=96,   y=70-20,
      updates={eu_bee_jank}},
    {type="speech",    x=96-4, y=70-20-12,
      post_draws={epdf_speech_goal_indicator("food_blue")}},
  }

  hive_entities = {
    {type="exit",      x=64,   y=128,   post_draws={epd_exit},
      reactions={go_to_overworld}},

    {type="honeycomb", x=96,   y=96,    reactions={erf_consume_carry_only("food_blue")}},
    {type="bee_blue",  x=96,   y=96-20,
      updates={eu_bee_jank}},
    {type="speech",    x=96-4, y=96-20-12,
      post_draws={epdf_speech_goal_indicator("food_blue")}},
    -- {type="food_blue", x=96-4, y=96-20-12,},

    {type="honeycomb", x=64,   y=48,    reactions={erf_consume_carry_only("food_green")}},
    {type="bee_green", x=64,   y=48-20,
      updates={eu_bee_jank}},
    {type="speech",    x=64-4, y=48-20-12,
      post_draws={epdf_speech_goal_indicator("food_green")}},
    -- {type="food_green",x=64-4, y=48-20-12,},

    {type="honeycomb", x=32,   y=96,    reactions={erf_consume_carry_only("food_pink")}},
    {type="bee_pink",  x=32,   y=96-20,
      updates={eu_bee_jank}},
    {type="speech",    x=32-4, y=96-20-12,
      post_draws={epdf_speech_goal_indicator("food_pink")}},
    -- {type="food_pink", x=32-4, y=96-20-12,},
  }

  end_entities = {
    {type="bee_blue",  x=96,   y=96-20,
      updates={eu_bee_jank}},
    {type="speech",    x=96-4, y=96-20-12,
      post_draws={epdf_speech_goal_indicator("food_blue")}},

    {type="bee_green", x=64,   y=96-20,
      updates={eu_bee_jank}},
    {type="speech",    x=64-4, y=96-20-12,
      post_draws={epdf_speech_goal_indicator("food_green")}},

    {type="bee_pink",  x=32,   y=96-20,
      updates={eu_bee_jank}},
    {type="speech",    x=32-4, y=96-20-12,
      post_draws={epdf_speech_goal_indicator("food_pink")}},

    {type="bee", x=64,   y=128-20,
      updates={eu_bee_jank}},
    {type="speech",    x=64-4, y=128-20-12,
      post_draws={epdf_speech_goal_indicator("heart")}},
  }

  for entity in all(hive_entities) do
    entity.ox = entity.x
    entity.oy = entity.y
  end
  for entity in all(title_entities) do
    entity.ox = entity.x
    entity.oy = entity.y
  end
  for entity in all(end_entities) do
    entity.ox = entity.x
    entity.oy = entity.y
  end

  map_setup = {
    [map_screens.hive] = { -- 1
      default_entities = {
        {type="hive", x=64, y=52,reactions={go_to_hive}},
        {type="exit", x=24, y=112,post_draws={epdf_lake(64,16,12)}},
        {type="reed", x=24+8, y=106+2},
        {type="reed", x=24+32+8, y=106+2},
        {type="reed", x=24+32+8+8, y=106+6},
        {type="lilipad", x=24+8+8, y=106+8},
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
        -- log("update 1", distance_from_home, screen_offset_x)
      end
    },
    [map_screens.blue_flowers_and_wasps] = { -- 2
      default_entities = {
        {type="food_blue", x=79,y=86,reactions={er_carry}},
        {type="food_blue", x=55,y=86,reactions={er_carry}},
        {type="food_blue", x=95,y=86,reactions={er_carry}},
        {type="hornet",x=32,y=52,petal_r=32,petal_r_offset=500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=74,y=42,petal_r=32,petal_r_offset=1000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=118,y=42,petal_r=32,petal_r_offset=1500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=52,y=32,petal_r=32,petal_r_offset=2000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=42,y=74,petal_r=32,petal_r_offset=2500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=96,y=32,petal_r=32,petal_r_offset=3000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
        -- log("update 2", distance_from_home, screen_offset_x)
      end
    },
    [map_screens.spiders_and_trees] = { -- 3
      default_entities = {
      },
      extra_entities = {
        {type="spider", x=16,y=-4,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
        {type="spider", x=64,y=-8,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
        {type="spider", x=112,y=-12,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
        if not p.carry_sprite then return end
        local local_px = p.x - screen_offset_x
        if local_px > 48 and local_px < 96 and not o.has_attacked then
          o.has_attacked = true
          for extra_entity in all(map_data.extra_entities) do
            inject_entity(extra_entity, screen_offset_x)
          end
          sfx(_sfx.spider)
        end
      end
    },
    [map_screens.houses_and_lake] = { -- 4
      default_entities = {
        {type="exit", x=32, y=112,post_draws={epdf_lake(64,16,12)}},
        {type="exit", x=32+16, y=112+12,post_draws={epdf_lake(64,16,12)}},
        {type="reed", x=32+8, y=106+2},
        {type="lilipad", x=40+8, y=106+8},
        {type="reed", x=48+8, y=106+2},
        {type="reed", x=32+48, y=106+12},
        {type="lilipad", x=40+49, y=106+16},
        {type="reed", x=48+48, y=106+12},
      },
      extra_entities = {
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
      end
    },
     [map_screens.green_flowers] = { -- 5
      default_entities = {
        {type="food_green", x=22,y=86,reactions={er_carry}},
        {type="food_green", x=62,y=86,reactions={er_carry}},
        {type="food_green", x=118,y=86,reactions={er_carry}},
      },
      extra_entities = {
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
      end
    },
    [map_screens.pink_flowers_and_spiders] = { -- 6
      default_entities = {
        {type="food_pink", x=38,y=86,reactions={er_carry}},
        {type="food_pink", x=54,y=86,reactions={er_carry}},
        {type="food_pink", x=102,y=86,reactions={er_carry}},
      },
      extra_entities = {
        {type="spider", x=16,y=-4,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
        {type="spider", x=64,y=-8,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
        {type="spider", x=112,y=-12,
          updates={eu_fall_n_run_off},reactions={er_drop, er_hurt, erf_sound(_sfx.spider)}},
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
        if not p.carry_sprite then return end
        local local_px = p.x - screen_offset_x
        if local_px > 48 and local_px < 96 and not o.has_attacked then
          o.has_attacked = true
          for extra_entity in all(map_data.extra_entities) do
            inject_entity(extra_entity, screen_offset_x)
          end
          sfx(_sfx.spider)
        end
      end
    },
    [map_screens.houses_and_wasps] = { -- 7
      default_entities = {
        {type="hornet",x=32,y=52,petal_r=32,petal_r_offset=3000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=74,y=42,petal_r=32,petal_r_offset=2500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=118,y=42,petal_r=32,petal_r_offset=2000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=52,y=32,petal_r=32,petal_r_offset=1500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=42,y=74,petal_r=32,petal_r_offset=1000,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
        {type="hornet",x=96,y=32,petal_r=32,petal_r_offset=500,
          updates={eu_hornet_cycle},reactions={er_drop, er_hurt}},
      },
      extra_entities = {
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
      end
    },
    [map_screens.open_space_variant_2] = { -- 8
      default_entities = {
      },
      extra_entities = {
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
      end
    },
    [map_screens.end_of_world] = { -- 9
      default_entities = {
      },
      extra_entities = {
      },
      update = function(o, map_data, distance_from_home, screen_offset_x)
      end
    },
  }

  extract_map_entities()
  init_overworld()
end

-- extracts tile-determined entities and sets the tile value to nil
function extract_map_entities()
  for k,v in pairs(map_setup) do
    log("extract_map_entities","start_new_map",k)
    local cel_offset_x, cel_offset_y = get_map_offset(k)
    log("extract_map_entities","cel_offset_x",cel_offset_x,"cel_offset_y",cel_offset_y)
    for rel_cel_x=0,15 do
      local cel_x = cel_offset_x + rel_cel_x
      for rel_cel_y=0,15 do
        local cel_y = cel_offset_y + rel_cel_y
        local map_value = mget(cel_x, cel_y)
        if map_value ~= 0 then
          local sprite = _s_by_n[map_value]
          local sprite_type = sprite and sprite.name or nil
          if sprite_type then
            log("extract_map_entities","rel_cel_x",rel_cel_x,"rel_cel_y",rel_cel_y)
            log("extract_map_entities","cel_x",cel_x,"cel_y",cel_y)
            log("extract_map_entities","content",map_value,"type",sprite_type)
            local rel_x = rel_cel_x * 8 + sprite.cx
            local rel_y = rel_cel_y * 8 + sprite.cy
            log("extract_map_entities","inserting","relative x,y",rel_x,rel_y)
            local entity = {type=sprite_type, x=rel_x,y=rel_y}
            if sprite.from_map_init then
              sprite.from_map_init(entity)
            end
            add(v.default_entities, entity)
            log("extract_map_entities","clearing", "width,height", sprite.w,sprite.h)
            for i=0,sprite.w-1 do
              for j=0,sprite.h-1 do
                log("extract_map_entities","clearing", "cel_x,cel_y", cel_x+i,cel_y+j)
                mset(cel_x+i,cel_y+j, 0)
              end
            end
          end
        end
      end
    end
  end
end

function inject_entity(entity, screen_offset_x)
  local new_entity = clone(entity)
  new_entity.x = new_entity.x + screen_offset_x
  new_entity.ox = new_entity.x
  new_entity.oy = new_entity.y
  add(overworld_entities, new_entity)
end

__gfx__
00000000000000000000000000000002200000000000000000077700bbbbbbbb000000000000000000000bbbbbbbbbbbbbbbbbbbbbb000000000000aa0000000
0000000000770005007700050000022a922000000000000000777770b3b3b3b30000077777700000000bbbbbbbbbbbbbbbbbbbbbbbbbb00000a000a99a000a00
000000000766705007667050000029a9a9a20000000000770777777033333333000777777777700000bb333333333333333333333333bb000a9aaa9449aaa9a0
0000000000766aa000766bb00002a2a9a929200000770777777777703333333300777777777777000bb33333333333333333333333333bb000a994499449a900
000000000a474a1a0b373b1b002a9a22229a92000777777777777777333333330777777777777770bb3333333333333333333333333333bb0a994999999499a0
000000004a4a4aaa3b3b3bbb02a2a9a9a9a929206776766767766766333333337777777777777777b33e333333333333393333333333333b0994222222224990
00000000049494000313130002a922a9a922a920666666666666666033333333777777777777777733e7e3333333333397933333333383330a492259225994a0
0000000000505000005050002a9a9a22229a9a920660600606600600333333337777777777777777333e33333333333339333333333878330a492259225994a0
000aa000000000000000000029a9a9a9a9a9a9a20aa0000000000000000000007777777777777776333333333333333333333333333383330a499999999994a0
00aa9a000077000500770005222a9a922a9a92220a8a0000020220200000000007777777777777603333333333833333333333e3333333330a499999929994a0
0aa979a0076670500766705029a2292442a229a20aaa077020212202000000000677777777777600333333333878333333333e7e333333330994992229994990
0aaa9aa000766cc000766ee029a9a2444429a9a200887667002112000000000000667777777660003333333333833333333333e3333333330a994999999499a0
00aaaa000c171c1c0e878e1e2a9a9244442a9a92009a6670002112000007700000006667776000003333333333333333333333333333333300a9944994499a00
000aa0001c1c1ccc8e8e8eee02a9a2444429a9200088770000282800007557000000000677000000333333333333333333333333333333330a9aaa9449aaa9a0
0000000001212100084848000029a2444429a200409aa000020220200067760000000000670000003333333333333333333333333393333300a000a99a000a00
00000000005050000050500000022222222220000444000020000002000660000000000006000000333338333333333333333333397933330000000aa0000000
000bb00000011000000ee00000000002200000000000522224440000005888000000000044000000333387833333333333333333339333330000000080000000
00bb1b000011d10000ee4e000000022992200000000052222444000000588888888000000000000033333833333333333e333333333333330000008880000000
0bb161b0011dfd100ee4f4e0000229999992200000005222244400000088885448888000000000003333333333333333e7e33333333333330ddd088880000000
0bbb1bb00111d1100eee4ee00229999229999220000052222444000008885f444f4888800000000033333333333333333e3333333333333300ddd888ddd00000
00bbbb000011110000eeee0029999224422999920000522224440000885ffffffffff8880000000033333333333333333333333333333333000ddd2dddddd000
000bb00000011000000ee000299224444442299200005552444400005445666f456664f00000000033333333333333333333333333333333000dd222dddd0000
000000000000000000000000299244444444299200005222244400000445666f456664f00000000033333e33333333333333338333333333008822222dd00000
000000000000000000000000299244444444299200005222244400000ff5666ff5666ff0000000005333e7e33333393333333878333333330888822288d00000
000770000000000000000000299244444444299200005222444400000f45666445666f405500000035333e3333339793333333833333333500088d2d88880000
007777770000000000777700299224444442299200005552444400000f444f444f444f40000000000335333333333933333333333333535000000ddd88883000
007777777770000007555570299992244229999200005222244400000ffffff88ffffff0000000000053353333333333333333333333350000000ddd3383b000
07777777777777000700007052299992299992250000522224440000044f4488884f44f00000000000035353333333333333333333533000000000d003330000
07777777777777770677776005522999999225500005555244444000044f4485684f44f0000000000000055333333333333333333535000000000000003b0000
676776766767767700666600000552299225500000552222444444000fffff8888fffff0000000000000000533333333333333333550000000000000b0300000
666666666666666600000000000005522550000005522222224444400f444f8818444f4000000000000000005353535353535353500000000000000003300000
060660600606606000000000000000055000000055555555224444440f444f8888444f4000000000000000000535553535355530000000000000000003b00000
00005ddd000000000066600000000000000000000000000003000030000000000000000000000000000000000000000000000000000000000000000000000000
00005ddddd000000077776000000000000000000000000003b3003b3004000000000077777000000000000000000000000000000000000000000000000000000
0000dddddddd0000077777600000000000000000000000003b3333b3044000000000007557700000000000000000000000000000000000000000000000000000
000ddd88848dd000057777600000000000066600000000003bb33bb3044f00000000005775570000000000000000000000000000000000000000000000000000
00dd44444444dd00705777760000000000677766000000003bbbbbb30444f0000000000777757000000000000000000000000000000000000000000000000000
0004885666848000777777776000000006777077660000003bbbbbb3044440000000022222222700000000000000000000000000000000000000000000000000
00048856668480007777777776000000060770007766660003bbbb30004400000000022552257500000000000000000000000000000000000000000000000000
00044456664440005777777777766000677070007007076000333300000b00000000022572257500000000000000000000000000000000000000000000000000
0008845666888000055577777777760067077770707770760ee0ee00000b00000000000077767500000000000000000000000000000000000000000000000000
000884888488800000000077775777666777777777777776eeeeeee0000b00000000000772777500000000000000000000000000000000000000000000000000
0004444dd444400000000005770577775776005555555550eeeeeee00000b0000000002227775000000000000000000000000000000000000000000000000000
000488dddd848000000000057770577756676607070707000eeeee000000b0000000007777767000000000000000000000000000000000000000000000000000
000488d56d8480000000000057770575577776666666600000eee0000000b0000000755775570000000000000000000000000000000000000000000000000000
000444dddd44400000000000057770500567777777777500000e000000000b000000077557000000000000000000000000000000000000000000000000000000
000884dd1d888000000000000577770000577755555550000000000000000b000000007770000000000000000000000000000000000000000000000000000000
000884dddd888000000000000055500000055500000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000
11110111011100011110101011001111000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121012201220002121010101210222100555500b00b000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010001000000101010101010001205555550b000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010100010000001010101010100010055555500b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010100010000001010101010100010555555550b000b0003030000000000000000000000000000000000000000000000000000000000000000000000000000
01110111011101101110101010101111555555550b000b0030003000300030000000000000000000000000000000000000000000000000000000000000000000
01210122012202201210101010102122555555550b000b0030003000300030004000400000000000000000000000000000000000000000000000000000000000
01010100010000001010101010100100555555550b000b0003000300030003000400040004000400000000000000000000000000000000000000000000000000
01010100010000001010101010100100555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010100010000001010101010101200555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110111011100011110111011201111555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22220222022200022220222022002222555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033433343334333433343334333433343334333433343334333433343334333433300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
43000000000000000000000000000033000000000000320000420000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032
42000000000000000000000000000032423242324232430000334232423242324232423242324232423242324232423200000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
__label__
44442992299244444444299229924444444429922992444444442992299244444444299229924444444429922992444444442992299244444444299229924444
44422992299224444442299229922444444229922992244444422992299224444442299229922444444229922992244444422992299224444442299229922444
42299992299992244229999229999224422999922999922442299992299992244229999229999224422999922999922442299992299992244229999229999224
29999225522999922999922552299992299992255229999229999225522999922999922552299992299992255229999229999225522999922999922552299992
9992255ff55229999992255ff55229999992255ff55229999992255ff55229999992255ff55229999992255ff55229999992255ff55229999992255ff5522999
922554fffff5522992255ffffff5522992255ffffff5522992255ffffff5522992255ffffff5522992255ffffff5522992255ffffff5522992255ffffff55229
255ffffffffff552255ffffffffff552255ffffffffff552255ffffffffff552255ffffffffff552255ffffffffff552255ffffffffff552255ffffffffff552
5ffffffffffffff55ffffffffffffff55ffffffffffffff55ffffffffffffff55ffffffffffffff55ffffffffffffff55ffffffffffffff55ffffffffffffff5
2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fffffffffffffffffffffffffffffffffffffffffffffffffff2
922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff229
99922fffff11111111111111fff1111111111fff1111111111144ffffffff1111111111111ffff111fff1111fff1111111fffffff1111111111111fffff22999
2999922fff11111111111111fff1111111111fff11111111111ffffffffff1111111111111ffff111fff1111fff1111111fffffff1111111111111fff2299992
42299992ff22211112221111fff1112222222fff11112222222ffffffffff2221112222111ffff111fff1111fff1112222111ffff2222222222111ff29999224
44422992ff22211112221111f441112222222fff11112222222ffffffffff2221112222111fff4111fff1111fff1112222111ffff2222222222111ff29922444
44442992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff1115fffffffff1111222ff29924444
44442992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ffffffffff1111222ff29924444
44442992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111ff41111fff111ffff111ffffff44ff1111fffff29924444
44422992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ffffffffff1111fffff29922444
42299992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ffffffffff1111fffff29999224
29999225fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ffffffffff1111fffff52299992
9992255ffffff11111111111fff1111111111fff11111111111fff1111111fff1111111111ffff111fff1111fff111ffff111ffff1111111111111fff5522999
92255ffff44ff11111111111fff1111111111fff11111111111fff1111111fff1111111111ffff111fff1111f55111ffff111ffff1111111111111fffff55229
255ffffffffff11112221111fff1112222222fff11112222222fff2222222fff1112222111ffff111fff1111fff111ffff111ffff2221112222222fffffff552
5ffffffffffff11112221111fff1112222222fff11112222222fff2222222fff1112222111ffff111fff1111fff111ffff111ffff2221112222222fffffffff5
2ffffffffffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ff44fff111ffffffffffffffff2
922ffffffffff1111fff1111fff111ffff55ffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111fffffff111ffffffffffffff229
99922ffffffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111fffffff111ffffffffffff22999
2999922ffffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111fffffff111ffffffffff2299992
42299992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111ff4111ffff111ffff111222fffffffff29999224
44422992fffff1111fff1111fff111ffffffffff1111ffffffffffffffffffff111ffff111ffff111fff1111fff111ffff111ffff111222fffffffff29922444
44442992ff11111111111111fff1111111111fff11111111111ffffffffff1111111111111ffff1111111111fff1111111222ffff1111111111111ff29924444
44442992ff11111111111111fff1111111111fff11111111111ffffffffff1111111111111ffff1111111111fff1111111222ffff1111111111111ff29924444
44442992ff22222222222222fff2222222222fff22222222222ffffffffff2222222222222ffff2222222222f777777222fffffff2222222222222ff29924444
44422992ff22222222222222fff2222222222fff22222222222ffffffffff2222222222222ffff22222222277777777772fffffff2222222222222ff29922444
42299992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff777777777777ffffffffffffffffffffff29999224
29999225fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77777711777777fffffffffffffffffffff52299992
9992255fff1111111111111111111111111111111111111111111111111111111111111111111111111177777711d1777777111111111111111111fff5522999
92255fffff111111111111111111111111111111111111111111111111111111111111111111111111117777711dfd177777111111111111111111fffff55229
255fffffff2222222222222222222222222222222222222222222222222222222222222222222222222277777111d1177777222222222222222222fffffff552
5fffffffff222222222222222222222222222222222222222222222222222222222222222222222222227777771111777776222222222222222222fffffffff5
2fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fffffffffffffffff77777711777776ffffffffffffffffffffff44ffff2
922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ffffff6777777777776fffffffffffffffffffffffffff229
99922ffffffffffffffffffffffffffffffff44fffffffffffffffffffffffffffffffffffffffffffffff66777777766ffffffffffffffffffffffffff22999
2999922fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6667776ffffffffffffffffffffffffff2299992
42299992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff677ffffffffffffffffffffffffff29999224
44422992fffffffffffffffffffffffffffffffffffffffffff44ff55fffffffffffffffffffffffffffffffffff67ffffffffffffffffffffffffff29922444
44442992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6ffffffffffffffffffffffffff29924444
44442992ffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29924444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29924444
44422992ffffffffffffffffffffffffffffffffffffffffffffffff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
42299992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77fff5fffffffffffffffffffff29999224
29999225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7667f5ffffffffffffffffffffff52299992
9992255ffffffffffffffffffffffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffff766ccfffffffffffffffffffffff5522999
92255fffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc171c1cffffffffffffffffffffffff55229
255ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1c1c1cccffffffffffffffffffffffffff552
5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12121ffffffffffffffffffffffffffffff5
2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5f5fffffffffffffffffffffffffffffff2
922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff229
99922fffffffffffffffffffffffffffff8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22999
2999922fffffffffffffffffffffffff888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ffffffffffffffffffffffffff2299992
42299992fffffffffffffffffffdddf8888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29999224
44422992ffffffffffffffffffffddd118dddfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
44442992fffffffffffffffffffffd11d1dddddfffffffffffffffffffffffff55ffffffffffffffffffff44fffffff22fffffffffffffffffffffff29924444
44442992fffffffffffffffffffff11dfd1dddfffffffffffffffffffffffffffffffffffffffffffffffffffffff229922fffffffffffffffffffff29924444
44442992ffffffffffffffffffff8111d11ddffffffffffffffffffffffffffffffffffffffffffffffffffffff2299999922ffffffffffff55fffff29924444
44422992fffffffffffffffffff888111188dffffffffffffffffffffffffffffffffffffffffffffffffffff22999922999922fffffffffffffffff29922444
42299992fff55ffffffffffffffff8811d8888ffffffffffffffffffffffffffffffffffffffffffffffffff2999922442299992ffffffffffffffff29999224
29999225fffffffffffffffffffffffddd88883fffffffffffffffffffffffffffffffffffffffffffffffff2992244444422992ffffffffff44ffff52299992
9992255ffffffffffffffffffffffffddd3383bffffffffffffffffffffffffffffffffffffff55fffffffff2992444444442992fff55ffffffffffff5522999
92255fffffffffffffffffffffffffffdff333fffffff55ffffffffffffffff44fffffffffffffffffff44ff2992444444442992fffffffffffffffffff55229
255fffffffffffffffffffffffffffffffff3bffffffffffffffffffffffffffffffffffffffffffffffffff2992444444442992fffffffffffffffffffff552
5fffffffffffffffffffffffffffffffffbf3fffffffffffffffffffffffffffffffffffffffffffffffffff2992244444422992fffffffffffffffffffffff5
2ffffffffffffff44ffffffffffffffffff33fffffffffffffffffffffffffffffffffffffffffffffffffff2999922442299992fffffffffffffffffffffff2
922ffffffffffffffffffffffffffffffff3bfffffffffffffffffffffffffffffffffffffffffffffffffff5229999229999225fffffffffffffffffffff229
99922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55229999992255ffffffffffffffffffff22999
2999922fffffffffffff55fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5522992255ffffffffffffffffffff2299992
42299992ffffffff44fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff552255fffffffffffffffffffff29999224
44422992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fffffffffffffffffffffff29922444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ffffffffffffff29924444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55ffffffffffffffffffffffffff29924444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29924444
44422992ffffffffffffffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
42299992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29999224
29999225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff52299992
9992255fffffffffff44fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5522999
92255ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55229
255ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff552
5fffffffffffffffffffffffffffffffffff77fff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fffffffffffffffffffffffffff5
2ffffffffffffffffffffffffffffffffff7667f5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
922fffffffffffffffffffffffffffffffff766aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff229
9992244ffffffffffffffffffffffffffffa474a1affffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fffff22999
2999922fffffffffffffffffffffffffff4a4a4aaafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2299992
42299992fffffffffffffff44ffffffffff49494fffffffffffffffffffffffff44fffffffffffffffffffffffffffffffffffffffffffffffffffff29999224
44422992ffffffffffffffffffffffffffff5f5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29924444
44442992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fffffffffffffffffffffff29924444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffff55ff29924444
44422992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
42299992ffffffffffffffffffffffff111f111f111ff11ff11fffff1f1fffff111ff11fffff111f111ff11f111f11ffffffffffffffffffffffffff29999224
29999225ffffffffffffffffffffffff1f1f1f1f1fff1fff1ffff5551f1ffffff1ff1f1fffff1f1f1fff1ffff1ff1f1fffffffffffffffffffffffff52299992
9992255fffffffffffffffffffffffff111f11ff11ff111f11144ffff1fffffff1ff1f1fffff11ff11ff1ffff1ff1f1ffffffffffffffffffffffffff5522999
92255fffffffffffffffffffffffffff1fff1f1f1fffff1fff1fffff1f1ffffff1ff1f1fffff1f1f1fff1f1ff1ff1f1ffffffffffffffffffffffffffff55229
255fffffffffffffffffffffffffffff1fff1f1f111f11ff11ffffff1f1ffffff1ff115fffff111f111f111f111f1f1ffffffffffffffffffffffffffffff552
5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
2ffffffffffffffffffffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff229
99922ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22999
2999922fffffffffffffffffffffffffffffffffffffffffffffffffff55fffffffffffffffffffffffffffff44ffffffffffffffffffffffffffffff2299992
42299992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29999224
44422992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29922444
44442992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29924444
4444299244ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ffffffffffffffffff29924444
44442992fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fffffffffffffffffffffffff29924444
44422992ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555fffffffffffffffffff44ffffffffffffffffffffffffffffff29922444
42299992ffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff29999224
29999225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5552299992
9992255ffffffffffff55ffffffffffffffff55ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5522999
92255ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55229
255ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff552
5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
2ffffffffffffff22ffffffffffffff22ffffffffffffff22ffffffffffffff22ffffffffffffff22ffffffffffffff22ffffffffffffff22ffffffffffff552
922ffffffffff229922ffffffffff229922ffffffffff229922ffffffffff229922ffffffffff229922ffffffffff229922ffffffffff229922ffffffffff229
99922ffffff2299999922ffffff2299999922ffffff2299999922ffffff2299999922ffffff2299999922ffffff2299999922ffffff2299999922ffffff22999
2999922ff22999922999922ff22999922999922ff22999922999922ff22999922999922ff22999922999922ff22999922999922ff22999922999922ff2299992
42299992299992244229999229999224422999922999922442299992299992244229999229999224422999922999922442299992299992244229999229999224
44422992299224444442299229922444444229922992244444422992299224444442299229922444444229922992244444422992299224444442299229922444
44442992299244444444299229924444444429922992444444442992299244444444299229924444444429922992444444442992299244444444299229924444
44442992299244444444299229924444444429922992444444442992299244444444299229924444444429922992444444442992299244444444299229924444

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a0b0c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c0d00000000000000
000000000000001a1b1c1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1b1c1d00000000000000
000000000000002a2b2c2d000000000000000000000000000000000000000000000000000000000000000a0b0c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b0c0d2a2b2c2d00000000000000
000000000000003a3b3c3d0000000000000000000000000000000000000000000000000000000a0b0c0d1a1b1c1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1b1c1d3a3b3c3d00000a0b0c0d00
00000000000000002526000000000000000000000000000000000000000000000000000000001a1b1c1d2a2b2c2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a2b2c2d0025260000001a1b1c1d00
00000000000000002526000000000000000000000000000000000000000000000000000000002a2b2c2d3a3b3c3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a3b3c3d0025260000002a2b2c2d00
00000000000000002526000000000000000000000000000000000000000000000000000000003a3b3c3d0025260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002526000025260000003a3b3c3d00
0000000000000000252600000000000000000000000000000000000000000000000000000000002526000025260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002526000025260000000025260000
000000000000000025260000000000000000000000002e2f002e2f2e2f000000000000000000002526000025260000000000000000272840412728404140410000002e2f0000002e2f00000000002e2f000000002e2f2e2f000000002e2f00000000000040412728404100002728272800002526000025260000000025260000
656565656565650035360065656565656565656565653e3f653e3f3e3f656565656565656565003536656535360065656565656500373850513738505150516565653e3f6565653e3f65656565653e3f656565653e3f3e3f656565653e3f65656565650050513738505165653738373800653536650035360065650035360065
0707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004445000000424300000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004243005455004243525300000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005253000000005253000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a0b0c0d0000000a0b0c0d0000000000000a0b0c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001a1b1c1d0000001a1b1c1d0000000000001a1b1c1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002a2b2c2d0000002a2b2c2d0000000000002a2b2c2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003a3b3c3d0000003a3b3c3d0000000000003a3b3c3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002526000000000025260000000000000000252600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002526000000000025260000000000000000252600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e2f002526002e2f0000252600404100002e2f002526002e2f00000027284041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e3f653536003e3f6565353600505165653e3f653536653e3f65656537385051000000000000000000000000000000000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707
__sfx__
00060000061200612008120081200812006120081200a120081200812008120081200812006120061200612006120061200812008120081200a1200a1200a1200a1200a120081200812008120081200812008120
010e00000d22019200162001410017220171001610015100162202410024100231000d2001b200171001510023200232002470000000000000000000000222002120023200212001b200192001b2001920000000
010e00000000000000196230d6000d60000000196240d6000d600000001962300000196000000019623000000d6000000019623000000d6000000019624000000d6000000019623000000d600000001962300000
000e0000192240d200192240d200192240d200192240120020224000002022401200202240120020224012001e224002001e224002001e224002001e224002002322403200232240f20022224032002222403200
000e00003d6000000400000000003d6250000000000000003d6003d6003d600000003d625000003d600000003d6000000400000000003d6250000000000000003d625000043d625000003d6003d6003d6003d600
000e00000d2201920016200141001722017100161001510016220241002410023100172001b22017100151001670023200247000000000000000000000000000232002120023210212101b210192101b21019210
0003000023e4423e4022e401fe4021e3020e301fe301ee301ce301ae3017e4014e4010e3010e30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000161301b1301e1302bf302ef3034f3009100061000710009100071000a100091000810009100091000810008100071000a10008100081000a10008100081000710009100071000a100081000910009100
0002000031120291201e12017120141200e12009120041202bb0022b001bb0011b000ab0004b0001b002a300263001c3000f3000830002b000bd0005d0001d0001d0001d0001d000000000000000000000000000
000e000000000000002350000000235522355223552235522255222552225522255223552235521b5521b5521b5521b5521955219552195521955219552195520000000000000000000000000000000000000000
010e00000d2201920016200141001722017100161001510016220241002410023100172001b22017100151002321023200232100000000000000000000000000222102120022210212001b200192002021019200
010e00000d2100d2000d2100d2000d2100d2000d21001200142100000014210012001421001200142100120017210032001721000200172100320017210002001221000200122100f20012210002001221003200
001800200615006150081500815006140061400a1400a1500815006150061500615006140061000614006100061500615008140091400915009140091500b1300b1500b1400b1401015010140101500b1500b150
000e0020061500610006150081000610006100061500a1000d150061000d1500610006100061000d15006100041500610004150091000910009100041500b1000b150061000b1501010010100101000315002100
000e00003d6000000400000000003d6150000000000000003d6003d6003d600000003d615000003d600000003d6000000400000000003d6003d60000000000003d615000043d615000003d6003d6003d60000000
000e000000000000002353422532205321e53220532205322353222532205321e5322053220532205002053400000000002353422532205321e53220532205322353222532205321e53225532255322050025534
000e000000000000002f5222e5222c5222a5222c5222c5222f5222e5222c5222a5222c5222c522205002c52200000000002f5222e5222c5222a5222c5222c5222f5222e5222c5222a52231522315222050031522
0006000006140061400813008130071300613007140091400814007140071400813008130061300613006130061400613007130081300814009130091300a1400914009150081400813008140071300713007150
000e00000000000000235000000023532235322353223532225322253222532225322353223532205322053220532205321e5321e5321e5321e5321e5321e5320000000000000000000000000000000000000000
000e00000000000000000000000027532275322753227532255322553225532255322753227532235322353223532235322253222532225322253222532225322250022500000000000000000000000000000000
000e000000000000002354222542205421e54220542205422354222542205421e5422054220542205002054200000000002354222542205421e54220542205422354222542205421e54225542255422050025542
000e000000000000000000000000275322753227532275322553225532255322553227532275322c5322c5322c5322c5322a5322a5322a5322a5322a5322a5322250022500000000000000000000000000000000
000e000000000000002350000000235322353223532235322253222532225322253223532235321b5321b5321b5321b5321953219532195321953219532195320000000000000000000000000000000000000000
000e00003d6000000400000000003d6150000000000000003d6003d6003d600000003d615000003d600000003d6000000400000000003d6153d60000000000003d600000043d600000003d6153d6003d61500000
000e0000192140d200192140d200192140d200192140120020214000002021401200202140120020214012001e214002001e214002001e214002001e214002001b225272251b2252722519225252251922525225
010600003d6000000400000000003d6000000000000000003d6003d6003d600000003d600000003d600000003d6150000000000000003d6003d60000000000003d600000043d600000003d6003d6003d60000000
000600001e4161e4001e4161b4001e4161b4001e4161b4001f3001f30023400234002340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001f3242340023400233002340023400234001b3001b3242340023400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000f4161b4001b4161b4001b4161b4001b4161b4001f3001f30023400234002340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800001903019000190301900022030220302203022030220001700017000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800001b0301b0001b0301b0001b000200302003020030200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800001e0301e0001e0301e0001e0001e0001b0501b0501b0001b0001b0001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800002203022000220302200022000220002200017050170001700017000170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00380020121301713016000130001013017130061000a1000f130171300d1001210019130121300d10012100121301713016000130001013017130061000a1001b130171300d1001210019130121300d10017100
003800002352222522205221e522205222052220500205002352222522205221e522255222552225500235002352422522205221e522205222050020500235002352222522205221e52225522255222550000000
00380000285252752525525235252552525500255002e505285252752525525235252a5252c5002a5252a500285252752525525235252552525500255002e505285252752525525235252a5252a5002a5252c525
002000003d6000000400000000003d6150000000000000003d6003d6003d600000003d615000003d600000003d6000000400000000003d6153d60000000000003d600000043d600000003d6153d6003d61500000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00003d6000000400000000003d6150000000000000003d6003d6003d600000003d615000003d600000003d6000000400000000003d6153d60000000000003d600000043d600000003d6153d6003d61500000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000027334273522340023400233002340023400234002b3542b35223400234002340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01020b04
00 0a020309
00 01020b04
02 05020309
03 00424344
03 0d0e100f
01 0d175255
00 0d0e5254
01 0d171253
00 0d171653
00 0d171213
00 0d0e1615
00 0d171055
00 0d171055
00 0d17100f
00 0d17100f
00 0d170355
00 0d171855
00 0d170355
02 0d171855
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 00191c44
00 41424344
00 1d1e1f20
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 21222364
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 00594344
00 00594344
00 00594344
00 00594344
01 00191a44
00 00191b44
00 00191c44
02 00191c44

