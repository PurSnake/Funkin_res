package funkin.util;

// import flixel.FlxG;
// import flixel.math.FlxMath;
// import flixel.math.FlxPoint;
import flixel.FlxSprite;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.FocusEvent;

// using StringTools;
class Utils
{
	/* Used to remove unneeded functions from OpenFl object
	 *
	 *
	 */
	@:access(openfl.text.TextField)
	public static function removeEventListeners<T:openfl.text.TextField>(textField:T)
	{
		textField.removeEventListener(FocusEvent.FOCUS_IN, textField.this_onFocusIn);
		textField.removeEventListener(FocusEvent.FOCUS_OUT, textField.this_onFocusOut);
		textField.removeEventListener(KeyboardEvent.KEY_DOWN, textField.this_onKeyDown);
		textField.removeEventListener(MouseEvent.MOUSE_DOWN, textField.this_onMouseDown);
		textField.removeEventListener(MouseEvent.MOUSE_WHEEL, textField.this_onMouseWheel);
		// old OpenFL stuff textField.removeEventListener(MouseEvent.DOUBLE_CLICK, textField.this_onDoubleClick);
	}

	/*
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
	 */
	/**
		Formats hours, minutes and seconds to just seconds.
	**/
	@:noUsing public inline static function timeToSeconds(h:Float, m:Float, s:Float):Float
		return h * 3600 + m * 60 + s;

	public inline static function getLastOfArray<T>(a:Array<T>):T
		return a[a.length - 1];

	public inline static function clearArray<T>(a:Array<T>):Array<T>
	{
		while (a.length > 0)
			a.pop();
		return a;
	}

	public static function findAndLoadXMLAnims<T:FlxSprite>(sprite:T, ?filePos:haxe.PosInfos):FlxSprite
	{
		var xmlAnims = [];
		for (i in sprite.frames.framesHash.keys())
		{
			final n = i.substr(0, i.length - 4);
			if (!xmlAnims.contains(n)) xmlAnims.push(n);
		}
		xmlAnims.length > 0 ? 
		{
			for (anim in xmlAnims) sprite.animation.addByPrefix(anim, anim, 24, false);
			sprite.animation.play(xmlAnims[0]); //play first animation
		} : trace("[WARNING] No animations found! (Cant load from XML)", filePos);
		return sprite;
	}
}
