package;

import flixel.FlxGame;
import flixel.FlxState;
import funkin.util.logging.CrashHandler;
import funkin.save.Save;
import haxe.ui.Toolkit;
import openfl.display.Sprite;
import openfl.display.MovieClip;
import openfl.events.Event;
import openfl.Lib;

typedef MainConfig = {
	/**
	 * Will play HAXEFLIXEL and FUNKIN intro on start.
	 * @default `true`
	 */
	var ?allowIntro:Bool;

	/**
	 * Will game load images to your GPU?
	 * Disable if you have no videocard.
	 * @default `true`
	 */
	var ?allowGPULoad:Bool;

	/**
	 * Open CMD with game logging on startup.
	 * Usefull for modmakers.
	 * @default `false`
	 */
	var ?enableOuputConsole:Bool;
};

class Main extends flixel.FlxGame
{
	public static var mainInstance(default, null):Sprite;
	public static var applicationScreen(get, never):MovieClip;

	public static var config:MainConfig; 
	@:noCompletion public static var GPULoadAllowed:Bool = true; 

	@:noCompletion inline static function get_applicationScreen()
		return Lib.current;

	public static var statisticMonitor:funkin.ui.debug.StatisticMonitor;

	public static function main():Void
	{
		mainInstance = new Main();
		CrashHandler.initialize();
		CrashHandler.queryStatus();
	}

	public function new()
	{
		#if windows
		@:functionCode("
			#include <windows.h>
			setProcessDPIAware() // allows for more crisp visuals
		")
		#end

		Save.load();
		initMainConfig();
		initHaxeUI();

		flixel.system.FlxAssets.FONT_DEFAULT = "VCR OSD Mono";

		haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;
		funkin.util.logging.AnsiTrace.traceBF();
		funkin.modding.PolymodHandler.loadAllMods();

		statisticMonitor = new funkin.ui.debug.StatisticMonitor(10, 3, 0xFFFFFF);
		
		super(
			1280, 720,
			funkin.InitState, 144, 144, 
			true, false
		);
		applicationScreen.addChild(this);

		#if !mobile
		applicationScreen.addChild(statisticMonitor);
		applicationScreen.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;
		#end

		#if debug
		game.debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil());
		#end

		#if hxcpp_debug_server
		trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
		#else
		trace('hxcpp_debug_server is disabled! This build does not support debugging.');
		#end

		funkin.util.tools.ShaderResizeFix.init();
	}

	var skipNextTickUpdate:Bool = false;
	public override function switchState()
	{
		super.switchState();
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t)
	{
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
	}

	function initMainConfig():Void
	{
		if (sys.FileSystem.exists("config.json"))
			config = cast haxe.Json.parse(sys.io.File.getContent("config.json"));

		if (config == null)
			config = {
				allowIntro: true,
				allowGPULoad: true,
				enableOuputConsole: false
			};
		trace(config);
		openfl.utils.Assets.allowGPU = GPULoadAllowed = config.allowGPULoad;
	}

	function initHaxeUI():Void
	{
		// Calling this before any HaxeUI components get used is important:
		// - It initializes the theme styles.
		// - It scans the class path and registers any HaxeUI components.
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		Toolkit.autoScale = false;
		// Don't focus on UI elements when they first appear.
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		funkin.input.Cursor.registerHaxeUICursors();
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
	}
}

