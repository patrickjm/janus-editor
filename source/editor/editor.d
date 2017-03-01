/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.editor;

import std.typecons : Tuple;

import dsfml.graphics;

import janus.editor;
import janus.editor.gui;
import janus.editor.actionqueue;
import janus.editor.editorobject;
import janus.globals;
import janus.engine : Tileset, EventProcessor;
import janus.engine.level;
import janus.engine.sizeable;

class Editor : EventProcessor
{
	protected
	{
		Vector2f _screenClick; /// these values define where the screen was originally clicked
		Vector2f _viewClick; /// these values define where in the view was the original clicking pt
		View _cam; /// editor camera
		float _currentZoom = 1; /// zoom factor on _cam

		Gui _guiSub; /// gui used for interactive elements (objects)
		Level _level;
		PolygonBuilder _polyBuilder = new PolygonBuilder();
		ActionQueue _queue;
		EditorObject[] _objects;
		EditorObject[] _selectedObjects;

		/// Editor modes
		EM _currentMode = EM.Draw;
		bool _moveCameraMode = false;

		// key event stores
		alias bool delegate(bool) KeyEvDel; /// Key event function - returns true if event handled, takes bool (true if key is pressed)
		KeyEvDel[Keyboard.Key] _singleKeyEvents;
		bool _hasRegisteredEvents = false;
	}
	package enum EM { Draw, Edit }

	@property
	{
		Gui guiSub() { return _guiSub; }
		View cam() { return _cam; }
		float zoomFactor() { return _currentZoom; }
		Level level() { return _level; }
		ActionQueue queue() { return _queue; }
		PolygonBuilder builder() { return _polyBuilder; }
		const(EditorObject[]) selectedObjects() { return _selectedObjects; }
	}

	this(Level p_level)
	{
		_level = p_level;
		// create the gui manager
		_guiSub = new Gui();
		_guiSub.style = new GuiStyle([
			"col1" : assets.get!Tileset("editor_gui1"),
			"col2" : assets.get!Tileset("editor_gui2")
		],
		[
			"main" : assets.get!Font("editor_gui")
		]);

		_cam = defaultView;

		_queue = new ActionQueue();

		addObject(new DummyEditorObj(150, 150));
	}

	void render(Time p_dt, RenderTarget p_rt)
	{
		p_rt.view = _cam;

		foreach(obj; _objects)
			obj.render(p_dt, p_rt);

		if (_polyBuilder.isActive)
			_polyBuilder.render(p_rt);

		window.view = defaultView;
		_guiSub.render(p_dt, p_rt);

		// render game mode in top left of screen
		import std.conv : dtext;
		import dsfml.graphics : Text, Color, RenderStates;
		static Text modeText;
		if (!modeText)
		{
			modeText = new Text("", assets.get!Font("editor_gui"));
			modeText.setCharacterSize(14);
			modeText.position = Vector2f(5, 20);
			modeText.setColor(Color.White);
		}
		modeText.setString(dtext("Mode: EM.", _currentMode, "\nZoom: ", 100f / _currentZoom, "%"));
		modeText.draw(p_rt, RenderStates.Default);
	}
	
