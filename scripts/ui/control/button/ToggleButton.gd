extends TextureButton
class_name ToggleButton


export(Texture) var normal_normal
export(Texture) var normal_pressed
export(Texture) var normal_hover
export(Texture) var normal_disabled
export(Texture) var normal_focused
export(Color) var normal_modulation := Color(0.8, 0.8, 0.8)


export(Texture) var toggled_normal
export(Texture) var toggled_pressed
export(Texture) var toggled_hover
export(Texture) var toggled_disabled
export(Texture) var toggled_focused
export(Color) var toggled_modulation := Color(1, 1, 1)


export(bool) var isToggle := false setget set_toggle, is_toggle
export(bool) var toggled := false setget set_toggled, is_toggled


func _ready():
	if isToggle:
		if toggled:
			get_node("Icon").self_modulate = toggled_modulation
		else:
			get_node("Icon").self_modulate = normal_modulation


func set_button_icon(value : Texture):
	get_node("Icon").texture = value


func get_button_icon() -> Texture:
	return get_node("Icon").texture


func set_toggle(value : bool):
	if value == isToggle:
		return
	
	isToggle = value
	if !isToggle && toggled:
		self.toggled = false
	elif isToggle:
		var t = toggled
		toggled = !toggled
		self.toggled = t

func is_toggle() -> bool:
	return isToggle


func set_toggled(value : bool):
	if value == toggled || !isToggle:
		return
	
	toggled = value
	var icon = get_node("Icon")
	if toggled:
		self.texture_normal = toggled_normal
		self.texture_pressed = toggled_pressed
		self.texture_hover = toggled_hover
		self.texture_disabled = toggled_disabled
		self.texture_focused = toggled_focused
		if icon != null:
			icon.self_modulate = toggled_modulation
	else:
		self.texture_normal = normal_normal
		self.texture_pressed = normal_pressed
		self.texture_hover = normal_hover
		self.texture_disabled = normal_disabled
		self.texture_focused = normal_focused
		if icon != null:
			icon.self_modulate = normal_modulation


func is_toggled() -> bool:
	return toggled


func _pressed():
	Audio.play_click()
	if isToggle:
		self.toggled = !toggled
