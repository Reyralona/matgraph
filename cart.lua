--[[ convert coordinates with origin at center to lua coordinates --]] 
function plane_coords(point)
    local x = 0
    local y = 0

    if (y > 0) then
        y = point[2] + origin[2]
    else
        y = -point[2] + origin[2]
    end

    x = point[1] + origin[1]
    return {x, y}
end

function scale_vector(vector, scale)
    local vecopy = {}
    for i = 1, #vector do
        vecopy[i] = vector[i] * scale
    end
    return vecopy
end

function draw_map()

    local w = origin[1]
    local h = origin[2]
    local off = 2 -- size of lines
    local gap = scale * number_line

    line({w, 1}, {w, height}, colors.white)
    line({1, h}, {width, h}, colors.white)

    for i = w, 0, -gap do
        line({i, h - off}, {i, h + off}, colors.white)
    end
    for i = w, width, gap do
        line({i, h - off}, {i, h + off}, colors.white)
    end
    for i = h, 0, -gap do
        line({w - off, i}, {w + off, i}, colors.white)
    end
    for i = h, height, gap do
        line({w - off, i}, {w + off, i}, colors.white)
    end

end

function clear()
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)
    term.clear()
end

function draw_point(pointobj, color)
    if (not point_off_bounds(pointobj)) then
        paintutils.drawPixel(pointobj[1], pointobj[2], color)
    else
        write({width - 8 * 8, 20}, "POB:TRUE")
    end
end

function line(pA, pB, color)
    paintutils.drawLine(pA[1], pA[2], pB[1], pB[2], color)
end

function box(coords, color)
    paintutils.drawBox(coords[1], coords[2], coords[3], coords[4], color)
end

function circle(cp, r, n, color)
    -- cp: center point
    -- r: radius
    -- n: num of points
    local delta_theta = 2 * math.pi / n
    local vertices = {}

    for i = 0, n do
        local theta = i * delta_theta
        local x = cp[1] + r * math.cos(theta)
        local y = cp[2] + r * math.sin(theta)
        local point = plane_coords(scale_vector({x, y}, scale))
        table.insert(vertices, point)
    end

    -- # Connect the vertices to draw the polygon
    for i = 1, n do
        local sp = vertices[i]
        local ep = vertices[i + 1]
        line(sp, ep, colors.red)
    end
end

function draw_polygon_from_points(pa, cl, cp)
    -- pa: point array 
    -- cl: color lines
    -- cp: color points

    for i = 1, #pa do
        for j = i + 1, #pa do
            local l1 = plane_coords(scale_vector(pa[i], scale))
            local l2 = plane_coords(scale_vector(pa[j], scale))
            line(l1, l2, cl)

        end
        local p = plane_coords(scale_vector(pa[i], scale))
        draw_point(p, cp)

    end
end

function draw_polygon_from_segments(sa, cl, cp)
    -- sa: segment array
    --     segment: { {p1.x, p1.y}, {p2.x, p2.y} }     -- cl: color lines
    -- cp: color points
    for i = 1, #sa do
        local l1 = plane_coords(scale_vector(sa[i][1], scale))
        local l2 = plane_coords(scale_vector(sa[i][2], scale))

        line(l1, l2, cl)
        draw_point(l1, cp)
        draw_point(l2, cp)

    end
end
--[[ 
    This is stupid but it works lol 
--]]
-- function fy(exp, domain)
--     local points = {}

--     for i = domain[1], domain[2], domain[3] do
--         res = lxp.evaluate(exp, {
--             y = i
--         })
--         table.insert(points, {res, i})
--     end
--     return points
-- end

function draw_char(pos, charmat)
    for i = 1, 8 do
        for j = 1, 8 do
            local col = charmat[j][i]
            if (col == 1) then
                draw_point({pos[1] + i, pos[2] + j}, col)
            end
        end
    end
end

function write(pos, str)
    if (point_off_bounds(pos)) then
        return
    end
    local x = pos[1]
    local y = pos[2]
    for i = 1, #str do
        local char = char_map[str:sub(i, i)]
        draw_char({x, y}, char)
        x = x + 8
    end
end

function point_off_bounds(point)
    if (point[1] < 0 or point[1] > width) or (point[2] < 0 or point[2] > height) then
        return true
    end
end

function fx(exp, domain)
    local points = {}

    for i = domain[1], domain[2], domain[3] do
        res = lxp.evaluate(exp, {
            x = i
        })
        table.insert(points, {i, res})
    end
    return points
end

