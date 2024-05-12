package funkin.ui.story;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.util.MathUtil;

class LevelTitle extends FlxSpriteGroup
{
	static final LOCK_PAD:Int = 4;

	public final level:Level;

	public var targetY:Float;
	public var isFlashing:Bool = false;
	var time:Float = 0;

	var title:FlxSprite;
	var lock:FlxSprite;

	public function new(x:Int, y:Int, level:Level)
	{
		super(x, y);

		this.level = level;

		if (this.level == null) throw "Level cannot be null!";

		buildLevelTitle();
		buildLevelLock();
	}

	override function get_width():Float
	{
		if (length == 0) return 0;

		return lock.visible ? (title.width + lock.width + LOCK_PAD) : title.width;
	}

	public override function update(elapsed:Float):Void
	{
		this.y = MathUtil.coolLerp(y, targetY, 0.17);

		if (isFlashing) {
			time += elapsed;
			color = (time % 0.1 > 0.05) ? FlxColor.WHITE : 0xFF33ffff;
		}
	}

	public function showLock():Void
	{
		lock.visible = true;
		this.x -= (lock.width + LOCK_PAD) / 2;
	}

	public function hideLock():Void
	{
		lock.visible = false;
		this.x += (lock.width + LOCK_PAD) / 2;
	}

	function buildLevelTitle():Void
	{
		title = level.buildTitleGraphic();
		add(title);
	}

	function buildLevelLock():Void
	{
		lock = new FlxSprite(0, 0).loadGraphic(Paths.image('storymenu/ui/lock'));
		lock.x = title.x + title.width + LOCK_PAD;
		lock.visible = false;
		add(lock);
	}
}
