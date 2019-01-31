pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

gravity = 0.25
xmove = 0
ymove = 0

player = {
    x = 10,
    y = 96-8,
    w = 8,
    h = 8,
    speed = 1,
    jump_speed = -3,
    jumping = false,
    grounded = true,
}

ground = {
    x = 0,
    y = 96,
    w = 128,
    h = 128,
}

function _update()
    get_input()

    local collide_x = did_collide_x()
    local collide_y = did_collide_y()

    if collide_x == false then
        player.x = player.x + xmove
    end

    if collide_y == false then
        ymove = ymove + gravity

        -- if (player.grounded == false) then
            player.y = player.y + ymove
        -- end
    elseif collide_y == true then
        player.grounded = true
        player.jumping = false
        player.y = (ground.y - player.h)

        ymove = 0
    end

    xmove = 0
    if ymove < 0 then
        ymove = 0
    end
end

function get_input()
    if btn(0) then
        xmove = -player.speed
    end

    if btn(1) then
        xmove = player.speed
    end

    if btn(2) and (player.jumping == false) then
        ymove = player.jump_speed

        player.jumping = true
        player.grounded = false
    end
end

function did_collide_x()
    local collide_x = false

    return collide_x
end

function did_collide_y()
    local collide_y = false

    if player.grounded == false then
        if (player.y + player.h + ymove) >= ground.y then
            collide_y = true
        end
    end

    return collide_y
end

function debug_info()
    print("ymove: " .. ymove, 0, 0)
    print("grounded: " .. (player.grounded and "true" or "false"), 0, 10)
    print("jumping: " .. (player.jumping and "true" or "false"), 0, 20)
    print("x: " .. player.x .. ", y: " .. player.y, 0, 30)
end

function _draw()
    cls(0)

    debug_info()

    draw_scene()
    draw_player()
end

function draw_player()
    spr(1, player.x, player.y)
end

function draw_scene()
    rectfill(ground.x, ground.y, ground.w, ground.h, 11)
end

__gfx__
00000000000909000000000000666660000000000004400000004400499999940000000000005000050606060800080000080000000000000000000000000000
000000000003980000090900065766570066666000444000000444000499bbbb4999999400055600005566608880888000880000000000000000000000000000
007007000aafaaa00003980006656065065766570444400004444400999bbb8b0499bbbb00506060055506668888878000788000000000000000000000000000
00077000aaff4f400aafaaa000655655066560650fcfc0000fcfc000bb3bbbb3999bbb8b05550666005000608888878000888000000000000000000000000000
000770000a3ffff0aaff4f4066677770006556550ffff0000ffff000bb34bbbbbb3bbbb300505060055506660888880000888000000000000000000000000000
00700700aaee88900a3ffff0606777756667777002f2240002222000bbb33403bb34bbbb00055600005556600088800000888000000000000000000000000000
00000000ae877d60aaee889000600050606777750222200002f224004bb04433bbb3340300005000050505060088800000088000000000000000000000000000
0000000008888880ae877d6000600050006000500f0040000f004000bb0003304bb0443300000000000000000008000000080000000000000000000000000000
