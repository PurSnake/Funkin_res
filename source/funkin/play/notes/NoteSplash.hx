package funkin.play.notes;

import funkin.play.notes.NoteDirection;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	static final ALPHA:Float = 0.6;
	static final FRAMERATE_DEFAULT:Int = 24;
	static final FRAMERATE_VARIANCE:Int = 2;

	static final ANGLE_VARIANCE:Int = 15;

	static var frameCollection:FlxFramesCollection;

	final noteStyle:NoteStyle;

	public function new(noteStyle:NoteStyle)
	{
		super(0, 0);

		this.noteStyle = noteStyle;
		this.noteStyle.buildNoteSplashSprite(this);

		this.alpha = ALPHA;
		this.animation.finishCallback = this.onAnimationFinished;
	}

	public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
	{
		this.animation.play(name, force, reversed, startFrame);
	}

	public dynamic function play(direction:NoteDirection, variant:Int = null):Void
	{
		if (variant == null) variant = FlxG.random.int(1, 2);

		switch (direction)
		{
			case NoteDirection.LEFT:
				this.playAnimation('splash${variant}Left');
			case NoteDirection.DOWN:
				this.playAnimation('splash${variant}Down');
			case NoteDirection.UP:
				this.playAnimation('splash${variant}Up');
			case NoteDirection.RIGHT:
				this.playAnimation('splash${variant}Right');
		}

		if (animation.curAnim == null) return;

		// Vary the speed of the animation a bit.
		animation.curAnim.frameRate = noteStyle.getNoteSplashAnimationFrameRate(direction, variant) + FlxG.random.int(-FRAMERATE_VARIANCE, FRAMERATE_VARIANCE);

		scale.x = scale.y = noteStyle.getNoteSplashScale();
		angle = FlxG.random.int(-ANGLE_VARIANCE, ANGLE_VARIANCE);
		centerOffsets();
		var styleOffsets = noteStyle.getNoteSplashOffsets();
		setPosition(x - ((width * 0.25 / scale.x) - styleOffsets[0]), y - ((height * 0.3 / scale.y) - styleOffsets[1]));
	}

	public dynamic function onAnimationFinished(animationName:String):Void
	{
		// *lightning* *zap* *crackle*
		this.kill();
	}
}
