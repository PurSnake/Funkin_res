package funkin.ui;

import openfl.display.BitmapData;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.filters.BitmapFilter;

import flixel.FlxG;
import flixel.util.FlxColor;

import flixel.text.FlxText;

// Redar13
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.Rectangle)
@:access(openfl.text._internal.TextEngine)
@:access(openfl.text.TextField)
class FlxFixedText extends FlxText
{
	public var useFilters(default, set):Bool = true;

	public var filters(default, set):Array<BitmapFilter>; // TODO: Remade styles to filters

	public var casheOldPixels:Bool = false;
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		_oldTextRect = Rectangle.__pool.get();
		_oldTextRect.setTo(0, 0, 0, FlxText.VERTICAL_GUTTER);
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		textField.removeEventListeners();
	}

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion
	var _oldTextRect:Rectangle;
 
	override function regenGraphic():Void
	{
		if (textField == null || !_regen)
			return;

		_flashRect.setEmpty();
		if (filters != null && useFilters)
		{
			for (filter in filters)
			{
				_flashRect.__expand(-filter.__leftExtension, -filter.__topExtension,
					filter.__leftExtension + filter.__rightExtension,
					filter.__topExtension + filter.__bottomExtension);
			}
			_flashRect.x *= 1.5;
			_flashRect.y *= 1.5;
			_flashRect.width *= 1.5;
			_flashRect.height *= 1.5;
		}
		final filterExtraWidth:Int = Math.round(_flashRect.width);
		final filterExtraHeight:Int = Math.round(_flashRect.height);
		
		final newHeight:Int = Math.ceil(Math.ceil(_autoHeight ? textField.textHeight + FlxText.VERTICAL_GUTTER : textField.height));

		_flashRect.setTo(_flashRect.x, _flashRect.y,
			textField.width + borderSize * 5 + filterExtraWidth,
			((textField.textHeight == 0 ? _oldTextRect.height : newHeight) + filterExtraHeight)
		);
		
		if (!_flashRect.equals(_oldTextRect))
		{
			_oldTextRect.copyFrom(_flashRect);
			// Need to generate a new buffer to store the text graphic
			final key:String = FlxG.bitmap.getUniqueKey("text");
			if (!casheOldPixels)
			{
				FlxG.bitmap.remove(graphic);
			}
			makeGraphic(Math.round(_oldTextRect.width - _oldTextRect.x * 3), Math.round(_oldTextRect.height - _oldTextRect.y * 3), FlxColor.TRANSPARENT, false, key);
			frame.offset.set(_oldTextRect.x, _oldTextRect.y);

			if (_hasBorderAlpha) _borderPixels = graphic.bitmap.clone();
			frameWidth -= filterExtraWidth - Math.round(_oldTextRect.x);
			frameHeight -= filterExtraHeight - Math.round(_oldTextRect.y);
			width = frameWidth;
			height = frameHeight;
			
			if (_autoHeight)
				textField.height = newHeight;

			_halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null && textField.text.length > 0)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();
			_matrix.translate(-_oldTextRect.x, -_oldTextRect.y);

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
	
	override function applyBorderStyle():Void
	{
		var iterations:Int = Std.int(borderSize * borderQuality);
		if (iterations <= 0)
		{
			iterations = 1;
		}
		var delta:Float = borderSize / iterations;

		switch (borderStyle)
		{
			case SHADOW:
				// Render a shadow beneath the text
				// (do one lower-right offset draw call)
				applyFormats(_formatAdjusted, true);

				for (i in 0...iterations)
				{
					copyTextWithOffset(delta, delta);
				}

				_matrix.translate(-shadowOffset.x * borderSize, -shadowOffset.y * borderSize);

			case OUTLINE:
				// Render an outline around the text
				// (do 8 offset draw calls)
				applyFormats(_formatAdjusted, true);

				var curDelta:Float = delta;
				for (i in 0...iterations)
				{
					copyTextWithOffset(-curDelta, -curDelta); // upper-left
					copyTextWithOffset(curDelta, 0); // upper-middle
					copyTextWithOffset(curDelta, 0); // upper-right
					copyTextWithOffset(0, curDelta); // middle-right
					copyTextWithOffset(0, curDelta); // lower-right
					copyTextWithOffset(-curDelta, 0); // lower-middle
					copyTextWithOffset(-curDelta, 0); // lower-left
					copyTextWithOffset(0, -curDelta); // lower-left

					_matrix.translate(curDelta, 0); // return to center
					curDelta += delta;
				}

			case OUTLINE_FAST:
				// Render an outline around the text
				// (do 4 diagonal offset draw calls)
				// (this method might not work with certain narrow fonts)
				applyFormats(_formatAdjusted, true);

				var curDelta:Float = delta;
				for (i in 0...iterations)
				{
					copyTextWithOffset(-curDelta, -curDelta); // upper-left
					copyTextWithOffset(curDelta * 2, 0); // upper-right
					copyTextWithOffset(0, curDelta * 2); // lower-right
					copyTextWithOffset(-curDelta * 2, 0); // lower-left

					_matrix.translate(curDelta, -curDelta); // return to center
					curDelta += delta;
				}

			case NONE:
		}
	}

	public override function destroy()
	{
		if (_oldTextRect != null)
			Rectangle.__pool.release(_oldTextRect);
		_oldTextRect = null;
		super.destroy();
	}

	public override function update(elapsed:Float)
	{
		if (!_regen && filters != null)
		{
			for (filter in filters)
			{
				if (filter.__renderDirty)
				{
					_regen = true;
					break;
				}
			}
		}
		super.update(elapsed);
	}

	function set_filters(newFilters:Array<BitmapFilter>):Array<BitmapFilter>
	{
		_regen = true;
		filters = newFilters;
		return textField == null || !useFilters ? null : textField.filters = filters;
	}
	function set_useFilters(a:Bool):Bool
	{
		if (useFilters != a)
		{
			_regen = true;
			textField.filters = a ? filters : null;
		}
		return useFilters = a;
	}
}