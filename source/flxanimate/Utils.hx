package flxanimate;

#if FLX_ANIMATE_SYS_PATHS
import sys.FileSystem;
import sys.io.File;
import openfl.display.BitmapData;
#else
import openfl.Assets;
#end

class Utils
{
	public inline static function isValidStr(path:String)
		return path != null && path != "";

	public inline static function getText(path:String)
		return #if FLX_ANIMATE_SYS_PATHS File.getContent(path)      #else Assets.getText(path) #end;

	public inline static function getBytes(path:String)
		return #if FLX_ANIMATE_SYS_PATHS File.getBytes(path)        #else Assets.getBytes(path) #end;

	public inline static function getBitmapData(path:String)
		return #if FLX_ANIMATE_SYS_PATHS BitmapData.fromFile(path)  #else Assets.getBitmapData(path) #end;

	public inline static function exists(path:String)
		return #if FLX_ANIMATE_SYS_PATHS FileSystem.exists(path)    #else Assets.exists(path) #end;
}