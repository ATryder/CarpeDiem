extends ToggleButton


export(Texture) var tri_normal
export(Texture) var tri_pressed
export(Texture) var tri_hover
export(Texture) var tri_disabled
export(Texture) var tri_focused

export(bool) var triggled := false setget set_triggled, is_triggled


func _ready():
	if !isToggle:
		self.isToggle = true


func set_toggled(value : bool):
	if !value && triggled:
		self.triggled = false
	else:
		.set_toggled(value)


func set_triggled(value : bool):
	triggled = value
	if !triggled:
		self.toggled = false
	else:
		self.toggled = true
		self.texture_normal = tri_normal
		self.texture_pressed = tri_pressed
		self.texture_hover = tri_hover
		self.texture_disabled = tri_disabled
		self.texture_focused = tri_focused


func is_triggled() -> bool:
	return triggled


func _pressed():
	Audio.play_click()
	if toggled:
		if triggled:
			self.triggled = false
		else:
			self.triggled = true
	else:
		self.toggled = true
