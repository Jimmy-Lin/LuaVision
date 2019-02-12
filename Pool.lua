local synchronize = require(script.Parent.Synchronize)

local pool = {
	pool_size = 5,
	pool_stride = 2
}

function pool.transform(input)
	local data = {}
	local pool_stride = pool.pool_stride
	local pool_size = pool.pool_size
	local pool_offset = math.floor(pool_size/2)
	local width = input.shape.width
	local height = input.shape.height
	local depth = input.shape.depth
	
	local shape = {
		depth = depth,
		height = math.floor((input.shape.height - 2 * pool_offset) / pool_stride),
		width = math.floor((input.shape.width - 2 * pool_offset) / pool_stride)
	}
	local output = { shape = shape, data = data }
	
	local threads = {}
	
	for k = 1, depth do
		local thread = coroutine.create(function()
			for i = 1 + pool_offset, width - pool_offset, pool_stride do
				for j = 1 + pool_offset, height - pool_offset, pool_stride do
					local max = nil
					
					for p = i - pool_offset, i + pool_offset do
						for q = j - pool_offset, j + pool_offset do
							local key = p..','..q..','..k
							local value = input.data[key]
							if max == nil then
								max = value
							else
								max = math.max(max, value)
							end
						end
					end
					
					local r = 1 + (i - pool_offset - 1)/pool_stride
					local s = 1 + (j - pool_offset - 1)/pool_stride
					
					output.data[r..','..s..','..k] = max
				end
			end
		end)
		coroutine.resume(thread)
		table.insert(threads, thread)
	end
	
	synchronize.all(threads, 'dead', 0.1)
	return output
end

return pool
