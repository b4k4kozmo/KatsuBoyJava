class_name UtilityTool
extends RefCounted
## Java: main/UtilityTool.java
##
## The Java version pre-scaled every sprite once at load time so that it could
## later be blitted 1:1. We do exactly the same: the returned ImageTexture is
## already the final on-screen size, so draw_texture() never has to stretch.

func scale_image(original: Texture2D, width: int, height: int) -> Texture2D:
	var image: Image = original.get_image()
	if image.is_compressed():
		image.decompress()
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
