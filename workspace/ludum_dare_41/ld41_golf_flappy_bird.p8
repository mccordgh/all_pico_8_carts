pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
--flaps as strokes
function _init()
    music(1)
    init_game()
    init_ball()
    init_player()
    init_player_start()
end

function init_game()
    collided = false
    padd = 2
    cam_x = 0
    course_par = 3

    gravity = 0.25
    wind = 0.15
    friction = 0.05
    meter_speed = .05
    
    power = 0
    max_power = 10
    draw_power = true
    power_meter_speed = max_power * meter_speed
    
    lift = 0
    max_lift = 8
    draw_lift = true
    lift_meter_speed = max_lift * meter_speed

    do_draw_meter = true
    landed = false
    hitting_ball = false
    flapping = false
    level_finish = false
    tree_collide = false
    --x_hit = false
    --y_hit = false
    catch_up_ball = false

    state = menu_state
    draw_state = draw_menu
    --state = hitting_state
end

function menu_state()
    if (btnp(4)) then
        state = init_level
        draw_state = draw_game
    end
end

function init_level()
    trees = {}
    make_trees(120, 100)
    
    state = hitting_state
end

function make_trees(start_pos, x_spacing)
    local xx = start_pos
    local tree_spacing = 50
    local yy = -(tree_spacing / 2) - 1
    local tree_inner_space = 20

    while (xx < 966) do
        local tree_shift = rnd(tree_spacing) - (tree_spacing / 2)
        --local spacer = 0
        local t1 = make_tree()
        local t2 = make_tree()

        t1.x = xx
        t1.y = yy + tree_shift
        t1.tree_flip = true

        t2.x = xx
        t2.y = yy + tree_shift + t1.y_stretch + tree_inner_space
        t2.tree_flip = false
        
        add(trees, t1)
        add(trees, t2)

        xx += x_spacing
    end
end

function make_tree()
    local t = {}

    t.spr_xpos = 0
    t.spr_ypos = 8
    t.spr_width = 8
    t.spr_height = 32
    t.x_stretch = 42
    t.y_stretch = 88

    t.x = xx
    t.y = yy

    return t
end

function _update()
    state()
end

function _draw()
    draw_state()
end

function draw_flag()
    sspr(8, 8, 8, 8, 1000, 4, 16, 16)
    x = 0

    local i = 0
    repeat
        sspr(8, 16, 8, 8, 1000, (16 * i) + 4, 16, 16)
        i += 1
    until i > 5

    sspr(8, 24, 8, 8, 1000, 100, 16, 16)
end

function draw_game()
    if (level_finish) then
        state = end_game
        draw_state = draw_final_score
        music(-1)
        music(0)
    else
        cls()
        if (hitting_ball) then
            set_camera_to_ball()
        else
            set_camera_to_player()
        end

        map(0, 0, 0, 0, 128, 16)

        sspr(player.sprite * 8, 0, 8, 8, player.x, player.y, 48, 48)

        draw_trees()
        draw_flag()

        spr(ball.sprite, ball.x, ball.y)

        if (do_draw_meter and (not level_finish)) then
            draw_all_meters()
            draw_score()
        end
        
        debug_info()
    end
end

function make_box(mx, my, mw, mh)
    mx += cam_x
    mw += cam_x
    --[[    
    --outer border
    rectfill(mx - 3, my - 3, mw + 3, mh + 3, 13)
    
    --middle border
    rectfill(mx - 2, my - 2, mw + 2, mh + 2, 6)
]]
    --inner border
    rectfill(mx - 1, my - 1, mw + 1, mh + 1, 13)
    
    --box
    rectfill(mx, my, mw, mh, 0)
end

function end_game()
    if (btnp(4)) then
        _init()
    end
end

function draw_final_score()
    local thumb_flip = player.strokes > course_par
    local cleared_col = 11

    if (thumb_flip) then
        cleared_col = 8
    end

    make_box(32, 32, 96, 96)

    print("course cleared!", cam_x + 35, 37, cleared_col)
    print("    par: " .. course_par, cam_x + 44, 48, 7)
    print("strokes: " .. player.strokes, cam_x + 44, 54, 7)
    print("  flaps: " .. player.flaps, cam_x + 44, 60, 7)
    
    sspr(16, 8, 16, 24, 56 + cam_x, 68, 16, 24, false, thumb_flip)    
end

function draw_score()
    make_box(76, 4, 120, 19)
    print("strokes: " .. player.strokes, cam_x + 77, 6, 7)
    print(" flaps: " .. player.flaps, cam_x + 77, 13, 7)
