package flixel.graphics.tile;

import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.system.FlxAssets.FlxShader;
import flixel.math.FlxMatrix;
import openfl.geom.ColorTransform;
import openfl.display.ShaderParameter;
import openfl.Vector;

@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Graphics)
@:access(openfl.display.BitmapData)
class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem>
{
	static inline var VERTICES_PER_QUAD = #if (openfl >= "8.5.0") 4 #else 6 #end;

	public var shader:FlxShader;

	var drawByShader:Bool;

	var rects:Vector<Float>;
	var transforms:Vector<Float>;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public function new()
	{
		super();
		type = FlxDrawItemType.TILES;
		rects = new Vector<Float>();
		transforms = new Vector<Float>();
		alphas = [];
		colorOffsets = [];
		colorMultipliers = [];
	}

	override public function reset():Void
	{
		super.reset();
		drawByShader = false;
		rects.length = 0;
		transforms.length = 0;
		alphas.splice(0, alphas.length);
		if (colorMultipliers != null)
			colorMultipliers.splice(0, colorMultipliers.length);
		if (colorOffsets != null)
			colorOffsets.splice(0, colorOffsets.length);
	}

	override public function dispose():Void
	{
		super.dispose();
		drawByShader = false;
		rects = null;
		transforms = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		var rect = frame.frame;
		rects.push(rect.x);
		rects.push(rect.y);
		rects.push(rect.width);
		rects.push(rect.height);

		transforms.push(matrix.a);
		transforms.push(matrix.b);
		transforms.push(matrix.c);
		transforms.push(matrix.d);
		transforms.push(matrix.tx);
		transforms.push(matrix.ty);

		var alphaMultiplier = transform?.alphaMultiplier ?? 1.0;
		if (!drawByShader)
			drawByShader = colored || alphaMultiplier != 1.0 || graphics.bitmap.__texture != null || Type.getClass(shader) != FlxGraphicsShader;

		for (i in 0...VERTICES_PER_QUAD)
			alphas.push(alphaMultiplier);

		if (colored)
		{
			for (i in 0...VERTICES_PER_QUAD)
			{
				colorMultipliers.push(transform.redMultiplier);
				colorMultipliers.push(transform.greenMultiplier);
				colorMultipliers.push(transform.blueMultiplier);
				colorMultipliers.push(1);

				colorOffsets.push(transform.redOffset);
				colorOffsets.push(transform.greenOffset);
				colorOffsets.push(transform.blueOffset);
				colorOffsets.push(transform.alphaOffset);
			}
		}
	}

	#if !flash
	override public function render(camera:FlxCamera):Void
	{
		if (#if cpp untyped __cpp__('this->rects->_hx___array->length == 0') #else rects.length == 0 #end)
			return;
		final canvasGraphics = camera.canvas.graphics;

		inline canvasGraphics.overrideBlendMode(blend);

		if (shader == null)
		{
			shader = graphics.shader;
		}

		if (drawByShader)
		{
			final isColored = colored;
			shader.bitmap.input = graphics.bitmap;
			shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
			shader.alpha.value = alphas;
			if (isColored)
			{
				shader.colorMultiplier.value = colorMultipliers;
				shader.colorOffset.value = colorOffsets;
			}

			// setParameterValue(shader.hasTransform, true);
			setParameterValue(shader.hasColorTransform, isColored);

			inline canvasGraphics.beginShaderFill(shader);
		}
		else
		{
			if (graphics.bitmap.readable)
			{
				canvasGraphics.__commands.beginBitmapFill(graphics.bitmap, null, false, camera.antialiasing || antialiasing); // test

				// inline canvasGraphics.beginBitmapFill(graphics.bitmap, null, false, camera.antialiasing || antialiasing);
			}
			else
			{
				// begin bitmap fill doesn't work with a hardware-only bitmap
				// to avoid exceptions, delegate to beginFill()
				canvasGraphics.__commands.beginFill(0, 1.0);
			}
			canvasGraphics.__visible = true;
		}

		var tileRect = Rectangle.__pool.get();
		var tileTransform = Matrix.__pool.get();

		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;

		var ri, ti;

		for (i in 0...Math.floor(rects.length / 4))
		{
			ri = i * 4;
			if (ri < 0) continue;
			tileRect.setTo(0, 0, rects[ri + 2], rects[ri + 3]);

			if (tileRect.width <= 0 || tileRect.height <= 0)
			{
				continue;
			}

			ti = i * 6;
			tileTransform.setTo(transforms[ti], transforms[ti + 1], transforms[ti + 2], transforms[ti + 3], transforms[ti + 4], transforms[ti + 5]);

			tileRect.__transform(tileRect, tileTransform);

			if (minX > tileRect.x) minX = tileRect.x;
			if (minY > tileRect.y) minY = tileRect.y;
			if (maxX < tileRect.right) maxX = tileRect.right;
			if (maxY < tileRect.bottom) maxY = tileRect.bottom;
		}

		canvasGraphics.__inflateBounds(minX, minY);
		canvasGraphics.__inflateBounds(maxX, maxY);

		canvasGraphics.__commands.drawQuads(rects, null, transforms);

		canvasGraphics.__dirty = true;
		canvasGraphics.__visible = true;

		Rectangle.__pool.release(tileRect);
		Matrix.__pool.release(tileTransform);

		// canvasGraphics.drawQuads(rects, null, transforms);


		canvasGraphics.endFill();

		super.render(camera);
	}

	#end
}
