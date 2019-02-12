local visualize = {
	initialized = false,
	board_size = 100,
	depth_separation = 6
}

-- Input Type: Tensor(A, B, C), Part
-- Output Type: None
function visualize.display(tensor, target)
	local data = tensor.data
	local shape = tensor.shape
	local width = shape.width
	local height = shape.height
	local depth = shape.depth
	local x_unit = 1.0 / width
	local y_unit = 1.0 / height
	local depth_separation = visualize.depth_separation
	local depth_var = math.ceil(depth / 2.0)
	if visualize.initialized == false then
		visualize.initialized = true
		for k = 1, depth do
			local billboard = Instance.new('BillboardGui', target)
			billboard.Name = tostring(k)
			billboard.Size = UDim2.new(0, visualize.board_size, 0, visualize.board_size)
			billboard.SizeOffset = Vector2.new(0, 0.6)
			billboard.StudsOffsetWorldSpace = Vector3.new(k - depth_var, 0, 0) * depth_separation
			for i = 1, width do
				for j = 1, height do
					local name = i .. ',' .. j
					local size = UDim2.new(x_unit, 0, y_unit, 0)
					local position = UDim2.new((i-1) * x_unit, 0, (j-1) * y_unit, 0)
					local pixel = Instance.new('Frame', billboard)
					pixel.BorderSizePixel = 0
					pixel.Size = size
					pixel.Position = position
					pixel.Name = name
				end
			end
		end
	end
	for k = 1, depth do
		coroutine.wrap(function()
			local billboard = target[tostring(k)]
			for i = 1, width do
				for j = 1, height do
					local name = i .. ',' .. j
					local key = name .. ',' .. k
					local pixel = billboard[name]
					if data[key] == nil then
						pixel.BackgroundColor3 = Color3.new(0,0,0)
					else
						local value = math.abs(data[key])
						value = math.min(math.max(0, value), 1)
						pixel.BackgroundColor3 = Color3.new(value, value, value)
					end
				end
			end
		end)()
	end
end

return visualize
