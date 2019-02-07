pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

gravity = 0.2
xmove = 0
ymove = 0
cam_x = 0
enemy_x = 0
star_x = 150
enemy_collide = false
you_win = false
player_disable_counter = 0
hearts = {}
enemies = {}
stars = {}
star_timer = 0
enemy_timer = 0
enemy_spawn_time = 120
star_spawn_time = 90
max_x = 992
max_sprites = 2
frame_change_number = 10
blue_check_sprite = 64
red_check_sprite = 65
reposition_y = 0

ground = {
    x = 0,
    y = 104,
    w = 128,
    h = 128,
}

function _init()
    music(0)
    local player_speed = 1
    -- local player_speed = 10

    player = make_entity("player", 1, 24, ground.y-8, 8, 8, player_speed, 2.8)
    matty = make_entity("matty", 5, 961, ground.y-8, 8, 8, 1, 1)
    charlie = make_entity("charlie", 3, 952, ground.y-8, 8, 8, 1, 1)
end

function make_entity(_type, _sprite, _x, _y, _w, _h, _speed, _jump_speed)
    local _start_sprite = _sprite

    local entity = {
        type = _type,
        sprite = _sprite,
        start_sprite = _start_sprite,
        x = _x,
        y = _y,
        w = _w,
        h = _h,
        frame = 0,
        speed = _speed,
        jump_speed = _jump_speed,
        jumping = false,
        -- grounded = true,
    }

    return entity
end

function make_heart(_x, _y)
    local heart = make_entity("heart", 11, _x, _y, 8, 8, 1, 1)

    if rnd(1) >= 0.95 then
        add(hearts, heart)
    end
end

function make_enemy()
    local enemy_x = player.x + 128

    if enemy_x > max_x then
        enemy_x = max_x
    end

    local enemy = make_entity("enemy", 7, enemy_x, ground.y - 8, 8, 8, 0.75, 1)

    return enemy
end

function make_star()
    local star_x = player.x + 128

    if star_x > max_x then
        star_x = max_x
    end

    local star = make_entity("enemy", 9, star_x, ground.y-8-16, 8, 8, 1.75, 1)

    return star
end

function update_enemies()
    if enemy_timer > enemy_spawn_time then
        add(enemies, make_enemy())
        enemy_timer = 0
    end

    for enemy in all(enemies) do
        update_frames(enemy)

        enemy.x = enemy.x - enemy.speed
    end
end

function update_frames(entity)
    entity.frame = entity.frame + 1

    if entity.frame > frame_change_number then
        entity.sprite = entity.sprite + 1
        entity.frame = 0

        if entity.sprite >= (entity.start_sprite + max_sprites) then
            entity.sprite = entity.start_sprite
        end
    end
end

function update_stars()
    if star_timer > star_spawn_time then
        add(stars, make_star())
        star_timer = 0
    end

    for star in all(stars) do
        update_frames(star)

        star.x = star.x - star.speed
    end
end

function update_hearts()
    for heart in all(hearts) do
        update_frames(heart)

        heart.x = heart.x + (rnd(8) - 4)
        heart.y = heart.y - heart.speed
    end
end


function _update()
    xmove = 0

    if you_win == false then
        star_timer = star_timer + 1
        enemy_timer = enemy_timer + 1
    end

    if enemy_collide == true then
        player_disable_counter = player_disable_counter + 1
        player.sprite = 17
    else
        update_frames(player)
        get_input()
    end

    if player_disable_counter >= 60 then
        enemy_collide = false
        player_disable_counter = 0
    end

    update_hearts()
    update_stars()
    update_enemies()
    update_frames(charlie)
    update_frames(matty)


    local collide_x = did_collide_x()
    local collide_y = did_collide_y()
    local block_below = is_ground_below()

    if collide_x == false then
        player.x = player.x + xmove
    end

    if collide_y == false then
        if (block_below == true and ymove < 0) or block_below == false then
            ymove = ymove + gravity

            player.y = player.y + ymove
        end

        if block_below == true and ymove > 0 then
            reset_player_jump()
        end
    else
        reset_player_jump()
    end

    update_camera()
end

function reset_player_jump()
    ymove = 0
    player.jumping = false

    reposition_y = player.y / 8
    local get_decimals = reposition_y - flr(reposition_y)

    if get_decimals < 0.5 then
        player.y = flr(player.y / 8) * 8
    else
        player.y = ceil(player.y / 8) * 8
    end
end

function update_camera()
    cam_x = player.x - 32
    cam_y = player.y - 96

    if cam_x < 0 then
        cam_x = 0
    end

    if cam_x > 880 then
        cam_x = 880
    end

    if cam_y < 0 then
        cam_y = 0
    end

    if cam_y > 880 then
        cam_y = 880
    end

    camera(cam_x, cam_y)
