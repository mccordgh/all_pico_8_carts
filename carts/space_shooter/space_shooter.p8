pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
t = 0 --time

function _init()
    ship = { x = 64, y = 120, spr = 1}
    bullets = {}
    enemies = {}

    for i = 1, 10 do
        add(enemies, { spr = 17, mx = i * 16, my = 60 - i * 8, x = -64, y = -32, rot = 30})
    end
end

function fire()
    local b = {spr = 3, x = ship.x, y = ship.y, dx = 0, dy = -3}

    add(bullets, b)
end

function _update()
    t += 1

    for b in all(bullets) do
        b.x += b.dx
        b.y += b.dy

        if (b.x < 0 or b.x > 128) or (b.y < 0 or b.y > 128) then
            del(bullets, b)
        end
    end

    if (t % 6 < 3) then
        ship.spr = 1
    else
        ship.spr = 2
    end

    for e in all(enemies) do
        if (t % 6 < 3) then
            e.spr = 17
        else
            e.spr = 18
        end

        e.x = e.rot * sin(t / 50) + e.mx
        e.y = e.rot * cos(t / 50) + e.my
        e.my += 0.1
    end

    if (btn(0)) then ship.x -= 1 end
    if (btn(1)) then ship.x += 1 end
    if (btn(2)) then ship.y -= 1 end
    if (btn(3)) then ship.y += 1 end

    if (btnp(4)) then fire() end
end

function _draw()
    cls()

    for b in all(bullets) do
        spr(b.spr, b.x, b.y)
    end

    spr(ship.spr, ship.x, ship.y)

    for e in all(enemies) do
        spr(e.spr, e.x, e.y)
    end

    for i = 1, ship.mh do

    end
end
__gfx__
000000000080080000800800000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000080080000800800000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700008888000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000088008800880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000088cc880088cc88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700080880800808808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a00000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b3b0000b3b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b373b00b373b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b37373bb37373b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b37373b00b37373b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b373b0000b373b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b3b000000b3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b00000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000