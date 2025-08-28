local definitions = require("@definitions")
local api = require("@definitions/api")
local global_types = require("@src/global_types")

local function lib(): typeof(definitions)
	local project: global_types.Project = {
		place_decls = {} :: { global_types.PlaceRepresentation },
		constant_decls = {},
		id_map = {},
	}

	local api = {
		_internal = project,
	}

	function api.declare_place(name: string, place: api.Place)
		local representation: global_types.PlaceRepresentation = {
			name = name,
			config = place,
		}

		table.insert(project.place_decls, representation)
	end

	function api.declare_constant(name: string, constant: api.Place) end

	return api :: any
end

return lib
