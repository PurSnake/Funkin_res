package funkin.play.stage;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.play.stage.StageProp;

typedef AnimationFrameCallback = String->Int->Int->Void;
typedef AnimationFinishedCallback = String->Void;

/**
 * A Bopper is a stage prop which plays a dance animation.
 * Y'know, a thingie that bops. A bopper.
 */
class Bopper extends StageProp implements IPlayStateScriptedClass
{
	/**
	 * The bopper plays the dance animation once every `danceEvery` beats.
	 * Set to 0 to disable idle animation.
	 */
	public var danceEvery(default, set):Int = 1;

	/**
	 * Whether the bopper should dance left and right.
	 * - If true, alternate playing `danceLeft` and `danceRight`.
	 * - If false, play `idle` every time.
	 *
	 * You can manually set this value, or you can leave it as `null` to determine it automatically.
	 */
	public var shouldAlternate:Null<Bool> = null;

	/**
	 * Offset the character's sprite by this much when playing each animation.
	 */
	public var animationOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	/**
	 * Add a suffix to the `idle` animation (or `danceLeft` and `danceRight` animations)
	 * that this bopper will play.
	 */
	public var idleSuffix(default, set):String = '';

	/**
	 * If this bopper is rendered with pixel art,
	 * disable anti-aliasing and render at 6x scale.
	 */
	public var isPixel(default, set):Bool = false;

	function set_isPixel(value:Bool):Bool
	{
		if (isPixel == value) return value;
		return isPixel = value;
	}

	/**
	 * Whether this bopper should bop every beat. By default it's true, but when used
	 * for characters/players, it should be false so it doesn't cut off their animations!!!!!
	 */
	public var shouldBop(default, set):Bool = true;

	function set_danceEvery(value:Int):Int
	{
		this.danceEvery = value;
		this.update_danceEvery();
		return value;
	}

	function set_idleSuffix(value:String):String
	{
		this.idleSuffix = value;
		this.update_danceEvery();
		this.dance();
		return value;
	}

	function set_shouldBop(value:Bool):Bool
	{
		this.shouldBop = value;
		this.update_danceEvery();
		return value;
	}

	var _realDanceEvery:Int = 1;

	/**
	 * The offset of the character relative to the position specified by the stage.
	 */
	public var globalOffsets(default, set):Array<Float> = [0, 0];

	function set_globalOffsets(value:Array<Float>):Array<Float>
	{
		this.offset.x = value[0];
		this.offset.y = value[1];
		return globalOffsets = value;
	}

	@:allow(funkin.ui.debug.anim.DebugBoundingState)
	var animOffsets(default, set):Array<Float> = [0, 0];

	function set_animOffsets(value:Array<Float>):Array<Float>
	{
		if (animOffsets == null) animOffsets = [0, 0];
		if ((animOffsets[0] == value[0]) && (animOffsets[1] == value[1])) return value;

		frameOffset.set(value[0], value[1]);

		return animOffsets = value;
	}

	public function resetPosition()
	{
		this.offset.x = globalOffsets[0];
		this.offset.y = globalOffsets[1];
	}

	/**
	 * Whether to play `danceRight` next iteration.
	 * Only used when `shouldAlternate` is true.
	 */
	var hasDanced:Bool = false;

