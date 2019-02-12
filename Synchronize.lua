local synchronize = {}

function synchronize.all(threads, thread_state, polling_period)
	while true do
		local all_threads_ready = true
		
		for _, thread in ipairs(threads) do
			if coroutine.status(thread) ~= thread_state then
				all_threads_ready = false
				break
			end
		end
		
		if all_threads_ready == true then
			break
		end
		
		wait(polling_period)
	end
end

return synchronize
