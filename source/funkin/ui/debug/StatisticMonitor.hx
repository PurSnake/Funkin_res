package funkin.ui.debug;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

import openfl.text._internal.TextFormatRange;
import openfl.display.Sprite;
import flixel.math.FlxMath;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
/*
class StatisticMonitor extends TextField
{
	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "";

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible) return;

		if (deltaTimeout > 1000) {
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		deltaTimeout += deltaTime;

		text = currentFPS
		+ '\n' + flixel.util.FlxStringUtil.formatBytes(memoryMegas);
	}

	inline function get_memoryMegas():Float
		return cast(System.totalMemory, UInt);
}
*/


using flixel.util.FlxStringUtil;

@:access(openfl.text.TextField)
class StatisticMonitor extends Sprite
{
	public var fpsText:TextField;
	public var bgSprite:Sprite;

	public var offsetX:Float;
	public var offsetY:Float;

	public var currentFPS(default, null):Float = 0;
	public var currentMem(default, null):UInt;
	public var memoryMegasMax(default, null):UInt = 0;

	@:keep @:noCompletion override function set_scaleX(value:Float):Float
	{
		value = super.set_scaleX(value);
		updatePos();
		return value;
	}

	@:keep @:noCompletion override function set_scaleY(value:Float):Float
	{
		value = super.set_scaleY(value);
		updatePos();
		return value;
	}

	public function updatePos()
	{
		fpsText.__textFormat.align = LEFT;
		bgSprite.y = x = y = 0;

		updateText();
		bgSprite.scaleY = fpsText.height + offsetY * 2 + 3;
		fpsText.y = offsetY;
	}

	public function new(offsetX:Float = 10, offsetY:Float = 10, color:Int = 0x000000)
	{
		super();

		this.offsetX = offsetX;
		this.offsetY = offsetY;

		mouseEnabled = false;

		bgSprite = new Sprite();
		bgSprite.mouseEnabled = false;
		bgSprite.graphics.beginFill(0xFF000000);
		bgSprite.graphics.drawRect(0, 0, 1, 1);
		bgSprite.graphics.endFill();
		bgSprite.alpha = 1 / 3;
		addChild(bgSprite);

		fpsText = new TextField();
		fpsText.selectable = fpsText.mouseEnabled = false;
		fpsText.defaultTextFormat = new TextFormat("VCR OSD Mono", 14, 0xEEEEEE);
		fpsText.autoSize = LEFT;
		fpsText.multiline = true;
		addChild(fpsText);

		fpsText.x = offsetX;
		fpsText.y = offsetY;

		fpsText.removeEventListeners();

		visible = Preferences.debugDisplay;
		@:bypassAccessor {
			// bind orig set method
			super.set_scaleX(1);
			super.set_scaleY(1);
		}

		FlxG.signals.preUpdate.add(flixelUpdate);
		FlxG.signals.gameResized.add((w, h) -> updatePos());
		updatePos();
	}

	@:noCompletion
	override function __enterFrame(deltaTime:Int):Void { }

	extern inline function __calc__fps(__cur__fps:Float, __e:Float):Float
		return FlxMath.lerp(__e == 0.0 ? 0.0 : 1.0 / __e, __cur__fps, Math.exp(-__e * 15.0));

	@:noCompletion var deltaTimeout:Float = 0.0;

	@:access(flixel.FlxGame._elapsedMS)
	function flixelUpdate():Void
	{
		currentFPS = __calc__fps(currentFPS, FlxG.game._elapsedMS / 1000);
		deltaTimeout += FlxG.game._elapsedMS;
		if (deltaTimeout < 75)
			return;

		deltaTimeout -= 75;

		updateText();
	}

	@:noCompletion var _text:String = '';
	@:noCompletion var _maxMemorytext:String = 4.formatBytes();

	inline function addLine(str:String = '', altStr:String = '')
	{
		_text += str;
		// _text += altStr;
		if (altStr != null)
			_text += '<font color = "#ffffff" faces = "' + fpsText.defaultTextFormat.font + '" size = "13">$altStr</font>';
		_text += '\n';
	}

	inline function updateText()
	{
		_text = '';
		addLine('FPS: ', Std.string(Math.floor(FlxG.updateFramerate > currentFPS ? currentFPS : FlxG.updateFramerate)));

		currentMem = cast System.totalMemory;
		if (currentMem <= FlxMath.MAX_VALUE_INT)
		{
			if (memoryMegasMax < currentMem)
			{
				memoryMegasMax = currentMem;
				_maxMemorytext = memoryMegasMax.formatBytes();
			}
			addLine('Mem: ', currentMem.formatBytes());
			addLine('Mem MAX: ', _maxMemorytext);
		}
		else
			addLine('<font color = "#ff8888" faces = "' + fpsText.defaultTextFormat.font + '" size = "12">' + 'Memory Leaking: ' + '</font>' +
			'<font color = "#ff9999" faces = "' + fpsText.defaultTextFormat.font + '" size = "13">' + '-${cast(currentMem - FlxMath.MAX_VALUE_INT, UInt).formatBytes()}' + '</font>');

		fpsText.htmlText = _text;

		bgSprite.scaleX = fpsText.width + offsetX * 2;
		bgSprite.x = 0;
		fpsText.x = bgSprite.x + offsetX;
	}
}

