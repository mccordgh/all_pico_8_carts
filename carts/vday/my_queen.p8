pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

music_intro = 20
music_main_bgm = 0
music_danger = 30

sfx_bonk = 10
sfx_cage = 11
sfx_alert = 12

has_played_bonk = false
has_played_alert = false
has_played_cage = false

-- Patrol radius 100 both ways

-- Bottom floor y: 480
-- 	x: 740, 568, 312, 96

-- Top floor y: 96
-- 	x 192, 352, 568, 832

enemy_patrol_radius = 8*7
bottom_floor_y = 480
top_floor_y = 96

has_won = false

gravity = 0.2
xmove = 0
ymove = 0
bottom_screen_cam_y = 48*8
cam_x = 0
-- cam_y = 0
cam_y = bottom_screen_cam_y
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
enemy_spawn_time = 140
star_spawn_time = 60
max_x = 1016
max_sprites = 2
frame_change_number = 10
blue_check_sprite = 64
red_check_sprite = 65
reposition_y = 0
browser_ymove = 0
intro_player_disabled = false
intro_draw_cage = false
intro_phase = 0
intro_show_text = false
intro_timer = 0
intro_text = {
    first_line = "qUEEN aTHENA, mATTY, n cHARLES",
    second_line = "WHERE ENJOYING A LOVELY PICNIC",
    third_line = "    WHEN ALL OF A SUDDEN...    "
}

ground = {
    x = 0,
    y = 104,
    w = 128,
    h = 128,
}

function _init()
    player_speed = 0.7
    player_start_x = 125*8
    player_start_y = bottom_floor_y

    -- DEBUGGING TYPE SETTINGS BELOW
    -- local player_speed = 1
    -- local player_start_x = 900
    -- local player_start_y = top_floor_y
    -- cam_y = 0


    player = make_entity("player", 1, player_start_x, player_start_y, 8, 8, player_speed, 2.8) -- bottom right (start)
    -- player = make_entity("player", 1, 10*8, 60*8, 8, 8, player_speed, 2.8) -- bottom left
    -- player = make_entity("player", 1, 108*8, ground.y-32, 8, 8, player_speed, 2.8) -- top right
    -- player = make_entity("player", 1, 64, ground.y-32, 8, 8, player_speed, 2.8) -- top left
    player.last_dir = 0
    matty = make_entity("matty", 5, 121*8, 60*8, 8, 8, 1, 1)
    charlie = make_entity("charlie", 3, 120*8, 60*8, 8, 8, 1, 1)
    browser = make_entity("browser", 49, 117*8, 96, 8, 8, 1, 4)
    dragon_head = make_entity("dragon_head", 49, 115*8, 63, 8, 8, -2, 4)
    intro_browser = make_entity("browser", 49, 100*8, player.y, 8, 8, 0.75, 1)
    intro_enemy = make_entity("enemy", 7, 129*8, player.y, 8, 8, 0.25, 1)

    -- matty later x,y 961, ground.y-8
    -- charlie later 952, ground.y-8

    door_x = 4*8
    door_y = 48*8
    door2_x = 4*8
    door2_y = 16*8
    door3_x = 3*8
    door3_y = 16*8

    door = make_entity("door", 9, door_x, door_y, 8, 8, 1, 1)
    door.teleport_to_x = door2_x
    door.teleport_to_y = door3_y - 8
    door.cam_y_to = 0

    door2 = make_entity("door", 9, door2_x, door2_y, 8, 8, 1, 1)
    door2.teleport_to_x = door_x
    door2.teleport_to_y = door_y + 8
    door2.cam_y_to = bottom_screen_cam_y

    door3 = make_entity("door", 9, door3_x, door3_y, 8, 8, 1, 1)
    door3.teleport_to_x = door_x
    door3.teleport_to_y = door_y + 8
    door3.cam_y_to = bottom_screen_cam_y

    -- _init_main()
    -- _init_intro()
    _init_title()

end

