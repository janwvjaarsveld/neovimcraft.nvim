-- Functions borrowed from folke/lazy.nvim
local neovimcraft_dir = "/neovimcraft"

local M = {}

function M.notify_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "Neovimcraft" })
end

-- Fast implementation to check if a table is a list
---@param tbl table
function M.is_list(tbl)
	local i = 0
	---@diagnostic disable-next-line: no-unknown
	for _ in pairs(tbl) do
		i = i + 1
		if tbl[i] == nil then
			return false
		end
	end
	return true
end

---@param value any
---@param indent string
function M.json_encode(value, indent)
	local t = type(value)

	if t == "string" then
		return string.format("%q", value)
	elseif t == "number" or t == "boolean" then
		return tostring(value)
	elseif t == "table" then
		local is_list = M.is_list(value)
		local parts = {}
		local next_indent = indent .. "  "

		if is_list then
			---@diagnostic disable-next-line: no-unknown
			for _, v in ipairs(value) do
				local e = M.json_encode(v, next_indent)
				if e then
					table.insert(parts, next_indent .. e)
				end
			end
			return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
		else
			local keys = vim.tbl_keys(value)
			table.sort(keys)
			---@diagnostic disable-next-line: no-unknown
			for _, k in ipairs(keys) do
				local e = M.json_encode(value[k], next_indent)
				if e then
					table.insert(parts, next_indent .. string.format("%q", k) .. ": " .. e)
				end
			end
			return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
		end
	end
end

function M.save(data, path)
	local f = io.open(path, "w")
	if f then
		f:write(M.json_encode(data, ""))
		f:close()
	else
		M.notify_error("Failed to save to " .. path)
	end
end

function M.save_db(data, path)
	local dir_path = path .. neovimcraft_dir
	local full_path = dir_path .. "/db.json"
	-- create directory if it doesn't exist
	local ok = os.execute("mkdir -p " .. dir_path)
	if not ok then
		M.notify_error("Failed to create directory " .. dir_path)
	end
	M.save(data, full_path)
end

function M.load_db(path)
	local f = io.open(path .. "/neovimcraft/db.json", "r")
	if f then
		local content = f:read("*a")
		f:close()
		return vim.fn.json_decode(content)
	end
	return nil
end

function M.array_contains(arr, value)
	for _, v in ipairs(arr) do
		if v == value then
			return true
		end
	end
	return false
end

return M
