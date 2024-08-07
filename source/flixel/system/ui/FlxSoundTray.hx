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
import flixel.system.FlxAssets.FlxSoundAsset;

import funkin.Paths;
	

import openfl.display.animation.AnimatedSprite;

/* W.I.P
import flixel.FlxCamera;
import flixel.FlxSprite;
*/


/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	public var active:Bool;

	var _width:Float = 80;
	var _defaultScale:Float = 1.0;

	public var volumeUpSound:FlxSoundAsset = Paths.sound("soundtray/Volup");
	public var volumeDownSound:FlxSoundAsset = Paths.sound("soundtray/Voldown");
	public var volumeMaxSound:FlxSoundAsset = Paths.sound("soundtray/VolMAX");

	public var silent:Bool = false;
	public var shouldShow:Bool = true;
	public var timeToExist:Float = 1.5;
	private var _localTimer:Float;
	private var _requestedY:Float;

	var splashSprite:AnimatedSprite;
	var _volumeSprite:Bitmap;

	/*
	var renderCamera:FlxCamera;
	var splashSprite:FlxSprite;
	*/

	@:keep
	public function new()
	{
		super();

		scaleX = _defaultScale;
		scaleY = _defaultScale;
		screenCenter();

		//final splashSprite:Bitmap = new Bitmap(Assets.getBitmapData(Paths.file("images/soundtray/volume-back.png")));
		//splashSprite.smoothing = true;

		//splashSprite = AnimatedSprite.fromFramesCollection(Paths.getSparrowAtlas("soundtray/volume"));
		var key = "soundtray/volume";
		splashSprite = AnimatedSprite.fromFramesCollection(flixel.graphics.frames.FlxAtlasFrames.fromSparrow(Paths.image(key, null, false), Paths.file('images/$key.xml')));
		splashSprite.y = -1;
		splashSprite.animation.addByPrefix("splash", "volume back", 24, false);
		splashSprite.animation.play("splash", true);
		splashSprite.animation.curAnim.play(true);
		splashSprite.animation.curAnim.finished = false;
		splashSprite.animation.curAnim.looped = false;
		_width = 382; //splashSprite.width;

		final disBg:Bitmap = new Bitmap(new BitmapData(233, 51, false, FlxColor.GRAY));
		_volumeSprite = new Bitmap(new BitmapData(1, 51, false, FlxColor.WHITE));
		disBg.x = _volumeSprite.x = 74;
		disBg.y = _volumeSprite.y = 7;
		addChild(disBg);
		addChild(_volumeSprite);
		addChild(splashSprite);


		/*
		splashSprite = new FlxSprite();
		splashSprite.frames = Paths.getSparrowAtlas("soundtray/volume");
		splashSprite.animation.addByPrefix("splash", "volume back", 1, true); //false
		splashSprite.animation.play("splash", true);
		trace(splashSprite.frames == null);
		trace(splashSprite.animation == null);

		renderCamera = new FlxCamera(0, 0, Std.int(splashSprite.width), Std.int(splashSprite.height));
		renderCamera.bgColor = FlxColor.TRANSPARENT;
		splashSprite.camera = renderCamera;
		_width = renderCamera.width;
		addChild(renderCamera.flashSprite);

		FlxG.signals.gameResized.add((w, h) -> renderCamera.onResize());
		*/

		_requestedY = y = -height;
		//_requestedY = y = 0;
		visible = false;
	}

	public function update(MS:Float):Void
	{
		if (active) {
			//renderSelf();

			_volumeSprite.width = MathUtil.fpsLerp(_volumeSprite.width, FlxG.sound.muted ? 0 : (237 * FlxG.sound.volume), MathUtil.getFPSRatio(.65)); //.15
			
			if (_localTimer >= timeToExist) _requestedY = -height;

			y = MathUtil.fpsLerp(y, _requestedY, MathUtil.getFPSRatio(.25)); //.15

			(y == -height && _localTimer >= timeToExist) ? hideSelf() : _localTimer += (MS / 1000);
		}
	}

	/*
	@:access(flixel.FlxCamera)
	public function renderSelf():Void
	{
		splashSprite.update(FlxG.elapsed);
		renderCamera.update(FlxG.elapsed);

		// CAM LOCK
		renderCamera.clearDrawStack();
		renderCamera.canvas.graphics.clear();
		// Clearing camera's debug sprite
		#if FLX_DEBUG
		renderCamera.debugLayer.graphics.clear();
		#end
	
		renderCamera.fill(renderCamera.bgColor.to24Bit(), renderCamera.useBgAlphaBlending, renderCamera.bgColor.alphaFloat);
		// CAM LOCK

		// DRAW
		splashSprite.draw();
		renderCamera.render();
		// DRAW

		// CAM UNLOCK
		renderCamera.canvas.graphics.overrideBlendMode(null);
		renderCamera.drawFX();
		// CAM UNLOCK
	}
	*/
	
	public function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		var globalVolume:Int = Math.round(FlxG.sound.volume * 20);
		if (FlxG.sound.muted) globalVolume = 0;

		if (shouldShow && !silent && forceSound)
		{
			var sound:FlxSoundAsset = up ? volumeUpSound : volumeDownSound;
			if (globalVolume == 20) sound = volumeMaxSound;
			if (sound != null) {
				final volumeSound = FlxG.sound.load(sound);
				volumeSound.onComplete = __soundOnComplete.bind(volumeSound);
				#if FLX_PITCH volumeSound.pitch = flixel.math.FlxMath.lerp(0.75, 1.25, FlxG.sound.volume); #end		
				volumeSound.play();
				FlxG.sound.list.remove(volumeSound); //due to stateSwitch bug
			}
		}

		if (shouldShow) {
			visible = true;
			active = true;

			splashSprite.animation.curAnim.finished = false;
			splashSprite.animation.curAnim.looped = false;
			splashSprite.animation.curAnim.play(true);

			//splashSprite.animation.play("splash", true);
			_localTimer = _requestedY = 0;
		}

		//_volumeSprite.width = 237 * (globalVolume/20);
		//_volumeSprite.width = 237 * FlxG.sound.volume;		
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
