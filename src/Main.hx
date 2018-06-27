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
	static inline var map_width = 200;
	static inline var map_height = 200;
	static inline var view_width = 31;
	static inline var view_height = 31;

	static inline var bananas_count_min = 20;
	static inline var tree_count_min = 20;

	var paused = false;


	var turn_timer = 0;
	static inline var turn_timer_max  = 10;


	var tiles = Data.int_2dvector(map_width, map_height);
	var free_map = Data.bool_2dvector(map_width, map_height);
	var entity_count = Data.int_2dvector(map_width, map_height);

	var player: Player;

	var tracked_entity: Dynamic = null;

	function new() {
		Gfx.resize_screen(screen_width, screen_height);
		Text.setfont("pixelFJ8", 16);
		Gfx.load_tiles("tiles", tilesize, tilesize);

		#if flash
		Gfx.resize_screen(screen_width, screen_height, 1);
		#else 
		Gfx.resize_screen(screen_width, screen_height, 1);
		#end


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
		player.x = 100;
		player.y = 100;
		add_to_free_map(player.x, player.y);


		make_mob(102, 102);
		make_mob(98, 106);


		make_bananas(10, 10);
		if (free_map[10][10]) {
			trace("huh");
		}

		for (i in 0...10) {
			var position = {
				x: 110 + Random.int(-10, 10), 
				y: 110 + Random.int(-10, 10)
			};
			if (free_map[position.x][position.y]) {
				make_bananas(position.x, position.y);
			}
		}
		for (i in 0...10) {
			var position = {
				x: 110 + Random.int(-10, 10), 
				y: 110 + Random.int(-10, 10)
			};
			if (free_map[position.x][position.y]) {
				make_tree(position.x, position.y);
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

	function make_mob(x, y) {
		var mob = new Mob();
		mob.x = x;
		mob.y = y;
		mob.home_x = x - 10;
		mob.home_y = y - 10;
		mob.state = MobState_Idle;
		add_to_free_map(x, y);
		mob.name = "mob";
		mob.motivation = 20;
	}

	function make_bananas(x, y) {
		var bananas = new Resource();
		bananas.x = x;
		bananas.y = y;
		bananas.resource_type = ResourceType_Bananas;
		add_to_free_map(x, y);
		bananas.name = "bananas";
	}

	function make_tree(x, y) {
		var tree = new Resource();
		tree.x = x;
		tree.y = y;
		tree.resource_type = ResourceType_Tree;
		add_to_free_map(x, y);
		tree.name = "tree";
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
		var distance_to_home = Math.dst(mob.x, mob.y, mob.home_x, mob.home_y);
		if (distance_to_home < mob.leash_range) {
			// Move around 
			var neighbor = random_neighbor_space(mob.x, mob.y);
			if (neighbor != null) {
				move_entity_to(mob, neighbor.x, neighbor.y);
			}
		} else {
			// Go home
			move_entity_to(mob, mob.home_x, mob.home_y);
		}


		var starving = ((mob.energy / mob.energy_max) < 0.25);

		// do goal if motivated
		// always do goal if starving
		if (starving || Random.chance(mob.motivation)) {
			// Determine if there's a goal to do
			var need_energy = ((mob.energy / mob.energy_max) < 0.75);
			var need_wood = (mob.wood == 0);

			var best_value = -100000000;
			var best_distance = 100000000;
			var best_goal = null;

			function process_for_value(entity) {
				if (!Values.values[mob.name].exists(entity.name)) {
					// No values for this type of goal
					return;
				}

				// total value is value of resources/dislike gained
				// minus the distance to goal
				// if nothing is gained, goal is ignored
				var distance = Std.int(Math.dst(mob.x, mob.y, entity.x, entity.y));

				// prioritize closer goals(even if gain is greater)
				if (distance > best_distance) {
					return;
				} else {

					var values = Values.values[mob.name][entity.name];

					var gain = 0;
					if (values.exists("energy")) {
						if (starving) {
							// prioritize energy above all if starving
							gain += 100 * values["energy"];
						} else if (need_energy) {
							gain += values["energy"];
						}
					}
					if (values.exists("wood") && need_wood) {
						gain += values["wood"]; 			
					}
					if (values.exists("dislike")) {
						gain += values["dislike"];
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

			for (resource in Entity.get(Resource)) {	
				process_for_value(resource);
			}
			for (mob in Entity.get(Mob)) {
				process_for_value(mob);
			}

			// Don't goal on yourself
			if (best_goal == mob) {
				best_goal = null;
			}

			if (best_goal != null) {
				// TODO: insert motivation check here
				mob.goal = best_goal;
				mob.state = MobState_Goal;
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
			// Next to goal, gather it
			// If not gathered yet, gather resource and delete
			if (mob.goal.hp > 0) {
				if (mob.wood > 0) {
					// wood makes you gather faster
					mob.goal.hp -= 2;
					mob.wood--;
				} else {
					mob.goal.hp -= 1;
				}
				mob.energy -= 1;


				if (mob.goal.hp <= 0) {
					mob.goal.delete();

					switch (mob.goal.resource_type) {
						case ResourceType_Tree: {
							mob.wood += 10;
						}
						case ResourceType_Bananas: {
							mob.energy += 40;
						}
						default:
					}
				}
			}

			if (mob.goal.hp <= 0) {
				mob.goal = null;
				mob.state = MobState_Idle;
			}		
		}
	}

	function update_entities() {
		// Respawn resources when they get low, respawn near resources of same type
		// NOTE: optimize if needed by tracking counts on addition/removal
		var bananas_count = 0;
		var tree_count = 0;
		for (resource in Entity.get(Resource)) {
			switch (resource.resource_type) {
				case ResourceType_Bananas: bananas_count++;
				case ResourceType_Tree: tree_count++;
				default:
			}
		}

		var k = 0;
		var all_resources = Entity.get(Resource);
		if (bananas_count < bananas_count_min) {
			while (true) {
				k = Random.int(0, all_resources.length - 1);
				if (all_resources[k].resource_type == ResourceType_Bananas) {
					break;
				}
			}

			var space = random_neighbor_space(all_resources[k].x, all_resources[k].y);
			if (space != null) {
				make_bananas(space.x, space.y);
			}
		}

		if (tree_count < tree_count_min) {
			var all_resources = Entity.get(Resource);
			while (true) {
				k = Random.int(0, all_resources.length - 1);
				if (all_resources[k].resource_type == ResourceType_Tree) {
					break;
				}	
			}

			var space = random_neighbor_space(all_resources[k].x, all_resources[k].y);
			if (space != null) {
				make_tree(space.x, space.y);
			}
		}




		for (mob in Entity.get(Mob)) {

    		// Mobs constantly consume energy
    		mob.energy_decrease_timer++;
    		if (mob.energy_decrease_timer >= mob.energy_decrease_timer_max) {
    			mob.energy_decrease_timer = 0;

    			mob.energy -= 3;

    			if (mob.energy < 0) {
    				mob.energy = 0;
    				// decrease hp if no energy
    				mob.hp -= 1;
    			}
    		}

    		if (mob.hp <= 0) {
    			mob.state = MobState_Dead;
    		}

    		switch (mob.state) {
    			case MobState_Dead: 
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
    	player.already_moved = false;

    	for (mob in Entity.get(Mob)) {
    		update_moving_entity(mob);
    	}
    }

    function render() {

    	Gfx.scale(4, 4);

    	var start_x = player.x - Math.floor(view_width / 2);
    	var end_x = player.x + Math.ceil(view_width / 2);
    	var start_y = player.y - Math.floor(view_height / 2);
    	var end_y = player.y + Math.ceil(view_height / 2);

    	Gfx.fill_box(0, 0, view_width * tilesize * scale, 
    		view_height * tilesize * scale, Col.LIGHTGREEN);
    	// for (x in start_x...end_x) {
    	// 	for (y in start_y...end_y) {
    	// 		if (!out_of_bounds(x, y)) {
    	// 			Gfx.draw_tile(screen_x(x), screen_y(y), 
    	// 				tiles[x][y]);
    	// 		}
    	// 	}
    	// }

    	for (mob in Entity.get(Mob)) {
    		if (mob.state == MobState_Dead) {
    			draw_entity(mob, Tiles.MobDead);
    		} else {
    			draw_entity(mob, Tiles.Mob);
    		}
    	}

    	for (resource in Entity.get(Resource)) {
    		switch (resource.resource_type) {
    			case ResourceType_Bananas: draw_entity(resource, Tiles.Bananas);
    			case ResourceType_Tree: draw_entity(resource, Tiles.Tree);
    			default:
    		}
    	}

    	draw_entity(player, Tiles.Player);




    	if (tracked_entity != null) {
    		var text_y = 0;
    		function display_line(text) {
    			Text.display(view_width * tilesize * scale + 10, text_y, text);
    			text_y += 20;
    		}

    		display_line('${tracked_entity.entity_type}');
    		display_line('x=${tracked_entity.x} y=${tracked_entity.y}');
    		switch (tracked_entity.entity_type) {
    			case EntityType_Player: {
    			}
    			case EntityType_Mob: {
    				display_line('home x=${tracked_entity.home_x} y=${tracked_entity.home_y}');
    				display_line('state=${tracked_entity.state}');
    				display_line('hp=${tracked_entity.hp}/${tracked_entity.hp_max}');
    				display_line('energy=${tracked_entity.energy}/${tracked_entity.energy_max}');
    				if (tracked_entity.goal != null) {
    					display_line('goal x=${tracked_entity.goal.x} goal y=${tracked_entity.goal.y}');
    				}
    			}
    			case EntityType_Resource: {
    				display_line('hp=${tracked_entity.hp}/${tracked_entity.hp_max}');
    				display_line('resource type=${tracked_entity.resource_type}');
    			}
    			default:
    		}
    	}
    }

    function update() {

    	if (Input.just_pressed(Key.SPACE)) {
    		paused = !paused;
    	}

    	if (!player.already_moved) {
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
    			player.already_moved = true;
    		}
    	}

    	if (Mouse.left_click()) {
    		for (entity in Entity.all) {
    			if (!out_of_viewport(entity.x, entity.y)
    				&& Math.dst2(screen_x(entity.x), screen_y(entity.y), 
    					Mouse.x, Mouse.y) < tilesize * tilesize * scale * scale) 
    			{
    				tracked_entity = entity;
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
    }
}
