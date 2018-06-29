import haxegon.*;
import haxe.ds.ObjectMap;
import haxegon.IntVector2;

enum EntityType {
	EntityType_Player;
	EntityType_Mob;
	EntityType_Resource;
}

enum ResourceType {
	ResourceType_None;
	ResourceType_Tree;
	ResourceType_Bananas;
}

enum MobState {
	MobState_None;
	MobState_Idle;
	MobState_Goal;
}


@:publicFields
class Entity {
	static var all = new Array<Dynamic>();
	static var entities = new ObjectMap<Dynamic, Array<Dynamic>>();

	static function get(type: Dynamic): Array<Dynamic> {
		if (!entities.exists(type)) {
			entities.set(type, new Array<Dynamic>());
		}
		return entities.get(type);
	}

	static var id_max = 0;
	var id = 0;

	function new() {
		var type = Type.getClass(this);
		if (!entities.exists(type)) {
			entities.set(type, new Array<Dynamic>());
		}
		entities.get(type).push(this);
		all.push(this);

		id = id_max;
		id_max++;
	}

	function delete() {
		for (type in entities) {
			for (entity in type) {
				if (entity == this)
				{
					type.remove(this);
					break;
				}
			}
		}
		all.remove(this);
	}
}

class Player extends Entity {
	var entity_type = EntityType_Player;

	var x: Int = 0;
	var y: Int = 0;
	var dx: Int = 0;
	var dy: Int = 0;
	var already_moved = false;
}

class Mob extends Entity {
	var entity_type = EntityType_Mob;

	var x: Int = 0;
	var y: Int = 0;
	var dx: Int = 0;
	var dy: Int = 0;
	var home_x: Int = 0;
	var home_y: Int = 0;
	var state: MobState = MobState_None;
	var leash_range = 3;

	var state_timer = 0;
	var goal: Dynamic = null;

	var hp = 10;
	var hp_max = 10;
	var energy = 50;
	var energy_max = 100;
	var energy_decrease_timer = 0;
	var energy_decrease_timer_max = 5;
	var motivation = 0; // 0 to 100, corresponds to chance of switching from idle to goal

	var wood = 0;

	var name = "";
}


class Resource extends Entity {
	var entity_type = EntityType_Resource;

	var x: Int = 0;
	var y: Int = 0;
	var resource_type = ResourceType_Bananas;
	var hp: Int = 10;
	var hp_max: Int = 10;

	var name = "";
}
