import hashlib
import os

root = os.path.join(os.path.dirname(__file__), "..", "UI", "Theme")
template = """[remap]

importer="texture"
type="CompressedTexture2D"
path="res://.godot/imported/{name}-{digest}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://UI/Theme/{name}"
dest_files=["res://.godot/imported/{name}-{digest}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""

for name in os.listdir(root):
	if not name.endswith(".png"):
		continue
	digest = hashlib.md5(("res://UI/Theme/" + name).encode()).hexdigest()
	path = os.path.join(root, name + ".import")
	with open(path, "w", newline="\n") as handle:
		handle.write(template.format(name=name, digest=digest))
	print("wrote", name + ".import")