end

function get_input()
    if btn(0) then
        xmove = -player.speed
    end

    if btn(1) then
        xmove = player.speed
    end

    if btn(2) and (player.jumping == false) then
        ymove = -player.jump_speed

        player.jumping = true
    end
end

function did_collide_x()
    local collide_x = false

    if player.x + xmove < 8 or player.x + xmove > max_x then
        collide_x = true
    end

    for enemy in all(enemies) do
        if did_collide_with(enemy) then
            collide_x = true
            enemy_collide = true
        end
    end

    for star in all(stars) do
        if did_collide_with(star) then
            collide_x = true
            enemy_collide = true
        end
    end

    if did_collide_with(matty) or did_collide_with(charlie) then
        you_win_dude()
    end

    if xmove > 0 and will_hit_block_x() then
        collide_x = true
    end

    return collide_x
end

function you_win_dude()
    you_win = true
    enemies = {}
    stars = {}
    star_timer = 0
    enemy_timer = 0
end

function did_collide_with(enemy)
    if (player.x < enemy.x + enemy.w) and (player.x + player.w > enemy.x) and (player.y < enemy.y + enemy.h) and (player.y + player.h > enemy.y) then
        return true
    end

    return false
end

function will_hit_block_x()
    local cell_size = 8
    local next_x = nil

    if xmove > 0 then
        next_x = player.x + player.w + xmove
    else
        next_x = player.x + xmove
    end

    local block_x = mget(flr(next_x / cell_size), flr(player.y / cell_size))

    local x_is_solid = fget(block_x, 3)

    return x_is_solid
end

function is_ground_below()
    local cell_size = 8
    local below_y = player.y + player.h

    local block_below = mget(flr(player.x / cell_size), flr(below_y / cell_size))
    local is_block_below = fget(block_below, 3)

    return is_block_below
end

function will_hit_block_y()
    local cell_size = 8
    local next_y = nil

    if ymove > 0 then
        next_y = player.y + player.h + ymove
    else
        next_y = player.y + ymove
    end

    local block_y = mget(flr(player.x / cell_size), flr(next_y / cell_size))
    local block_y_right = mget(flr(player.x / cell_size) + 1, flr(next_y / cell_size))
    local y_is_solid = fget(block_y, 3)
    local y_right_is_solid = fget(block_y_right, 3)

    return y_is_solid or y_right_is_solid
end

function did_collide_y()
    local collide_y = false

   if ymove != 0 and will_hit_block_y() then
        collide_y = true
    end

    -- if player.grounded == false then
    --     if (player.y + player.h + ymove) >= ground.y then
    --         collide_y = true
    --     end
    -- end

    return collide_y
end

function debug_info()
    debug_y_pos = 18
    debug_x_pos = 10

    debug_print("cam_y: " ..cam_y)
    -- debug_print("ymove: " .. ymove)
    -- debug_print("block_below: " .. (block_below and "true" or "false"))
    -- debug_print("jumping: " .. (player.jumping and "true" or "false"))
    -- debug_print("y: " .. player.y)
    -- debug_print("ceil: " ..ceil(player.y / 8) * 8)
    -- debug_print("repos_y: " ..reposition_y)
    -- print("cam_x, 0: " .. cam_x .. ", 0", cam_x + 10, 10, 11)
    -- print("y: " .. player.y, cam_x + 10, 30, 7)
    -- print("y / 8: " ..(player.y / 8), cam_x + 10, 36, 7)
    -- print("flr: " ..flr(player.y / 8) * 8, cam_x + 10, 36, 7)
    -- print("ymove: " .. ymove, cam_x + 10, 36, 7)
    -- print("jumping: " .. (player.jumping and "true" or "false"), cam_x + 10, 42, 7)
    -- print("cam_x: " .. cam_x .. " / " .. (cam_x / 16), cam_x + 10, 40)
end

function debug_print(wat)
    debug_y_pos = debug_y_pos + 6

    print(wat, cam_x + debug_x_pos, debug_y_pos, 7)
end

function draw_background()
    rectfill(cam_x, 0, cam_x + 127, 128, 1)
    map(0, 16, 0, 0, 128, 16, 0)

    -- for y = 0, 2, 1 do
    --     for x = 0, 30, 1 do
    --         sspr(0, 32, 32, 32, 8 * (x * 4) + 8, 8 * (y * 4) + 8)
    --     end
    -- end
end

function _draw()
    cls(0)
    draw_background()

    draw_player()

    draw_scene()
    draw_matty_and_charles()
    draw_hearts()

    if you_win == false then
        draw_cage()
        draw_enemies()
        draw_stars()
    end

    draw_foreground()

    if you_win == true then
        draw_winning_things()
    end

    debug_info()
