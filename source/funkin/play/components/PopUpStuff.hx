package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxDirection;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;

class PopUpStuff extends FlxTypedGroup<FlxSprite>
{
	public var offsets:Array<Int> = [0, 0];

	override public function new()
	{
		super();
	}

	public function displayRating(daRating:String)
	{
		if (daRating == null) daRating = "good";

		var ratingPath:String = daRating;

		if (PlayState.instance.currentStageId.startsWith('school')) ratingPath = "weeb/pixelUI/" + ratingPath + "-pixel";

		var rating:FunkinSprite = FunkinSprite.create(0, 0, ratingPath);
		rating.scrollFactor.set(.75, .75);

		rating.zIndex = 1000;
		rating.x = (FlxG.width * 0.474) + offsets[0];
		rating.y = (FlxG.camera.height * 0.45 - 60) + offsets[1];
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.angle = FlxG.random.int(-5, 5);
		rating.angularVelocity = FlxG.random.int(-5, 5);
		add(rating);

		if (PlayState.instance.currentStageId.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * Constants.PIXEL_ART_SCALE * 0.7));
			rating.antialiasing = false;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 0.65));
			rating.antialiasing = true;
		}
		rating.updateHitbox();

		rating.x -= rating.width / 2;
		rating.y -= rating.height / 2;

		rating.scale.x *= 0.85;
		rating.scale.y *= 0.85;
		FlxTween.tween(rating, {"scale.x": rating.scale.x / 0.85, "scale.y": rating.scale.y / 0.85}, Conductor.instance.beatLengthMs * 0.001 / 2, {ease: FlxEase.bounceOut});
		FlxTween.tween(rating, {alpha: 0, angle: FlxG.random.int(-8, 8)}, 0.2,
		{
			onComplete: function(tween:FlxTween) {
				remove(rating, true);
				rating.destroy();
			},
			startDelay: Conductor.instance.beatLengthMs * 0.001
		});
	}

	public function displayCombo(?combo:Int = 0):Int
	{
		if (combo == null) combo = 0;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.instance.currentStageId.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}
		var comboSpr:FunkinSprite = FunkinSprite.create(pixelShitPart1 + 'combo' + pixelShitPart2);
		comboSpr.x = (FlxG.width * 0.507) + offsets[0];
		comboSpr.y = (FlxG.camera.height * 0.44) + offsets[1];
		comboSpr.acceleration.y = FlxG.random.int(450, 600);
		comboSpr.velocity.y = -FlxG.random.int(130, 160);
		comboSpr.velocity.x = FlxG.random.int(-10, 15);
		comboSpr.angle = FlxG.random.int(-2, 2);
		comboSpr.angularVelocity = FlxG.random.int(-5, 5);
		comboSpr.scrollFactor.set(.75, .75);

		comboSpr.x -= comboSpr.width * 0.25;
		comboSpr.y -= comboSpr.height * 0.25;
		if (combo > 24) add(comboSpr);

		if (PlayState.instance.currentStageId.startsWith('school'))
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * Constants.PIXEL_ART_SCALE * 0.7));
			comboSpr.antialiasing = false;
		}
		else
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		comboSpr.updateHitbox();

		comboSpr.scale.x *= 0.9;
		comboSpr.scale.y *= 0.9;
		FlxTween.tween(comboSpr, {"scale.x": comboSpr.scale.x / 0.9, "scale.y": comboSpr.scale.y / 0.9}, Conductor.instance.beatLengthMs * 0.001 / 2, {ease: FlxEase.bounceOut});
		FlxTween.tween(comboSpr, {alpha: 0, angle: FlxG.random.int(-6, 6)}, 0.2,
		{
			onComplete: function(tween:FlxTween) {
				remove(comboSpr, true);
				comboSpr.destroy();
			},
			startDelay: Conductor.instance.beatLengthMs * 0.001
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		while (tempCombo != 0)
		{
			seperatedScore.push(tempCombo % 10);
			tempCombo = Std.int(tempCombo / 10);
		}
		while (seperatedScore.length < 3)
			seperatedScore.push(0);

		var daLoop:Int = 1;
		for (i in seperatedScore)
		{
			var numScore:FunkinSprite = FunkinSprite.create(0, comboSpr.y + 25, pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2);

			if (PlayState.instance.currentStageId.startsWith('school'))
			{
				numScore.setGraphicSize(Std.int(numScore.width * Constants.PIXEL_ART_SCALE * 0.7));
				numScore.antialiasing = false;
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * 0.45));
				numScore.antialiasing = true;
			}
			numScore.updateHitbox();

			numScore.x = comboSpr.x - (36 * daLoop); //- 90;
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y = -FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.angle = FlxG.random.int(-3, 3);
			numScore.angularVelocity = FlxG.random.int(-5, 5);
			numScore.scrollFactor.set(.75, .75);
			add(numScore);


			numScore.scale.x *= 0.95;
			numScore.scale.y *= 0.95;
			FlxTween.tween(numScore, {"scale.x": numScore.scale.x / 0.95, "scale.y": numScore.scale.y / 0.95}, Conductor.instance.beatLengthMs * 0.002 / 4, {ease: FlxEase.bounceOut});
			FlxTween.tween(numScore, {alpha: 0, angle: FlxG.random.int(-4, 4)}, 0.2,
			{
				onComplete: function(tween:FlxTween) {
					remove(numScore, true);
					numScore.destroy();
				},
				startDelay: Conductor.instance.beatLengthMs * 0.002
			});

			daLoop++;
		}
		return combo;
	}
}