function plot_function(pa, lcolor, pcolor)
    -- pa: point array
    -- write({1, 20}, string.format("NOP: %d", #pa))
    for i = 1, #pa do
        local p = plane_coords(scale_vector(pa[i], scale))
        if (i < #pa) then
            local p2 = plane_coords(scale_vector(pa[i + 1], scale))
            line(p, p2, lcolor)
        end
        draw_point(p, pcolor)
        if (animate_function == 1) then
            sleep(clockspeed)
        end
    end
    animate_function = 0

end

function update_origin(dx, dy)
    origin = {dx, dy}
    -- if (clicked_x_pos < dx) then
    --     origin[1] = origin[1] + 1
    -- end
    -- if (clicked_x_pos > dx) then
    --     origin[1] = origin[1] - 1
    -- end
    -- if (clicked_y_pos < dy) then
    --     origin[2] = origin[2] + 1
    -- end
    -- if (clicked_y_pos > dy) then
    --     origin[2] = origin[2] - 1
    -- end
end

function oscillate(n, dir, min, max, interval)

    if (dir == 1) then
        n = n + interval
    else
        n = n - interval
    end
    if (n >= max and dir == 1) then
        dir = 0
    elseif (n <= min and dir == 0) then
        dir = 1
    end

    return n, dir
end

function update_clicked_pos(x, y)
    clicked_x_pos = x
    clicked_y_pos = y
end

function clicked_inside(coords)
    local x1 = coords[1]
    local y1 = coords[2]
    local x2 = coords[3]
    local y2 = coords[4]
    local x = clicked_x_pos
    local y = clicked_y_pos
    if (x > x1 and x < x2 and y > y1 and y < y2) then
        return true
    end
    return false
end

--[[
    TODO:

    [X] -> Cartesian Plane
    [X] -> Scaling function
    [X] -> Draw Polygons
    [ ] -> Draw Polygons but only outer lines
    [ ] -> Solve flickering (unlikely)
    [X] -> Graph Functions
    [X] -> To move around the graph, recalculate the cartesian plane origin from mouse drag coordinates
            [ ] ? It doesnt work as expected, try calculating the direction of the mouse drag and updating 
                  The origin coordinates accordingly
            [X] ? It works as expected, but the movement is not smooth as it doesnt calculate diagonals,
                  Only the changes in X and Y coordinates 
                  (Actually using drag again, but limited to a center hitbox)
--]]

--[[
    Libraries
--]]
-- require "intersect"
require "char_matrices"
require "cube"
lxp = require "luaxp"
pretty = require("cc.pretty")

--[[
    General Config
--]]
sin = math.sin
cos = math.cos
term.setGraphicsMode(1)
width, height = term.getSize(1)

--[[
    General Coordinates
--]]

--[[ 
    Globals
--]]
pp = pretty.pretty_print
scale = 10
origin = {width / 2, height / 2}
clicked_x_pos, clicked_y_pos = 1, 1
animated = 1
number_line = 5
clockspeed = 0.1
animate_function = 0
clock = os.startTimer(clockspeed)
loop = 1

cube1 = Cube.init({-10, 0}, 10, 0.5, 0.5, 0.5, 0, 0, 0, 2, colors.lime)
cube2 = Cube.init({10, 0}, 10, 0.5, 0.5, 0.5, 0, 0, 0, 2, colors.cyan)
d1 = 1
n1 = 0

d2 = 1
n2 = 0

while (loop == 1) do
    clear()
    draw_map()
    --[[
        Moving Coordinates
    --]]
    origin_coords = {origin[1] - scale * 1, origin[2] - scale * 1, origin[1] + scale * 1, origin[2] + scale * 1}
    --[[ 
        Draw box around origin to move around graph 
    --]]
    box(origin_coords, colors.gray)

    cube1.render()
    cube2.render()
    -- cube1.update()
    -- cube2.update()

    write({1, 1}, string.format("SCALE:%d", scale))
    write({width - 14 * 8, 10}, string.format("NUMBER LINE:%2d", number_line))
    local coords = string.format("X:%d Y:%d", origin[1], origin[2])
    write({width - #coords * 8, 1}, coords)

    func = string.format("sin(cos(x-%.2f*2)+%.2f)", n2, n2)
    plot_function(fx(func, {-10, 10, 0.5}), colors.lime, colors.blue)
    write({1, 10}, string.format("F(X)=%s", string.upper(func)))

    --[[ To oscillate between two values --]]
    -- n1, d1 = oscillate(n1, d1, -100, 100, 0.525)
    n2 = n2 + 0.5

    -- draw_polygon_from_points(
    --     {{-5, 5}, {-15, 5}, {-15, 15}, {-5, 15}, {-10, 20}, {-10, 10}, {-20, 10}, {-20, 20}}
    --     , colors.lime, colors.blue
    -- )

    -- circle({10, 10}, 5, 100, colors.red)

    -- draw_polygon_from_segments({{{-5, 5}, {-5, 15}}, -- A
    -- {{-5, 15}, {-10, 20}}, -- B
    -- {{-10, 20}, {-20, 20}}, -- C
    -- {{-20, 20}, {-15, 15}}, -- D
    -- {{-15, 15}, {-5, 15}}, -- E
    -- {{-15, 15}, {-15, 5}}, -- F
    -- {{-15, 5}, {-20, 10}}, -- G
    -- {{-20, 10}, {-20, 20}}, -- H 
    -- {{-15, 5}, {-5, 5}} -- I
    -- }, colors.cyan, colors.yellow)

    evts = {os.pullEvent()}

    if (animated == 1) then
        if (evts[1] == "timer" and evts[2] == clock) then
            cube1.angleX = cube1.angleX + 0.05
            cube1.angleZ = cube1.angleZ + 0.05
            cube2.angleY = cube2.angleY + 0.05
            cube2.angleZ = cube2.angleZ + 0.05
            clock = os.startTimer(clockspeed)
        end
    end

    if (evts[1] == "mouse_scroll" and evts[2] > 0) then -- scrolling down, scale down
        if (scale > 1) then
            scale = scale - 1
        end
    end
    if (evts[1] == "mouse_scroll" and evts[2] < 0) then -- scrolling up, scale up
        if (scale < 100) then
            scale = scale + 1
        end
    end

    if (evts[1] == "term_resize") then
        width, height = term.getSize(1)
        origin = {width / 2, height / 2}
    end

    if (evts[1] == "mouse_click") then
        update_clicked_pos(evts[3], evts[4])
    end

    if (evts[1] == "mouse_drag") then
        if (clicked_inside(origin_coords)) then
            update_clicked_pos(evts[3], evts[4])
            update_origin(evts[3], evts[4])
        end
    end
    -- sleep(0.1)
end
