package funkin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import funkin.graphics.FunkinSprite;

import funkin.ui.title.TitleState;

#if hxvlc
import hxvlc.flixel.*;
import hxvlc.openfl.*;
#end
class IntroState extends funkin.ui.MusicBeatState
{
	override function create() {
		super.create();

		#if hxvlc
		if (Main.config?.allowIntro) {
			final _cachedAutoPause = FlxG.autoPause;
			Paths.sound('introSound');
			FunkinSprite.cacheTexture("introHeads"); //Paths.image('introHeads');
			FlxG.autoPause = true;
			var video:FlxVideo = new FlxVideo(false);
			//trace(Paths.videos("gameIntro"));
			var pathTo:String = "assets/videos/videos/gameIntro.mp4"; 
			trace(sys.FileSystem.exists(pathTo));
			video.onEndReached.add(() -> {
				FlxG.autoPause = _cachedAutoPause;
				video.dispose();
				new FlxTimer().start(.5, (_) -> startHeads());
			}, true);

			if (video.load(pathTo)) //if (video.load(Paths.videos("gameIntro"))) {  //if (video.load("assets/videos/videos/HaxeLogoJumscare.mp4")) { 
			{
				trace('We got intro vid');
				new FlxTimer().start(.15, (_) -> video.play());
				FlxG.autoPause = false;
			} else {
				trace('Theres no intro video ;(');
				new FlxTimer().start(.5, (_) -> startHeads());
			}
		} else #end FlxG.switchState(() -> new TitleState());
	}

	function startHeads() {
		final headIntroSprite = FunkinSprite.create("introHeads");
		headIntroSprite.antialiasing = true;
		headIntroSprite.screenCenter();
		add(headIntroSprite);

		final introSound = new FlxSound().loadEmbedded(Paths.sound("introSound"), false, true, () ->  {
			remove(headIntroSprite, true);
			new FlxTimer().start(.15, (_) -> FlxG.switchState(() -> new TitleState()));
		});
		FlxG.sound.list.add(introSound.play());
	}
}