	override bool processEvent(const(Event) p_e)
	{
		// KEYBOARD EVENT SYSTEM:
		// putting event delegates here because it means all the code is 
		// in one easy place
		if (!_hasRegisteredEvents)
		{
			// camera button pressed. toggle camera mode
			registerKeyEvent(mixin(EditorSettings.Main.KeyCameraMode), delegate bool(bool p_pressed) {
				_moveCameraMode = p_pressed;
				return true;
			});
			// undo button pressed
			registerKeyEvent(mixin(EditorSettings.Main.KeyUndo), delegate bool(bool p_pressed) {
				if (!p_pressed || Mouse.isButtonPressed(Mouse.Button.Left))
					return false;
				_queue.undo();
				return true;
			});
			// redo button pressed
			registerKeyEvent(mixin(EditorSettings.Main.KeyRedo), delegate bool(bool p_pressed) {
				if (!p_pressed || Mouse.isButtonPressed(Mouse.Button.Left))
					return false; 
				_queue.redo();
				return true;
			});
			// mode-toggle pressed
			registerKeyEvent(mixin(EditorSettings.Main.KeyToggleMode), delegate bool(bool p_pressed) {
				if (p_pressed && !_polyBuilder.isActive)
				{
					toggleMode(_currentMode == EM.Draw ? EM.Edit : EM.Draw);
					return true;
				}
				return false;
			});
			// restart game pressed
			registerKeyEvent(mixin(EditorSettings.Main.KeyRestart), delegate bool(bool p_pressed) {
				if (p_pressed && Keyboard.isKeyPressed(Keyboard.Key.LControl))
				{
					manager.triggerRestart();
					return true;
				}
				return false;
			});
			// zoom-reset pressed
			registerKeyEvent(mixin(EditorSettings.Main.KeyResetZoom), delegate bool(bool p_pressed) {
				if (p_pressed)
				{
					View newView = defaultView;
					newView.center = _cam.center;
					newView.zoom(1);
					_currentZoom = 1;
					_cam = newView;
					return true;
				}
				return false;
			});
			_hasRegisteredEvents = true;
		}
		// keyboard event handlers:
		if (p_e.type == Event.EventType.KeyPressed || p_e.type == Event.EventType.KeyReleased)
			if (processKeyEvent(cast(Keyboard.Key)p_e.key.code, p_e.type == Event.EventType.KeyPressed))
				return true;

		// ******
		// VIEW RESIZING:
		if (p_e.type == Event.EventType.Resized)
		{
			View newView = new View(FloatRect(0f, 0f, window.getSize.x, window.getSize.y));
			newView.center = _cam.center;
			newView.zoom(_currentZoom);
			_cam = newView;
		}

		// *****
		// MOUSE EVENT HANDLING:
		if (p_e.type == Event.EventType.MouseWheelMoved) // zooming
		{
			const zFactor = 1.3f;
			_currentZoom *= (p_e.mouseWheel.delta > 0) ? (1f / zFactor) : zFactor;
			_currentZoom = _currentZoom < .3f ? .3f : _currentZoom;
			_currentZoom = _currentZoom > 3 ? 3 : _currentZoom;
			View newView = defaultView;
			newView.center = _cam.center;
			newView.zoom(_currentZoom);
			_cam = newView;
		}
		else if (_moveCameraMode) // camera panning (space is pressed)
		{
			static bool pressed = false;
			if (Mouse.isButtonPressed(Mouse.Button.Left))
			{
				if (p_e.type == Event.EventType.MouseButtonPressed && p_e.mouseButton.button == Mouse.Button.Left) // first click
				{
					pressed = true;
					_screenClick = Vector2f(Mouse.getPosition(window).x, Mouse.getPosition(window).y);
					_viewClick = _cam.center;
				}
				else if (p_e.type == Event.EventType.MouseButtonReleased && p_e.mouseButton.button == Mouse.Button.Left)
					pressed = false;

				if (p_e.type == Event.EventType.MouseMoved && pressed) // drag the view!
				{
					_cam.center = _viewClick + (_screenClick - Vector2f(Mouse.getPosition(window).x, Mouse.getPosition(window).y)) * _currentZoom;
				}
				return true;
			}
			else pressed = false;
		}
		else if (p_e.type == Event.EventType.MouseButtonPressed 
		         && _currentMode == EM.Draw
		         && Mouse.isButtonPressed(Mouse.Button.Right)
		         && !Mouse.isButtonPressed(Mouse.Button.Left)) // draw mode:
		{
			if (!_polyBuilder.isActive) // is this the first point
			{
				// right clicking to draw vertices
				Vector2f mouse = mouseViewLoc();
				// choosing if a new polygon should be created or make a hole:
				static PolygonObject target; // should there be a hole - and inside which poly? 
				import std.stdio;
				foreach(poly; grabObjectsByType!PolygonObject) // loop through all the polys and see if mouse is inside
				{
					if (poly.poly.isPointInside(mouse.x, mouse.y))
					{
						target = poly;
						break;
						// Disabling holes for now
//						target = null;
//						return true;
					}
				}
				_polyBuilder.startAt(mouse.x, mouse.y, target);
				target = null;
				return true;
			}
		}
		// all the control processing is done, so pass the event along to the objects
		processSelections(p_e); // selection system
		if (_polyBuilder.isActive())
			if (_polyBuilder.processEvent(p_e))
				return true;
		if (_guiSub.processEvent(p_e))
			return true;
		foreach(obj; _objects)
			if (obj.processEvent(p_e))
				return true;

		return false;
	}

	Vector2f win2Cam(Vector2i p_in)
	{
		return window.mapPixelToCoords(p_in, _cam);
	}
	Vector2f win2Cam(Vector2f p_in)
	{
		return window.mapPixelToCoords(Vector2i(cast(int)p_in.x, cast(int)p_in.y), _cam);
	}
	Vector2i cam2Win(Vector2i p_in)
	{
		return window.mapCoordsToPixel(Vector2f(p_in.x, p_in.y), _cam);
	}
	Vector2i cam2Win(Vector2f p_in)
	{
		return window.mapCoordsToPixel(p_in, _cam);
	}
	/// returns the location of the mouse in global coordinates (with the camera in mind)
	Vector2f mouseViewLoc()
	{
		return window.mapPixelToCoords(Mouse.getPosition(window), _cam);
	}

	/// switches the current editor mode to p_to (and makes changes accordingly)
	void toggleMode(EM p_to)
	{
		import std.algorithm : canFind;

		void toDrawMode()
		{
		}
		void toEditMode()
		{

		}
		// just make a map of delegate functions to call depending on the mode being switched to
		alias void delegate() toggleFunc;
		static toggleFunc[EM] functions;
		if (!functions) functions = [
			EM.Draw : &toDrawMode,
			EM.Edit : &toEditMode
		];
		// set the mode
		_currentMode = p_to;
		// call the delegate
		functions[_currentMode]();
		// sort out all the objects
		sortObjects();
	}

