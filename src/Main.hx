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


	var turn_timer = 0;
	static inline var turn_timer_max  = 10;


	var tiles = Data.int_2dvector(map_width, map_height);
	var walls = Data.bool_2dvector(map_width, map_height);

	var player: Player;

	var gnome_bananas = 10;
	var gnome_wood = 10;



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
			return {
				x: x + move.x * Random.int(1, 10), 
				y: y + move.y * Random.int(1, 10)
			};
		}

		for (i in 0...10) {
			var position = random_nearby(110, 110);
			make_bananas(position.x, position.y);
		}
		for (i in 0...10) {
			var position = random_nearby(110, 110);
			make_tree(position.x, position.y);
		}
	}

	function make_gnome(x, y) {
		var gnome = new Gnome();
		gnome.x = x;
		gnome.y = y;
		gnome.tile = Tiles.Gnome;
		gnome.home_x = x - 10;
		gnome.home_y = y - 10;
		gnome.state = NpcState_Idle;
	}

	function make_bananas(x, y) {
		var bananas = new Resource();
		bananas.x = x;
		bananas.y = y;
		bananas.type = ResourceType_Bananas;
		bananas.tile = Tiles.Bananas;
	}

	function make_tree(x, y) {
		var tree = new Resource();
		tree.x = x;
		tree.y = y;
		tree.type = ResourceType_Tree;
		tree.tile = Tiles.Tree;
	}


	function get_free_map(): Vector<Vector<Bool>> {
		var free_map = Data.bool_2dvector(map_width, map_height, true);
		// Gnomes
		for (gnome in Entity.get(Gnome)) {
			if (gnome.moved) {
				free_map[gnome.x + gnome.dx][gnome.y + gnome.dy] = false;
			} else {
				free_map[gnome.x][gnome.y] = false;
			}
		}
		// Walls
		for (x in 0...map_width) {
			for (y in 0...map_height) {
				if (walls[x][y]) {
					free_map[x][y] = false;
				}
			}
		}
		// TODO: Add player collision here
		// free_map[player.x][player.y] = false;

		return free_map;
	}


	var time: Float = 0;
	var current_block_name = "NONE";
	function time_block(next_block_name: String) {
		var temp = Timer.stamp();
		trace('Block \"$current_block_name\" took ${(temp - time) * 1000} ms.');
		time = temp;
		current_block_name = next_block_name;
	}

	function a_star(x1: Int, y1: Int, x2: Int, y2: Int): Array<IntVector2> {
		function heuristic_score(x1: Int, y1: Int, x2: Int, y2: Int): Int {
			return Std.int(Math.abs(x2 - x1) + Math.abs(y2 - y1));
		}

		function path(prev: Vector<Vector<IntVector2>>, x: Int, y: Int): Array<IntVector2> {
			var current = {x: x, y: y};
			var temp = {x: x, y: y};
			var path: Array<IntVector2> = [{x: current.x, y: current.y}];
			while (prev[current.x][current.y].x != -1) {
				temp.x = current.x;
				temp.y = current.y;
				current.x = prev[temp.x][temp.y].x;
				current.y = prev[temp.x][temp.y].y;
				path.push({x: current.x, y: current.y});
			}
			return path;
		}

		time_block("Reset");

		time_block("get_free_map");

		var move_map: Vector<Vector<Bool>>;
		move_map = get_free_map();
        move_map[x2][y2] = true; // destination cell needs to be "free" for the algorithm to find paths correctly


        time_block("closed open init");

        var infinity = 10000000;
        var closed = Data.bool_2dvector(map_width, map_height, false);
        var open = Data.bool_2dvector(map_width, map_height, false);
        open[x1][y1] = true;
        var open_length = 1;
        var prev = new Vector<Vector<IntVector2>>(map_width);
        for (x in 0...map_width) {
        	prev[x] = new Vector<IntVector2>(map_height);
        	for (y in 0...map_height) {
        		prev[x][y] = {x: -1, y: -1};
        	}
        }


        time_block("scores");

        var g_score = Data.int_2dvector(map_width, map_height, infinity);
        g_score[x1][y1] = 0;
        var f_score = Data.int_2dvector(map_width, map_height, infinity);

        f_score[x1][y1] = heuristic_score(x1, y1, x2, y2);

        time_block("rest");

        while (open_length != 0) {
        	var current = function() {
        		var lowest_score = infinity;
        		var lowest_node = {x: x1, y: y1};
        		for (x in 0...map_width) {
        			for (y in 0...map_height) {
        				if (open[x][y] && f_score[x][y] <= lowest_score) {
        					lowest_node.x = x;
        					lowest_node.y = y;
        					lowest_score = f_score[x][y];
        				}
        			}
        		}
        		return lowest_node;
        	}();

        	if (current.x == x2 && current.y == y2) {
        		return path(prev, current.x, current.y);
        	}

        	open[current.x][current.y] = false;
        	open_length--;
        	closed[current.x][current.y] = true;
        	for (dx in -1...2) {
        		for (dy in -1...2) {
        			if (Math.abs(dx) + Math.abs(dy) != 1) {
        				continue;
        			}
        			var neighbor_x = Std.int(current.x + dx);
        			var neighbor_y = Std.int(current.y + dy);
        			if (out_of_bounds(neighbor_x, neighbor_y) || !move_map[neighbor_x][neighbor_y]) {
        				continue;
        			}

        			if (closed[neighbor_x][neighbor_y]) {
        				continue;
        			}
        			var tentative_g_score = g_score[current.x][current.y] + 1;
        			if (!open[neighbor_x][neighbor_y]) {
        				open[neighbor_x][neighbor_y] = true;
        				open_length++;
        			} else if (tentative_g_score >= g_score[neighbor_x][neighbor_y]) {
        				continue;
        			}

        			prev[neighbor_x][neighbor_y].x = current.x;
        			prev[neighbor_x][neighbor_y].y = current.y;
        			g_score[neighbor_x][neighbor_y] = tentative_g_score;
        			f_score[neighbor_x][neighbor_y] = g_score[neighbor_x][neighbor_y] + heuristic_score(neighbor_x, neighbor_y, x2, y2);
        		}
        	}
        }

        
        time_block("END");


        return new Array<IntVector2>();
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

    function draw_entity(entity) {
    	Gfx.draw_tile(screen_x(entity.x) * tilesize, screen_y(entity.y) * tilesize,
    		entity.tile); 
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
    		draw_entity(gnome);
    	}

    	for (resource in Entity.get(Resource)) {
    		draw_entity(resource);
    	}

    	draw_entity(player);
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

    var random_move_possible: Array<IntVector2> = [{x: 1, y: 0}, {x: -1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1},
    {x: 1, y: 1}, {x: -1, y: 1}, {x: -1, y: -1}, {x: 1, y: -1}];
    function random_move(x, y): IntVector2 {
    	var moves = Random.shuffle(random_move_possible);

    	while (moves.length > 0 && walls[x + moves[0].x][y + moves[0].y]) {
    		moves.shift();
    	}

    	return moves[0];
    }

    function random_neighbor(x, y): IntVector2 {
    	var move = random_move(x, y);
    	return {x: x + move.x, y: y + move.y}
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

	

	function update() {

		if (turn_timer == 0) {
			for (gnome in Entity.get(Gnome)) {
				switch (gnome.state) {
					case NpcState_Idle: {

						var distance_to_home = Math.dst(gnome.x, gnome.y, gnome.home_x, gnome.home_y);
						if (distance_to_home < gnome.leash_range) {
    						// Move around 
    						var neighbor = random_neighbor(gnome.x, gnome.y);
    						move_entity_to(gnome, neighbor.x, neighbor.y);
    					} else {
    						// Go home
    						move_entity_to(gnome, gnome.home_x, gnome.home_y);
    					}

    					gnome.state_timer++;
    					if (gnome.state_timer > gnome.gather_interval) {
    						gnome.state_timer = 0;
    						gnome.state = NpcState_MovingTo;

    						var resource = closest_resource(gnome.x, gnome.y);
    						if (resource != null) {
    							var random_displacement = random_move(resource.x, resource.y);
    							gnome.destination_x = resource.x - random_displacement.x;
    							gnome.destination_y = resource.y - random_displacement.y;
    							gnome.gathered_resource = resource;
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
    					gnome.gathered_resource.hp--;

    					if (gnome.gathered_resource.hp <= 0) {
    						// If not gathered yet, gather resource and delete
							if (!gnome.gathered_resource.gathered) {
								gnome.gathered_resource.delete();

								switch (gnome.gathered_resource.type) {
									case ResourceType_Tree: {
										gnome_wood++;
									}
									case ResourceType_Bananas: {
										gnome_bananas++;
									}
									default:
								}
							}

							gnome.gathered_resource = null;
							gnome.state = NpcState_Idle;
						}
					}
					default:
				}
			}
		}


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

			update_result();
		}


		render();
	}
}