end

function draw_cage()
    spr(18, charlie.x - 8, charlie.y - 8) -- cage left top
    spr(19, charlie.x, charlie.y - 8) -- cage middle top
    spr(19, matty.x - 1, matty.y - 8) -- cage middle top
    spr(20, matty.x + 8 - 1, matty.y - 8) -- cage right top

    spr(34, charlie.x - 8, charlie.y) -- cage left bottom
    spr(35, charlie.x, charlie.y) -- cage middle bottom
    spr(35, matty.x - 1, matty.y) -- cage middle bottom
    spr(36, matty.x + 8 - 1, matty.y) -- cage right bottom
end

function draw_matty_and_charles()
    spr(matty.sprite, matty.x, matty.y)
    spr(charlie.sprite, charlie.x, charlie.y)
end

function draw_stars()
    for star in all(stars) do
        spr(star.sprite, star.x, star.y)
    end
end

function draw_enemies()
    for enemy in all(enemies) do
        spr(enemy.sprite, enemy.x, enemy.y)
    end
end

function draw_hearts()
    for heart in all(hearts) do
        spr(heart.sprite, heart.x, heart.y)
    end
end

function draw_player()
    local flip_x = xmove < 0

    spr(player.sprite, player.x, player.y, 1, 1, flip_x)
end

function draw_scene()
    local cell_size = 16

    map(0, 0, 0, 0, 128, 16, 1)
end

function draw_foreground()
    map(0, 0, 0, 0, 128, 16, 4)
end

function draw_winning_things()
    local yy = 38

    make_heart(matty.x + 4, matty.y - 8)
    make_heart(charlie.x + 4, charlie.y - 8)

    rectfill(cam_x, yy - 1, cam_x + 128, yy + 16 + 1, 8)
    rectfill(cam_x + 1, yy, cam_x + 126, yy + 16, 14)
    print("you found matty and charlie!", cam_x + 4, 40, 0)
    print("we love you, our queen!!! <3", cam_x + 4, 48, 0)
end

