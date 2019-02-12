local synchronize = require(script.Parent.Synchronize)

function box(size)
	local mask = {}
	local value = 1.0 / math.pow(size,2)
	for i = 1, size do
		for j = 1, size do
			local key = i .. ',' .. j
			mask[key] = value
		end
	end
	return mask
end

function identity(size)
	local mask = {}
	local mid = size/2 + 0.5
	for i = 1, size do
		for j = 1, size do
			local key = i .. ',' .. j
			if i == mid and j == mid then
				mask[key] = 1
			else
				mask[key] = 0
			end
		end
	end
	return mask
end

function laplacian(size)
	local mask = {}
	local peak = -(math.pow(size, 2) - 1)
	local mid = size/2 + 0.5
	for i = 1, size do
		for j = 1, size do
			local key = i .. ',' .. j
			if i == mid and j == mid then
				mask[key] = peak
			else
				mask[key] = -1
			end
		end
	end
	return mask
end

function vertical_derivative(size)
	local mask = {}
	local scale = math.pow(size, 0)
	local mid = size/2 + 0.5
	for i = 1, size do
		for j = 1, size do
			local key = i .. ',' .. j
			if i < mid then
				mask[key] = -1.0 / scale
			elseif i == mid then
				mask[key] = 0
			elseif i > mid then
				mask[key] = 1.0 / scale
			end
		end
	end
	return mask
end

function horizontal_derivative(size)
	local mask = {}
	local scale = math.pow(size, 0)
	local mid = size/2 + 0.5
	for i = 1, size do
		for j = 1, size do
			local key = i .. ',' .. j
			if j < mid then
				mask[key] = -1.0 / scale
			elseif j == mid then
				mask[key] = 0
			elseif j > mid then
				mask[key] = 1.0 / scale
			end
		end
	end
	return mask
end

local mask_size = 5
local convolve = {
	mask_size = mask_size,
	masks = {
		identity(mask_size),
		box(mask_size),
		laplacian(mask_size),
		horizontal_derivative(mask_size),
		vertical_derivative(mask_size)
	}
}

-- Input Type = Tensor(w,h,d)
-- Output Type = Tensor(w-2k,h-2k,d*m) where m = # masks and k = floor(m/2)
function convolve.transform(input)
	local data = {}
	local mask_count = #(convolve.masks)
	local mask_size = convolve.mask_size
	local mask_offset = math.floor(mask_size/2)
	local width = input.shape.width
	local height = input.shape.height
	local depth = input.shape.depth
	
	local shape = {
		depth = depth * mask_count,
		height = input.shape.height - 2 * math.floor(convolve.mask_size/2),
		width = input.shape.width - 2 * math.floor(convolve.mask_size/2)
	}
	local output = { shape = shape, data = data }
	
	local threads = {}
	
	for k = 1, depth do
		local thread = coroutine.create(function()
			for w = 1, mask_count do
				--wait()
				local mask = convolve.masks[w]
				-- Apply mask to slice at depth k and write results to depth (k - 1) * mask_count + w
				local output_depth = (k - 1) * mask_count + w
				
				local min = nil
				local max = nil
				local count = 0
				
				for i = 1 + mask_offset, width - mask_offset do
					for j = 1 + mask_offset, height - mask_offset do
						local output_key = (i - mask_offset) .. ',' .. (j - mask_offset) .. ',' .. output_depth
						-- Computed the local dot product
						local value = dot_product(input, i, j, k, mask)
						output.data[output_key] = value
						
						if min == nil then
							min = value
						else
							min = math.min(min, value)
						end
						if max == nil then
							max = value
						else
							max = math.max(max, value)
						end
					end
				end
			end
		end)
		coroutine.resume(thread)
		table.insert(threads, thread)
	end
	
	synchronize.all(threads, 'dead', 0.1)
	return output
end

function dot_product(input, i, j, k, mask)
	local m = convolve.mask_size
	local k = math.floor(m/2)
	local x = i + k
	local y = j + k
	local result = 0.0
	for p = 1, m do
		for q = 1, m do
			-- (p,q) = mask coordinate
			-- (r,s) = image coordinate (reflected)
			local r = x - (p-1)
			local s = y - (q-1)
			--r = (i-k) + (p-1)
			--s = (j-k) + (q-1)
			local weight = mask[p .. ',' .. q]
			local value = input.data[r .. ',' .. s .. ',' .. k]
			result = result + weight * value
		end
	end
	return result
end

return convolve
