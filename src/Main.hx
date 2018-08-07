import haxegon.*;
import haxe.ds.Vector;
import haxe.Timer;
import Entity;

using haxegon.MathExtensions;
using Lambda;


@:publicFields
class Main {
	static inline var screen_width = 1600;
	static inline var screen_height = 1000;
	static inline var scale = 4;
	static inline var tilesize = 8;
	static inline var map_width = 100;
	static inline var map_height = 100;
	static inline var view_width = 31;
	static inline var view_height = 31;

	var paused = false;

	var turn_timer = 0;
	static inline var turn_timer_max  = 10;


	var tiles = Data.int_2d_vector(map_width, map_height);
	var free_map = Data.bool_2d_vector(map_width, map_height);
	var entity_count = Data.int_2d_vector(map_width, map_height);

	var player: Player;

	var tracked_entity: Dynamic = null;
	var history_scroll = 0;

	var mob_names = [
	"gnome",
	"dragon",
	];
	var mob_lists = new Map<String, Array<Mob>>();
	var mob_population_caps: Map<String, Int> = [
	"gnome" => 50,
	"dragon" => 70,
	];
	var mob_growth_chances: Map<String, Int> = [
	"gnome" => 0,
	"dragon" => 0,
	];
	var cap_reduce_timers = new Map<String, Int>();
	static inline var cap_reduce_timers_max = 100;
	var mob_tiles: Map<String, Int> = [
	"gnome" => Tiles.Gnome,
	"dragon" => Tiles.Dragon,
	];


	var resource_names = [
	"bananas",
	"tree",
	"flower",
	];
	var resource_lists = new Map<String, Array<Resource>>();
	var resource_tiles: Map<String, Int> = [
	"bananas" => Tiles.Bananas,
	"tree" => Tiles.Tree,
	"flower" => Tiles.Flower,
	];
	var resource_caps: Map<String, Int> = [
	"bananas" => 300,
	"tree" => 300,
	"flower" => 10,
	];
	var resource_respawn_chances: Map<String, Int> = [
	"bananas" => 50,
	"tree" => 50,
	"flower" => 30,
	];

	function new() {
		Gfx.resize_screen(screen_width, screen_height);
		Text.setfont("pixelFJ8", 16);
		Gfx.load_tiles("tiles", tilesize, tilesize);

		#if flash
		Gfx.resize_screen(screen_width, screen_height, 1);
		#else 
		Gfx.resize_screen(screen_width, screen_height, 1);
		#end


		// Initialize mob variables
		for (name in mob_names) {
			mob_lists[name] = new Array<Mob>();

			if (!mob_population_caps.exists(name)) {
				trace('Population cap undefined for \"${name}\"');
				mob_population_caps[name] = 1000;
			}

			if (!mob_growth_chances.exists(name)) {
				trace('Growth chance undefined for \"${name}\"');
				mob_growth_chances[name] = 0;
			}

			cap_reduce_timers[name] = 0;

			if (!mob_tiles.exists(name)) {
				trace('Tile undefined for \"${name}\"');
				mob_tiles[name] = Tiles.None;
			}
		}

		// Initialize resource variables
		for (name in resource_names) {
			resource_lists[name] = new Array<Resource>();

			if (!resource_caps.exists(name)) {
				trace('Population cap undefined for \"${name}\"');
				mob_population_caps[name] = 1000;
			}

			if (!resource_tiles.exists(name)) {
				trace('Tile undefined for \"${name}\"');
				resource_tiles[name] = Tiles.None;
			}
		}

		for (x in 0...map_width) {
			for (y in 0...map_height) {
				entity_count[x][y] = 0;
			}
		}

		for (x in 0...map_width) {
			for (y in 0...map_height) {
				free_map[x][y] = true;
			}
		}

		for (x in 0...map_width) {
			for (y in 0...map_height) {
				tiles[x][y] = Tiles.Ground;
			}
		}


		player = new Player();
		player.x = 50;
		player.y = 50;
		add_to_free_map(player.x, player.y);



		for (i in 0...10) {
			var position = {
				x: 50 + Random.int(-20, 20), 
				y: 50 + Random.int(-20, 20)
			};
			if (free_map[position.x][position.y]) {
				make_gnome(position.x, position.y);
			}
		}

		// for (i in 0...20) {
		// 	var position = {
		// 		x: 130 + Random.int(-20, 20), 
		// 		y: 130 + Random.int(-20, 20)
		// 	};
		// 	if (free_map[position.x][position.y]) {
		// 		make_dragon(position.x, position.y);
		// 	}
		// }


		for (i in 0...10) {
			var position = {
				x: 50 + Random.int(-20, 20), 
				y: 50 + Random.int(-20, 20)
			};
			if (free_map[position.x][position.y]) {
				make_resource(position.x, position.y, "bananas");
			}
		}
		for (i in 0...10) {
			var position = {
				x: 50 + Random.int(-20, 20), 
				y: 50 + Random.int(-20, 20)
			};
			if (free_map[position.x][position.y]) {
				make_resource(position.x, position.y, "tree");
			}
		}

		for (i in 0...10) {
			var position = {
				x: 50 + Random.int(-20, 20), 
				y: 50 + Random.int(-20, 20)
			};
			if (free_map[position.x][position.y]) {
				make_resource(position.x, position.y, "flower");
			}
		}
	}

