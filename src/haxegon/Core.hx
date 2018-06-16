package haxegon;

import haxe.Timer;
import openfl.display.*;
import openfl.events.*;
import openfl.Lib;

#if haxegon3D
import haxegon3D.*;
#end

@:access(Main)
@:access(haxegon.Gfx)
#if haxegon3D
@:access(haxegon3D.Gfx3D)
#end
@:access(haxegon.Music)
@:access(haxegon.Mouse)
@:access(haxegon.Input)
class Core extends Sprite {
    var main: Main;

    //NEW FRAMERATE CODE - From HaxePunk fixed FPS implementation
    private var maxelapsed: Float;
    private var maxframeskip: Int;
    private var tickrate: Int;

    // Timing information.
    private var TARGETFRAMERATE: Int = 60;
    private var _delta: Float;
    private var _time: Float;
    private var _last: Float;
    private var _timer: Timer;
    private var _rate: Float;
    private var _skip: Float;
    private var _prev: Float;
    private var _skipedupdate: Int;

    // Debug timing information.
    private var _updatetime: Float;
    private var _rendertime: Float;
    private var _gametime: Float;
    private var _framesthissecond_counter: Float;
    
    public function new() {
        super();

        Gfx.initrun = true;
        init();
    }

    public function init() {
        maxelapsed = 0.0333;
        maxframeskip = 5;
        tickrate = 20;
        _delta = 0;

        // on-stage event listener
        if (Gfx.initrun) {
            addEventListener(Event.ADDED_TO_STAGE, addedtostage);
            Lib.current.addChild(this);
        } else {
            loaded();
        }
    }

    private function addedtostage(e: Event = null) {
        removeEventListener(Event.ADDED_TO_STAGE, addedtostage);
        loaded();
    }

    private function loaded() {
        //Init library classes
        if (Gfx.initrun) {
            Input.init(this.stage);
            Mouse.init(this.stage);
        }

        Gfx.init(this.stage);

        Music.init();

        //Default setup
        Gfx.resize_screen(768, 480);
        Text.setfont("opensans", 24);

        main = new Main();

        // start game loop
        _rate = 1000 / TARGETFRAMERATE;
        // fixed framerate
        _skip = _rate * (maxframeskip + 0.98);
        _last = _prev = Lib.getTimer();
        if (_timer != null) _timer.stop();
        _timer = new Timer(tickrate);
        //_timer.run = ontimer;
        stage.addEventListener(Event.ENTER_FRAME, onenterframe);
        Gfx.updatefps = 0;
        Gfx.renderfps = 0;
        _framesthissecond_counter = -1;

        Gfx.initrun = false;
    }

    private function onenterframe(FlashEvent: Event){
        ontimer();
    }

    private function ontimer() {
        Gfx.skiprender = false;
        _skipedupdate = 0;

        // update timer
        _time = Lib.getTimer();
        _delta += (_time - _last);
        _last = _time;

        if (_framesthissecond_counter == -1) {
            _framesthissecond_counter = _time;
        }

        // quit if a frame hasn't passed
        if (_delta < _rate) return;

        // Slide the frame window back ever so slightly to avoid causing hiccups when the call
        // interval to ontimer() approaches the length of a frame
        if (_delta > 1.5 * _rate) {
            _delta -= 0.01;
        }

        // update timer
        _gametime = Std.int(_time);

        // update loop
        if (_delta > _skip) _delta = _skip;
        while (_delta >= _rate) {
            //HXP.elapsed = _rate * HXP.rate * 0.001;
            // update timer
            _updatetime = _time;
            _delta -= _rate;
            _prev = _time;

            // update loop
            if (Gfx.clearscreeneachframe) Gfx.skiprender = true;
            _skipedupdate++; //Skip one update now; we catch it later at render
            if (_skipedupdate > 1) doupdate();

            // update timer
            _time = Lib.getTimer();
        }

        // update timer
        _rendertime = _time;

        // render loop
        Gfx.skiprender = false; doupdate();
        Gfx.renderfps++;

        if (_rendertime - _framesthissecond_counter > 1000) {
            //trace("Update calls: " + Gfx.updatefps +", Render calls: " + Gfx.renderfps);
            _framesthissecond_counter = Lib.getTimer();
            Gfx.updatefps_max = Gfx.updatefps;
            Gfx.renderfps_max = Gfx.renderfps;
            Gfx.renderfps = 0;
            Gfx.updatefps = 0;
        }

        // update timer
        _time = Lib.getTimer();
    }

    public function doupdate() {
        Gfx.updatefps++;
        Mouse.update(Std.int(Lib.current.mouseX / Gfx.screenscale), Std.int(Lib.current.mouseY / Gfx.screenscale));
        Input.update();

        if (!Gfx.skiprender) {
            Gfx.drawto.lock();
            if (Gfx.clearscreeneachframe) Gfx.clear_screen();
        }
        main.update();
        if (!Gfx.skiprender) {
            Text.drawstringinput();
            Debug.showLog();

            Gfx.drawto.unlock();

            #if haxegon3D
            Gfx3D.view.render();
            #end
        }

        Mouse.mousewheel = 0;
    }
}