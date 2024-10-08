package funkin.play.character;

import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.play.character.CharacterData.CharacterRenderType;

/**
 * A SparrowCharacter is a Character which is rendered by
 * displaying an animation derived from a SparrowV2 atlas spritesheet file.
 *
 * BaseCharacter has game logic, SparrowCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class SparrowCharacter extends BaseCharacter
{
	public function new(id:String)
	{
		super(id, CharacterRenderType.Sparrow);
	}

	override function onCreate(event:ScriptEvent):Void
	{
		trace('Creating Sparrow character: ' + this.characterId);

		loadSpritesheet();
		loadAnimations();

		super.onCreate(event);
	}

	function loadSpritesheet()
	{
		trace('[SPARROWCHAR] Loading spritesheet ${_data.assetPath} for ${characterId}');

		var tex:FlxFramesCollection = Paths.getSparrowAtlas(_data.assetPath, "shared");
		if (tex == null)
		{
			trace('Could not load Sparrow sprite: ${_data.assetPath}');
			return;
		}

		this.frames = tex;
		this.isPixel = _data.isPixel;
		this.antialiasing = !_data.isPixel;

		this.setScale(_data.scale);
	}

	function loadAnimations()
	{
		trace('[SPARROWCHAR] Loading ${_data.animations.length} animations for ${characterId}');

		FlxAnimationUtil.addAtlasAnimations(this, _data.animations);

		for (anim in _data.animations)
			anim.offsets == null ? setAnimationOffsets(anim.name, 0, 0) : setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);

		var animNames = this.animation.getNameList();
		trace('[SPARROWCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
	}
}
