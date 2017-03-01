/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.actionargs;

import janus.editor.action;
import janus.editor.actionqueue;
import janus.engine.level;

class DraggableMovedArgs : ActionArgs
{
	import janus.editor.gui.draggable;

	public GuiDraggable[] draggable;
	public int redoX, redoY; /// location to snap back to on redo
	public int undoX, undoY; /// location to snap back to on undo

	public this(GuiDraggable p_drag)
	{
		draggable = p_drag;

		redoX = draggable.x;
		redoY = draggable.y;
		undoX = draggable.x;
		undoY = draggable.y;
		super("DraggableMovedArgs");
	}
}

class ObjectCreatedArgs : ActionArgs
{
	import janus.editor.editorobject;
	import janus.editor.gui.draggable;

	public EditorObject obj, parent;
	public GuiDraggable draggable;
	
	public this(string p_info, EditorObject p_obj)
	{
		obj = p_obj;
		super(p_info);
	}
}

class PointDrawnArgs : ActionArgs
{
	import janus.engine.level.vertex;

	public LevelVertex point;
	public LevelPolygon parent; /// only used when the first point is drawn

	public this(LevelVertex p_pt)
	{
		point = p_pt;
		import std.conv : text;
		super(text("(", point.x, ",", point.y, ")"));
	}
}
