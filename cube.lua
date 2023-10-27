--[[
    For matrix multiplication, the number of columns of the first matrix
    must match the numbers of rows of the second matrix.

    3 Rows       1 Rows
    3 Columns    1 Column
    [ 1 0 0 ]    [ x ]
    [ 0 1 0 ]    [ y ]
    [ 0 0 1 ]    [ z ]

    They match, therefore, the matrix multiplication is valid.

    The first row of the first matrix 
    is multiplied by the first column of the second matrix and
    the values are added together. So on and so forth.

    [ 1*x + 0*y + 0*z ]   [ x ] = [ 1 ] 
    [ 0*x + 1*y + 0*z ] X [ y ] = [ 1 ]
    [ 0*x + 0*y + 1*z ]   [ z ] = [ 1 ]
--]]

function point_to_matrix(point)
    local m = {}
    for i=1, #point do
        table.insert(m, {point[i]})
    end
    return m
end

function matmul(a, b)
    local colsA = #a[1]
    local rowsA = #a
    local colsB = #b[1]
    local rowsB = #b

    if(colsA ~= rowsB) then 
        error(
            string.format("Columns of matrix A: %d dont match Rows of matrix B: %d", colsA, rowsB)
        ) 
    end

    local result = {}

    for i=1, rowsA do
        table.insert(result, {})
        for j=1, colsB do
            table.insert(result[i], 0)
            local sum = 0;
            for k=1, colsA do
                sum = sum + a[i][k] * b[k][j]
            end 
            result[i][j] = sum
        end
    end

    return result;

end

function translate(point, origin)
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

-- function draw_point(p, color)
--     paintutils.drawPixel(p[1], p[2], color)
-- end
function draw_line(pA, pB, color)
    paintutils.drawLine(pA[1], pA[2], pB[1], pB[2], color)
end
function scale_matrix(m, scale)
    for i=1, #m do
        for j=1, #m[1] do
            m[i][j] = m[i][j] * scale
        end
    end
end
function rotateX(m, angle)
    rotationX = {
        {1, 0, 0},
        {0, cos(angle), -sin(angle)},
        {0, sin(angle), cos(angle)}
    }
    return matmul(rotationX, m)
end
function rotateY(m, angle)
    rotationY = {
        {cos(angle), 0, -sin(angle)},
        {0, 1, 0},
        {sin(angle), 0, cos(angle)}
    }
    return matmul(rotationY, m)
end
function rotateZ(m, angle)
    rotationZ = {
        {cos(angle), -sin(angle), 0},
        {sin(angle), cos(angle), 0},
        {0, 0, 1}
    }
    return matmul(rotationZ, m)
end
function draw_map()

    local w = origin[1]
    local h = origin[2]
    local off = 2 -- size of lines
    local gap = scale * 10

    draw_line({w, 1}, {w, height}, colors.white)
    draw_line({1, h}, {width, h}, colors.white)

    for i = w, 0, -gap do
        draw_line({i, h - off}, {i, h + off}, colors.white)
    end
    for i = w, width, gap do
        draw_line({i, h - off}, {i, h + off}, colors.white)
    end
    for i = h, 0, -gap do
        draw_line({w - off, i}, {w + off, i}, colors.white)
    end
    for i = h, height, gap do
        draw_line({w - off, i}, {w + off, i}, colors.white)
    end
end
function scale_vector(vector, scale)
    local vecopy = {}
    for i = 1, #vector do
        vecopy[i] = vector[i] * scale
    end
    return vecopy
end
--[[
    To render a 3 dimensional object onto 
    a 2 dimensional plane, we need to use a projection matrix.

    The projection matrix converts the 3 dimensional matrix from 
    the 3d object into a 2 dimension plane for rendering it into a 2d screen.

    3D point:            Projection Matrix (Projecting into 2D)        Result Matrix
        3x1                    2X3                                        2x1                                                              
        [ x ]               [ 1 0 0 ]                                    [ x ]
        [ y ]               [ 0 1 0 ]                                    [ y ]
        [ z ]

    If we multiply these matrices, the X spots 
    and Y spots on the projection matrix, along with the 0 on the Z non existent
    row, multiply with the 3D point and eliminate the Z coordinate.
    This exact matrix is used for ortographic projection.

]]

Cube = {}
function Cube.init(_origin_point, _size, _width, _height, _depth, _angleX, _angleY, _angleZ, _distance, _color)
    local self = setmetatable({}, Cube)

    self.origin_point = translate(scale_vector(_origin_point, scale), origin)
    self.size = _size
    self.width = _width
    self.height = _height
    self.depth = _depth
    self.angleX = _angleX
    self.angleY = _angleY
    self.angleZ = _angleZ
    self.distance = _distance
    self.color = _color
    self.projected2d = {}

    self.points = {
        {-self.width, -self.height, -self.depth},
        {self.width, -self.height, -self.depth},
        {self.width, self.height, -self.depth},
        {-self.width, self.height, -self.depth},
        {-self.width, -self.height, self.depth},
        {self.width, -self.height, self.depth},
        {self.width, self.height, self.depth},
        {-self.width, self.height, self.depth}
    }

    self.connect = function(p1, p2)
        draw_line(
            translate(scale_vector(p1, scale), self.origin_point), 
            translate(scale_vector(p2, scale), self.origin_point), 
            self.color, 
            self.origin_point
        )
    end

    self.update = function() 
        self.origin_point = translate(scale_vector(_origin_point, scale), origin)
    end

    self.render = function() 
        local projected2d_matrix = {}
        for i = 1, #self.points do
            --[[ Converts a 3d vector to 3x1 matrix ]]
            local point_matrix = point_to_matrix(self.points[i])
            --[[ Rotate the 3 dimensional point in 3 dimensional space first ]]

            local rotated = rotateX(point_matrix, self.angleX)
            rotated = rotateY(rotated, self.angleY)
            rotated = rotateZ(rotated, self.angleZ)
            --[[ 
                After rotations are done, calculate the 
                projected matrix from the result with perspective (distance from the camera, z axis)
            ]]
            local perspective
            if(self.distance > 0) then
                perspective = 1/(self.distance - rotated[3][1]) else perspective = 1
            end
            local projection_matrix = {
                {perspective, 0, 0},
                {0, perspective, 0},
                {0, 0, 1}
            } 
            --[[ 
                Project the result into 2D space
                p2d[1] = projected X component   |  p2d[1][1] = projected point of X component
                p2d[2] = projected Y component   |  p2d[2][1] = projected point of Y component
                p2d[3] = projected Z component   |  p2d[3][1] = projected point of Z component
            ]]
            self.projected_point = matmul(projection_matrix, rotated)
            scale_matrix(self.projected_point, self.size)
            table.insert(projected2d_matrix, {self.projected_point[1][1], self.projected_point[2][1]})
        end
        -- [[ Connect 4 planes of 2 dimensional cube projected as a 3 dimensional cube ]]
        for i=1, 4 do
            --connect point i to the next, if face is done (4 points), modulus to zero.
            self.connect(projected2d_matrix[i], projected2d_matrix[i % 4+1])
            --connect the next 4 points, if face is done (4 points), modulus to 4, since the first 4 are done.
            self.connect(projected2d_matrix[i+4], projected2d_matrix[(((i+2)%4)+ 1)+4])
            -- connect last points
            self.connect(projected2d_matrix[i], projected2d_matrix[i+4])
        end
        self.update()
    end
    return self
end