function _init_title()
    music(music_intro)

    player.x = 60
    player.y = 48+4

    matty.x = 20
    matty.y = player.y

    charlie.x = 102
    charlie.y = player.y

    browser.x = 82
    browser.y = 80-4

    dragon_head.x = 64-10
    dragon_head.y = 8

    intro_enemy.x = 32+8
    intro_enemy.y = browser.y

    update_state = _update_title
    draw_state = _draw_title
end

function _update_title()
    get_title_input()

    update_frames(player)
    update_frames(charlie)
    update_frames(matty)
    update_frames(browser)
    update_frames(dragon_head)
    update_frames(intro_enemy)

    make_heart(32, 136)
    make_heart(96, 136)

    update_hearts()
end

function get_title_input()
    if btn(2) then
        _init_intro()
    end
end

function _draw_title()
    cls(0)
    rectfill(0, 0, 127, 127, 1)
    rect(0, 0, 127, 127, 13)

    local logo_start_x = 20
    local logo_start_y = 32
    local spacing = 0
    local spacer = 12

    for sprite_num = 68, 74, 1 do
        spr(sprite_num, logo_start_x + spacing, logo_start_y)
        spacing = spacing + spacer

        if sprite_num == 72 then
            spr(sprite_num, logo_start_x + spacing, logo_start_y)
            spacing = spacing + spacer
        end
    end

    draw_player()
    draw_matty_and_charles()
    draw_browser()
    draw_dragon_head()
    draw_intro_enemy()
    draw_hearts()

    print("Press Up Arrow to Start!", 16, 96, 14)
    print("Press Up Arrow to Start!", 16, 96+8, 12)
    print("Press Up Arrow to Start!", 16, 96+16, 7)
end

function _init_intro()
    -- music(music_intro)

    hearts = {}

    matty.x = 121*8
    matty.y = 60*8

    player.x = player_start_x
    player.y = player_start_y

    charlie.x = 120*8
    charlie.y = 60*8

    browser.x = 117*8
    browser.y = 96

    dragon_head.x = 115*8
    dragon_head.y = 63

    intro_enemy.x = 129*8
    intro_enemy.y = player.y

    update_state = _update_intro
    draw_state = _draw_intro
end

function _init_main()
    music(music_main_bgm)

    intro_enemy = nil
    intro_browser = nil

    matty.x = 961
    matty.y = ground.y-8
    charlie.x = 952
    charlie.y = matty.y

    init_enemies()

    update_state = _update_main
    draw_state = _draw_main
end

function init_enemies()
-- Bottom floor y: 480
-- 	x: 704, 568, 312, 96

-- Top floor y: 96
-- 	x 192, 352, 568, 832

    make_enemy("enemy", 7, 704, bottom_floor_y)
    make_enemy("enemy", 7, 568, bottom_floor_y)
    make_enemy("enemy", 7, 312, bottom_floor_y)

    make_enemy("enemy", 7, 192, top_floor_y)
    make_enemy("enemy", 7, 352, top_floor_y)
    make_enemy("enemy", 7, 568, top_floor_y)
    make_enemy("enemy", 7, 832, top_floor_y)
end

function _draw()
    draw_state()
end

function _update()
    update_state()
end

function current_intro_max()
    if intro_phase == 0 then
        return 60*12
        -- return 1
    end

    if intro_phase == 1 then
        return 29*8
    end

    if intro_phase == 2 then
        return 38*8
    end

    if intro_phase == 3 then
        return 12*8
    end
end

function _update_intro()
    intro_timer = intro_timer + 1

    if intro_timer > 60*4 and intro_phase == 0 then
        intro_show_text = true
    end

    local timer_max = current_intro_max()

    if intro_timer >= timer_max then
        intro_phase = intro_phase + 1
        intro_timer = 0

        if intro_phase == 2 then
            intro_browser.speed = 0.3

            music(music_danger)
        end

        if intro_phase == 4 then
            _init_main()
        end
    end

    update_current_intro_phase()

    if not intro_player_disabled then
        update_frames(player)
    end

    update_frames(charlie)
    update_frames(matty)

    if intro_enemy != nil then
        update_frames(intro_enemy)
    end

    if intro_browser != nil then
        update_frames(intro_browser)
    end

    update_camera()
end