	public function new(danceEvery:Int = 1)
	{
		super();
		this.danceEvery = danceEvery;

		if (this.animation != null)
		{
			this.animation.callback = this.onAnimationFrame;
			this.animation.finishCallback = this.onAnimationFinished;
		}
		update_danceEvery();
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);
		update_danceEvery();
	}

	/**
	 * Called when an animation finishes.
	 * @param name The name of the animation that just finished.
	 */
	function onAnimationFinished(name:String)
	{
		// TODO: Can we make a system of like, animation priority or something?
		if (!canPlayOtherAnims)
			canPlayOtherAnims = true;
	}

	/**
	 * Called when the current animation's frame changes.
	 * @param name The name of the current animation.
	 * @param frameNumber The number of the current frame.
	 * @param frameIndex The index of the current frame.
	 *
	 * For example, if an animation was defined as having the indexes [3, 0, 1, 2],
	 * then the first callback would have frameNumber = 0 and frameIndex = 3.
	 */
	function onAnimationFrame(name:String = "", frameNumber:Int = -1, frameIndex:Int = -1)
	{
		// Do nothing by default.
		// This can be overridden by, for example, scripted characters,
		// or by calling `animationFrame.add()`.

		// Try not to do anything expensive here, it runs many times a second.
	}

	function update_shouldAlternate():Void
	{
		this.shouldAlternate = hasAnimation('danceLeft');
	}

 	/**
	 * Called when the BPM of the song changes.
	 */
	public function onBpmChange(event:SongTimeScriptEvent)
	{
		update_danceEvery();
	}

	/**
	 * Called once every beat of the song.
	 */
	public function onBeatHit(event:SongTimeScriptEvent):Void
	{
		if ((_realDanceEvery > 0 && event.beat % _realDanceEvery == 0))
			dance(shouldBop);
	}

	function update_danceEvery()
	{
		if (danceEvery <= 0 || shouldAlternate || this.animation.getByName('idle$idleSuffix') == null || shouldBop)
		{
			_realDanceEvery = danceEvery;
			return;
		}

		var daIdle = this.animation.getByName('idle$idleSuffix');
		var calc:Float = (daIdle.numFrames / daIdle.frameRate) / (Conductor.instance.beatLengthMs / 1000);
		var danceEveryNumBeats:Int = Math.ceil(calc);
		var numeratorTweak:Int = (Conductor.instance.timeSignatureNumerator % 2 == 0) ? 2 : 3;
		if (danceEveryNumBeats > numeratorTweak)
		{
			while (danceEveryNumBeats % numeratorTweak != 0)
				danceEveryNumBeats++;
		}
		_realDanceEvery = Std.int(Math.max(danceEvery, danceEveryNumBeats));
	}

	/**
	 * Called every `danceEvery` beats of the song.
	 */
	public function dance(forceRestart:Bool = false):Void
	{
		if (this.animation == null)
			return;

		if (shouldAlternate == null)
			update_shouldAlternate();

		if (shouldAlternate)
		{
			hasDanced ? playAnimation('danceRight$idleSuffix', forceRestart) : playAnimation('danceLeft$idleSuffix', forceRestart);
			hasDanced = !hasDanced;
		}
		else
			playAnimation('idle$idleSuffix', forceRestart);
	}

	public function hasAnimation(id:String):Bool
	{
		if (this.animation == null) return false;

		return this.animation.getByName(id) != null;
	}

	override function update(elapsed:Float)
	{
		if(animation != null && animation.curAnim != null)
			if(isAnimationFinished() && hasAnimation(getCurrentAnimation() + '-loop'))
				playAnimation(getCurrentAnimation() + '-loop');

		super.update(elapsed);
	}


	/**
	 * Ensure that a given animation exists before playing it.
	 * Will gracefully check for name, then name with stripped suffixes, then fail to play.
	 * @param name The animation name to attempt to correct.
	 * @param fallback Instead of failing to play, try to play this animation instead.
	 */
	function correctAnimationName(name:String, ?fallback:String = 'idle'):String
	{
		// If the animation exists, we're good.
		if (hasAnimation(name)) return name;

		var idx = name.lastIndexOf('-');
		if (idx != -1)
		{
			var correctName = name.substring(0, name.lastIndexOf('-'));
			FlxG.log.notice('Bopper tried to play animation "$name" that does not exist, stripping suffixes...');
			return correctAnimationName(name.substr(0, idx), fallback);
		}
		else if (fallback != null && fallback != name)
		{
			FlxG.log.warn('Bopper tried to play animation "$name" that does not exist, fallback to $fallback');
			return correctAnimationName(fallback);
		}
		else
		{
			FlxG.log.error('Bopper tried to play animation "$name" that does not exist! This is bad!');
			return null;
		}
	}

	public var canPlayOtherAnims:Bool = true;

	/**
	 * @param name The name of the animation to play.
	 * @param restart Whether to restart the animation if it is already playing.
	 * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
	 * @param reversed If true, play the animation backwards, from the last frame to the first.
	 */
	public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
	{
		if (!canPlayOtherAnims && !ignoreOther) return;

		var correctName = correctAnimationName(name);
		if (correctName == null) return;

		this.animation.play(correctName, restart, reversed, 0);

		if (ignoreOther)
			canPlayOtherAnims = false;

		applyAnimationOffsets(correctName);
	}

	var forceAnimationTimer:FlxTimer = new FlxTimer();

	/**
	 * @param name The animation to play.
	 * @param duration The duration in which other (non-forced) animations will be skipped, in seconds (NOT MILLISECONDS).
	 */
	public function forceAnimationForDuration(name:String, duration:Float):Void
	{
		// TODO: Might be nice to rework this function, maybe have a numbered priority system?

		if (this.animation == null) return;

		var correctName = correctAnimationName(name);
		if (correctName == null) return;

		this.animation.play(correctName, false, false);
		applyAnimationOffsets(correctName);

		canPlayOtherAnims = false;
		forceAnimationTimer.start(duration, (timer) -> {
			canPlayOtherAnims = true;
		}, 1);
	}

	function applyAnimationOffsets(name:String):Void
	{
		var offsets = animationOffsets.get(name);
		if (offsets != null && !(offsets[0] == 0 && offsets[1] == 0))
			this.animOffsets = [offsets[0], offsets[1]];
		else
			this.animOffsets = [0, 0];
	}

	public function isAnimationFinished():Bool
	{
		return this.animation.finished;
	}

	public function setAnimationOffsets(name:String, xOffset:Float, yOffset:Float):Void
	{
		animationOffsets.set(name, [xOffset, yOffset]);
	}

	/**
	 * Returns the name of the animation that is currently playing.
	 * If no animation is playing (usually this means the character is BROKEN!),
	 *	 returns an empty string to prevent NPEs.
	 */
	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null) return "";
		return this.animation.curAnim.name;
	}

	override function destroy():Void
	{
		super.destroy();
	}

	public function onPause(event:PauseScriptEvent) {}

	public function onResume(event:ScriptEvent) {}

	public function onSongStart(event:ScriptEvent) {}

	public function onSongEnd(event:ScriptEvent) {}

	public function onGameOver(event:ScriptEvent) {}

	public function onGameOverLoop(event:GameOverLoopScriptEvent) {}

	public function onNoteIncoming(event:NoteScriptEvent) {}

	public function onNoteHit(event:HitNoteScriptEvent) {}

	public function onNoteMiss(event:NoteScriptEvent) {}

	public function onSongEvent(event:SongEventScriptEvent) {}

	public function onNoteGhostMiss(event:GhostMissNoteScriptEvent) {}

	public function onStepHit(event:SongTimeScriptEvent) {}

	public function onCountdownStart(event:CountdownScriptEvent) {}

	public function onCountdownStep(event:CountdownScriptEvent) {}

	public function onCountdownEnd(event:CountdownScriptEvent) {}

	public function onSongLoaded(event:SongLoadScriptEvent) {}

	public function onSongRetry(event:ScriptEvent) {}
}
