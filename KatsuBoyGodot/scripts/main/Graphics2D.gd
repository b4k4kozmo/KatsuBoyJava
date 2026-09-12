class_name Graphics2D
extends Node2D
## Stand-in for java.awt.Graphics2D.
##
## Java kept the pen state (font, colour, stroke, alpha composite) on the
## Graphics2D object and then called drawString / fillRect / drawImage. Godot's
## draw_* calls each take their colour explicitly, so we keep the same pen state
## here and let the helpers below apply it. That way every drawing routine in
## the game still reads like the original.
##
## Every layer the game draws on extends this, which is why all of them can be
## passed as the "g2" argument interchangeably.

var _font: Font
var _font_size: int = 24
var _color: Color = Color.WHITE
var _stroke: float = 1.0
## Java's AlphaComposite: multiplied into every sprite we blit.
var alpha: float = 1.0

## A 1x1 white pixel, for shader-driven fills where we need real UVs.
static var white_pixel: Texture2D = _make_white_pixel()


static func _make_white_pixel() -> Texture2D:
	var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	return ImageTexture.create_from_image(img)


## Reset the pen at the top of a frame.
func reset_pen() -> void:
	alpha = 1.0
	_stroke = 1.0


func set_font(font: Font, size: int) -> void:
	_font = font
	_font_size = size


## Java: g2.setFont(g2.getFont().deriveFont(size)) - keep the font, change size.
func derive_font(size: int) -> void:
	_font_size = size


func set_color(color: Color) -> void:
	_color = color


func set_stroke(width: float) -> void:
	_stroke = width


## Java: changeAlpha(g2, value) / setComposite(AlphaComposite...)
func change_alpha(value: float) -> void:
	alpha = value


## The tint every sprite blit is drawn with, so the alpha composite applies.
func tint() -> Color:
	return Color(1, 1, 1, alpha)


## Java: g2.drawString(text, x, y) - (x, y) is the text BASELINE in both APIs.
func draw_str(text: String, x: int, y: int) -> void:
	if _font == null:
		return
	draw_string(_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _color)


## Java: g2.getFontMetrics().getStringBounds(text, g2).getWidth()
func get_string_width(text: String) -> int:
	if _font == null:
		return 0
	return int(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x)


## Java: g2.drawImage(image, x, y, null) - draws at the sprite's own size.
func draw_img(texture: Texture2D, x: int, y: int) -> void:
	if texture == null:
		return
	draw_texture(texture, Vector2(x, y), tint())


## Java: g2.drawImage(image, x, y, width, height, null)
func draw_img_scaled(texture: Texture2D, x: int, y: int, width: int, height: int) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(x, y, width, height), false, tint())


func fill_rect(x: int, y: int, width: int, height: int) -> void:
	draw_rect(Rect2(x, y, width, height), _color, true)


func fill_round_rect(x: int, y: int, width: int, height: int, arc_width: int, _arc_height: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _color
	sb.set_corner_radius_all(int(arc_width / 2.0))
	draw_style_box(sb, Rect2(x, y, width, height))


func draw_round_rect(x: int, y: int, width: int, height: int, arc_width: int, _arc_height: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = _color
	sb.set_border_width_all(int(_stroke))
	sb.set_corner_radius_all(int(arc_width / 2.0))
	draw_style_box(sb, Rect2(x, y, width, height))