end

function draw_all_meters()
    draw_meter_box()

    if (draw_power) then
        local power_percent = (power / max_power) * 100
        if (power_percent > 100) then
            power_percent = 100
        end
        print ("p o w e r ", cam_x + 29, 58, 7)
        if (power > -1) then
            make_box(20, 50, 70, 56)
            rectfill(cam_x + 20, 50, cam_x + 20 + (power_percent / 2), 56, 14)
            if (power_percent < 1) then
                sfx(4)
            end
        end
    end

    if (draw_lift) then
        local lift_percent = (lift / max_lift) * 100
        if (lift_percent > 100) then
            lift_percent = 100
        end
        print ("l", cam_x + 19, 12, 7)
        print ("i", cam_x + 19, 20, 7)
        print ("f", cam_x + 19, 28, 7)
        print ("t", cam_x + 19, 36, 7)
        if (lift > -1) then
            make_box(10, 6, 16, 56)
            rectfill(cam_x + 10, 56 - (lift_percent / 2), cam_x + 16, 56, 9)
            if (lift_percent < 1) then
                sfx(5)
            end
        end
    end 
end

function draw_trees()
    for tr in all(trees) do
        sspr(tr.spr_xpos, tr.spr_ypos, tr.spr_width, tr.spr_height, tr.x, tr.y, tr.x_stretch, tr.y_stretch,  tr.tree_flip, tr.tree_flip)    
    end
end

function draw_menu()
    cls()
    print("Golden Beak", 32, 30, 7)
    print("golf", 48, 40, 10)

    print("press Z to start, swing, and", 0, 70, 7)
    print("flap while egg is in the air", 0, 82, 7)
end

function draw_meter_box()
    make_box(8, 4, 72, 64)
end

function init_ball()
    ball = {}
    ball.x = 48
    --ball.x = 1000
    ball.x_speed = 0
    ball.y = 108
    ball.y_speed = 0
    ball.width = 8
    ball.height = 8
    ball.sprite = 3
end

function reset_player_vars()
    player.x = ball.x - 44
    player.y = ball.y - 40
    player.sprite = 13
    player.frame_count = 0
    player.frame = 0
    player.frame_spd = 6
    player.power = -1
    player.lift = -1
end

function init_player()
    player = {}
    reset_player_vars()
    --player.power = max_power / 2
    --player.lift = max_lift / 2
end

function init_player_start()
    player.strokes = 0
    player.flaps = 0
end

function hitting_state()
if ((not hitting_ball) and (not landed)) then
        not_hitting()
    else
        hitting()
    end
end

function landed_state()

end

function power_meter()
    power += power_meter_speed

    if (btnp(4)) then
        if (power > max_power) then
            power = max_power
        end
        if (power < 1) then
            power = 1
        end
        player.power = power
    end

    if (power >= max_power + (max_power * .05)) then
        power = 0
    end
end

function lift_meter()
    lift += lift_meter_speed

    if (btnp(4)) then
        if (lift > max_lift) then
            lift = max_lift
        end
        if (lift < 1) then
            lift = 1
        end
        player.lift = lift
    end

    if (lift >= max_lift + (max_lift * .05)) then
        lift = 0
    end
end

function not_hitting()
    if (player.power == -1) then
        power_meter()
    else if (player.lift == -1) then
        lift_meter()
    else
        swing_animate()
    end
    end
end

function swing_animate()
    player.frame_count += 1

    if (player.frame_count == player.frame_spd) then
        sfx(6)
        player.frame += 1
        player.frame_count = 0

        if (player.frame == 1) then
            player.sprite = 14
        end

        if (player.frame == 2) then
            player.sprite = 15
        end

        if (player.frame == 3) then
            player.sprite = 14
        end

        if (player.frame == 4) then
            player.sprite = 13
            player.strokes += 1

            hitting_ball = true
            do_draw_meter = false
            catch_up_ball = true

            lift = 0
            power = 0

            ball.x_speed = player.power
            ball.y_speed = player.lift
        end
    end
end

function reset_golfing_vars()
    flapping = false
    hitting_ball = false
    landed = false
    collided = false
    tree_collide = false
    played_hit_sfx = false
end

function hitting()
    if (flapping and btnp(4) and (not landed) and (not collided)) then
        flap()
    end

    if (not flapping and not played_hit_sfx) then
        sfx(7)
        played_hit_sfx = true
    end

    if (landed and (collided or ball.x_speed == 0)) then
        reset_golfing_vars()
        reset_player_vars()
    end

    ball_collision()
    apply_ball_force()
    apply_physics()
