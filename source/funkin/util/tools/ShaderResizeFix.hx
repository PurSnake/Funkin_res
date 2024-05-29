package funkin.util.tools;

class ShaderResizeFix { // this is work or not?
	public static var doResizeFix:Bool = true;

	public static function init() {
		FlxG.signals.gameResized.add((w:Int, h:Int) -> {fixSpritesShadersSizes();});
		FlxG.signals.postStateSwitch.add(fixSpritesShadersSizes);
	}

	public static function fixSpritesShadersSizes() {
		if (doResizeFix){
			fixSpriteShaderSize(FlxG.game);
	
			for (cam in FlxG.cameras.list) 
				if (cam != null && (cam.filters != null || cam.filters != []))
					fixSpriteShaderSize(cam.flashSprite);
		}
	}
	
	@:access(openfl.display.DisplayObject)
	public static function fixSpriteShaderSize(sprite:openfl.display.DisplayObject) // Shout out to Ne_Eo for bringing this to my attention
		if (sprite != null){
			sprite.__cleanup();
			function dispose(bitmapData:openfl.display.BitmapData){
				if (bitmapData != null){
					bitmapData.dispose();
					bitmapData = null;
				}
			}
			dispose(sprite.__cacheBitmapData);
			dispose(sprite.__cacheBitmapData2);
			dispose(sprite.__cacheBitmapData3);
		}
}