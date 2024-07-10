package funkin.ui.transition;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import funkin.modding.module.ModuleHandler;

class CustomTransition extends flixel.FlxSubState
{
	public static var colors:Array<Int> = [0x0, FlxColor.BLACK, FlxColor.BLACK];
	public static var finishCallback:Void->Void;
	public static var nextCamera:FlxCamera;
	public static var transTimeMult:Float = 1;

	public static var currentTransition:CustomTransition = null;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();
		CustomTransition.startTransition(duration, isTransIn, this);
	}

	public static dynamic function startTransition(duration:Float, isTransIn:Bool, transitionSubState:CustomTransition)
	{
		if (duration <= 0) {
			finish();	// dont bother creating shit
			return;				// actually nvmd it soflocks you lmao
		}

		if (CustomTransition.currentTransition != null && isTransIn) return; //redo for ability to skip

		CustomTransition.currentTransition = transitionSubState;

		final zoom:Float = FlxMath.bound(FlxG.camera.zoom, 0.05, 1);
		final width:Int  = Std.int(FlxG.width / zoom);
		final height:Int = Std.int(FlxG.height / zoom);
		final realColors = colors.copy();
		if (!isTransIn) realColors.reverse();

		final transGradient:FlxSprite = flixel.util.FlxGradient.createGradientFlxSprite(1, height * 2, realColors);
		transGradient.setPosition(-(width - FlxG.width) * 0.5, isTransIn ? -height : -height * 2);
		transGradient.scrollFactor.set();
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transitionSubState.add(transGradient);

		// actually uses nextCamera now WOW!!!!
		transGradient.cameras = [nextCamera ?? FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		nextCamera = null;

		FlxTween.tween(transGradient, {y: isTransIn ? height : 0}, duration * transTimeMult, {onComplete: (t:FlxTween) -> finish()});
	}

	public static dynamic function finish() 
	{
		trace("Closing transition and using custom callback");
		if(finishCallback != null) finishCallback();
		CustomTransition.currentTransition = null;
	}
}