end

function tree_collision()
    --x_hit = false
    --y_hit = false
    
    for tr in all(trees) do
        if ((ball.x > tr.x) and (ball.x < tr.x + (tr.x_stretch - padd))) 
        and (ball.y > tr.y or (ball.y + ball.height) > tr.y) and (ball.y < tr.y + (tr.y_stretch - padd)) then
            tree_collide = true
            ball.sprite = 3
            del(trees, tr)
            sfx(8)
        end

        --if ((ball.y > tr.y) and (ball.y < tr.y + (tr.y_stretch - padd))) then
         --   y_hit = true
        --end
    end

    --tree_collide = x_hit and y_hit
end

function ball_collision()
    tree_collision()
    
    if (ball.x + ball.width > 1016) then
        ball.x_speed = 0
        level_finish = true
    end
    
    if (tree_collide) then
        reset_player_vars()
        collided = true
        ball.x_speed = 0
    end

    if (ball.y > 108) then
        ball.y_speed = 0
        ball.y = 108
    end

    if (ball.y == 108) then
        if (ball.x_speed == 0) then
            hitting_ball = false
            do_draw_meter = true
        else
            ball.x_speed -= friction
        end
    end

    if ((not landed) and (not collided) and btnp(4)) then
        flapping = true
        ball.sprite = 4
        wind /= 2
        flap()
    end
end

function apply_ball_force()
    ball.x += ball.x_speed

    if (not landed) then
        if (ball.y - ball.y_speed > 0) then
            ball.y -= ball.y_speed
        else
            ball.y = 0
        end
    end
end

function flap()
    player.flaps += 1

    if (ball.y > 8) then
        sfx(9)
        ball.y_speed = 2
        ball.x_speed = 1.5
    end
end

function apply_physics()
    ball.x_speed -= wind
    
    if (not landed) then
        ball.y_speed -= gravity
    end

    if (ball.x_speed < 0) then
        ball.x_speed = 0
    end

    if (ball.y > 108) then
        ball.y_speed = 0
        ball.y = 108
        landed = true
    end
end

function to_string(str)
    if (str) then
        return "true"
    end

    return "false"
end

function debug_info()
    --print("collided: " .. to_string(collided), cam_x + 50, 10, 15)
    --print("ball x: " .. ball.x .. ", y: " .. ball.y, cam_x + 64, 94, 15)
    --print("ball speed x: " .. ball.x_speed .. ", y: " .. ball.y_speed, cam_x + 10, 30, 15)
    --print("pow: " .. power, cam_x + 10, 10, 15)
    --print("lift: " .. lift, cam_x + 10, 20, 15)
    --print("landed: true", cam_x + 70, 20, 15)
    --print("x_hit: " .. to_string(x_hit), cam_x + 50, 50, 15)
    --print("y_hit: " .. to_string(y_hit), cam_x + 50, 70, 15)
    --print("camera x: " .. cam_x, cam_x + 64, 100, 7)
end

function set_camera_to_ball()
    if (catch_up_ball) then
        if (cam_x <= ball.x - 64) then
            cam_x = ball.x - 64
            catch_up_ball = false
        end
    else
        if (ball.x - 64 < 0) then
            cam_x = 0
        else if (ball.x + ball.width > 966) then
            cam_x = 894
        else
            cam_x = ball.x - 64
        end
        end
    end

    camera(cam_x, 0)
end

function set_camera_to_player()
    if (ball.x + ball.width > 966) then
        cam_x = 894
    else if (cam_x < player.x + 24) then
        cam_x += 2
    end
    end

    camera(cam_x, 0)
