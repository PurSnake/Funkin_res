package funkin.graphics;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import openfl.display3D.textures.TextureBase;
import funkin.graphics.framebuffer.FixedBitmapData;
import openfl.display.BitmapData;

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 * - TODO: Better cache handling for textures.
 */
class FunkinSprite extends flixel.addons.effects.FlxSkewedSprite //FlxSprite
{
	/**
	 * An internal list of all the textures cached with `cacheTexture`.
	 * This excludes any temporary textures like those from `FlxText` or `makeSolidColor`.
	 */
	static var currentCachedTextures:Map<String, FlxGraphic> = [];

	/**
	 * An internal list of textures that were cached in the previous state.
	 * We don't know whether we want to keep them cached or not.
	 */
	static var previousCachedTextures:Map<String, FlxGraphic> = [];

	/**
	 * @param x Starting X position
	 * @param y Starting Y position
	 */
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
	}

	/**
	 * Works similar to scrollFactor, but with sprite's camera zoom.
	 */
	public var zoomFactor:Float = 1;
	public var initialZoom:Float = 1;

	/**
	 * Additional offseting variable.
	 */
	public var frameOffset:FlxPoint = FlxPoint.get();

	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		__doPreZoomScaleProcedure(camera);
		//var r = super.getScreenBounds(newRect, camera);
		var r = getScreenBoundsFixed(newRect, camera);
		__doPostZoomScaleProcedure();
		return r;
	}

	public function getScreenBoundsFixed(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();
		
		if (camera == null)
			camera = FlxG.camera;
		
		newRect.setPosition(x, y);
		if (pixelPerfectPosition)
			newRect.floor();

		_scaledOrigin.set(origin.x * Math.abs(scale.x), origin.y * Math.abs(scale.y));
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - (offset.x + frameOffset.x) + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - (offset.y + frameOffset.y) + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	private inline function __shouldDoScaleProcedure()
		return zoomFactor != 1;

	var __oldScale:FlxPoint;
	var __skipZoomProcedure:Bool = false;

	private function __doPreZoomScaleProcedure(camera:FlxCamera)
	{
		if (__skipZoomProcedure = !__shouldDoScaleProcedure())
			return;
		__oldScale = FlxPoint.get(scale.x, scale.y);
		var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
		var diff = requestedZoom * camera.zoom;

		scale.scale(diff);
	}

	private function __doPostZoomScaleProcedure()
	{
		if (__skipZoomProcedure)
			return;
		scale.set(__oldScale.x, __oldScale.y);
		__oldScale.put();
		__oldScale = null;
	}

	public override function drawComplex(camera:FlxCamera)
	{
		_frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed)
		{
			_matrix.concat(transformMatrix);
		}
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			updateSkewMatrix();
			_matrix.concat(_skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(offset + frameOffset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		doAdditionalMatrixStuff(_matrix, camera);

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	public function doAdditionalMatrixStuff(matrix:FlxMatrix, camera:FlxCamera)
	{
		matrix.translate(-camera.width / 2, -camera.height / 2);

		var requestedZoom = FlxMath.lerp(1, camera.zoom, zoomFactor);
		var diff = requestedZoom / camera.zoom;
		matrix.scale(diff, diff);
		matrix.translate(camera.width / 2, camera.height / 2);
	}

	public override function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
	{
		if (__shouldDoScaleProcedure())
		{
			__oldScale = FlxPoint.get(scrollFactor.x, scrollFactor.y);
			var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
			var diff = requestedZoom / camera.zoom;

			scrollFactor.scale(1 / diff);

			var r = super.getScreenPosition(point, Camera);

			scrollFactor.set(__oldScale.x, __oldScale.y);
			__oldScale.put();
			__oldScale = null;

			return r;
		}
		return super.getScreenPosition(point, Camera);
	}

	/**
	 * Create a new FunkinSprite with a static texture.
	 * @param x The starting X position.
	 * @param y The starting Y position.
	 * @param key The key of the texture to load.
	 * @return The new FunkinSprite.
	 */
	public static function create(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
	{
		var sprite:FunkinSprite = new FunkinSprite(x, y);
		sprite.loadTexture(key);
		return sprite;
	}

	/**
	 * Create a new FunkinSprite with a Sparrow atlas animated texture.
	 * @param x The starting X position.
	 * @param y The starting Y position.
	 * @param key The key of the texture to load.
	 * @return The new FunkinSprite.
	 */
	public static function createSparrow(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
	{
		var sprite:FunkinSprite = new FunkinSprite(x, y);
		sprite.loadSparrow(key);
		return sprite;
	}

	/**
	 * Create a new FunkinSprite with a Packer atlas animated texture.
	 * @param x The starting X position.
	 * @param y The starting Y position.
	 * @param key The key of the texture to load.
	 * @return The new FunkinSprite.
	 */
	public static function createPacker(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
	{
		var sprite:FunkinSprite = new FunkinSprite(x, y);
		sprite.loadPacker(key);
		return sprite;
	}

	/**
	 * Load a static image as the sprite's texture.
	 * @param key The key of the texture to load.
	 * @return This sprite, for chaining.
	 */
	public function loadTexture(key:String):FunkinSprite
	{
		var graphicKey:String = Paths.image(key);
		if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

		loadGraphic(graphicKey);

		return this;
	}

	/**
	 * Apply an OpenFL `BitmapData` to this sprite.
	 * @param input The OpenFL `BitmapData` to apply
	 * @return This sprite, for chaining
	 */
	public function loadBitmapData(input:BitmapData):FunkinSprite
	{
		loadGraphic(input);

		return this;
	}

	/**
	 * Apply an OpenFL `TextureBase` to this sprite.
	 * @param input The OpenFL `TextureBase` to apply
	 * @return This sprite, for chaining
	 */
	public function loadTextureBase(input:TextureBase):FunkinSprite
	{
		var inputBitmap:FixedBitmapData = FixedBitmapData.fromTexture(input);

		return loadBitmapData(inputBitmap);
	}

	/**
	 * Load an animated texture (Sparrow atlas spritesheet) as the sprite's texture.
	 * @param key The key of the texture to load.
	 * @return This sprite, for chaining.
	 */
	public function loadSparrow(key:String):FunkinSprite
	{
		var graphicKey:String = Paths.image(key);
		if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

		this.frames = Paths.getSparrowAtlas(key);

		return this;
	}

	/**
	 * Load an animated texture (Packer atlas spritesheet) as the sprite's texture.
	 * @param key The key of the texture to load.
	 * @return This sprite, for chaining.
	 */
	public function loadPacker(key:String):FunkinSprite
	{
		var graphicKey:String = Paths.image(key);
		if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

		this.frames = Paths.getPackerAtlas(key);

		return this;
	}

	/**
	 * Determine whether the texture with the given key is cached.
	 * @param key The key of the texture to check.
	 * @return Whether the texture is cached.
	 */
	public static function isTextureCached(key:String):Bool
	{
		return FlxG.bitmap.get(key) != null;
	}

	/**
	 * Ensure the texture with the given key is cached.
	 * @param key The key of the texture to cache.
	 */
	/*public static function cacheTexture(key:String):Void
	{
		// We don't want to cache the same texture twice.
		if (currentCachedTextures.exists(key)) return;

		if (previousCachedTextures.exists(key))
		{
			// Move the graphic from the previous cache to the current cache.
			var graphic = previousCachedTextures.get(key);
			previousCachedTextures.remove(key);
			currentCachedTextures.set(key, graphic);
			return;
		}

		var bitmap = BitmapData.fromFile(key);
		if (bitmap == null)
		{
			trace('oh no its returning null NOOOO ($key)');
			return;
		}

		if (bitmap.image != null)
		@:privateAccess
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		final graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentCachedTextures.set(key, graph);
	}*/

	public static function cacheTexture(key:String):Void
	{
		// We don't want to cache the same texture twice.
		if (currentCachedTextures.exists(key)) return;

		if (previousCachedTextures.exists(key))
		{
			// Move the graphic from the previous cache to the current cache.
			var graphic = previousCachedTextures.get(key);
			previousCachedTextures.remove(key);
			currentCachedTextures.set(key, graphic);
			return;
		}

		// Else, texture is currently uncached.
		var graphic:FlxGraphic = FlxGraphic.fromAssetKey(key, false, null, true);
		if (graphic == null)
		{
			FlxG.log.warn('Failed to cache graphic: $key');
		}
		else
		{
			trace('Successfully cached graphic: $key');
			graphic.persist = true;
			currentCachedTextures.set(key, graphic);
		}
	}

	public static function cacheSparrow(key:String):Void
	{
		cacheTexture(Paths.image(key));
	}

	public static function cachePacker(key:String):Void
	{
		cacheTexture(Paths.image(key));
	}

	/**
	 * Call this, then `cacheTexture` to keep the textures we still need, then `purgeCache` to remove the textures that we won't be using anymore.
	 */
	public static function preparePurgeCache():Void
	{
		previousCachedTextures = currentCachedTextures;
		currentCachedTextures = [];
	}

	public static function purgeCache():Void
	{
		// Everything that is in previousCachedTextures but not in currentCachedTextures should be destroyed.
		for (graphicKey in previousCachedTextures.keys())
		{
			var graphic = previousCachedTextures.get(graphicKey);
			if (graphic == null) continue;

			/*@:privateAccess {
			if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
				graphic.bitmap.__texture.dispose();
			}*/

			FlxG.bitmap.remove(graphic);
			graphic.destroy();
			previousCachedTextures.remove(graphicKey);
		}
	}

	static function isGraphicCached(graphic:FlxGraphic):Bool
	{
		if (graphic == null) return false;
		var result = FlxG.bitmap.get(graphic.key);
		if (result == null) return false;
		if (result != graphic)
		{
			FlxG.log.warn('Cached graphic does not match original: ${graphic.key}');
			return false;
		}
		return true;
	}

	/**
	 * Acts similarly to `makeGraphic`, but with improved memory usage,
	 * at the expense of not being able to paint onto the resulting sprite.
	 *
	 * @param width The target width of the sprite.
	 * @param height The target height of the sprite.
	 * @param color The color to fill the sprite with.
	 * @return This sprite, for chaining.
	 */
	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
	{
		// Create a tiny solid color graphic and scale it up to the desired size.
		var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
		frames = graphic.imageFrame;
		scale.set(width / 2.0, height / 2.0);
		updateHitbox();

		return this;
	}

	/**
	 * Ensure scale is applied when cloning a sprite.R
	 * The default `clone()` method acts kinda weird TBH.
	 * @return A clone of this sprite.
	 */
	public override function clone():FunkinSprite
	{
		var result = new FunkinSprite(this.x, this.y);
		result.frames = this.frames;
		result.scale.set(this.scale.x, this.scale.y);
		result.updateHitbox();

		return result;
	}

	public override function destroy():Void
	{
		frameOffset = flixel.util.FlxDestroyUtil.put(frameOffset);
		frames = null;
		// Cancel all tweens so they don't continue to run on a destroyed sprite.
		// This prevents crashes.
		FlxTween.cancelTweensOf(this);
		super.destroy();
	}
}
