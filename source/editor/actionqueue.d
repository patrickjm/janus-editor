/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.actionqueue;

import janus.editor.action;

/// class that holes a queue of janus.editor.actions to be undone/redone
package class ActionQueue
{
	private Action[] _queue; /// holds actions that can be undone
	private Action[] _storage; /// holds actions that can be redone
	import std.stdio;

	/// adds the action to the undo queue. Be advised that this destroys the redo queue
	void push(Action p_action)
	{
		_queue = p_action ~ _queue;
		if (_queue.length > 100)
			_queue.length = 100;
		_storage = [];
	}
	void undo()
	{
		if (_queue.length > 0)
		{
			_queue[0].undo();
			_storage = _queue[0] ~ _storage;
			_queue = _queue[1 .. $];
		}
	}

	void redo()
	{
		if (_storage.length > 0)
		{
			_storage[0].redo();
			_queue = _storage[0] ~ _queue;
			_storage = _storage[1 .. $];
		}
	}

	/// removes any action thats info starts with p_prefix
	void purge(string p_prefix)
	{
		import std.algorithm : strip;
		import std.string : startsWith;
		_storage = _storage.strip!(a => a.info.startsWith(p_prefix));
		_queue = _queue.strip!(a => a.info.startsWith(p_prefix));
	}

	override string toString() 
	{
		import std.conv : text;
		return text("Undo Queue: ", _queue, "\nRedo Queue: ", _storage, "\n\n");
	}
}