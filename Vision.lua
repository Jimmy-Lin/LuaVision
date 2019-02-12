camera = require(script.Camera)
convolve = require(script.Convolve)
pool = require(script.Pool)
visualize = require(script.Visualize)

vision = {
	eye = script.Parent.Parent.Head
}

-- Pipeline plan
-- camera Plane: maintains a frame that gets updated by rays.
-- Interpolation Plane: interpolates values from sensor frame to upsample
-- Luminence Plane: Computes the greyscale of the interpolated plane
-- Gaussian Plane: computes a low-pass of the interpolated plane
-- Laplacian Plane: computes a high-pass of the interpolated plane
-- Vertical Derivative Plane: computes the vertical derivative
-- Horizontal Derivative Plane: computes the horizontal derivative

-- Edge Detection
-- Corner Detection
-- Texton Segmentation
-- Texture Segmentation



function render(eye)
	local target = eye
	local layer
	layer = camera.transform(eye)
	visualize.display(layer, target)
	wait(1)
	layer = convolve.transform(layer)
	--visualize.display(layer, target)
	wait(1)
	layer = pool.transform(layer)
	--visualize.display(layer, target)
	wait(1)
end

function initialize()
	local eye = vision.eye
	while true do
		render(eye)
		wait(0.1)
	end
end

initialize()