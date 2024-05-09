package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * Handles volume control in a way that is compatible with alternate control schemes.
 */
class VolumePlugin extends FlxBasic
{
	public function new()
	{
		super();
	}

	public static function initialize()
	{
		FlxG.plugins.addPlugin(new VolumePlugin());
	}

	private var _changeVolumeHoldTime:Float = 0;
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var isHaxeUIFocused:Bool = haxe.ui.focus.FocusManager.instance?.focus != null;

		if (!isHaxeUIFocused)
		{
			// Rebindable volume keys.
			/*
				if (PlayerSettings.player1.controls.VOLUME_MUTE) FlxG.sound.toggleMuted();
				else if (PlayerSettings.player1.controls.VOLUME_UP) FlxG.sound.changeVolume(0.1);
				else if (PlayerSettings.player1.controls.VOLUME_DOWN) FlxG.sound.changeVolume(-0.1);
			*/
			final contInst = PlayerSettings.player1.controls;

			if (contInst.VOLUME_MUTE) FlxG.sound.toggleMuted();
			else if (contInst.VOLUME_UP_P) FlxG.sound.changeVolume(0.05);
			else if (contInst.VOLUME_DOWN_P) FlxG.sound.changeVolume(-0.05);
		
			if (contInst.VOLUME_MUTE || contInst.VOLUME_UP_P || contInst.VOLUME_DOWN_P) _changeVolumeHoldTime = 0;
			
			if (contInst.VOLUME_UP || contInst.VOLUME_DOWN)
			{
				final checkLastHold:Int = Math.floor((_changeVolumeHoldTime - 0.35) * 10);
				_changeVolumeHoldTime += elapsed;
				final checkNewHold:Int = Math.floor((_changeVolumeHoldTime - 0.35) * 10);
				
				if(_changeVolumeHoldTime > 0.35 && checkNewHold - checkLastHold > 0)
					FlxG.sound.changeVolume((checkNewHold - checkLastHold) * (contInst.VOLUME_UP ? 1 : -1) / 20, false);
			}

		}
	}
}
