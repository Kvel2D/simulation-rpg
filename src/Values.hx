import haxegon.*;
import haxe.ds.Vector;
import Entity;

using haxegon.MathExtensions;
using Lambda;

class Values {

	// NOTE: can optimize name to avoid hashing by strings
    // make an array of names, use the index of the name in this array 
    // instead of string itself

	var values: Map<String, Map<String, Map<String, Int>>> = {
		"gnome" => {
			"bananas" => {
				"energy" => 40,
			},

			"tree" => {
				"wood" => 40,
			},

			// ex:
			// "dragon" => {
			// 	"dislike" => 40,
			// },
		},

		// ex:
		// "dragon" => {
		// 	"bananas" => {
		// 		"energy" => 10,
		// 	},

		// 	"gnome" => {
		// 		"energy" => 40,
		// 		"dislike" => 40,
		// 	},
		// },
	};
}