__gfx__
00000000000909000000000005555500000000000004400000440000499999940000000000090000a0a0a0900800080000080000177717770000000000000000
00000000000398000009090076557650055555000004440000444000bbbb99404999999400a990000aaa99008880888000080000156715670000000000000000
007007000aafaaa00003980065456550765576500004444000444440b8bbb999bbbb99400a0a0900aaa099908888878000070000155515550000000000000000
00077000aaff4f400aafaaa06656650065456550000cfcf0000cfcf03bbbb3bbb8bbb999aaa099900a0009008888878000080000111111110000000000000000
000770000a3ffff0aaff4f400777755566566500000ffff0000ffff0bbbb43bb3bbbb3bb0a090900aaa099900888880000080000771777170000000000000000
00700700aaee88990a3ffff0677775050777755500422f200002222030433bbbbbbb43bb00a990000aa999000088800000080000671567150000000000000000
00000000ae877d60aaee889906000500677775050002222000422f2033440bb430433bbb00090000a09090900088800000080000551555150000000000000000
0000000008888880ae877d600600050006000500000400f0000400f0033000bb33440bb400000000000000000008000000080000111111110000000000000000
0000000000000900555566666666666666667777000505000000dd00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a4896805006006006006006006007000055500000ddd0000ddddd00000000000000000000000000000000000000000000000000000000000000000
0000000098a888d80500600600600600600600700dd6ddd000dddd000d57dd570000000000000000000000000000000000000000000000000000000000000000
0000000009a48878050060060060060060060070dd665650007575000dd6d0d60005d00000000000000000000000000000000000000000000000000000000000
0000000093888e780500600600600600600600700d5666600077770000d66d6600567d0000000000000000000000000000000000000000000000000000000000
0000000000a83e88050060060060060060060070dd775566005755d0ddd77770056666d000000000000000000000000000000000000000000000000000000000
0000000000aaaae8050060060060060060060070d7577d6000555500d0d7777600566d0000000000000000000000000000000000000000000000000000000000
00000000000a0aa00500600600600600600600700dddddd000700d0000d000500005d00000000000000000000000000000000000000000000000000000000000
000000000000000005006006006006006006007005566770055667705555777755557777005dd600005dd600055dd660055dd660000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000000000000000000
00000000000000005555600600600600600600775555777705566770055667705555777705556660005dd600005dd600055dd660000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555666666666666
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052222222255662222222260
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222255662222222600
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555666666666600
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222e22222222226600
2211221100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222ee222222e2226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee222222ee2226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522ee222222ee22226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222222ee222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222ee2222226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222222ee22222226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222ee222222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222ee22222ee226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222ee22222ee2226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee22222ee22226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222222222e222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555666666666600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222255662222222600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052222222255662222222260
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555666666666666
__gff__
000000000000000000000000000b000000000000000606060600000000000000000000000006060606060606060000000000000000000000000000000000000000000000000000000000000000060606000000000000000000000000000606060000000000000000000000000006060600000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d000000000000000000000000000027002700000000000000000000000000270000000000000000000000000000002700270000000000000000000000000027000000000000000000000000000000270027000000000000000000000000002700000000000000000000000000002700270000000000000000000000000d0d0d
0d000000000000000000000000000026002600000000000000000000000000260000000000000000000000000000002600260000000000000000000000000026000000000000000000000000000000260026000000000000000000000000002600000000000000000000000000002600260000000000000000000000000d0d0d
0d000000000000000000000000000027002700000000000000000000000000270000000000000000000000000000002700270000000000000000000000000027000000000000000000000000000000270027000000000000000000000000002700000000000000000000000000002700270000000000000000000000000d0d0d
0d000000000000000000000000000026002600000000000000000000000000260000000000000000000000000000002600260000000000000000000000000026000000000000000000000000000000260026000000000000000000000000002600000000000000000000000000002600260000000000000000000000000d0d0d
0d000000000000000000000000000025002500000000000000000000000000250000000000000000000000000000002500250000000000000000000000000025000000000000000000000000000000250025000000000000000000000000002500000000000000000000000000002500250000000000000000000000000d0d0d
0d000000000000160000000000000026002600000000000017000000000000260000000000000015000000000000002600260000000000001600000000000026000000000000001700000000000000260026000000000000150000000000002600000000000000001600000000002600260000000000000000000000000d0d0d
0d000000000000280000000000000026002600000000000028000000000000260000000000000028000000000000002600260000000000002800000000000026000000000000002800000000000000260026000000000000280000000000002600000000000000002800000000002600260000000000000000000000000d0d0d
0d00000000000026000000000d000025002500000000000026000000000000250000000000000026000000000000002500250000000000002600000000000025000000000000002600000000000000250025000000000000260000000000002500000000000000002600000000002500250000000000000000000000000d0d0d
0d0d0000000000250000000d0d000026002600000000000025000000000000260000000000000025000000000000002600260000000000002500000000000026000000000000002500000000000000260026000000000000250000000000002600000000000000002500000000002600260000000000000000000000000d0d0d
0d0d0d00000000250000000d0d0d0025002500000000000025000000000000250000000000000025000000000000002500250000000000002500000000000025000000000000002500000000000000250025000000000000250000000000002500000000000000002500000000002500250000000000000000000000000d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b000000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000
00000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a000000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000
00000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b000000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000
00000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a000000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000
0000000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f00002a00000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f00002a00000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f0000002a00000000004d4e4f00000000002a002a00004d4e4f00004d4e4f00000000
0000000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f00002b00000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f00002b00000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f0000002b00000000005d5e5f00000000002b002b00005d5e5f00005d5e5f00000000
0000000000186d6e6f18000000002a002a00006d6e6f00180018006d6e6f00002a00000000186d6e6f18000000002a002a00006d6e6f00180018006d6e6f00002a00000000186d6e6f18000000002a002a00006d6e6f00180018006d6e6f0000002a00000000186d6e6f18000000002a002a00006d6e6f00006d6e6f00000000
00000000002c0000002c000000002a002a0000000000002c002c0000000000002a000000002c0000002c000000002a002a0000000000002c002c0000000000002a000000002c0000002c000000002a002a0000000000002c002c000000000000002a000000002c0000002c000000002a002a0000000000000000000000000000
00000000002a0000002a000000002b002b0000000000002a002a0000000000002b000000002a0000002a000000002b002b0000000000002a002a0000000000002b000000002a0000002a000000002b002b0000000000002a002a000000000000002b000000002a0000002a000000002b002b0000000000000000000000000000
0000000000290000002900000000290029000000000000290029000000000000290000000029000000290000000029002900000000000029002900000000000029000000002900000029000000002900290000000000002900290000000000000029000000002900000029000000002900290000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001200001205000000120500000012050000001205000000130500000013050000001305000000130500000015050000001505000000150500000015050000001705000000170500000017050000001705000000
001200001e7321e1321e7321e132000000000000000000001f7321f1321f7321f13200000000000000000000211322113221132211321f1321f1321f1321f1322373223132237322313200000000000000000000
001200000000000000000000663500000000000663506200000000000006600000000000006635000000663500000000000000006635000000000006635062000000000000066000000000000066350663506635
__music__
00 01024344
01 01024344
00 01024344
00 01020344
02 01020344

