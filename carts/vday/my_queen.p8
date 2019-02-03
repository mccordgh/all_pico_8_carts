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

matty = {
    type = "matty",
    sprite = 5,
    x = 968,
    y = 88,
    w = 8,
    h = 8,
}

charlie = {
    type = "charlie",
    sprite = 3,
    x = 952,
    y = 88,
    w = 8,
    h = 8,
}

player = {
    type = "player",
    sprite = 1,
    x = 932,
    y = 96-8,
    w = 8,
    h = 8,
    speed = 5,
    jump_speed = 4,
    jumping = false,
    grounded = true,
}

ground = {
    x = 0,
    y = 96,
    w = 128,
    h = 128,
}

function _init()
    enemies = {}

    add(enemies, make_enemy())
    add(enemies, make_enemy())
    add(enemies, make_enemy())
    add(enemies, make_enemy())
    add(enemies, make_enemy())
    add(enemies, make_enemy())
    add(enemies, make_enemy())

    stars = {}

    add(stars, make_star())
    add(stars, make_star())
    add(stars, make_star())
    add(stars, make_star())
    add(stars, make_star())
    add(stars, make_star())
    add(stars, make_star())
end

function make_heart(_x, _y)
    local heart = {
        type = "heart",
        sprite = 11,
        x = _x,
        y = _y,
        w = 8,
        h = 8,
        speed = 1,
    }

    if rnd(1) >= 0.90 then
        add(hearts, heart)
    end
end

function make_enemy()
    enemy_x = enemy_x + 300

    local enemy = {
        type = "enemy",
        sprite = 7,
        x = enemy_x,
        y = player.y,
        w = 8,
        h = 8,
        speed = 1,
    }

    return enemy
end

function make_star()
    star_x = star_x + 300

    local star = {
        type = "enemy",
        sprite = 9,
        x = star_x,
        y = player.y - 12,
        w = 8,
        h = 8,
        speed = 1,
    }

    return star
end

function update_enemies()
    for enemy in all(enemies) do
        enemy.x = enemy.x - enemy.speed
    end
end

function update_stars()
    for star in all(stars) do
        star.x = star.x - star.speed
    end
end

function update_hearts()
    for heart in all(hearts) do
        heart.x = heart.x + (rnd(8) - 4)
        heart.y = heart.y - heart.speed
    end
end


function _update()
    if enemy_collide == true then
        player_disable_counter = player_disable_counter + 1
        player.sprite = 17
    else
        player.sprite = 1
        get_input()
    end

    if player_disable_counter >= 90 then
        enemy_collide = false
        player_disable_counter = 0
    end

    update_hearts()
    update_stars()
    update_enemies()

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
    -- if yMove < 0 then
    --     yMove = 0
    -- end
    update_camera()
end

function update_camera()
    cam_x = player.x - 32

    if cam_x < 0 then
        cam_x = 0
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

    if player.x + xMove < 8 or player.x + xMove > 976 then
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

    local collide_with_matty = false

    if did_collide_with(matty) then
        collide_with_matty = true

        you_win = true
    end

    if did_collide_with(charlie) then

        you_win = true
    end

    return collide_x
end

function did_collide_with(enemy)
    if (player.x < enemy.x + enemy.w) and (player.x + player.w > enemy.x) and (player.y < enemy.y + enemy.h) and (player.y + player.h > enemy.y) then
        return true
    end

    return false
end

function did_collide_y()
    local collide_y = false

    if player.grounded == false then
        if (player.y + player.h + yMove) >= ground.y then
            collide_y = true
        end
    end

    return collide_y
end

function debug_info()
    -- print("yMove: " .. yMove, cam_x + 10, 50)
    print("cam_x, 0: " .. cam_x .. ", 0", cam_x + 10, 10)
    -- print("grounded: " .. (player.grounded and "true" or "false"), cam_x + 10, 10)
    -- print("jumping: " .. (player.jumping and "true" or "false"), cam_x + 10, 20)
    -- print("x: " .. player.x .. ", y: " .. player.y, cam_x + 10, 30)
    -- print("cam_x: " .. cam_x .. " / " .. (cam_x / 16), cam_x + 10, 40)
end

function _draw()
    cls(0)

    draw_player()
    debug_info()

    draw_scene()
    draw_enemies()
    draw_stars()
    draw_matty_and_charles()
    draw_hearts()
    draw_winning_things()
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
    rect(0, 0, 127, 127, 14)
    local cell_size = 16

    map(0, 0, 0, 0, 128, 16)
end

function draw_winning_things()
    if you_win == true then
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
00000000000909000000000000666660000000000004400000004400499999940000000000005000050606060800080000080000077777770000000000000000
000000000003980000090900065766570066666000444000000444000499bbbb4999999400055600005566608880888000880000056666670000000000000000
007007000aafaaa00003980006656065065766570444400004444400999bbb8b0499bbbb00506060055506668888878000788000055555550000000000000000
00077000aaff4f400aafaaa000655655066560650fcfc0000fcfc000bb3bbbb3999bbb8b05550666005000608888878000888000000000000000000000000000
000770000a3ffff0aaff4f4066677770006556550ffff0000ffff000bb34bbbbbb3bbbb300505060055506660888880000888000777707770000000000000000
00700700aaee88900a3ffff0606777756667777002f2240002222000bbb33403bb34bbbb00055600005556600088800000888000666705660000000000000000
00000000ae877d60aaee889000600050606777750222200002f224004bb04433bbb3340300005000050505060088800000088000555505550000000000000000
0000000008888880ae877d6000600050006000500f0040000f004000bb0003304bb0443300000000000000000008000000080000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a489680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000098a888d80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009a488780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000093888e780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a83e880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaae80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a0aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
