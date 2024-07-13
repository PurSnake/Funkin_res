package funkin;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;

import haxe.PosInfos;
import haxe.io.Path;

import flash.media.Sound;

import sys.FileSystem;
import sys.io.File;

/**
 * A core class which handles determining asset paths.
 */
class Paths
{
	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var dumpExclusions:Array<String> = ['assets/music/freakyMenu/freakyMenu.${Constants.EXT_SOUND}'];

	public static function clearStoredMemory() {
		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		//#if !html5 openfl.Assets.cache.clear("songs"); #end
	}


	static var currentLevel:Null<String> = null;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = name.toLowerCase();
	}

	public static function stripLibrary(path:String):String
	{
		var parts:Array<String> = path.split(':');
		if (parts.length < 2) return path;
		return parts[1];
	}

	public static function getLibrary(path:String):String
	{
		var parts:Array<String> = path.split(':');
		if (parts.length < 2) return 'preload';
		return parts[0];
	}

	static function getPath(file:String, type:AssetType, library:Null<String>):String
	{
		file = file.replace("\\", "/");
		while(file.contains("//")) {
			file = file.replace("//", "/");
		}

		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		var levelPath:String = getLibraryPathForce(file, 'shared');
		if (OpenFlAssets.exists(levelPath, type)) return levelPath;

		return getPreloadPath(file);
	}

	public static function getLibraryPath(file:String, library = 'preload'):String
	{
		return if (library == 'preload' || library == 'default') getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	static inline function getLibraryPathForce(file:String, library:String):String
	{
		return '$library:assets/$library/$file';
	}

	static inline function getPreloadPath(file:String):String
	{
		return 'assets/$file';
	}

	public static function file(file:String, type:AssetType = TEXT, ?library:String):String
	{
		return getPath(file, type, library);
	}

	public static function animateAtlas(path:String, ?library:String):String
	{
		return getLibraryPath('images/$path', library);
	}

	public static function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	public static function frag(key:String, ?library:String):String
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	public static function vert(key:String, ?library:String):String
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	public static function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	public static function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	public static function soundStr(key:String, ?library:String):String
	{
		return getPath('sounds/$key.${Constants.EXT_SOUND}', SOUND, library);
	}

	public static function sound(key:String, ?library:String):Sound
	{
		return returnSound('sounds/$key.${Constants.EXT_SOUND}', SOUND, library);
	}

	public static function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	public static function musicStr(key:String, ?library:String):String
	{
		return getPath('music/$key.${Constants.EXT_SOUND}', MUSIC, library);
	}

	public static function music(key:String, ?library:String):Sound
	{
		return returnSound('music/$key.${Constants.EXT_SOUND}', MUSIC, library);
	}

	public static function videos(key:String, ?library:String):String
	{
		return getPath('videos/$key.${Constants.EXT_VIDEO}', BINARY, library ?? 'videos');
	}


	public static function voicesStr(song:String, ?suffix:String = ''):String
	{
		if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files
		return 'assets/songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}';
	}
	public static function voices(song:String, ?suffix:String = ''):Sound
	{
		if (suffix == null) suffix = ''; // no suffix, for a sorta backwards compatibility with older-ish voice files
		return returnSound('songs/${song.toLowerCase()}/Voices$suffix', MUSIC);
	}



	public static function instStr(song:String, ?suffix:String = '', ?withExtension:Bool = true):String
	{
		var ext:String = withExtension ? '.${Constants.EXT_SOUND}' : '';
		return 'assets/songs/${song.toLowerCase()}/Inst$suffix$ext';
	}
	/**
	 * Gets the path to an `Inst.mp3/ogg` song instrumental from songs:assets/songs/`song`/
	 * @param song name of the song to get instrumental for
	 * @param suffix any suffix to add to end of song name, used for `-erect` variants usually
	 * @param withExtension if it should return with the audio file extension `.mp3` or `.ogg`.
	 * @return String
	 */
	public static function inst(song:String, ?suffix:String = '', ?withExtension:Bool = true):Sound
	{
		return returnSound('songs/${song.toLowerCase()}/Inst$suffix', MUSIC);
	}

	public static function image(key:String, ?library:String, ?allowGPU:Bool = true):FlxGraphic
	{
		return imageGraphic(key, allowGPU, library);
	}

	public static function imageGraphic(key:String, ?allowGPU:Bool = true, ?library:String, ?unique:Bool = false, ?filePos:PosInfos):FlxGraphic
	{
		if(key.lastIndexOf('.') < 0) key += '.${Constants.EXT_IMAGE}';

		OpenFlAssets.allowGPU = (Main.GPULoadAllowed && allowGPU); // Main config AND choise
		final graphic:FlxGraphic = FlxG.bitmap.add(getPath('images/$key', IMAGE, library));
		if (graphic == null)
			trace('oh no $key returning null NOOOO');
		else
			graphic.destroyOnNoUse = false;
		OpenFlAssets.allowGPU = Main.GPULoadAllowed;
		return graphic;
	}

	public static function returnSound(key:String, ?type:AssetType = SOUND, ?lib:String)
	{
		if(key.lastIndexOf('.') < 0) key += '.${Constants.EXT_SOUND}';

		final file:String = getPath(key, type, lib);
		if(!currentTrackedSounds.exists(file))
			if(OpenFlAssets.exists(file, type))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));

		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	public static function font(key:String):String
	{
		return 'assets/fonts/$key';
	}

	public static function ui(key:String, ?library:String):String
	{
		return xml('ui/$key', library);
	}

	public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}

enum abstract PathsFunction(String)
{
	var MUSIC;
	var INST;
	var VOICES;
	var SOUND;
}
