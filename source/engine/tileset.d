/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.tileset;

import dsfml.graphics;

/// Storage class for tileset information
class Tileset
{
	this(Texture p_tex, int p_frameWidth, int p_frameHeight)
	{
		_texture = p_tex;
		_frameWidth = p_frameWidth;
		_frameHeight = p_frameHeight;
		_spr = new Sprite();
	}

	@property
	{
		Texture texture() { return _texture; }
		int frameWidth() { return _frameWidth; }
		int frameHeight() { return _frameHeight; }
		int texWidth() { return _texture.getSize().x; }
		int texHeight() { return _texture.getSize().y; }
		Vector2u size() { return _texture.getSize(); }
		Vector2f frameSize() { return Vector2f(_frameWidth, _frameHeight); }
		Vector2f texSize() { return Vector2f(_texture.getSize().x, _texture.getSize().y); }
	}

	void drawFrame(RenderTarget p_target, int p_x, int p_y, int[] p_frameCoords, Vector2f p_scale = Vector2f(1f, 1f), Color p_color = Color.White, RenderStates p_rs = RenderStates.Default())
	{
		_spr.setTexture(_texture);
		_spr.textureRect = IntRect(p_frameCoords[0] * _frameWidth, p_frameCoords[1] * _frameHeight, _frameWidth, _frameHeight);
		_spr.color = p_color;
		_spr.scale = p_scale;
		_spr.position = Vector2f(p_x, p_y);
		_spr.draw(p_target, p_rs);
	}

	void drawFrame(RenderTarget p_target, IntRect p_dest, int[] p_frameCoords, Color p_color = Color.White, RenderStates p_rs = RenderStates.Default())
	{
		drawFrame(p_target, p_dest.left, p_dest.top, p_frameCoords, Vector2f(cast(float)p_dest.width / frameWidth, cast(float)p_dest.height / frameHeight), p_color, p_rs);
	}

	/// draw rects based on texture frames
	/// p_tlf = top left frame coordinates
	void drawTexturedRect(RenderTarget p_target, IntRect p_dest, int[] p_tlf, Color p_col = Color.White, RenderStates p_rs = RenderStates.Default())
	{
		// draw bottom first
		drawFrame(p_target, IntRect(p_dest.left + _frameWidth, p_dest.top + p_dest.height - _frameHeight, p_dest.width - _frameWidth * 2, _frameHeight), [p_tlf[0] + 1, p_tlf[1] + 2], p_col, p_rs); // bottom
		drawFrame(p_target, p_dest.left, p_dest.top + p_dest.height - _frameHeight, [p_tlf[0], p_tlf[1] + 2], Vector2f(1, 1), p_col, p_rs); // bottom left
		drawFrame(p_target, p_dest.left + p_dest.width - _frameWidth, p_dest.top + p_dest.height - _frameHeight, [p_tlf[0] + 2, p_tlf[1] + 2], Vector2f(1, 1), p_col, p_rs); // bottom right
		
		// draw top next
		drawFrame(p_target, IntRect(p_dest.left + _frameWidth, p_dest.top, p_dest.width - _frameWidth * 2, _frameHeight), [p_tlf[0] + 1, p_tlf[1]], p_col, p_rs); // top
		drawFrame(p_target, p_dest.left, p_dest.top, p_tlf, Vector2f(1, 1), p_col, p_rs); // top left
		drawFrame(p_target, p_dest.left + p_dest.width - _frameWidth, p_dest.top, [p_tlf[0] + 2, p_tlf[1]], Vector2f(1, 1), p_col, p_rs); // top right

		// last is the middle
		if (p_dest.height >= 2 * _frameHeight) // make sure we actually need to draw the middle
		{
			drawFrame(p_target, IntRect(p_dest.left + _frameWidth, p_dest.top + _frameHeight, p_dest.width - _frameWidth * 2, p_dest.height - _frameHeight * 2), [p_tlf[0] + 1, p_tlf[1] + 1], p_col, p_rs); // middle
			drawFrame(p_target, IntRect(p_dest.left, p_dest.top + _frameHeight, _frameWidth, p_dest.height - _frameHeight * 2), [p_tlf[0], p_tlf[1] + 1], p_col, p_rs); // left
			drawFrame(p_target, IntRect(p_dest.left + p_dest.width - _frameWidth, p_dest.top + _frameHeight, _frameWidth, p_dest.height - _frameHeight * 2), [p_tlf[0] + 2, p_tlf[1] + 1], p_col, p_rs); // right
		}
	}

private:
	Texture _texture;
	int _frameWidth, _frameHeight;
	Sprite _spr;
}