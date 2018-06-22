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
	static inline var tilesize = 8;
	static inline var map_width = 200;
	static inline var map_height = 200;
	static inline var view_width = 31;
	static inline var view_height = 31;

	static inline var bananas_count_min = 20;
	static inline var tree_count_min = 20;


	var turn_timer = 0;
	static inline var turn_timer_max  = 10;


	var tiles = Data.int_2dvector(map_width, map_height);
	var free_map = Data.bool_2dvector(map_width, map_height);
	var entity_count = Data.int_2dvector(map_width, map_height);

	var player: Player;


	function new() {
		Gfx.resize_screen(screen_width, screen_height);
		Text.setfont("pixelFJ8", 8);
		Gfx.load_tiles("tiles", tilesize, tilesize);

		#if flash
		Gfx.resize_screen(screen_width, screen_height, 4);
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


		make_gnome(102, 102);
		make_gnome(98, 106);

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

	function make_gnome(x, y) {
		var gnome = new Gnome();
		gnome.x = x;
		gnome.y = y;
		gnome.home_x = x - 10;
		gnome.home_y = y - 10;
		gnome.state = NpcState_Idle;
		add_to_free_map(x, y);
	}

	function make_bananas(x, y) {
		var bananas = new Resource();
		bananas.x = x;
		bananas.y = y;
		bananas.resource_type = ResourceType_Bananas;
		add_to_free_map(x, y);
	}

	function make_tree(x, y) {
		var tree = new Resource();
		tree.x = x;
		tree.y = y;
		tree.resource_type = ResourceType_Tree;
		add_to_free_map(x, y);
	}


	function screen_x(x) {
		return x - player.x + Math.floor(view_width / 2);
	}

	function screen_y(y) {
		return y - player.y + Math.floor(view_height / 2);
	}

	function out_of_bounds(x, y) {
		return x < 0 || y < 0 || x >= map_width || y >= map_height;
	}

	function out_of_viewport(x, y) {
		return screen_x(x) < 0 || screen_y(y) < 0 
		|| screen_x(x) >= view_width || screen_y(y) >= view_height;
	}

	function draw_entity(entity, tile) {
		if (!out_of_viewport(entity.x, entity.y)) {
			Gfx.draw_tile(screen_x(entity.x) * tilesize, screen_y(entity.y) * tilesize,
				tile); 
		}
	}

	function render() {
		var start_x = player.x - Math.floor(view_width / 2);
		var end_x = player.x + Math.ceil(view_width / 2);
		var start_y = player.y - Math.floor(view_height / 2);
		var end_y = player.y + Math.ceil(view_height / 2);

		for (x in start_x...end_x) {
			for (y in start_y...end_y) {
				if (!out_of_bounds(x, y)) {
					Gfx.draw_tile(screen_x(x) * tilesize, screen_y(y) * tilesize, 
						tiles[x][y]);
				}
			}
		}

		for (gnome in Entity.get(Gnome)) {
			if (gnome.state == NpcState_Dead) {
				draw_entity(gnome, Tiles.GnomeDead);
			} else {
				draw_entity(gnome, Tiles.Gnome);
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




		for (entity in Entity.all) {
			if (!out_of_viewport(entity.x, entity.y)
				&& Math.dst2(screen_x(entity.x) * tilesize, 
					screen_y(entity.y) * tilesize, 
					Mouse.x, Mouse.y) < tilesize * tilesize) 
			{
				var text_y = 0;
				function display_line(text) {
					Text.display(view_width * tilesize + 10, text_y, text);
					text_y += 10;
				}

				display_line('${entity.entity_type}');
				display_line('x=${entity.x} y=${entity.y}');
				switch (entity.entity_type) {
					case EntityType_Player: {
					}
					case EntityType_Gnome: {
						display_line('home x=${entity.home_x} y=${entity.home_y}');
						display_line('destination x=${entity.destination_x}');
						display_line('state=${entity.state}');
						display_line('hp=${entity.hp}/${entity.hp_max}');
						display_line('energy=${entity.energy}/${entity.energy_max}');
					}
					case EntityType_Resource: {
						display_line('hp=${entity.hp}/${entity.hp_max}');
						display_line('resource type=${entity.resource_type}');
					}
				}
				break;
			}
		}
	}

	var random_move_possible: Array<IntVector2> = [{x: 1, y: 0}, {x: -1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1},
	{x: 1, y: 1}, {x: -1, y: 1}, {x: -1, y: -1}, {x: 1, y: -1}];
	function random_move(x, y): IntVector2 {
		var moves = Random.shuffle(random_move_possible);
		trace(moves.length);

		return moves[0];
	}

	function random_move_to_space(x, y): IntVector2 {
		var moves = Random.shuffle(random_move_possible);

		var i = 0;
		while (i < moves.length 
			&& !out_of_bounds(x + moves[i].x, y + moves[i].y)
			&& free_map[x + moves[i].x][y + moves[i].y]) 
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
			entity.moved = true;

			return true;
		} else {
			return false;
		}
	}


	function gnome_idle(gnome: Gnome) {
		// When idle, go home and move around nearby
		var distance_to_home = Math.dst(gnome.x, gnome.y, gnome.home_x, gnome.home_y);
		if (distance_to_home < gnome.leash_range) {
			// Move around 
			var neighbor = random_neighbor_space(gnome.x, gnome.y);
			if (neighbor != null) {
				move_entity_to(gnome, neighbor.x, neighbor.y);
			}
		} else {
			// Go home
			move_entity_to(gnome, gnome.home_x, gnome.home_y);
		}


		// Gather if energy is low
		if (gnome.energy / gnome.energy_max < 0.75) {

			var resource = closest_resource(gnome.x, gnome.y);
			if (resource != null) {

				var random_displacement = random_move(resource.x, resource.y);
				if (random_displacement != null) {
					gnome.destination_x = resource.x - random_displacement.x;
					gnome.destination_y = resource.y - random_displacement.y;
					gnome.gathered_resource = resource;

					gnome.state = NpcState_Attack;
				} else {
					trace("fail");
				}
			}
		}
	}

	function gnome_attack(gnome: Gnome) {
		var distance_to_goal = Math.dst2(gnome.x, gnome.y, 
			gnome.gathered_resource.x, gnome.gathered_resource.y);

		if (distance_to_goal > 2) {
			// Not next to goal yet
			var move = {
				x: Math.sign(gnome.gathered_resource.x - gnome.x), 
				y: Math.sign(gnome.gathered_resource.y - gnome.y)
			};

			move_entity_to(gnome, gnome.x + move.x, gnome.y + move.y);
		} else {
			// Next to goal, gather it
			// If not gathered yet, gather resource and delete
			if (gnome.gathered_resource.hp > 0) {
				if (gnome.wood > 0) {
					// wood makes you gather faster
					gnome.gathered_resource.hp -= 2;
					gnome.wood--;
				} else {
					gnome.gathered_resource.hp -= 1;
				}
				gnome.energy -= 1;


				if (gnome.gathered_resource.hp <= 0) {
					gnome.gathered_resource.delete();

					switch (gnome.gathered_resource.resource_type) {
						case ResourceType_Tree: {
							gnome.wood += 10;
						}
						case ResourceType_Bananas: {
							gnome.energy += 40;
							if (gnome.energy > gnome.energy_max) {
								gnome.energy = gnome.energy_max;
							}
						}
						default:
					}
				}
			}

			if (gnome.gathered_resource.hp <= 0) {
				gnome.gathered_resource = null;
				gnome.state = NpcState_Idle;
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




		for (gnome in Entity.get(Gnome)) {

    		// Gnomes constantly consume energy
    		gnome.energy_decrease_timer++;
    		if (gnome.energy_decrease_timer >= gnome.energy_decrease_timer_max) {
    			gnome.energy_decrease_timer = 0;

    			gnome.energy -= 3;

    			if (gnome.energy < 0) {
    				gnome.energy = 0;
    				// decrease hp if no energy
    				gnome.hp -= 1;
    			}
    		}

    		if (gnome.hp <= 0) {
    			gnome.state = NpcState_Dead;
    		}

    		switch (gnome.state) {
    			case NpcState_Dead: 
    			case NpcState_Idle: gnome_idle(gnome);
    			case NpcState_Attack: gnome_attack(gnome);
    			default:
    		}

    	}



    	function update_moving_entity(entity) {
    		add_to_free_map(entity.x, entity.y);

    		entity.x += entity.dx;
    		entity.y += entity.dy;
    		entity.dx = 0;
    		entity.dy = 0;
    		entity.moved = false;

    		subtract_from_free_map(entity.x, entity.y);
    	}

    	update_moving_entity(player);

    	for (gnome in Entity.get(Gnome)) {
    		update_moving_entity(gnome);
    	}
    }

    function update() {

    	if (!player.moved) {
    		if (Mouse.right_held()) {
    			var mouse_difference_x = Mouse.x - screen_x(player.x) * tilesize - tilesize / 2;
    			var mouse_difference_y = Mouse.y - screen_y(player.y) * tilesize - tilesize / 2;
    			if (Math.abs(mouse_difference_x) > tilesize / 2) {
    				player.dx = Math.sign(mouse_difference_x);
    			}
    			if (Math.abs(mouse_difference_y) > tilesize / 2) {
    				player.dy = Math.sign(mouse_difference_y);
    			}
    			player.moved = true;
    		}
    	}

    	turn_timer++;
    	if (turn_timer >= turn_timer_max) {
    		turn_timer = 0;

    		update_entities();
    	}

    	render();
    }
}
