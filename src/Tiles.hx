
@:publicFields
class Tiles {
    static inline var tileset_width = 10;
    static inline function tilenum(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = tilenum(0, 1); // bugged tile

    static inline var Player = tilenum(0, 0);
    static inline var Wall = tilenum(1, 0);
    static inline var Ground = tilenum(2, 0);
    static inline var Gnome = tilenum(3, 0);
    static inline var Bananas = tilenum(4, 0);
    static inline var Tree = tilenum(5, 0);
    static inline var Dragon = tilenum(7, 0);
    static inline var Flower = tilenum(8, 0);

}