	function add_to_free_map(x, y) {
		entity_count[x][y]++;
		free_map[x][y] = false;
	}
	function subtract_from_free_map(x, y) {
		entity_count[x][y]--;
		if (entity_count[x][y] == 0) {
			free_map[x][y] = true;
		}
	}

	function add_resource_to_lists(resource: Resource) {
		resource_lists[resource.name].push(resource);
	}

	function remove_resource_from_lists(resource: Resource) {
		resource_lists[resource.name].remove(resource);
	}

	function add_mob_to_lists(mob: Mob) {
		mob_lists[mob.name].push(mob);
	}

	function remove_mob_from_lists(mob: Mob) {
		mob_lists[mob.name].remove(mob);
	}


	// TODO: create lists of next chars for each vowel/pair to make names
	// more coherent
	var vowels = ['a', 'e', 'i', 'o', 'u'];
	var consonants = ['y', 'q', 'w', 'r', 't', 'p', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm'];
	var generated_names = [""];
	function generate_name(): String {

		function random_consonant(): String {
			return consonants[Random.int(0, consonants.length - 1)];
		}
		function random_vowel(): String {
			return vowels[Random.int(0, vowels.length - 1)];
		}

		var name = "";
		while (generated_names.indexOf(name) != -1) {
			var length = Random.int(2, 3);
			for (i in 0...length) {
				var consonant_first = Random.bool();
				if (consonant_first) {
					name += random_consonant();
					name += random_vowel();
				} else {
					name += random_vowel();
					name += random_consonant();
				}

				// Capitalize first letter
				if (i == 0) {
					name = name.charAt(0).toUpperCase() + name.charAt(1);
				}
			}
		}

		generated_names.push(name);

		return name;
	}

	function make_gnome(x, y) {
		var gnome = new Mob();
		gnome.x = x;
		gnome.y = y;
		gnome.state = MobState_Idle;
		add_to_free_map(x, y);
		gnome.name = "gnome";
		gnome.personal_name = generate_name();
		gnome.motivation = 20;
		add_mob_to_lists(gnome);
	}

	function make_dragon(x, y) {
		var dragon = new Mob();
		dragon.x = x;
		dragon.y = y;
		dragon.state = MobState_Idle;
		add_to_free_map(x, y);
		dragon.name = "dragon";
		dragon.motivation = 20;
		add_mob_to_lists(dragon);
	}

	function make_resource(x, y, name) {
		var resource = new Resource();
		resource.x = x;
		resource.y = y;
		add_to_free_map(x, y);
		resource.name = name;
		add_resource_to_lists(resource);
	}

	// in terms of cells
	function view_x(x) {
		return x - player.x + Math.floor(view_width / 2);
	}
	function view_y(y) {
		return y - player.y + Math.floor(view_height / 2);
	}

	// in terms of pixels
	function screen_x(x) {
		return view_x(x) * tilesize * scale;
	}
	function screen_y(y) {
		return view_y(y) * tilesize * scale;
	}

	function out_of_bounds(x, y) {
		return x < 0 || y < 0 || x >= map_width || y >= map_height;
	}

	function out_of_viewport(x, y) {
		return view_x(x) < 0 || view_y(y) < 0 
		|| view_x(x) >= view_width || view_y(y) >= view_height;
	}

	function draw_entity(entity, tile) {
		if (!out_of_viewport(entity.x, entity.y)) {
			Gfx.draw_tile(screen_x(entity.x), screen_y(entity.y),
				tile); 
		}
	}

	var random_move_possible: Array<IntVector2> = [{x: 1, y: 0}, {x: -1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1},
	{x: 1, y: 1}, {x: -1, y: 1}, {x: -1, y: -1}, {x: 1, y: -1}];
	function random_move(x, y): IntVector2 {
		var moves = Random.shuffle(random_move_possible);

		return moves[0];
	}

	function random_move_to_space(x, y): IntVector2 {
		var moves = Random.shuffle(random_move_possible);

		var i = 0;
		while (i < moves.length 
			&& (out_of_bounds(x + moves[i].x, y + moves[i].y)
				|| !free_map[x + moves[i].x][y + moves[i].y])) 
		{
			i++;
		}

		if (i < moves.length) {
			return moves[i];
		} 	else {
			return null;
		}
	}	

	function random_neighbor(x, y): IntVector2 {
		var move = random_move(x, y);
		if (move != null) {
			return {x: x + move.x, y: y + move.y} 
		} else {
			return null;
		}
	}

	function random_neighbor_space(x, y): IntVector2 {
		var move = random_move_to_space(x, y);
		if (move != null) {
			return {x: x + move.x, y: y + move.y} 
		} else {
			return null;
		}
	}

	function closest_resource(x, y): Resource {
		// Go to closest resource
		var closest = null;
		var closest_distance: Float = 100000;
		for (resource in Entity.get(Resource)) {
			var distance = Math.dst2(resource.x, resource.y, x, y);
			if (distance < closest_distance) {
				closest_distance = distance;
				closest = resource;
			}
		}

		return closest;
	}

	function get_move_to(x1, y1, x2, y2): IntVector2 {
		return {x: Math.sign(x2 - x1), y: Math.sign(y2 - y1)};
	}

	function move_entity_to(entity, x, y): Bool {
		var move = get_move_to(entity.x, entity.y, x, y);
		if (move.x != 0 || move.y != 0) {
			entity.dx = move.x;
			entity.dy = move.y;

			return true;
		} else {
			return false;
		}
	}


	function mob_idle(mob: Mob) {
		// When idle, go home and move around nearby
		// var distance_to_home = Math.dst(mob.x, mob.y, mob.home_x, mob.home_y);
		// if (distance_to_home < mob.leash_range) {
		// 	// Move around 
		var neighbor = random_neighbor_space(mob.x, mob.y);
		if (neighbor != null) {
			move_entity_to(mob, neighbor.x, neighbor.y);
		}
		// } else {
		// 	// Go home
		// 	move_entity_to(mob, mob.home_x, mob.home_y);
		// }

		// If mob is low on energy, food is more valuable
		var energy_weight = 0;
		var energy_amount = mob.energy / mob.energy_max;
		if (energy_amount < 0.25) {
			energy_weight = 100;
		} else if (energy_amount < 0.75) {
			energy_weight = 10;
		} else if (energy_amount < 0.99) {
			energy_weight = 1; 
		} else {
			energy_weight = 0;
		}

		// Wood is valuable only when mob has none
		var wood_weight = 0;
		if (mob.wood == 0) {
			wood_weight = 1;
		}

		var happy_weight = 1;

		// do goal if motivated
		if (Random.chance(mob.motivation)) {
			// Determine if there's a goal to do

			var best_value = -100000000;
			var best_distance = 100000000;
			var best_goal = null;

			function process_for_value(entity) {
				if (!InteractionData.to_attacker[mob.name].exists(entity.name)) {
					// No values for this type of goal
					return;
				}

				// total value is value of resources/happy gained
				// minus the distance to goal
				// if nothing is gained, goal is ignored
				var distance = Std.int(Math.dst(mob.x, mob.y, entity.x, entity.y));

				// prioritize closer goals
				// NOTE: this might be pruning goals too hard
				if (distance > best_distance) {
					return;
				} else {

					var values = InteractionData.to_attacker[mob.name][entity.name];

					var gain = 0;
					if (values.exists("energy")) {
						gain += energy_weight * values["energy"];
					}
					if (values.exists("wood")) {
						gain += wood_weight * values["wood"]; 			
					}
					if (values.exists("happy")) {
						gain += happy_weight *values["happy"];
					}

					// If gain something and got a better score
					// select this goal
					if (gain != 0 && (gain - distance) > best_value) {
						best_value = gain -	distance;
						best_distance = distance;
						best_goal = entity;
					}
				}
			}

			var resources = Entity.get(Resource);
			var mobs = Entity.get(Mob);
			var goal_entities = resources.concat(mobs);

			Random.shuffle(goal_entities);

			// sort, stopping at some random number of examined goals
			// stopping point is from 0 to total number of goals
			// distribution is such that stopping point is more often
			// closer to total number of goals
			// 
			// all of this is to make it that most of the time
			// the goal with top score is picked
			// but sometimes other goals are picked as well
			// 
			// it's possible that the worst goal will be picked
			// but this has a very low chance of occuring
			var stopping_point = Random.float(0, 1);
			stopping_point = stopping_point * stopping_point;
			stopping_point = goal_entities.length * (1 - stopping_point);

			var i = 0;
			for (entity in goal_entities) {	
				process_for_value(entity);

				i++;
				if (i > stopping_point) {
					break;
				}
			}

			// Don't pick yourself as goal
			if (best_goal == mob) {
				best_goal = null;
			}

			if (best_goal != null) {
				mob.goal = best_goal;
				mob.state = MobState_Goal;
				mob.goal_duration = Random.int(5, 15);

				// record goal/interaction in mob's history
				var history_entry = '';
				var interaction_name = 'no_interaction_name';
				if (InteractionData.names.exists(mob.name) 
					&& InteractionData.names[mob.name].exists(mob.goal.name)) 
				{
					interaction_name = InteractionData.names[mob.name][mob.goal.name];
				}
				history_entry += '${interaction_name}';
				history_entry += '->${mob.goal.name}';
				history_entry += ' for ${mob.goal_duration} turns';
				mob.history.unshift(history_entry);
			}
		}
	}

	function mob_goal(mob: Mob) {
		var distance_to_goal = Math.dst2(mob.x, mob.y, 
			mob.goal.x, mob.goal.y);

		if (distance_to_goal > 2) {
			// Not next to goal yet
			var move = {
				x: Math.sign(mob.goal.x - mob.x), 
				y: Math.sign(mob.goal.y - mob.y)
			};

			move_entity_to(mob, mob.x + move.x, mob.y + move.y);
		} else {
			// Next to goal, interact with it

			mob.goal_duration--;
			if (mob.goal_duration == 0 || mob.goal.health <= 0) {
				mob.goal = null;
				mob.state = MobState_Idle;
			} else {
				// Wood speeds up interaction
				var wood_multiplier = 1;
				if (mob.wood > 0) {
					wood_multiplier = 2;
					mob.wood--;
				}
				mob.energy -= 1;

				// Apply value exchanges
				// Give values to attacker
				if (InteractionData.to_attacker[mob.name].exists(mob.goal.name)) {
					var values = InteractionData.to_attacker[mob.name][mob.goal.name];
					if (values.exists("wood")) {
						mob.wood += values["wood"] * wood_multiplier;
					}
					if (values.exists("energy")) {
						mob.energy += values["energy"] * wood_multiplier;
					}
				}
				// Give values to goal(most of the time take)
				if (InteractionData.to_goal[mob.name].exists(mob.goal.name)) {
					var values = InteractionData.to_goal[mob.name][mob.goal.name];
					if (values.exists("wood")) {
						mob.goal.wood += values["wood"] * wood_multiplier;
					}
					if (values.exists("energy")) {
						mob.goal.energy += values["energy"] * wood_multiplier;
					}

					if (values.exists("health")) {
						mob.goal.health += values["health"] * wood_multiplier;

						// When health is 0, goal entity is deleted
						if (mob.goal.health <= 0) {
							mob.goal.delete();

							if (mob.goal.entity_type == EntityType_Mob) {
								remove_mob_from_lists(mob.goal);
							} else if (mob.goal.entity_type == EntityType_Resource) {
								remove_resource_from_lists(mob.goal);
							}
						}
					}
				}
			}
		}
	}

	function update_entities() {
		// Respawn resources
		for (name in resource_names) {
			var list = resource_lists[name];
			var cap = resource_caps[name];
			var chance = resource_respawn_chances[name];
			var respawn = Math.floor(cap / list.length);

			for (i in 0...respawn) {
				if (Random.chance(chance)) {
					var random_resource = list[Random.int(0, list.length - 1)];
					var space = random_neighbor_space(random_resource.x, random_resource.y);
					if (space != null) {
						make_resource(space.x, space.y, name);
					}			
				}
			}
		}


		// Update population caps
		// if population is below 50% of cap for a long time, the cap is reduced by 25%
		for (key in mob_population_caps.keys()) {
			var current_population = mob_lists[key].length;
			var cap = mob_population_caps[key];

			if (current_population / cap < 0.5) {
				cap_reduce_timers[key]++;
				if (cap_reduce_timers[key] > cap_reduce_timers_max) {
					mob_population_caps[key] = Math.floor(0.75 * mob_population_caps[key]);
					cap_reduce_timers[key] = 0;
				} 
			} else {
				// went above 50%, reset reduce timer
				if (cap_reduce_timers[key] > 0) {
					cap_reduce_timers[key] = 0;
				}
			}
		}
		
		// Respawn mobs
		// Update population caps
		for (key in mob_population_caps.keys()) {
			if (mob_lists[key].length == 0) {
				continue;
			}

			var growth_chance = mob_growth_chances[key];

			if (Random.chance(growth_chance)) {
				var mob_list = mob_lists[key];
				var current_population = mob_list.length;
				var cap = mob_population_caps[key];

				var respawn_amount = Math.floor(cap / current_population);
				for (i in 0...respawn_amount) {
					var random_mob = mob_list[Random.int(0, mob_list.length - 1)];
					var space = random_neighbor(random_mob.x, random_mob.y);
					if (space != null) {
						switch (key) {
							case "gnome": make_gnome(space.x, space.y);
							case "dragon": make_dragon(space.x, space.y);
							default:
						}
					}	
				}
			}
		}

		// Update mobs
		for (mob in Entity.get(Mob)) {

    		// Mobs constantly consume energy
    		mob.energy_decrease_timer++;
    		if (mob.energy_decrease_timer >= mob.energy_decrease_timer_max) {
    			mob.energy_decrease_timer = 0;

    			mob.energy -= 3;

    			if (mob.energy < 0) {
    				mob.energy = 0;
    				// decrease health if no energy
    				mob.health -= 1;
    			}
    		}

    		if (mob.health <= 0) {
    			mob.delete();
    			remove_mob_from_lists(mob);
    		}

    		switch (mob.state) {
    			case MobState_Idle: mob_idle(mob);
    			case MobState_Goal: mob_goal(mob);
    			default:
    		}

    	}



    	function update_moving_entity(entity) {
    		add_to_free_map(entity.x, entity.y);

    		entity.x += entity.dx;
    		entity.y += entity.dy;
    		entity.dx = 0;
    		entity.dy = 0;

    		subtract_from_free_map(entity.x, entity.y);
    	}

    	update_moving_entity(player);
    	player.moved_this_turn = false;

    	for (mob in Entity.get(Mob)) {
    		update_moving_entity(mob);
    	}
    }

    function render() {

    	Gfx.scale(scale, scale);

    	var start_x = player.x - Math.floor(view_width / 2);
    	var end_x = player.x + Math.ceil(view_width / 2);
    	var start_y = player.y - Math.floor(view_height / 2);
    	var end_y = player.y + Math.ceil(view_height / 2);

    	Gfx.fill_box(0, 0, view_width * tilesize * scale, 
    		view_height * tilesize * scale, Col.LIGHTGREEN);

    	for (resource in Entity.get(Resource)) {
    		draw_entity(resource, resource_tiles[resource.name]);
    	}
    	
    	for (mob in Entity.get(Mob)) {
    		draw_entity(mob, mob_tiles[mob.name]);
    	}

    	

    	draw_entity(player, Tiles.Player);


    	// World border
    	if (player.x < view_width / 2) {
    		var border_width = ((view_width / 2) - 1 - player.x) * tilesize * scale;
    		Gfx.fill_box(0, 0, border_width, screen_height, Col.BLACK);
    	} else if (player.x > map_width - view_width / 2) {
    		var border_width = ((view_width / 2) - (map_width - 1 - player.x)) * tilesize * scale;
    		Gfx.fill_box(view_width * tilesize * scale - border_width, 0,
    			border_width, screen_height, Col.BLACK);
    	}
    	if (player.y < view_height / 2) {
    		var border_height = ((view_height / 2) - 1 - player.y) * tilesize * scale;
    		Gfx.fill_box(0, 0, screen_width, border_height, Col.BLACK);
    	} else if (player.y > map_height - view_height / 2) {
    		var border_height = ((view_height / 2) - (map_height - 1 - player.y)) * tilesize * scale;
    		Gfx.fill_box(0, view_height * tilesize * scale - border_height,
    			screen_width, border_height, Col.BLACK);
    	}


    	// Display tracked entity info
    	if (tracked_entity != null) {
    		var text_y = 0;
    		function display_line(text) {
    			Text.display(view_width * tilesize * scale + 10, text_y, text);
    			text_y += 20;
    		}

    		display_line('Mob Info');
    		display_line('${tracked_entity.entity_type}');
    		display_line('x=${tracked_entity.x} y=${tracked_entity.y}');
    		
    		text_y = 100;
    		display_line('Goal Info:');
    		switch (tracked_entity.entity_type) {
    			case EntityType_Player: {
    			}
    			case EntityType_Mob: {
    				display_line('home x=${tracked_entity.home_x} y=${tracked_entity.home_y}');
    				display_line('state=${tracked_entity.state}');
    				display_line('health=${tracked_entity.health}/${tracked_entity.health_max}');
    				display_line('energy=${tracked_entity.energy}/${tracked_entity.energy_max}');
    				display_line('population=${mob_lists[tracked_entity.name].length}');
    				display_line('name=${tracked_entity.name}');
    				display_line('personal name=${tracked_entity.personal_name}');
    				if (tracked_entity.goal != null) {
    					display_line('goal x=${tracked_entity.goal.x} goal y=${tracked_entity.goal.y}');
    					display_line('goal name=${tracked_entity.goal.name}');
    				}

    				text_y = 350;
    				display_line('Mob History:');
    				var tracked_history: Array<String> = tracked_entity.history;
    				for (i in 0...Std.int(Math.min(10, tracked_history.length))) {
    					display_line('${history_scroll + i})${tracked_history[history_scroll + i]}');
    				}
    			}
    			case EntityType_Resource: {
    				display_line('health=${tracked_entity.health}/${tracked_entity.health_max}');
    				display_line('name=${tracked_entity.name}');
    			}
    			default:
    		}
    	}


    	Text.display(view_width * tilesize * scale + 10, 800, 'x=${player.x} y=${player.y}');
    	
    	Text.display(view_width * tilesize * scale + 10, 850, 'x=${Mouse.x} y=${Mouse.y}');
    }

    function update() {

    	if (Input.just_pressed(Key.SPACE)) {
    		paused = !paused;
    	}

    	if (!player.moved_this_turn) {
    		if (Mouse.right_held()) {
    			var mouse_difference_x = Mouse.x - screen_x(player.x) 
    			- tilesize * scale / 2;
    			var mouse_difference_y = Mouse.y - screen_y(player.y)
    			- tilesize * scale / 2;
    			if (Math.abs(mouse_difference_x) > tilesize * scale / 2) {
    				player.dx = Math.sign(mouse_difference_x);
    			}
    			if (Math.abs(mouse_difference_y) > tilesize * scale/ 2) {
    				player.dy = Math.sign(mouse_difference_y);
    			}

    			if (!out_of_bounds(player.x + player.dx, player.y + player.dy)) { 
    				player.moved_this_turn = true;
    			} else {
    				player.dx = 0;
    				player.dy = 0;
    			}
    		} else {
    			var left = Input.pressed(Key.LEFT);
    			var right = Input.pressed(Key.RIGHT);
    			var up = Input.pressed(Key.UP);
    			var down = Input.pressed(Key.DOWN);
    			
    			if (left && !right) {
    				player.dx = -1;
    			} else if (right && !left) {
    				player.dx = 1;
    			} else if (up && !down) {
    				player.dy = -1;
    			} else if (down && !up) {
    				player.dy = 1;
    			}

    			if (!out_of_bounds(player.x + player.dx, player.y + player.dy)) { 
    				player.moved_this_turn = true;
    			} else {
    				player.dx = 0;
    				player.dy = 0;
    			}
    		}
    	}

    	if (Mouse.left_click()) {
    		for (entity in Entity.all) {
    			if (!out_of_viewport(entity.x, entity.y)
    				&& Math.dst2(screen_x(entity.x), screen_y(entity.y), 
    					Mouse.x, Mouse.y) < tilesize * tilesize * scale * scale) 
    			{
    				tracked_entity = entity;
    				// Reset history scroll position
    				history_scroll = 0;
    				break;
    			}
    		}
    	}

    	if (!paused) {
    		turn_timer++;
    		if (turn_timer >= turn_timer_max) {
    			turn_timer = 0;

    			update_entities();
    		}
    	}

    	render();

    	// History scroll buttons
    	if (tracked_entity != null) {
    		GUI.text_button(1270, 330, "UP", function() { history_scroll--; });
    		GUI.text_button(1270, 360, "DOWN", function() { history_scroll++; });
    		if (history_scroll < 0) {
    			history_scroll = 0;
    		} else if (history_scroll > tracked_entity.history.length - 10) {
    			history_scroll = Std.int(tracked_entity.history.length - 10);
    			if (history_scroll < 0) {
    				history_scroll = 0;
    			}
    		}
    	}
    }
}