end
__gfx__
00000000ccccccccbbbbbbbb00000000000000003333333333333333333b333333333333cccccccccccccccccccccccccccccccc00000a0000000a0000000a00
00000000ccccccccbbbbbbbb000ff0000000000033333333333333333333333333333333cccccccccccccccccccccccccccccccc00000f0000000f0000000f00
00700700ccccccccbbbbbbbb00ffff00000870003333333b333333333333333333333333cccccccccccc66cccccccccccccccccc000088800000888000008880
00077000ccccccccbbbbbbbb0fff77f000088a003b3333b3b333333333333b333b333333cccccccc6666666ccccccccccccccccc00008f8000008f8006008880
00077000ccccccccbbbbbbbb0ffff7f00802808033b33333333333b33b3333b33333333bccccccc666667666cccccccccccccccc0000f8000000f8000066ff00
00700700ccccccccbbbbbbbbfffffffff082880f3333333333333333b333333333333333ccccccc666667766cccccccccccccccc000061000006010000000100
00000000ccccccccbbbbbbbb0ffffff00ff88ff033333333333333333333333333333333ccccccc666666776cccccccccccccccc000006000660010000000100
00000000ccccccccbbbbbbbb00ffff0000ffff003333b333333333333333333333333333ccccccc666666676cccccccccccccccc000004600000040000000400
033333300000003000000000f7000000000000003333333333b3b3330000000000000000cccccc666666666666666666666666cc000000000000000000000000
333333b3000003b300000000f77000000000000033b33333333b33330000000000000000cc66666666666666666666666666666c000000000000000000000000
333b3b330000775000000000fff000000000000033333333333333330000000000000000c666666666666666666666666666666c000000000000000000000000
333333b30077776000000000fff000000000000033333333333333330000000000000000c666666666666666666666666666666c000000000000000000000000
333b3b337777776000000000ffff00000000000022222222222222220000000000000000c666666666666666666666666666666c000000000000000000000000
333333b30777776000000000ffff000000000000424444f4444444440000000000000000c666666666666666666666666666666c000000000000000000000000
33333b330077776000000000ffff0000000000004f442444244424420000000000000000cc6666666666666666666666666666cc000000000000000000000000
033333300000775000000000ffff00000000000044244424442f44240000000000000000cccccccccccccccccccccccccccccccc000000000000000000000000
044444f00000006000000000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f00000006000000000fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f00000006000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f00000006000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000600fffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000600fffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f00000006000000000ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f000000060ffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f000000060ffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000600fffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000600000000ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f000000060fffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f000000060fffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f000000060000000fffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
045564f00000026200ffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
045564f00000022200ffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
045564f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
045564f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001000000000000000000000000000000010000000000000000000000000000000100000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101090a0b0c010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101090a0b0c01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101191a1b1c010101010101010101010101010101010101
010101010101010101010101090a0b0c01010101010101010101010101010101010101191a1b1c0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
010101010101010101010101191a1b1c01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101090a0b0c0101010101010101010101010101090a0b0c0101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101090a0b0c0101010101010101010101010101010101010101010101010101010101191a1b1c0101010101010101010101010101191a1b1c0101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101191a1b1c0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101090a0b0c010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101090a0b0c01010101
0101010101191a1b1c0101010101010101010101010101090a0b0c01010101010101010101010101010101010101010101010101010101010101010101090a0b0c01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101191a1b1c01010101
0101010101010101010101010101010101010101010101191a1b1c01010101010101010101010101010101010101010101010101010101010101010101191a1b1c010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0707080708070807080708070807080708070807080708070807070807080708070807080708070807080708070807080708070807080708070807070807080708070807080708070807080708070708070807080708070807080708070807080708070807080708070708070807080707080708070807080707080708070807
0605060506050606050605060506050605060506050605060506060506050605060506050605060506050605060605060506050605060506050605060506050605060506050605060506050605060506050605060506050606050605060506050605060506050605060506050605060506050506050605060506050605060506
1615161516151616151615161516151615161516151615161516161516151615161516151615161516151615161615161516151615161516151615161516151615161516151615161516151615161516151615161516151616151615161516151615161516151615161516151615161516151516151615161516151615161516
00000000ba00000000e00ba000000ba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
018000001875024750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01800000102221c222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
018000001f2222b222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
018000001822224222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000472006720097200d72012720177201b720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000001472015720187201b7201e7202172024720000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000003610046100561006610066100a6000c6000d6000f6002440014600106001040017600204000a60018400104000b6001860022600166000460018600036000a6001b6001c6000f6001e6001e6001f600
000200000842017420144201962016620254200a4201a620144202442014620106201042017620204200a62018420104200b6001860022600166000460018600036000a6001b6001c6000f6001e6001e6001f600
000200000775007750077500775007750047500275001750015000000026700077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000306113d600000003f60000000000003f60000000000003f60000000000003d600000003a600000003460000000000002c600000000000000000000000000000000000000000000000000000000000000
011000080c7230000004124000000c625000000412400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100010187201740014400196001f7201c7200a4001a60014400244001c7201f72010400176001f7201c72018400104000b6001860022600166000460018600036000a6001b6001c6000f6001e6001e6001f600
011000080c7230000009124000000c625000000912400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000102472017400144001960023720217200a4001a6001440024400247202372010400176002172023720104000b6001860022600166000460018600036000a6001b6001c6000f6001e6001e6001f60000000
__music__
00 01020344
01 0a0b4344
00 0c0b4344
00 0a0d4344
02 0c0d4344