function update_current_intro_phase()
    if intro_phase == 1 then
        if intro_browser.x < (charlie.x - 16) then
            intro_browser.x = intro_browser.x + intro_browser.speed
        else
            if not has_played_cage then
                sfx(sfx_cage)

                has_played_cage = true
            end

            intro_draw_cage = true
        end

        if intro_enemy.x > player.x + 8 then
            intro_enemy.x = intro_enemy.x - intro_enemy.speed
        else
            if not has_played_bonk then
                music(-1)
                sfx(sfx_bonk)

                has_played_bonk = true
            end

            intro_player_disabled = true
            player.sprite = 17
        end
    end

    if intro_phase == 2 then
        if intro_browser.x > 106*8 then
            intro_browser.x = intro_browser.x - intro_browser.speed
            charlie.x = charlie.x - intro_browser.speed
            matty.x = matty.x - intro_browser.speed
        end

        if intro_enemy.x < 129*8 then
            intro_enemy.x = intro_enemy.x + intro_enemy.speed
        end
    end

    if intro_phase == 3 then
        if not has_played_alert then
            music(-1)
            sfx(sfx_alert)

            has_played_alert = true
        end

        player.sprite = 1
    end
end

function _draw_intro()
    _draw_main()

    if intro_phase == 0 and intro_show_text == true then
        local box_x = 896
        local box_y = 408

        rectfill(box_x, box_y, box_x+127, box_y+44, 1)
        rect(box_x, box_y, box_x+127, box_y+44, 13)

        print(intro_text.first_line, box_x+4, box_y+8, 7)
        print(intro_text.second_line, box_x+4, box_y+20, 7)
        print(intro_text.third_line, box_x+4, box_y+32, 7)
    end

    if intro_phase == 1 or intro_phase == 2 then
        draw_intro_browser()
        draw_intro_enemy()
    end

    if intro_draw_cage == true then
        draw_cage()
    end

    if intro_phase == 3 then
        spr(54, player.x, player.y - 10)
    end
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

    if rnd(1) >= 0.95 then
        local heart = make_entity("heart", 11, _x, _y, 8, 8, 1, 1)

        add(hearts, heart)
    end
end

function player_is_on_bottom_screen()
    return player.y > 148
end

function make_enemy(_type, _sprite, _x, _y)
    local enemy = make_entity(_type, _sprite, _x, _y, 8, 8, 0.9, 1)

    enemy.start_x = enemy.x
    enemy.start_y = enemy.y

    add(enemies, enemy)
end

function make_star()
    local star_x = 0

    if player_is_on_bottom_screen() then
        star_x = player.x - 128
    else
        star_x = player.x + 128
    end

    if star_x > max_x then
        star_x = max_x
    end

    if star_x < 0 then
        star_x = 0
    end

    local star = make_entity("enemy", 9, star_x, player.y-16, 8, 8, 1.75, 1)

    return star
end

function update_enemies()
    for enemy in all(enemies) do
            update_frames(enemy)

        if (enemy.x + enemy.speed > enemy.start_x + enemy_patrol_radius) or (enemy.x + enemy.speed < enemy.start_x - enemy_patrol_radius) then
            enemy.speed = -enemy.speed
        end

        enemy.x = enemy.x + enemy.speed
    end

    -- if (enemy_timer > enemy_spawn_time) and (cam_x > 0 and cam_x < 760) then
        -- add(enemies, make_enemy())
        -- enemy_timer = 0
    -- end

    -- for enemy in all(enemies) do
    --     update_frames(enemy)

    --     if player_is_on_bottom_screen() then
    --         enemy.x = enemy.x + enemy.speed
    --     else
    --         enemy.x = enemy.x - enemy.speed
    --     end
    -- end

    -- for enemy in all(enemies) do
    --     if enemy.x < 0 or enemy.x > max_x then
    --         del(enemies, enemy)
    --     end
    -- end
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
    if (star_timer > star_spawn_time) and (cam_x > 0 and cam_x < 760) then
        add(stars, make_star())
        star_timer = 0
    end

    for star in all(stars) do
        update_frames(star)

        if player_is_on_bottom_screen() then
            star.x = star.x + star.speed
        else
            star.x = star.x - star.speed
        end
    end

    for star in all(stars) do
        if star.x < 0 or star.x > max_x then
            del(stars, star)
        end
    end
