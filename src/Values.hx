import haxegon.*;
import haxe.ds.Vector;
import Entity;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class Values {

	static inline var bananas_energy = 40;
	static inline var tree_wood = 40;

	// NOTE: can optimize name to avoid hashing by strings
    // make an array of names, use the index of the name in this array 
    // instead of string itself

	static var values: Map<String, Map<String, Map<String, Int>>> = [
		"gnome" => [
			"bananas" => [
				"energy" => bananas_energy,
			],

			"tree" => [
				"wood" => tree_wood,
			],

			"dragon" => [
				"dislike" => 5,
			],
		],

		"dragon" => [
			"gnome" => [
				"energy" => 100,
				"dislike" => 100,
			],
		],
	];
}