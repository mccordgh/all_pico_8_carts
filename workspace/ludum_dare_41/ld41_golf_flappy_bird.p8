pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
function _init()
    init_game_vars()
    init_ball_vars()
end

function init_game_vars()

end

function init_ball_vars()
    ball = {}
    ball.x = 16
    ball.y = 116
end
-->8
function _update()
    if (btn(1)) then
        ball.x += 10
    end

    if (btn(0)) then
        ball.x -= 10
    end
end
-->8
function _draw()
    cls()
    camera(ball.x - 64 < 0 and 0 or ball.x - 64)

    map(0, 0, 0, 0, 128, 16)

    spr(3, ball.x, ball.y)
end
__gfx__
00000000ccccccccbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccbbbbbbbb000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ccccccccbbbbbbbb00ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ccccccccbbbbbbbb0fff77f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ccccccccbbbbbbbb0ffff7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ccccccccbbbbbbbbffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccbbbbbbbb0ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccccbbbbbbbb00ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102020201010101010101010101010101010101010101010101010101020202010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101020201010202010101010101010101010101010101010101010101010202010101020201010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101020202020101010101010101010101010101010101010101010101010102020101010101020201010101010101010101010101010101010101020201010101010102020101010101010101010101010101010101010101010102
0201010101010102020202020202020101010101010101010101010101010101010101010102020101010202020101010101010101010101010101010101010101010201010101010101010102020101010101010101010101010101010201010101010101010101010202010101010101010101010101010101010101010102
0201010101010202010101010101010202010101010101010101010101010101010101020202010101010101010202010101010101010101010101010101010102020101010101010101010101020201010101010101010101010101010201010101010101010101010101020101010101010101010101010101010101020202
0201010101020101010101010101010101020202020101010101010101010101020202010101010101010101010102020201010101010101010101010101020201010101010101010101010101010202010101010101010101010101020101010101010101010101010101010201010101010101010101010101010102020102
0201010102010101010101010101010101010101020202020201010102020202020101010101010101010101010101010202020101010101010101010202010101010101010101010101010101010101020201010101010101010202010101010101010101010101010101010102010101010101010101010101020201010102
0201010201010101010101010101010101010101010101010101020201010101010101010101010101010101010101010101010202020101010102020201010101010101010101010101010101010101010202020201010101010201010101010101010101010101010101010101020101010101010101010202010101010102
0201020101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020201010101010101010101010101010101010101010101010101010202020202020101010101010101010101010101010101010101010202010101010102020101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102020202020201010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010102
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
