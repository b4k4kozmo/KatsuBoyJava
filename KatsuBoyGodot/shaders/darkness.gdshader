shader_type canvas_item;
// Day / night darkness, and the circle of light around the player.
//
// This replaces a screen-sized gradient texture that had to be rebuilt in
// software every time the player's light changed. It uses one colour - the
// palette's kamiblack, passed in from GamePanel - and varies only its opacity,
// so night can never introduce a colour that is not in the game's palette.

// The five opacity stops of the original gradient, as fractions of 255.
const float STOP_0 = 25.0 / 255.0;
const float STOP_1 = 75.0 / 255.0;
const float STOP_2 = 150.0 / 255.0;
const float STOP_3 = 225.0 / 255.0;
const float STOP_4 = 240.0 / 255.0;

// Where the light is and how far it reaches, in screen pixels.
uniform vec2 light_center = vec2(480.0, 288.0);
// 0 means no light source: flat darkness everywhere.
uniform float light_radius = 0.0;
uniform vec2 screen_size = vec2(960.0, 576.0);

// The colour night is painted in. Always a palette colour.
uniform vec4 dark_color : source_color = vec4(0.102, 0.008, 0.169, 1.0);
// How dark full night gets.
uniform float darkness : hint_range(0.0, 1.0) = 0.941;
// 0 = broad daylight, 1 = fully night. Driven by the day/night cycle.
uniform float fade : hint_range(0.0, 1.0) = 0.0;
// 0 = smooth falloff. Higher posterises the light into that many steps, for a
// chunkier look that matches the pixel art.
uniform int bands : hint_range(0, 16) = 0;


// The original gradient's shape: five stops at 0, 0.25, 0.5, 0.75 and 1.
float falloff(float d) {
	if (d < 0.25) { return mix(STOP_0, STOP_1, d / 0.25); }
	if (d < 0.50) { return mix(STOP_1, STOP_2, (d - 0.25) / 0.25); }
	if (d < 0.75) { return mix(STOP_2, STOP_3, (d - 0.50) / 0.25); }
	return mix(STOP_3, STOP_4, clamp((d - 0.75) / 0.25, 0.0, 1.0));
}

void fragment() {
	float a = darkness;

	if (light_radius > 0.5) {
		vec2 pixel = UV * screen_size;
		float d = clamp(distance(pixel, light_center) / light_radius, 0.0, 1.0);
		// Scale the gradient so "darkness" still controls how black night gets.
		a = falloff(d) * (darkness / STOP_4);
	}

	if (bands > 0) {
		float steps = float(bands);
		a = floor(a * steps + 0.5) / steps;
	}

	COLOR = vec4(dark_color.rgb, a * fade);
}
