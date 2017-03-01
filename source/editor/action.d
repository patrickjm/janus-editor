/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.action;

public import janus.editor.actionargs;
public import janus.editor.actionqueue;

/// base class for action arguments to be passed to delegates
package class ActionArgs
{
	private string _info;

	this(string p_infos) { _info = p_infos; }

	public @property string info() { return _info; }
	public @property string info(string p_info) { _info = p_info; return p_info; }

	override string toString() { return _info; }
}

/// class for undo/redo actions.
/// basically just a container for delegates.
/// T... = type of function arguments.
package class Action
{
	/// Action delegate type
	alias void delegate(ActionArgs p_args) ActionDel;
	// Action function type
	//alias void function(T) ActionFunc;

	private ActionDel _undo, _redo;
	private bool _undone = false; /// undo() and redo() can only be alternated, never repeated
	private string _info;
	private ActionArgs _dat; /// args for undo/redo functions

	this(string p_info, ActionDel p_undo, ActionDel p_redo, ActionArgs p_args)
	{
		if (p_undo is null || p_redo is null)
			throw new Exception("undo or redo arguments cannot be null!");

		_info = p_info;
		_undo = p_undo;
		_redo = p_redo;
		_dat = p_args;
	}

	@property bool undone() { return _undone; }
	@property string info() { return _info ~ _dat.toString(); }

	void undo()
	{
		if (!_undone)
		{
			_undone = true;
			_undo(_dat);
		}
		else
			throw new Exception("This action has not been (un)done: " ~ info);
	}

	void redo()
	{
		if (_undone)
		{
			_undone = false;
			_redo(_dat);
		}
		else
			throw new Exception("This Action has not been undone: " ~ info);
	}

	override string toString() 
	{
		return info;
	}
}