import haxegon.*;
import haxe.ds.ObjectMap;
import haxegon.IntVector2;

enum EntityType {
    EntityType_Player;
    EntityType_Gnome;
    EntityType_Resource;
}

enum ResourceType {
    ResourceType_None;
    ResourceType_Tree;
    ResourceType_Bananas;
}

enum NpcState {
    NpcState_None;
    NpcState_Dead;
    NpcState_Idle;
    NpcState_Attack;
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
    var moved = false;
}

class Gnome extends Entity {
	var entity_type = EntityType_Gnome;

    var x: Int = 0;
    var y: Int = 0;
    var dx: Int = 0;
    var dy: Int = 0;
    var moved = false;
    var home_x: Int = 0;
    var home_y: Int = 0;
    var destination_x: Int = 0;
    var destination_y: Int = 0;
    var state: NpcState = NpcState_None;
    var leash_range = 3;

    var state_timer = 0;
    var gathered_resource: Resource = null;

    var hp = 10;
    var hp_max = 10;
    var energy = 50;
    var energy_max = 100;
    var energy_decrease_timer = 0;
    var energy_decrease_timer_max = 5;

    var wood = 0;
}


class Resource extends Entity {
	var entity_type = EntityType_Resource;

    var x: Int = 0;
    var y: Int = 0;
    var resource_type = ResourceType_Bananas;
    var hp: Int = 10;
    var hp_max: Int = 10;
}
