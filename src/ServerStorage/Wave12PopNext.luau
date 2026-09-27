return function(n)
	local q = require(game.ServerStorage.Wave12Queue)
	local cursor = game.ServerStorage:FindFirstChild('Wave12Cursor')
	if not cursor then
		cursor = Instance.new('IntValue')
		cursor.Name = 'Wave12Cursor'
		cursor.Value = 1
		cursor.Parent = game.ServerStorage
	end
	local jobs = {}
	for _ = 1, n do
		local job = q[cursor.Value]
		if not job then break end
		table.insert(jobs, job)
		cursor.Value += 1
	end
	return jobs
end
