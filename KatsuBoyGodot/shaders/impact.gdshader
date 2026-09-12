shader_type canvas_item;
// A quick expanding ring, drawn where a hit lands.
//
// One material draws every impact on screen, so the per-impact values are
// smuggled in through the vertex colour: RGB is the palette colour to use, and
// ALPHA is how far through its life this impact is (0 = just happened, 1 =
// gone). EffectsLayer sets that per draw call.

// Chops the ring into blocks so it matches the 3x pixel art instead of being a
// smooth circle. Roughly (sprite size / 3).
uniform float cells = 28.0;
// How thick the ring starts out, as a fraction of the quad.
uniform float thickness : hint_range(0.02, 0.5) = 0.22;

void fragment() {
	float t = clamp(COLOR.a, 0.0, 1.0);

	// Snap to a coarse grid -> chunky pixels rather than a smooth curve.
	vec2 uv = floor(UV * cells) / cells + (0.5 / cells);

	float d = length(uv - vec2(0.5)) * 2.0;
	// Start as a small ring rather than a filled blob, then expand outwards.
	float radius = 0.18 + t * 0.82;
	float width = thickness * (1.0 - t) + 0.04;

	// Hard edges, not a soft glow - this is pixel art.
	float ring = step(abs(d - radius), width);
	// Fade out over its life, and never draw outside the quad.
	float a = ring * pow(1.0 - t, 0.6) * step(d, 1.0);

	COLOR = vec4(COLOR.rgb, a);
}
