local api = require("@definitions/api")

export type PlaceRepresentation = {
	config: api.Place,

	name: string,
}

export type Project = {
	id_map: {
		[string]: number,
	},

	constant_decls: {
		[string]: api.Constant,
	},

	place_decls: { PlaceRepresentation },
}

return nil
