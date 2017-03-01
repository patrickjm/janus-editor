uniform sampler2D texture;
uniform vec2 texSize; // full texture size
uniform vec2 texFrameSize; // individual frame size
uniform vec2 texFrameOffset; // where to get the frame from the image
uniform vec2 globalOffset; // offset the texture rendering (camera / polygon position)
uniform vec4 addColor; // additive blending

void main()
{
	// get the correct pixel
	vec2 pixTexPos = vec2(texFrameOffset.x + mod(gl_FragCoord.x + globalOffset.x, texFrameSize.x),
							texFrameOffset.y + texFrameSize.y - mod(gl_FragCoord.y - globalOffset.y, texFrameSize.y));
	
	vec4 pixel = texture2D(texture, pixTexPos / texSize) + addColor;

	// output
	gl_FragColor = gl_Color * pixel;
}