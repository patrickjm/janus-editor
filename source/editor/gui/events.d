/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.events;

import std.signals;

//template Tuple(E...)
//{
//    alias E Tuple;
//}

class GuiEvent(T...){
	mixin Signal!(T);       

	void clear()
	{
		foreach(slot; _list)
			disconnect(slot);
		_list = [];
	}
    void broadcast(T args){ 
        emit(args);
    }       
    void opAddAssign(slot_t slot){
        connect(slot);
		_list ~= slot;
    }
    void opSubAssign(slot_t slot) {
        disconnect(slot);
		import std.algorithm : strip;
		_list.strip(slot);
    }
protected:
	slot_t[] _list;
}