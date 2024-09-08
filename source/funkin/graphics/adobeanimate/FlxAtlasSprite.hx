package funkin.graphics.adobeanimate;

import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;
import flxanimate.frames.FlxAnimateFrames;
import openfl.display.BitmapData;
import openfl.utils.Assets;

import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import openfl.geom.ColorTransform;
import openfl.display.BlendMode;
//FlxAnimate Draw

/**
 * A sprite which provides convenience functions for rendering a texture atlas with animations.
 */
class FlxAtlasSprite extends FlxAnimate
{
	static final SETTINGS:Settings =
	{
		// ?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
		FrameRate: 24.0,
		Reversed: false,
		// ?OnComplete:Void -> Void,
		ShowPivot: #if debug false #else false #end,
		Antialiasing: true,
		ScrollFactor: null,
		// Offset: new FlxPoint(0, 0), // This is just FlxSprite.offset
	};

	/**
	 * Signal dispatched when an animation finishes playing.
	 */
	public var onAnimationFinish:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	var currentAnimation:String;

	var canPlayOtherAnims:Bool = true;

	public function new(x:Float, y:Float, ?path:String, ?settings:Settings)
	{
		if (settings == null) settings = SETTINGS;

		if (path == null)
		{
			throw 'Null path specified for FlxAtlasSprite!';
		}

		super(x, y, path, settings);

		if (this.anim.curInstance == null)
			throw 'FlxAtlasSprite not initialized properly. Are you sure the path (${path}) exists?';

		anim.onComplete.add((instName:String, symName:String) -> onAnimationFinish.dispatch(currentAnimation));
		onAnimationFinish.add(cleanupAnimation);

		// This defaults the sprite to play the first animation in the atlas,
		// then pauses it. This ensures symbols are intialized properly.
		this.anim.play();
		this.anim.pause();
	}

	/**
	 * @return A list of all the animations this sprite has available.
	 */
	public function listAnimations():Array<String>
	{
		if (this.anim == null) return [];
		return this.anim.getFrameLabelNames();
		// return [""];
	}

	/**
	 * @param id A string ID of the animation.
	 * @return Whether the animation was found on this sprite.
	 */
	@:access(flxanimate.animate.FlxAnim)
	public function hasAnimation(id:String):Bool
	{
		return anim.animsMap.exists(id) || anim.symbolDictionary.exists(id) || anim.getLabel(id) != null;
	}

	/**
	 * @return The current animation being played.
	 */
	public function getCurrentAnimation():String
	{
		return this.currentAnimation;
	}

	/**
	 * `anim.finished` always returns false on looping animations,
	 * but this function will return true if we are on the last frame of the looping animation.
	 */
	public function isLoopFinished():Bool
	{
		if (this.anim == null || !this.anim.isPlaying) return false;

		// Reverse animation finished.
		if (this.anim.reversed
			&& this.anim.curFrame == 0
			|| // Forward animation finished.
			!this.anim.reversed
			&& this.anim.curFrame >= (this.anim.length - 1)) return true;

		return false;
	}

