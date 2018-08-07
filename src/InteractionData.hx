import haxegon.*;
import haxe.ds.Vector;
import Entity;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class InteractionData {

	static inline var bananas_energy = 4;
	static inline var tree_wood = 4;

	static var to_attacker: Map<String, Map<String, Map<String, Int>>> = [
		"gnome" => [
			"bananas" => [
				"energy" => bananas_energy,
			],

			"tree" => [
				"wood" => tree_wood,
			],

			"dragon" => [
				"happy" => 5,
			],

			"flower" => [
				"happy" => 5,
			],
		],

		"dragon" => [
			"gnome" => [
				"energy" => 100,
				"happy" => 100,
			],
		],
	];

	static var to_goal: Map<String, Map<String, Map<String, Int>>> = [
		"dragon" => [
			"gnome" => [
				"health" => -1,
			],
		],

		"gnome" => [
			"banana" => [
				"health" => -1,
			],
			"tree" => [
				"health" => -1,
			],
		],
	];

	static var names: Map<String, Map<String, String>> = [
		"gnome" => [
			"gnome" 	=> "talk",
			"bananas" 	=> "eat",
			"dragon" 	=> "attack",
			"flower" 	=> "look",
			"tree" 		=> "collect",
		],

		"dragon" => [
			"gnome" => "attack",
		],
	];
}