end

function update_hearts()
    for heart in all(hearts) do
        update_frames(heart)

        heart.x = heart.x + (rnd(8) - 4)
        heart.y = heart.y - heart.speed
    end
end


function _update_main()
    xmove = 0

    if you_win == false then
        star_timer = star_timer + 1
        enemy_timer = enemy_timer + 1
    end

    if enemy_collide == true and you_win == false then
        player_disable_counter = player_disable_counter + 1
        player.sprite = 17
    else
        update_frames(player)
        get_input()
    end

    if player_disable_counter >= 40 then
        enemy_collide = false
        player_disable_counter = 0
    end

    update_hearts()

    if you_win == false then
        update_stars()
        update_enemies()
        update_browser()
        update_dragon_head()
        update_frames(browser)
    end

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

    update_frames(charlie)
    update_frames(matty)

    update_camera()
end

function update_dragon_head()
    if dragon_head.y <= 64 then
        dragon_head_ymove = 1.65
    end

    if dragon_head.y >= 96 then
        dragon_head_ymove = -1.65
    end

    dragon_head.y = dragon_head.y + dragon_head_ymove
end

function update_browser()
    if browser.y <= 64 then
        browser_ymove = 1.65
    end

    if browser.y >= 96 then
        browser_ymove = -1.65
    end

    browser.y = browser.y + browser_ymove
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
    cam_x = player.x - 64
    -- cam_y = player.y - 96

    if cam_x < 0 then
        cam_x = 0
    end

    if cam_x > 896 then
        cam_x = 896
    end

    if cam_y < 0 then
        cam_y = 0
    end

    if cam_y > 400 then
        cam_y = 400
    end

    camera(cam_x, cam_y)
end

function get_input()
    if btn(0) then
        xmove = -player.speed
        player.last_dir = 0
    end

    if btn(1) then
        xmove = player.speed
        player.last_dir = 1
    end

    if btn(2) and (player.jumping == false) then
        ymove = -player.jump_speed

        player.jumping = true
    end
end

function did_collide_x()
    if player.sprite == 17 then
        return
    end

    local collide_x = false

    if player.x + xmove < 0 or player.x + xmove > max_x then
        collide_x = true
    end

    if did_collide_with(door) then
        player.x = door.teleport_to_x
        player.y = door.teleport_to_y

        cam_y = door.cam_y_to
    end

    if did_collide_with(door2) then
        player.x = door2.teleport_to_x
        player.y = door2.teleport_to_y

        cam_y = door2.cam_y_to
    end

    if did_collide_with(door3) then
        player.x = door3.teleport_to_x
        player.y = door3.teleport_to_y

        cam_y = door3.cam_y_to
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

    if did_collide_with(browser) then
        collide_x = true
        enemy_collide = true
    end

    if did_collide_with(dragon_head) then
        collide_x = true
        enemy_collide = true
    end

    if did_collide_with(matty) or did_collide_with(charlie) then
        you_win_dude()
    end

    if xmove != 0 and will_hit_block_x() then
        collide_x = true
    end

    if enemy_collide == true then
        sfx(sfx_bonk)
    end

    return collide_x
end

function you_win_dude()
    if not has_won then
        music(music_intro)
        you_win = true
        enemies = {}
        stars = {}
        star_timer = 0
        enemy_timer = 0
        browser.y = 0
        dragon_head.y = 0
        has_won = true
    end
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

    return collide_y
end

function debug_info()
    debug_y_pos = 18
    debug_x_pos = 40

    -- debug_print("cam: " ..cam_x ..", " ..cam_y)
    -- debug_print("on_bottom: " ..(player_is_on_bottom_screen() and "true" or "false"))
    -- debug_print("player: " ..player.x ..", " ..player.y)
    -- debug_print("ymove: " .. ymove)
    -- debug_print("block_below: " .. (block_below and "true" or "false"))
    -- debug_print("jumping: " .. (player.jumping and "true" or "false"))
    -- debug_print("x, y: " .. player.x .."," ..player.y)
    -- debug_print("ceil: " ..ceil(player.y / 8) * 8)
