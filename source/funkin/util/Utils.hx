package funkin.util;

import flixel.util.typeLimit.OneOfFour;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.FocusEvent;
#if sys
import sys.io.File;
import sys.FileSystem;
import sys.thread.Thread;
#end
import openfl.filters.ShaderFilter;
import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import lime.app.Future;
import lime.app.Promise;
import haxe.Json;
import haxe.io.Path;
import haxe.PosInfos;

using StringTools;

typedef DynamicColor = OneOfFour<FlxColor, Float, String, Array<Dynamic>>;

class Utils
{

	@:noUsing public inline static function precacheSound(sound:String, ?library:String = null)
		FlxG.sound.cache(Paths.sound(sound, library));

	@:noUsing public inline static function precacheMusic(sound:String, ?library:String = null)
		FlxG.sound.cache(Paths.music(sound, library));

	@:access(openfl.text.TextField)
	public static function removeEventListeners<T:openfl.text.TextField>(textField:T)
	{
		// i think it is optimization
		textField.removeEventListener(FocusEvent.FOCUS_IN, textField.this_onFocusIn);
		textField.removeEventListener(FocusEvent.FOCUS_OUT, textField.this_onFocusOut);
		textField.removeEventListener(KeyboardEvent.KEY_DOWN, textField.this_onKeyDown);
		textField.removeEventListener(MouseEvent.MOUSE_DOWN, textField.this_onMouseDown);
		textField.removeEventListener(MouseEvent.MOUSE_WHEEL, textField.this_onMouseWheel);
		textField.removeEventListener(MouseEvent.DOUBLE_CLICK, textField.this_onDoubleClick);
	}


	static var _mousePoint:FlxPoint = new FlxPoint();
	static var _objPoint:FlxPoint = new FlxPoint();

	public static function mouseOverlapping<T:flixel.FlxObject>(obj:T, ?mousePoint:FlxPoint)
	{
		// if (_mousePoint == null) _mousePoint = FlxPoint.get();
		if (mousePoint == null)
			mousePoint = _mousePoint;
		// if (_objPoint == null) _objPoint = FlxPoint.get();
		FlxG.mouse.getScreenPosition(obj.camera, mousePoint);
		obj.getScreenPosition(_objPoint, obj.camera);
		return FlxMath.pointInCoordinates(mousePoint.x, mousePoint.y, _objPoint.x, _objPoint.y, obj.width, obj.height);
	}
}
