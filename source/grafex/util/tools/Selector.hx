package grafex.util.tools;

class Selector<T> {
	public var items:Array<T> = [];
	public var currentIndex:Int;
	public var currentItem(get, set):T;
	public var lockedKeys:Array<Int> = [];

	public var enable:Bool = true;
	public var looping:Bool = true;

	public var onselect:T->Void;
	public var onchoice:T->Void;
	public var ondechoice:T->Void;

	public function new(items:Array<T>, ?onselect:T->Void, ?onchoice:T->Void, ?ondechoice:T->Void) {
		this.items = items;
		this.onselect = onselect;
		this.onchoice = onchoice;
		this.ondechoice = ondechoice;
		currentIndex = 0;
	}

	public function change(num:Int):Void {
		if (!enable) return;
		
		var lastIndex:Int = currentIndex;
		var reload:Bool = true;
		currentIndex += num;

		if (currentIndex == -1)
			currentIndex = looping ? items.length - 1 : 0;
		if (currentIndex == items.length)
			currentIndex = looping ? 0 : items.length - 1;
		
		while (lockedKeys.contains(currentIndex)) {
			if (num > 0) currentIndex++;
			else currentIndex--;

			if (looping) {
				if (currentIndex == -1)
					currentIndex = items.length - 1;
				if (currentIndex == items.length)
					currentIndex = 0;
			} else {
				currentIndex = lastIndex;
				reload = false;
				break;
			}
		}

		if (lastIndex == currentIndex && !reload) return;

		if (ondechoice != null) ondechoice(items[lastIndex]);
		if (onchoice != null) onchoice(currentItem);
	}

	public function select():Void {
		if (!enable) return;
		onselect(currentItem);
	}

	public function get_currentItem():T {
		return items[currentIndex];
	}

	public function set_currentItem(item:T):T {
		items[currentIndex] = item;
		return item;
	}
}