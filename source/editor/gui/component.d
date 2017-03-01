/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.component;

import janus.editor.settings;
import janus.editor.gui;
import janus.engine.eventprocessor;
import dsfml.system.time;
import std.algorithm;
import dsfml.graphics;

/// Base abstract GUI component.
abstract class GuiComponent : EventProcessor
{
public:

	/// Parent of this component
	GuiComponent parent = null;
	/// Text label, if this component has one
	string label = "Component";
	
	/// Standard render function. Don't override unless you know what you're doing
	void render(Time p_dt, RenderTarget p_canvas)
	{
		if (!_alive)
			return;
		{
			//static if (EditorSettings.Gui.UseRenderCaching) // Alternate code to account for render caching
			//{
			//	// Make sure we have a RenderTexture to use with the right dimensions
			//	if (_refreshFlagged)
			//	{
			//		refreshRenderCache();
			//		_refreshFlagged = false;
			//	}
			//	// Do the actual rendering
			//	if (isAlive)
			//	{
			//		if (isRenderFlagged())
			//		{
			//			backendRender(p_dt, _renderCache);
			//			_renderFlagged = false;
			//		}
					
			//		// draw the rendertexture
			//		static int[] pos;
			//		pos = globalPosition;
			//		_drawer.position = Vector2f(pos[0], pos[1]);
			//		_drawer.setTexture(_renderCache.getTexture());
			//		p_canvas.draw(_drawer);

			//		renderChildren(p_dt, p_canvas);
			//	}
			//}
			//else // Don't use render caching. Just draw every frame every time
			//{
			//	if (isAlive)
			//	{
			//		backendRender(p_dt, p_canvas);
			//		renderChildren(p_dt, p_canvas);
			//	}
			//}
		}

		renderChildren(p_dt, p_canvas);
	}
	
	/**
	* Processes the event. Remember to call/return super.
	* Returns: True if the event was handled, false if it should be passed along the chain.
	*/
	bool processEvent(const(Event) p_e)
	{
		if (!_alive)
			return false;

		foreach(child; _children)
			if(child.isAlive && child.processEvent(p_e))
				return true;

		return false;
	}

	void processGlobalEvent(const(Event) p_e) 
	{
		if (!_alive)
			return;
		foreach(child; _children)
			if (child.isAlive)
				child.processGlobalEvent(p_e);
	}
	
	/// Adds the component c to the back of the rendering queue.
	GuiComponent add(GuiComponent p_c)
	{
		return add!GuiComponent(p_c);
	}

	/// Adds the component c to the back of the rendering queue.
	T add(T)(T p_c) if (is(T : GuiComponent))
	{
		if (p_c is null)
			return null;

		p_c.parent = this;
		import std.algorithm : canFind;
		if (!_children.canFind(p_c))
	    {
			_children = p_c ~ _children;
			return p_c;
		}
		return null;
	}
	
	/// Removes the component c from the rendering queue.
	void remove(GuiComponent p_c)
	{
		if (p_c is null)
			return;

		for(int i = 0; i < _children.length; i++)
		{
			if(_children[i] == p_c)
			{
				_children = _children[0 .. i] ~ _children[i + 1 .. $];
				p_c.parent = null;
				return;
			}
		}
	}

	/// returns a list of all components of type T that are children of this component
	T[] grabChildrenByType(T : GuiComponent)()
	{
		T[] ret;
		foreach(obj; _children)
			if (auto d = cast(T)obj)
				ret ~= d;
		return ret;
	}
	
	/** 
	* Focuses this particular component, brings all (+ nested) parents to the front of the rendering 
	* queue, and unfocuses everything else in the heirarchy.
	*/
	void focus()
	{
		GuiComponent chain = this;
		while(chain.parent)
		{
			chain.moveToFront();
			chain = chain.parent;
		}
		chain.unfocus();
		_focused = true;
	}
	
	/// Unfocuses this component and all (+ nested) children.
	void unfocus()
	{
		_focused = false;
		foreach(GuiComponent c; _children)
			c.unfocus();
	}
	
	/// Moves component p_c to the front of the rendering queue.
	void moveToFront(GuiComponent p_c)
	{
		import std.algorithm : strip;
		_children = p_c ~ _children.strip(p_c);
	}

	/// Moves component p_c to the back of the rendering queue.
	void moveToBack(GuiComponent p_c)
	{
		import std.algorithm : strip;
		_children = _children.strip(p_c) ~ p_c;
	}

	/// Moves this component to the front of its parent's rendering queue
	void moveToFront()
	{
		if(parent !is null)
			parent.moveToFront(this);
	}