	/**
	 * Plays an animation.
	 * @param id A string ID of the animation to play.
	 * @param restart Whether to restart the animation if it is already playing.
	 * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
	 * @param loop Whether to loop the animation
	 * NOTE: `loop` and `ignoreOther` are not compatible with each other!
	 */
	public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, ?loop:Bool = false):Void
	{
		if (loop == null) loop = false;

		// Skip if not allowed to play animations.
		if (!canPlayOtherAnims && !ignoreOther) return;

		if (id == null || id == '') id = this.currentAnimation;

		if (this.currentAnimation == id && !restart && anim.isPlaying)
		{
			// Skip if animation is already playing.
			return;
		}

		// Skip if the animation doesn't exist
		if (!hasAnimation(id))
		{
			trace('Animation ' + id + ' not found');
			return;
		}

		/*
			anim.callback = function(_, frame:Int) {
				var offset = loop ? 0 : -1;

				var frameLabel = anim.getFrameLabel(id);
				if (frame == (frameLabel.duration + offset) + frameLabel.index)
				{
					if (loop)
					{
						playAnimation(id, true, false, true);
					}
					else
					{
						onAnimationFinish.dispatch(id);
					}
				}
			};
		 */

		anim.play(id, true, false);
		anim.curInstance.symbol.loop = loop ? Loop : PlayOnce;

		// Prevent other animations from playing if `ignoreOther` is true.
		if (ignoreOther) canPlayOtherAnims = false;

		// Move to the first frame of the animation.
		this.currentAnimation = id;
	}

	/**
	 * Stops the current animation.
	 */
	public function stopAnimation():Void
	{
		if (this.currentAnimation == null) return;

		/*
			this.anim.removeAllCallbacksFrom(getNextFrameLabel(this.currentAnimation));

			goToFrameIndex(0);
		 */

		anim.stop();
	}

	function addFrameCallback(label:String, callback:Void->Void):Void
	{
		var frameLabel = this.anim.getFrameLabel(label);
		frameLabel.add(callback);
	}

	function getNextFrameLabel(label:String):String
	{
		final list = listAnimations();
		return list[(getLabelIndex(label) + 1) % list.length];
	}

	function getLabelIndex(label:String):Int
	{
		return listAnimations().indexOf(label);
	}

	function goToFrameIndex(index:Int):Void
	{
		this.anim.curFrame = index;
	}

	public function cleanupAnimation(_:String):Void
	{
		canPlayOtherAnims = true;
		// this.currentAnimation = null;
		this.anim.pause();
	}

	public override function draw():Void
	{
		if(alpha == 0) return;
		updateSkewMatrix();

		if (useAtlas)
		{
			for (i => camera in cameras)
			{
				final _point:FlxPoint = getScreenPosition(_camerasCashePoints[i], camera).subtractPoint(offset + frameOffset);
				_point.addPoint(origin);
				_camerasCashePoints[i] = _point;
			}

			updateTrig();
			if (anim.curInstance != null)
			{
				_flashRect.setEmpty();

				anim.curInstance.updateRender(_lastElapsed, anim.curFrame, anim.symbolDictionary, anim.swfRender);
				_matrix.identity();
				if (flipX != anim.curInstance.flipX)
				{
					_matrix.a *= -1;
					// _matrix.tx += width;
				}
				if (flipY != anim.curInstance.flipY)
				{
					_matrix.d *= -1;
					// _matrix.ty += height;
				}
				if (frames != null)
					parseElement(anim.curInstance, _matrix, colorTransform, blend, cameras);
				width = Math.abs(_flashRect.width);
				height = Math.abs(_flashRect.height);
				frameWidth = Math.round(width / scale.x);
				frameHeight = Math.round(height / scale.y);

				relativeX = _flashRect.x - x;
				relativeY = _flashRect.y - y;
			}
		}
		else
		{
			relativeX = relativeY = 0;
			basicDraw();
		}

		if (showPivot && (showPosPoint || showMidPoint))
		{
			var mat = FlxPooledMatrix.get();
			if (showMidPoint)
			{
				mat.translate(-_pivot.frame.width * 0.5, -_pivot.frame.height * 0.5);
				mat.scale(pivotScale / camera.zoom, pivotScale / camera.zoom);
				mat.translate(origin.x, origin.y);
				// mat.translate(-offset.x, -offset.y);
				drawPivotLimb(_pivot, mat, cameras);
				mat.identity();
			}
			if (showPosPoint)
			{
				mat.translate(-_indicator.frame.width * 0.5, -_indicator.frame.height * 0.5);
				mat.scale(pivotScale / camera.zoom, pivotScale / camera.zoom);
				// mat.translate(-offset.x, -offset.y);
				drawPivotLimb(_indicator, mat, cameras);
			}
			mat.put();
		}
	}

	public override function getScreenBounds(?newRect:FlxRect, ?camera:flixel.FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();

		if (camera == null)
			camera = FlxG.camera;
		newRect.setPosition(x + relativeX, y + relativeY);
		if (pixelPerfectPosition)
			newRect.floor();
		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - (offset.x + frameOffset.x) + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - (offset.y + frameOffset.y) + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}


	@:noCompletion
	override function drawComplex(camera:flixel.FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset + frameOffset);
		_point.add(origin.x, origin.y);
		_matrix.concat(matrixExposed ? transformMatrix : FlxAnimate._skewMatrix);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}
}