end

function debug_print(wat)
    debug_y_pos = debug_y_pos + 6

    print(wat, cam_x + debug_x_pos, cam_y + debug_y_pos, 8)
end

function draw_background()
    rectfill(cam_x, 0, cam_x + 128, 196, 1)
    rectfill(cam_x, 360, cam_x + 128, 512, 1)
    rectfill(832, 360, 1024, 512, 12)
    map(0, 16, 0, 0, 128, 64, 0)
    map(0, 16, 0, 48*8, 100, 64, 0)

    -- this is all the <- castle sign
    rectfill(898, 468, 936, 476, 4)
    rect(898, 468, 936, 476, 0)
    rectfill(916, 476, 920, 487, 4)
    rect(916, 476, 920, 487, 0)
    print("<-castle", 902, 470, 00)
end

function _draw_main()
    cls(0)
    draw_background()

    draw_player()

    draw_scene()
    draw_hearts()

    if you_win == false and update_state != _update_intro then
        draw_enemies()
        draw_stars()
        draw_browser()
        draw_dragon_head()
    end

    draw_foreground()
    draw_matty_and_charles()

    if you_win == false and update_state != _update_intro then
        draw_cage()
    end


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
    local should_flip = update_state == _update_intro

    spr(matty.sprite, matty.x, matty.y, 1, 1, should_flip)
    spr(charlie.sprite, charlie.x, charlie.y, 1, 1, should_flip)
end

function draw_intro_browser()
    local flip_me = intro_phase < 2

    spr(intro_browser.sprite, intro_browser.x, intro_browser.y, 1, 1, flip_me)
end

function draw_intro_enemy()
    local flip_me = intro_phase >= 2

    spr(intro_enemy.sprite, intro_enemy.x, intro_enemy.y, 1, 1, flip_me)
end

function draw_browser()
    spr(browser.sprite, browser.x, browser.y)
end

function draw_dragon_head()
    sspr(13*8, 1*8, 16, 16, dragon_head.x, dragon_head.y)
end

function draw_stars()
    for star in all(stars) do
        spr(star.sprite, star.x, star.y)
    end
end

function draw_enemies()
    for enemy in all(enemies) do
        local flip_x = enemy.speed > 0

        spr(enemy.sprite, enemy.x, enemy.y, 1, 1, flip_x)
    end
end

function draw_hearts()
    for heart in all(hearts) do
        spr(heart.sprite, heart.x, heart.y)
    end
end

function draw_player()
    local flip_x = player.last_dir == 0

    spr(player.sprite, player.x, player.y, 1, 1, flip_x)
end

function draw_scene()
    local cell_size = 16

    map(0, 0, 0, 0, 128, 64, 1)
end

