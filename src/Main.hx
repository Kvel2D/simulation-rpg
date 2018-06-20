import haxegon.*;
import haxe.ds.Vector;
import haxe.Timer;
import Entity;

using haxegon.MathExtensions;
using Lambda;


@:publicFields
class Main {
	static inline var screen_width = 1000;
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
	var walls = Data.bool_2dvector(map_width, map_height);

	var player: Player;


	function new() {
		Gfx.resize_screen(screen_width, screen_height);
		Text.setfont("Seraphimb1", 30);
		Gfx.load_tiles("tiles", tilesize, tilesize);

		#if flash
		Gfx.resize_screen(screen_width, screen_height, 4);
		#else 
		Gfx.resize_screen(screen_width, screen_height, 1);
		#end


		for (x in 0...map_width) {
			for (y in 0...map_height) {
				walls[x][y] = false;
			}
		}

		walls[102][100] = true;
		walls[103][100] = true;
		walls[104][100] = true;
		walls[105][105] = true;

		for (x in 0...map_width) {
			for (y in 0...map_height) {
				if (walls[x][y]) {
					tiles[x][y] = Tiles.Wall;
				} else {
					tiles[x][y] = Tiles.Ground;
				}
			}
		}


		player = new Player();
		player.x = 100;
		player.y = 100;


		make_gnome(102, 102);
		make_gnome(98, 106);

		function random_nearby(x, y): IntVector2 {
			var move = random_move(x, y);
			if (move != null) {
				return {
					x: x + move.x * Random.int(1, 10), 
					y: y + move.y * Random.int(1, 10)
				};
			} else {
				return null;
			}
		}

		for (i in 0...10) {
			var position = random_nearby(110, 110);
			if (position != null) {
				make_bananas(position.x, position.y);
			}
		}
		for (i in 0...10) {
			var position = random_nearby(110, 110);
			if (position != null) {
				make_tree(position.x, position.y);
			}
		}
	}

	function make_gnome(x, y) {
		var gnome = new Gnome();
		gnome.x = x;
		gnome.y = y;
		gnome.home_x = x - 10;
		gnome.home_y = y - 10;
		gnome.state = NpcState_Idle;
	}

	function make_bananas(x, y) {
		var bananas = new Resource();
		bananas.x = x;
		bananas.y = y;
		bananas.type = ResourceType_Bananas;
	}

	function make_tree(x, y) {
		var tree = new Resource();
		tree.x = x;
		tree.y = y;
		tree.type = ResourceType_Tree;
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

	function draw_entity(entity, tile) {
		Gfx.draw_tile(screen_x(entity.x) * tilesize, screen_y(entity.y) * tilesize,
			tile); 
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
			switch (resource.type) {
				case ResourceType_Bananas: draw_entity(resource, Tiles.Bananas);
				case ResourceType_Tree: draw_entity(resource, Tiles.Tree);
				default:
			}
		}

		draw_entity(player, Tiles.Player);
	}

	var random_move_possible: Array<IntVector2> = [{x: 1, y: 0}, {x: -1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1},
	{x: 1, y: 1}, {x: -1, y: 1}, {x: -1, y: -1}, {x: 1, y: -1}];
	function random_move(x, y): IntVector2 {
		var moves = Random.shuffle(random_move_possible);

		while (moves.length > 0 && walls[x + moves[0].x][y + moves[0].y]) {
			moves.shift();
		}

		if (moves.length > 0) {
			return moves[0];
		} else {
			return null;
		}
	}

	function random_neighbor_space(x, y): IntVector2 {
		var move = random_move(x, y);
		if (move != null) {
			return {x: x + move.x, y: y + move.y} 
		} else {
			return null;
		}
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

	function update_entities() {
		// Respawn resources when they get low, respawn near resources of same type
		var bananas_count = 0;
		var tree_count = 0;
		for (resource in Entity.get(Resource)) {
			switch (resource.type) {
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
				if (all_resources[k].type == ResourceType_Bananas) {
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
				if (all_resources[k].type == ResourceType_Tree) {
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

    			gnome.energy--;

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
    			case NpcState_Idle: {

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
						gnome.state = NpcState_MovingTo;

						var resource = closest_resource(gnome.x, gnome.y);
						if (resource != null) {
							var random_displacement = random_move(resource.x, resource.y);
							if (random_displacement != null) {
								gnome.destination_x = resource.x - random_displacement.x;
								gnome.destination_y = resource.y - random_displacement.y;
								gnome.gathered_resource = resource;
							}
						}
					}
				}
				case NpcState_MovingTo: {
					var moved = move_entity_to(gnome, gnome.destination_x, gnome.destination_y);

					if (!moved) {
						// reached destination
						gnome.state = NpcState_Gathering;
					}
				}
				case NpcState_Gathering: {
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

							switch (gnome.gathered_resource.type) {
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
				default:
			}
		}
	}

	function update_result() {
		function update_moving_entity(entity) {
			entity.x += entity.dx;
			entity.y += entity.dy;
			entity.dx = 0;
			entity.dy = 0;
			entity.moved = false;
		}

		if (player.moved) {
			update_moving_entity(player);
		}

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
			update_result();
		}


		render();
	}
}