	/// Moves this component to the back of its parent's rendering queue
	void moveToBack()
	{
		if(parent !is null)
			parent.moveToBack(this);
	}
	
	/**
	* Obtains this component's children.
	*	Returns: The original array of children. Any changes to this array will be reflected in this component.
	*/
	GuiComponent[] getChildren() 
	{ 
		return _children.dup;
	}
	
	bool isInside(int p_x, int p_y, bool p_useGlobalCoordinates = true)
	{
		//import std.stdio, std.conv;
		//writeln(text(label, globalPosition, " isInside(", p_x, ", ", p_y, ", ", p_useGlobalCoordinates, ") ", size));
		if (p_useGlobalCoordinates)
		{
			int[2] pos = globalPosition;
			return p_x >= pos[0] && p_x < pos[0] + sizeX
					&& p_y >= pos[1] && p_y < pos[1] + sizeY;
		}
		else return p_x >= x && p_x < x + sizeX
					&& p_y >= y && p_y < y + sizeY;
		
	}

	bool isMouseInside()
	{
		import janus.globals;
		Vector2f pt = window.mapPixelToCoords(Mouse.getPosition(window));
		return isInside(cast(int)pt.x, cast(int)pt.y, true);
	}

	bool isMouseInside(View p_view)
	{
		import janus.globals;
		Vector2f pt = window.mapPixelToCoords(Mouse.getPosition(window), p_view);
		return isInside(cast(int)pt.x, cast(int)pt.y, true);
	}
	
	/// Whether to update/render this and all child components
	void setAlive(bool p_alive)
	{
		_alive = p_alive;
	}
	
	/// Neither this component nor its children will update/render
	void kill()
	{
		setAlive(false);
	}
	
	/// This component and its children will begin rendering again
	void revive()
	{
		setAlive(true);
	}
	
	Gui getRoot()
	{
		GuiComponent chain = this;
		while(chain.parent)
			chain = chain.parent;
		if (typeid(chain) == typeid(Gui))
			return cast(Gui)chain;
		return null;
	}
	
	@property 
	{
		bool isFocused() { return _focused; } /// Readonly focused property. Use focus() or unfocus() to change.
		
		int[2] position() { return [_x, _y]; } /// position relative to parent

		/// position relative to parent
		void position(int[2] p_value)
		{
			_x = p_value[0];
			_y = p_value[1];
		}
		
		void sizeX(int p_sizeX)
		{
			_sizeX = p_sizeX;
			//_refreshFlagged = true;
		}
		
		int sizeX() { return _sizeX; }
		
		void sizeY(int p_sizeY)
		{
			_sizeY = p_sizeY;
			//_refreshFlagged = true;
		}

		int sizeY() { return _sizeY; }
		
		int[2] size() { return [sizeX, sizeY]; } /// clickable size of component
		
		/// clickable size of component
		void size(int[2] p_value)
		{
			sizeX = p_value[0];
			sizeY = p_value[1];
		}
		
		/// position relative to (0, 0)
		int[2] globalPosition()
		{
			int[2] ret = [_x, _y];
			GuiComponent chain = this;
			while(chain.parent)
			{
				chain = chain.parent;
				ret[0] += chain.clientX;
				ret[1] += chain.clientY;
			}
			return ret;
		}
		
		bool isAlive() { return _alive; } /// Whether this and all child components are alive
	
		int clientX() { return x; } /// X position bounding children
		
		int clientY() { return y; } /// Y position bounding children
		
		int[2] clientPosition() { return [clientX, clientY]; } /// Position bounding children

		/// Position relative to parent
		int x() { return _x; }
		/// Position relative to parent
		int x(int p_x) { _x = p_x; return _x; }
		/// Position relative to parent
		int y() { return _y; }
		/// Position relative to parent
		int y(int p_y) { _y = p_y; return _y; }

		int centerX() { return _x + _sizeX / 2; }
		int centerY() { return _y + _sizeY / 2; }
	}
	
protected:
	int _x, _y = 0;
	/// Iterates over children and renders them
	void renderChildren(Time p_dt, RenderTarget p_canvas)
	{
		foreach(child; _children)
			if (child.isAlive)
				child.render(p_dt, p_canvas);
	}
	
	bool _focused = false;

	@property
	{

	}

private:
	GuiComponent[] _children = [];
	bool _alive = true; /// Should this component render
	static Sprite _drawer; /// Used to render the RenderTexture
	int _sizeX, _sizeY = 0; /// Size for checking if mouse pressed
};