function draw_foreground()
    map(0, 0, 0, 0, 128, 64, 4)
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
0000000000000900555566666666666666667777000505000000dd0000000000000000003333333344444444eeeeeeee00000000000000000000077700000000
0000000000a4896805006006006006006006007000055500000ddd0000ddddd00000000033343333444444444444444400000000000000000337779000000000
0000000098a888d80500600600600600600600700dd6ddd000dddd000d57dd570000000033333333343343333433433300000000000000003337799000000000
0000000009a48878050060060060060060060070dd665650007575000dd6d5d60005d00033333433333334333333343300000000000000773333993000000000
0000000093888e780500600600600600600600700d5666600077770000d66d6600567d0033333333333333333333333300000000009008773333333000000000
0000000000a83e88050060060060060060060070dd775566005755d0ddd77770056666d043333333433333334333333300000000091988773333333300000000
0000000000aaaae8050060060060060060060070d7577d6000555500d0d7777600566d0033343333333433333334333300000000099977733393333300000000
00000000000a0aa00500600600600600600600700dddddd000700d0000d000500005d00033333333333333333333333300000000099997333999333300000000
000000000000000005006006006006006006007005566770055667705555777755557777005dd600005dd600055dd660055dd660079993399739333300000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600007099993339333300000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600007077373379333300000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000007000399333700000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000799337700000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000000993377000000000
000000000000000005006006006006006006007005566770055667700556677005566770005dd600005dd600005dd600005dd600000000079993377000000000
00000000000000005555600600600600600600775555777705566770055667705555777705556660005dd600005dd600055dd660000000009900000000000000
00000000040887000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fff2b7300408870000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ffff437fff2b73000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
000000000eeff4930ffff437000000000300030003000b0000088000000000000000000000000000000000000000000000000000000000000000000000000000
000000009fffa9970eeff49340000004004000f0004000d000088000000000000000000000000000000000000000000000000000000000000000000000000000
000000009496a9439fffa99744444444088009900dd0011000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000094669909496a9434f9f9f9488789979dd7d117100088000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009400a900946699044444444088009900dd0011000088000000000000000000000000000000000000000000000000000000000000000000000000000
1122112200033333b33b0000000666000e00000e0e00000e000eee000e00000e0eeeeee00e00000e00ee00000000000000000000555555555555666666666666
1122112200333333333bb000006777600ee000ee0de000ed00eddde00e00000e0eddddd00ee0000e00ee00000000000000000000052222222255662222222260
22112211033333333333b300067777660ede0ede00de0ed00ed000de0e00000e0e0000000ede000e00ee00000000000000000000005222222255662222222600
221122113333333833333b30077777760e0ded0e000ded000e00000e0e00000e0eeee0000e0de00e00ee00000000000000000000005555555555666666666600
112211223333333333333b30077777550e00d00e0000e0000e000e0e0e00000e0eddd0000e00de0e00dd00000000000000000000005522222222222222226600
11221122333333333333333b057575500e00000e0000e0000de00ded0de000ed0e0000000e000dee000000000000000000000000005522222222222222226600
22112211333333333333333b005050000e00000e0000e00000deeede00deeed00eeeeee00e0000de00ee00000000000000000000005522222e22222222226600
22112211333383333333333b000000000d00000d0000d000000ddd0d000ddd000dddddd00d00000d00dd0000000000000000000000552222ee222222e2226600
00000000333333333333333b000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee222222ee2226600
00000000333333333833333b00000000000000000000000000000000000000000000000000000000000000000000000000000000005522ee222222ee22226600
0000000055333333333333b3000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222222ee222226600
000000003533333333333bb500000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222ee2222226600
0000000003533333333333500000000000000000000000000000000000000000000000000000000000000000000000000000000000552222222ee22222226600
000000000033533333333500000000000000000000000000000000000000000000000000000000000000000000000000000000000055222222ee222222226600
00000000000055355353530000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222ee22222ee226600
0000000000000533553530000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222ee22222ee2226600
000000000000002225400000000000000000000000000000000000000000000000000000000000000000000000000000000000000055222ee22222ee22226600
0000000000000022554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000552222222222e222226600
00000000000000225440000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
00000000000000225440000000000000000000000000000000000000000000000000000000000000000000000000000000000000005522222222222222226600
00000000000000225540000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555666666666600
00000000000000222540000000000000000000000000000000000000000000000000000000000000000000000000000000000000005222222255662222222600
00000000000000225540000000000000000000000000000000000000000000000000000000000000000000000000000000000000052222222255662222222260
00000000000000254440000000000000000000000000000000000000000000000000000000000000000000000000000000000000555555555555666666666666
00000000000000255440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000225540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000225540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000255440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000002255444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000022225444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000222225444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002222225444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0d000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0000000000000000000000000000000000000000000000000
d0d0d0d000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0000000000000000000000000000000000000000000003400
d0d0d00000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0000000000000000000000034000000000000003444000000
d0d0000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0003400343434440000000000000000000000003400000000
d000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0000000340034340000000000340034343400000000003400
d0000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0003400000000003400340000000000003400000000000000
d00000d0d0d000000000000000000072000000000000000000000000000000720000000000000000000000000000007200720000000000000000000000000072
0000000000000000000000000000007200720000000000000000000000000072000000000000d0d0000000000000000000003434000000000034000000340000
d0000000000000000000000000000062000000000000000000000000000000620000000000000000000000000000006200620000000000000000000000000062
000000000000000000000000000000620062000000000000000000000000006200000000000000d0000034003400003400003400003400000000000000000034
d0d00000000000000000000000000072000000000000000000000000000000720000000000000000000000000000007200720000000000000000000000000072
00000000000000000000000000000072007200000000000000000000000000720000000000000000000000000000000034000000000000003400340000000000
d0d0d000000000000000000000000062000000000000d0d0d0d0d000000000620000000000000000000000000000006200620000000000000000000000000062
00000000000000000000000000000062006200000000000000000000000000620000000000000000000034340000000000000000003434000000000034343400
d0d0d0d00000000000000000000000520000000000d0d0000000d0d0000000520000000000000000000000000000005200520000000000000000000000000052
00000000000000000000000000000052005200000000000000000000000000520000000000000000000000343400003434000034001424000000000000000000
d0d0d0d0d0000000000000000000006200000000d0d000007100d0d0000000620000000000000051000000000000006200620000000000007100000000000062
00000000000000510000000000000062006200000000000071000000000000620000000000000000000000001424000000000000001525000000340000340000
d0d0d0d0d0d00000000000000000006200000000d0d00000820000d0d00000620000000000000082000000000000006200620000000000008200000000000062
00000000000000820000000000000062006200000000000082000000000000620000000000000000000034001525000000000000001626003400000000000000
d0d0d0d0d0d0d0000000000000000052000000d0d000000062000000d0d000520000000000000062000000000000005200520000000000006200000000000052
00000000000000620000000000000052005200000000000062000000000000520000000000000000000000001626000000000000001626000000000000000000
d0d0d0d0d0d0d0d000000000000000620000d0d00000000052000000d0d00062000000000000005200000000000000620062000000d0d0005200d0d000000062
00000000000000520000000000000062006200000000000052000000000000620000000000000000000000001626000000000000001626000000000000000000
d0d0d0d0d0d0d0d0d00000000000005200d0d000000000005200000000d0d0520000000000000052000000000000005200520000d0d0d0005200d0d0d0000052
00000000000000520000000000000052005200000000000052000000000000520000000000000000000000001727000000000000001727000000433353000000
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0a1a1a1a1a1a1a1a1a1a1a1a1a1a1b1b1b1b1b1b1b1b1
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d091919191919191919191919191919191919191919191
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d091919191919191919191919191919191919191919191
__gff__
000000000000000000000000000b00000000000000060606060b0b0b00000000000000000006060606060606060000000000000606060000000000000000000000060606000000000000000000060606000606000000000000000000000606060006060000000000000000000006060600060600000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d000000000000000000000000000027002700000000000000000000000000270000000000000000000000000000002700270000000000000000000000000027000000000000000000000000000000270027000000000000000000000000002700000000000000000000000000002700270000000000000000000000000d0d0d
0d000000000000000000000000000026002600000000000000000000000000260000000000000000000000000000002600260000000000000000000000000026000000000000000000000000000000260026000000000000000000000000002600000000000000000000000000002600260000000000000000000000000d0d0d
0d000000000000000000000000000027002700000000000000000000000000270000000000000000000000000000002700270000000000000000000000000027000000000000000000000000000000270027000000000000000000000000002700000000000000000000000000002700270000000000000000000000000d0d0d
0d000000000000000000000000000026002600000000000000000000000000260000000000000000000000000000002600260000000000000000000000000026000000000000000000000000000000260026000000000000000000000000002600000000000000000000000000002600260000000000000000000000000d0d0d
0d0000000000000000000000000000250025000000000000000000000000002500000000000000000000000000000025002500000000000d0d0d000000000025000000000000000000000000000000250025000000000000000000000000002500000000000000000000000000002500250000000000000000000000000d0d0d
0d00000000000016000000000000002600260000000000001700000000000026000000000000001500000000000000260026000000000d0016000d0000000026000000000000001700000000000000260026000000000000150000000000002600000000000000001600000000002600260000000000000000000000000d0d0d
0d00000000000028000000000000002600260000000000002800000000000026000000000000002800000000000000260026000000000d0028000d0000000026000000000000002800000000000000260026000000000000280000000000002600000000000000002800000000002600260000000000000000000000000d0d0d
0d00000000000026000000000d000025002500000000000026000000000000250000000d00000026000000000000002500250000000d00002600000d00000025000000000000002600000000000000250025000000000000260000000000002500000000000000002600000000002500250000000000000000000000000d0d0d
0d000000000000250000000d0d0000260026000000000000250000000000002600000d0d0d0000250000000000000026002600000d000000250000000d000026000000000000002500000000000000260026000000000d0025000d000000002600000000000000002500000000002600260000000000000000000000000d0d0d
0d0d0000000000250000000d0d0d00250025000000000000250000000000002500000d0d0d0000250000000000000025002500000d000000250000000d0000250000000000000025000000000000002500250000000d0d0025000d0d0000002500000000000000002500000000002500250000000000000000000000000d0d0d
0d0d0d000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d0000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0d0d0d00000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b000000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000
00000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a000000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000
00000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000002b000000000000000000000000002b002b000000000000000000000000000000002b000000000000000000000000002b002b0000000000000000000000000000
00000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000002a000000000000000000000000002a002a000000000000000000000000000000002a000000000000000000000000002a002a0000000000000000000000000000
0000000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f00002a00000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f00002a00000000004d4e4f00000000002a002a00004d4e4f00000000004d4e4f0000002a00000000004d4e4f00000000002a002a00004d4e4f00004d4e4f00000000
0000000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f00002b00000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f00002b00000000005d5e5f00000000002b002b00005d5e5f00000000005d5e5f0000002b00000000005d5e5f00000000002b002b00005d5e5f00005d5e5f00000000
0000000000006d6e6f18000000002a002a00006d6e6f00180018006d6e6f00002a00000000186d6e6f18000000002a002a00006d6e6f00180018006d6e6f00002a00000000186d6e6f18000000002a002a00006d6e6f00180018006d6e6f0000002a00000000186d6e6f18000000002a002a00006d6e6f00006d6e6f00000000
0000000000000000002c000000002a002a0000000000002c002c0000000000002a000000002c0000002c000000002a002a0000000000002c002c0000000000002a000000002c0000002c000000002a002a0000000000002c002c000000000000002a000000002c0000002c000000002a002a0000000000000000000000000000
0000000000000000002a000000002b002b0000000000002a002a0000000000002b000000002a0000002a000000002b002b0000000000002a002a0000000000002b000000002a0000002a000000002b002b0000000000002a002a000000000000002b000000002a0000002a000000002b002b0000000000000000000000000000
0000000000000000002900000000290029000000000000290029000000000000290000000029000000290000000029002900000000000029002900000000000029000000002900000029000000002900290000000000002900290000000000000029000000002900000029000000002900290000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001200001203000000120300000012030000001203000000130300000013030000001303000000130300000015030000001503000000150300000015030000001703000000170300000017030000001703000000
001200001e7221e1221e7221e122000000000000000000001f7221f1221f7221f12200000000000000000000211222112221122211221f1221f1221f1221f1222372223122237222312200000000000000000000
001200000000000000000000663500000000000663506200000000000006600000000000006635000000663500000000000000006635000000000006635062000000000000066000000000000066350663506635
0018000018533185321853218532185321853218532185001f5321f5321f5321f5321f5321f5321f532000001d5321d5321d5321d5321d5321d5321d532000001c5321c5321c5321c5321c5321c5321c5321c532
001800000000000000066050662506625000000662506200000000000006600066250660000000066250660000000000000660506625066250000006625062000000000000066000662506600000000662506600
001800001c5311c5321c5321c5321c5321c5321c53200000245322453224532245322453224532245320000021532215322153221532215322153221532245112451124511245112451123521235212352123521
001a00001105512055110551205511055120551105512055130551405513055140551305214052130521405211055120551105512055110551205511055120551305514055130551405513052140521305214052
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000455004610015500200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000355004610065500461000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000007140091500d1501014013140181401e140241302a1303413039120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01024344
01 01024344
00 01024344
00 01020344
02 01020344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 04064544
03 04060544
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 07424344