	/// Adds the object to the list (and its draggable to the gui manager)
	/// Returns: null if p_obj is null or already in the list, or p_obj otherwise
	EditorObject addObject(EditorObject p_obj)
	{
		import std.algorithm : canFind;
		if (p_obj !is null && !_objects.canFind(p_obj))
		{
			_objects ~= p_obj;
			_guiSub.add(p_obj.selector);

			// add the object's children recursively
			foreach(child; p_obj.children)
				addObject(child);

			p_obj.onActivate();
			sortObjects();
			return p_obj;
		}
		return null;
	}

	/// Removes the object from the list (and its draggable from the gui manager)
	/// Returns: null if p_obj is null or not in the list, or p_obj otherwise
	EditorObject removeObject(EditorObject p_obj)
	{
		import std.algorithm : canFind, countUntil;
		if (p_obj !is null && _objects.canFind(p_obj))
		{
			int i = _objects.countUntil(p_obj);
			_objects = _objects[0 .. i] ~ _objects[i + 1 .. $];

			// remove the object's children recursively
			foreach(child; p_obj.children)
				removeObject(child);

			_guiSub.remove(p_obj.selector);
			p_obj.onDeactivate();
			//sortObjects();
			return p_obj;
		}
		return null;
	}

	/// stores the object and sets its selectable property to true
	void selectObject(EditorObject p_object)
	{
		import std.algorithm : canFind;
		if (!_selectedObjects.canFind(p_object))
		{
			_selectedObjects ~= p_object;
			p_object.select();
		}
	}

	/// deselects everything and selects only p_object
	void selectOnly(EditorObject p_object)
	{
		deselectAll();
		selectObject(p_object);
	}

	/// removes the object from the selection list and sets its selectable property to false
	void deselectObject(EditorObject p_object)
	{
		import std.algorithm : countUntil;
		int num;
		if ((num = _selectedObjects.countUntil(p_object)) != -1)
		{
			_selectedObjects = _selectedObjects[0 .. num] ~ _selectedObjects[num + 1 .. $];
			p_object.deselect();
		}
	}

	/// clears the selection list and sets all previously selected objects' selectable properties to false
	void deselectAll()
	{
		foreach(obj; _selectedObjects)
			obj.deselect();
		_selectedObjects = [];
	}

	/// Sorts all the EditorObjects (and their respective draggables) 
	void sortObjects()
	{
		import std.algorithm : sort, canFind;
		auto sorted = sort!((a, b) => EditorObjectTypeList.map[typeid(a)] > EditorObjectTypeList.map[typeid(b)])(_objects);
		_objects = [];

		foreach(obj; sorted)
			_objects ~= obj; // add it to the new list

		foreach(child; _guiSub.grabChildrenByType!GuiDraggable)
			if (typeid(child.meta) == typeid(EditorObject))
				_guiSub.remove(child);

		foreach(obj; _objects)
			_guiSub.add(obj.selector); // add it back, now sorted

		// remove any stragglers
		foreach(child; _guiSub.grabChildrenByType!GuiDraggable)
		{
			if (typeid(child.meta) == typeid(EditorObject))
			{
				if (!_objects.canFind(cast(EditorObject)child.meta))
					_guiSub.remove(child);
			}
		}

		// activate and deactivate objects based on if they belong in this mode
		foreach(obj; _objects)
		{
			if (EditorObjectTypeList.approvedTypes[_currentMode].canFind(typeid(obj)))
				obj.onActivate();
			else
				obj.onDeactivate();
		}
	}

	/// returns a list of all editor objects of type T
	T[] grabObjectsByType(T : EditorObject)()
	{
		T[] ret;
		foreach(obj; _objects)
			if (auto d = cast(T)obj)
				ret ~= d;
		return ret;
	}

	/// returns a list of object.pred where object : T
	R[] grabObjectMembers(T : EditorObject, R, string pred)()
	{
		R[] ret;
		foreach(obj; grabObjectsByType!T)
			ret ~= mixin("obj." ~ pred);
		return ret;
	}

protected:
	void registerKeyEvent(Keyboard.Key p_key, KeyEvDel p_func)
	{
		_singleKeyEvents[p_key] = p_func;
	}

	bool processKeyEvent(Keyboard.Key p_key, bool p_pressed)
	{
		auto func = _singleKeyEvents.get(p_key, null);
		if (!func) return false;
		return func(p_pressed);
	}

	/// handle the selection engine (selecting/deselecting objects)
	void processSelections(const(Event) p_e)
	{
		if (_polyBuilder.isActive)
			return;
		// check for left mouse clicks
		if (p_e.type == Event.EventType.MouseButtonReleased && p_e.mouseButton.button == Mouse.Button.Left)
		{
			auto mousePos = mouseViewLoc;
			EditorObject sel; // which object are we selecting?
			foreach(obj; _objects)
			{
				if (obj.isAlive && obj.isPointInside(mousePos.x, mousePos.y))
				{
					sel = obj;
				}
			}
			if (!Keyboard.isKeyPressed(Keyboard.Key.LControl))
				deselectAll(); // multiselect or single select?

			if (sel !is null) // selection
				selectObject(sel);
		}
	}
}