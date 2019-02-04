pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

gravity = 0.5
xMove = 0
yMove = 0
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
ENEMY_SPAWN_TIME = 120
STAR_SPAWN_TIME = 90
MAX_X = 992
MAX_SPRITES = 2
FRAME_CHANGE_NUMBER = 10
blue_check_sprite = 64
red_check_sprite = 65

ground = {
    x = 0,
    y = 104,
    w = 128,
    h = 128,
}

function _init()
    -- local player_speed = 1.25
    local player_speed = 10

    player = make_entity("player", 1, 24, ground.y - 8, 8, 8, player_speed, 5)
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

    if enemy_x > MAX_X then
        enemy_x = MAX_X
    end

    local enemy = make_entity("enemy", 7, enemy_x, ground.y - 8, 8, 8, 0.75, 1)

    return enemy
end

function make_star()
    local star_x = player.x + 128

    if star_x > MAX_X then
        star_x = MAX_X
    end

    local star = make_entity("enemy", 9, star_x, ground.y-8-16, 8, 8, 2, 1)

    return star
end

function update_enemies()
    if enemy_timer > ENEMY_SPAWN_TIME then
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

    if entity.frame > FRAME_CHANGE_NUMBER then
        entity.sprite = entity.sprite + 1
        entity.frame = 0

        if entity.sprite >= (entity.start_sprite + MAX_SPRITES) then
            entity.sprite = entity.start_sprite
        end
    end
end

function update_stars()
    if star_timer > STAR_SPAWN_TIME then
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
    -- update_stars()
    -- update_enemies()
    update_frames(charlie)
    update_frames(matty)


    local collide_x = did_collide_x()
    local collide_y = did_collide_y()

    if collide_x == false then
        player.x = player.x + xMove
    end

    if collide_y == false then
        if (player.grounded == false) then
            yMove = yMove + gravity

            player.y = player.y + yMove
        end
    elseif collide_y == true then
        yMove = 0

        player.grounded = true
        player.jumping = false
        player.y = (ground.y - player.h)
    end

    xMove = 0

    update_camera()
end

function update_camera()
    cam_x = player.x - 32

    if cam_x < 0 then
        cam_x = 0
    end

    if cam_x > 880 then
        cam_x = 880
    end

    camera(cam_x, 0)
end

function get_input()
    if btn(0) then
        xMove = -player.speed
    end

    if btn(1) then
        xMove = player.speed
    end

    if btnp(2) and (player.jumping == false) then
        yMove = -player.jump_speed

        player.jumping = true
        player.grounded = false
    end
end

function did_collide_x()
    local collide_x = false

    if player.x + xMove < 8 or player.x + xMove > MAX_X then
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

function did_collide_y()
    local collide_y = false
    local cell_size = 8
    local next_y = player.y + player.h + yMove

    local block = mget(flr(player.x / cell_size), flr(next_y / cell_size))
    local is_solid = fget(block, 3)

    if fget(block, 3) then
        collide_y = true
    end

    -- if player.grounded == false then
    --     if (player.y + player.h + yMove) >= ground.y then
    --         collide_y = true
    --     end
    -- end

    return collide_y
end

function debug_info()
    -- print("yMove: " .. yMove, cam_x + 10, 50)
    print("cam_x, 0: " .. cam_x .. ", 0", cam_x + 10, 10, 11)
    -- print("grounded: " .. (player.grounded and "true" or "false"), cam_x + 10, 10)
    -- print("jumping: " .. (player.jumping and "true" or "false"), cam_x + 10, 20)
    -- print("x: " .. player.x .. ", y: " .. player.y, cam_x + 10, 10, 4)
    -- print("cam_x: " .. cam_x .. " / " .. (cam_x / 16), cam_x + 10, 40)
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
        draw_enemies()
        draw_stars()
    end

    draw_foreground()
    draw_winning_things()
    -- debug_info()
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
    spr(player.sprite, player.x, player.y)
end

function draw_scene()
    local cell_size = 16

    map(0, 0, 0, 0, 128, 16, 1)
end

function draw_foreground()
    map(0, 0, 0, 0, 128, 16, 4)
end

