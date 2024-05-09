package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

import funkin.util.MathUtil;


import funkin.Paths;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	public var active:Bool;

	var _width:Float = 80;
	var _defaultScale:Float = 1.0;

	public var volumeUpSound:String = Paths.sound("soundtray/Volup");
	public var volumeDownSound:String = Paths.sound("soundtray/Voldown");
	public var volumeMaxSound = Paths.sound("soundtray/VolMAX");

	public var silent:Bool = false;
	public var shouldShow:Bool = true;
	public var timeToExist:Float = 1.5;
	private var _localTimer:Float;
	private var _requestedY:Float;

	var _volumeSprite:Bitmap;

	@:keep
	public function new()
	{
		super();

		scaleX = _defaultScale;
		scaleY = _defaultScale;
		screenCenter();

		final splashSprite:Bitmap = new Bitmap(Assets.getBitmapData(Paths.image("soundtray/volume-back")));
		_width = splashSprite.width;

		final disBg:Bitmap = new Bitmap(new BitmapData(200, 68, false, FlxColor.GRAY));
		_volumeSprite = new Bitmap(new BitmapData(1, 68, false, FlxColor.WHITE));
		disBg.x = _volumeSprite.x = 78;
		addChild(disBg);
		addChild(_volumeSprite);
		addChild(splashSprite);

		_requestedY = y = -height;
		//_requestedY = y = 0;
		visible = false;
	}

	public function update(MS:Float):Void
	{
		if (active) {
			if (_localTimer >= timeToExist) _requestedY = -height;

			y = MathUtil.fpsLerp(y, _requestedY, MathUtil.getFPSRatio(.25)); //.15

			(y == -height && _localTimer >= timeToExist) ? hideSelf() : _localTimer += (MS / 1000);
		}
	}

	public function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		var globalVolume:Int = Math.round(FlxG.sound.volume * 20);
		if (FlxG.sound.muted) globalVolume = 0;

		if (shouldShow && !silent && forceSound)
		{
			var sound = up ? volumeUpSound : volumeDownSound;
			if (globalVolume == 20) sound = volumeMaxSound;
			if (sound != null) {
				final volumeSound = FlxG.sound.load(sound);
				volumeSound.onComplete = __soundOnComplete.bind(volumeSound);
				#if FLX_PITCH	
				volumeSound.pitch = flixel.math.FlxMath.lerp(0.75, 1.25, FlxG.sound.volume);
				#end		
				volumeSound.play();
				FlxG.sound.list.remove(volumeSound); //due to stateSwitch bug
			}
		}

		if (shouldShow) {
			visible = true;
			active = true;
			_localTimer = _requestedY = 0;
		}

		_volumeSprite.width = 10 * globalVolume;
	}


	@:noCompletion static function __soundOnComplete(sound:flixel.sound.FlxSound)
	{
		FlxG.sound.list.add(sound); // back for recycling -- Thx RichTrash <3
		sound.onComplete = null;
	}
	
	function hideSelf() {
		visible = false;
		active = false;	

		#if FLX_SAVE
		// Save sound preferences
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end
