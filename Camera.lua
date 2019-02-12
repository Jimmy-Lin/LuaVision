local synchronize = require(script.Parent.Synchronize)
local camera = {
	near = 1.0,
	far = 300.0,
	top = 1.0,
	bottom = -1.0,
	left = -1.0,
	right = 1.0,
	vertical_resolution = 64.0,
	horizontal_resolution = 64.0
}

-- Input Type = Part
-- Output Type = Tensor(n,n,4)
function camera.transform(eye)
	local horizontal_resolution = camera.horizontal_resolution
	local vertical_resolution = camera.vertical_resolution
	
	local data = {}
	local shape = {
		depth = 1,
		height = vertical_resolution,
		width = horizontal_resolution
	}
	
	local near = camera.near
	local far = camera.far
	local top = camera.top
	local bottom = camera.bottom
	local left = camera.left
	local right = camera.right
	
	local vertical_unit = (top - bottom) / vertical_resolution
	local horizontal_unit = (right - left) / horizontal_resolution
	
	local forward = eye.CFrame.lookVector
	local upward = eye.CFrame.upVector
	local rightward = eye.CFrame.rightVector
	
	local eye_origin = eye.Position
	local image_origin = eye_origin + forward * near
	
	local threads = {}
	
	for i = 1, horizontal_resolution do
		local thread = coroutine.create(function()
			for j = 1, vertical_resolution do
				local key = i .. ',' .. j
				local x = left +  (i-1) * horizontal_unit
				local y = top - (j-1) * vertical_unit
				local image_offset = x * rightward + y * upward
				local image_position = image_origin + image_offset
				local image_direction = (image_position - eye_origin).unit
				local ray = Ray.new(image_position, image_direction * far)
				local object, collision_point = workspace:FindPartOnRayWithIgnoreList(ray, {eye})
				local result
				if object == nil or object['Color'] == nil then
					result = Vector3.new(0,0,0)
				else
					local distance = (collision_point - image_position).magnitude
					local fog = 1 - (math.max(near, distance) - near) / (far - near)
					local color = object['Color']
					
					result = fog * Vector3.new(color.r, color.g, color.b)
				end
				data[key .. ',' .. 2] = result.X
				data[key .. ',' .. 3] = result.Y
				data[key .. ',' .. 4] = result.Z
				data[key .. ',' .. 1] = 0.2126 * result.X + 0.7152 * result.Y + 0.0722 * result.Z
			end
		end)
		coroutine.resume(thread)
		table.insert(threads, thread)
	end
	
	synchronize.all(threads, 'dead', 0.1)
	
	return { shape = shape, data = data }
end

return camera