function draw_winning_things()
    if you_win == false then
        -- 34, 35, 36
        spr(18, charlie.x - 8, charlie.y - 8) -- cage left top
        spr(19, charlie.x, charlie.y - 8) -- cage middle top
        spr(19, matty.x - 1, matty.y - 8) -- cage middle top
        spr(20, matty.x + 8 - 1, matty.y - 8) -- cage right top

        spr(34, charlie.x - 8, charlie.y) -- cage left bottom
        spr(35, charlie.x, charlie.y) -- cage middle bottom
        spr(35, matty.x - 1, matty.y) -- cage middle bottom
        spr(36, matty.x + 8 - 1, matty.y) -- cage right bottom
    else
        local yy = 38

        make_heart(matty.x + 4, matty.y - 8)
        make_heart(charlie.x + 4, charlie.y - 8)

        rectfill(cam_x, yy - 1, cam_x + 128, yy + 16 + 1, 8)
        rectfill(cam_x + 1, yy, cam_x + 126, yy + 16, 14)
        print("YOU FOUND MATTY AND CHARLIE!", cam_x + 4, 40, 0)
        print("WE LOVE YOU, OUR QUEEN!!! <3", cam_x + 4, 48, 0)
    end
end

__gfx__
00000000000909000000000005555500000000000004400000440000499999940000000000050000606060500800080000080000177717770000000000000000
00000000000398000009090076557650055555000004440000444000bbbb99404999999400655000066655008880888000080000156715670000000000000000
007007000aafaaa00003980065456550765576500004444000444440b8bbb999bbbb994006060500666055508888878000070000155515550000000000000000
00077000aaff4f400aafaaa06656650065456550000cfcf0000cfcf03bbbb3bbb8bbb99966605550060005008888878000080000111111110000000000000000
000770000a3ffff0aaff4f400777755566566500000ffff0000ffff0bbbb43bb3bbbb3bb06050500666055500888880000080000771777170000000000000000
00700700aaee88900a3ffff0677775050777755500422f200002222030433bbbbbbb43bb00655000066555000088800000080000671567150000000000000000
00000000ae877d60aaee889006000500677775050002222000422f2033440bb430433bbb00050000605050500088800000080000551555150000000000000000
0000000008888880ae877d600600050006000500000400f0000400f0033000bb33440bb400000000000000000008000000080000111111110000000000000000
0000000000000000555566666666666666667777000505000000dd00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a4896805006006006006006006007000055500000ddd0000ddddd00000000000000000000000000000000000000000000000000000000000000000
0000000098a888d80500600600600600600600700dd6ddd000dddd000d57dd570000000000000000000000000000000000000000000000000000000000000000
0000000009a48878050060060060060060060070dd665650007575000dd6d0d60005d00000000000000000000000000000000000000000000000000000000000
0000000093888e780500600600600600600600700d5666600077770000d66d6600567d0000000000000000000000000000000000000000000000000000000000
0000000000a83e88050060060060060060060070dd775560005755d0ddd77770056666d000000000000000000000000000000000000000000000000000000000
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
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052222222222222222222260
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222222222222222600
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222222222222222600
11221122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
112211220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222e22222ee226600
22112211000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222ee2222ee2226600
2211221100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222ee22222e22226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222e22222ee22226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee2222ee222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522e222222e2222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222e22222226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222222ee22222226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222ee222222226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222e2222222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222ee222222e226600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222ee222222ee226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee222222ee2226600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222e222222e222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522e22222222222226600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222222222222222600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222222222222222600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052222222222222222222260
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555566666666666
__gff__
000000000000000000000000000b000000000000000606060600000000000000000000000006060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0d000000000000260000000000000025002500000000000026000000000000250000000000000026000000000000002500250000000000002600000000000025000000000000002600000000000000250025000000000000260000000000002500000000000000002600000000002500250000000000000000000000000d0d0d
0d000000000000250000000000000026002600000000000025000000000000260000000000000025000000000000002600260000000000002500000000000026000000000000002500000000000000260026000000000000250000000000002600000000000000002500000000002600260000000000000000000000000d0d0d
0d000000000d00250000000000000025002500000000000025000000000000250000000000000025000000000000002500250000000000002500000000000025000000000000002500000000000000250025000000000000250000000000002500000000000000002500000000002500250000000000000000000000000d0d0d
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
