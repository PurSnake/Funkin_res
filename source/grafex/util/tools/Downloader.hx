package grafex.util.tools;

import sys.io.*;

import openfl.net.*;
import openfl.events.*;
import openfl.utils.*;
import openfl.utils.ByteArray;

class Downloader {
	static inline var SECONDS:String = 'S';
	static inline var BYTES:String = 'B';
	static inline var KILO:String = 'K';
	static inline var MEGA:String = 'M';

	static inline function getTime() {
		return haxe.Timer.stamp();
	}
	
	public static function test() {
		var file = Downloader.download('https://gist.githubusercontent.com/luiscoms/f3703016ee218fd5283b/raw/1ef9722e60809fab2a4991b2e4cee8f13a6ab193/trollface', "assets/file.txt"); //url | path
		
		file.progress = function () {
			Sys.println(file.status.percent);
		}
		file.complete = function () {
			trace(file.status.total_time);
		}
	}

	public static function download(url:String, ?path:String = null) {
		return new Downloader(url, path);
	}

	public var open:Dynamic;
	public var progress:Dynamic;
	public var complete:Dynamic;
	public var error:Dynamic;

	public var data:ByteArray;

	public var status:DownloadStatus = {
		downloaded_bytes: 'null',
		passed_time: 'null',

		download_speed: 'null',
		remain_time: 'null',

		total_bytes: 'null',
		total_time: 'null',

		percent: 'null'
	};

	public function cancel():Void {
		if (__urlLoader != null) {
			__urlLoader.close();
			status = null;
		}
	}

	@:noCompletion private function convertData(bytes:Int, total:Int) {
		function convertBytes(b:Float) {
			if (b < 1024) return b + ' ' + BYTES;
			if (b < 1024*1024) return b/1024 + ' ' + KILO + BYTES;
			return b/(1024*1024) + ' ' + MEGA + BYTES;
		}

		var time:Float = getTime();

		var deltaB:Int = bytes - __lastBytes;
		var deltaT:Float = time - __lastTime;

		var __lasts:Float = time - __begin;

		__lastBytes = bytes;
		__lastTime = time;

		var timeR:Float = __lasts * total / bytes - __lasts;
		if (timeR < 0) timeR = 0;

		return {
			downloaded: convertBytes(bytes),
			total: convertBytes(total),
			speed: convertBytes(deltaB / deltaT) + '/' + SECONDS,
			pass: __lasts + ' ' + SECONDS,
			remain: timeR + ' ' + SECONDS,
			percent: bytes/total + '%'
		}
	}

	@:noCompletion private var __begin:Float = 0;

	@:noCompletion private var __lastBytes:Int = 0;
	@:noCompletion private var __lastTime:Float = 0;

	@:noCompletion private var __data:ByteArray;
	@:noCompletion private var __path:String;
	@:noCompletion private var __urlLoader:URLLoader;

	@:noCompletion private function new(url:String, path:String) {
		var request = new URLRequest(url);
		
		__urlLoader = new URLLoader();
		__urlLoader.addEventListener(Event.COMPLETE, urlLoader_onComplete);
		__urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_onIOError);
		__urlLoader.addEventListener(ProgressEvent.PROGRESS, urlLoader_onProgress);
		__urlLoader.load(request);

		__begin = getTime();
		__lastTime = __begin;

		__path = path;
	}

	@:noCompletion private function urlLoader_onComplete(event:Event) {
		status.total_time = getTime() - __begin + ' ' + SECONDS;
		status.percent = '1%';

		if (complete != null) complete();

		if ((__urlLoader.data is #if desktop ByteArrayData #else ByteArray #end)) {
			__data = __urlLoader.data;
		} else {
			__data = new ByteArray();
			__data.writeUTFBytes(Std.string(__urlLoader.data));
		}

		if (__path != null) {
			File.saveBytes(__path, __data);
			__urlLoader.close();
		}

	}
	
	@:noCompletion private function urlLoader_onIOError(event:IOErrorEvent):Void {
		if (error != null) error(event);
		cancel();
	}
	
	@:noCompletion private function urlLoader_onProgress(event:ProgressEvent):Void {
		var newData = convertData(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
		status.downloaded_bytes = newData.downloaded;
		status.total_bytes = newData.total;
		status.remain_time = newData.remain;
		status.download_speed = newData.speed;
		status.passed_time = newData.pass;
		status.percent = newData.percent;

		if (progress != null) progress();
	}
}

typedef DownloadStatus = {
	var downloaded_bytes:String;
	var passed_time:String;

	var download_speed:String;
	var remain_time:String;

	var total_bytes:String;
	var total_time:String;

	var percent:String;
}