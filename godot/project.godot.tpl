; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="{{PROJECT_NAME}}"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.6", "GL Compatibility")

[display]

; Base resolution — change to match your target canvas size
window/size/viewport_width=1280
window/size/viewport_height=720
; 2 = canvas_items (pixel-perfect), 1 = viewport (stretch whole viewport)
window/stretch/mode="canvas_items"
; "keep" keeps aspect ratio, "expand" allows wider viewports to show more
window/stretch/aspect="keep"

[rendering]

; GL Compatibility is widest device support (WebGL2, low-end mobile, older desktops)
; Change to "forward_plus" or "mobile" if you need advanced rendering features
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"

[audio]

; Lower mix_rate saves CPU on low-end targets; 44100 is standard
driver/mix_rate=44100

; [input] is intentionally omitted — Godot regenerates default ui_* actions on first open.
; Add custom actions via Project > Input Map in the editor.
