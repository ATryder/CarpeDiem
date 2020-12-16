extends TextureRect
class_name ControlTransition

export var length := 0.3
export var playOnStart := false
export var freeOnEnd := true
export var reverse := false setget set_reverse, get_reverse

export(NodePath) var toControl : NodePath
var controlTo : Control setget set_control, get_control
export(NodePath) var fromControl : NodePath
var controlFrom : Control setget set_from_control, get_from_control
var contPos : Vector2
var contPos2 : Vector2
export(NodePath) var controlParent : NodePath
var parent : Node
var childIndex := 0 setget set_child_index, get_child_index

var callback setget set_callback, get_callback
export var reattach := true
export var keepOutControl := false
export var copySizeFlags := true
var vpTo : Viewport setget set_viewport, get_viewport
var vpFrom : Viewport setget set_viewport2, get_viewport2

var tme := 0.0

var initialized = false setget set_initialized, is_initialized


func _ready():
	material.set_shader_param("perc", 0.0)
	
	if initialized:
		return
	
	if playOnStart:
		set_process(true)
		return
	
	var fc
	var tc
	var p
	if controlFrom != null:
		fc = controlFrom
	elif fromControl != null:
		fc = get_node(fromControl)
	if controlTo != null:
		tc = controlTo
	elif toControl != null:
		tc = get_node(toControl)
	if parent != null:
		p = parent
	elif controlParent != null:
		p = get_node(controlParent)
	
	if tc == null:
		tc = get_parent()
	if fc == null:
		if controlTo == null:
			set_control(tc, p, childIndex)
	elif controlTo == null:
		if controlFrom == null:
			set_transition(fc, tc, p, childIndex)
		else:
			set_control(tc)
	elif controlFrom == null:
		set_from_control(fc)
	
	set_process(false)


func _play_on_start():
	playOnStart = false
	var fc
	var tc
	var p
	if controlFrom != null:
		fc = controlFrom
	elif fromControl != null:
		fc = get_node(fromControl)
	if controlTo != null:
		tc = controlTo
	elif toControl != null:
		tc = get_node(toControl)
	if parent != null:
		p = parent
	elif controlParent != null:
		p = get_node(controlParent)
	
	if tc == null:
		tc = get_parent()
	if fc == null:
		if controlTo == null:
			set_control(tc, p, childIndex)
	elif controlTo == null:
		if controlFrom == null:
			set_transition(fc, tc, p, childIndex)
		else:
			set_control(tc)
	elif controlFrom == null:
		set_from_control(fc)
	play()


func _process(delta):
	if playOnStart:
		_play_on_start()
	
	tme += delta
	step(min(length, tme), delta)
	if tme >= length:
		_end()


func step(time : float, delta : float):
	material.set_shader_param("perc", time / length)


func set_initialized(value : bool):
	initialized = value


func is_initialized() -> bool:
	return initialized


func is_end():
	return tme >= length


func _end(reattach_control := reattach, free := freeOnEnd):
	set_process(false)
	
	if get_parent() == parent:
		parent.remove_child(self)
	if reattach_control:
		if reverse && controlFrom != null:
			controlFrom.rect_position = Vector2(contPos.x, contPos.y)
			if parent != null && controlFrom.get_parent() != parent:
				if controlFrom.get_parent() != null:
					controlFrom.get_parent().remove_child(controlFrom)
				if parent.get_child_count() == 0 || childIndex >= parent.get_child_count():
					parent.add_child(controlFrom)
				else:
					parent.add_child(controlFrom)
					parent.move_child(controlFrom, max(childIndex, 0))
			elif controlFrom.get_parent() == vpFrom:
				vpFrom.remove_child(controlFrom)
			
			if keepOutControl && controlTo.get_parent() == vpTo:
				vpTo.remove_child(controlTo)
		else:
			controlTo.rect_position = Vector2(contPos.x, contPos.y)
			if parent != null && controlTo.get_parent() != parent:
				if controlTo.get_parent() != null:
					controlTo.get_parent().remove_child(controlTo)
				if parent.get_child_count() == 0 || childIndex >= parent.get_child_count():
					parent.add_child(controlTo)
				else:
					parent.add_child(controlTo)
					parent.move_child(controlTo, max(childIndex, 0))
			elif controlTo.get_parent() == vpTo:
				vpTo.remove_child(controlTo)
			
			if (keepOutControl && controlFrom != null
					&& controlFrom.get_parent() == vpFrom):
				vpFrom.remove_child(controlFrom)
	elif keepOutControl:
		if reverse:
			if controlTo.get_parent() == vpTo:
				vpTo.remove_child(controlTo)
		elif controlFrom != null && controlFrom.get_parent() == vpFrom:
			vpFrom.remove_child(controlFrom)
	
	if callback != null:
		var cb = callback
		callback = null
		cb[0].call(cb[1], self)
		callback = cb
	if free:
		queue_free()


func is_playing() -> bool:
	return is_processing()


func play(play : bool = true, renderControl := !initialized, attachToParent := true):
	if !play:
		set_process(false)
		return
	
	if vpFrom == null && material.get_shader_param("TEXTURE2") == null:
		material.set_shader_param("TEXTURE2", CD.get_blank_texture())
	if renderControl:
		initialized = true
		vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
		if vpFrom != null:
			vpFrom.render_target_update_mode = Viewport.UPDATE_ONCE
		if controlTo.get_parent() != vpTo:
			if controlTo.get_parent() != null:
				controlTo.get_parent().remove_child(controlTo)
			controlTo.rect_position = Vector2(0, 0)
			vpTo.add_child(controlTo)
		if controlFrom != null && controlFrom.get_parent() != vpFrom:
			if controlFrom.get_parent() != null:
				controlFrom.get_parent().remove_child(controlFrom)
			controlFrom.rect_position = Vector2(0, 0)
			vpFrom.add_child(controlFrom)
	
	if copySizeFlags:
		if controlFrom != null:
			size_flags_horizontal = controlFrom.size_flags_horizontal
			size_flags_vertical = controlFrom.size_flags_vertical
		else:
			size_flags_horizontal = controlTo.size_flags_horizontal
			size_flags_vertical = controlTo.size_flags_vertical
			
	if (attachToParent && parent != null
			&& get_parent() != parent):
		if get_parent() != null:
			get_parent().remove_child(self)
		if childIndex >= parent.get_child_count() || parent.get_child_count() == 0:
			parent.add_child(self)
		else:
			parent.add_child(self)
			parent.move_child(self, max(childIndex, 0))
	set_process(true)


func pause():
	play(false)


func to_start():
	tme = 0


func to_end():
	tme = length


func stop():
	play(false)
	to_start()


func set_transition(contFrom : Control, contTo : Control,
		parent = null, childIdx = -1, width := -1,
		height := -1):
	var idx = childIdx
	if (contFrom != null && contFrom.get_parent() != null
			&& (contFrom.get_parent() == vpTo
			|| contFrom.get_parent() == vpFrom)):
		contFrom.get_parent().remove_child(contFrom)
	if (contTo != null && contTo.get_parent() != null
			&& (contTo.get_parent() == vpTo
			|| contTo.get_parent() == vpFrom)):
		contTo.get_parent().remove_child(contTo)
	if childIdx < 0 && contFrom.get_parent() != null:
		idx = contFrom.get_index()
	if parent == null:
		set_control(contTo, contFrom.get_parent(), idx,
				width, height)
	else:
		set_control(contTo, parent, idx,
				width, height)
	set_from_control(contFrom, width, height)


func set_control(cont : Control, parent = null, childIdx = -1,
	width := -1, height := -1):
	if cont == null:
		if vpTo != null:
			vpTo.queue_free()
			vpTo = null
		controlTo = null
		parent = null
		childIndex = 0
		play(false)
		return
	
	controlTo = cont
	if parent != null:
		self.parent = parent
		if childIdx < 0:
			self.childIndex = controlTo.get_index()
		else:
			self.childIndex = childIdx
	elif controlTo.get_parent() != null:
		self.parent = controlTo.get_parent()
		if childIdx < 0:
			self.childIndex = controlTo.get_index()
		else:
			self.childIndex = childIdx
	else:
		if childIdx >= 0:
			childIndex = childIdx
	
	var size = Vector2(controlTo.rect_size.x, controlTo.rect_size.y)
	contPos = Vector2(controlTo.rect_position.x, controlTo.rect_position.y)
	rect_position = Vector2(contPos.x, contPos.y)
	if width >= 0:
		size.x = width
	if height >= 0:
		size.y = height
	if vpTo == null:
		initialized = false;
		self.vpTo = create_viewport(size)
		add_child(vpTo)
	else:
		vpTo.size = size
		for c in vpTo.get_children():
			if c != cont && c != controlFrom:
				c.queue_free()
		if is_playing():
			vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
			if controlTo.get_parent() != vpTo:
				if controlTo.get_parent() != null:
					controlTo.get_parent().remove_child(controlTo)
				controlTo.rect_position = Vector2(0, 0)
				vpTo.add_child(controlTo)
		self.texture = vpTo.get_texture()


func get_control() -> Control:
	return controlTo


func set_from_control(cont : Control, width := -1, height := -1):
	if cont == null:
		if vpFrom != null:
			vpFrom.queue_free()
			vpFrom = null
			if material != null:
				material.set_shader_param("TEXTURE2", CD.get_blank_texture())
		controlFrom = null
		return
	
	controlFrom = cont
	if parent == null and controlFrom.get_parent() != null:
		parent = controlFrom.get_parent()
		if childIndex < 0:
			self.childIndex = controlTo.get_index()
	
	var size = Vector2(controlFrom.rect_size.x, controlFrom.rect_size.y)
	contPos2 = Vector2(controlFrom.rect_position.x, controlFrom.rect_position.y)
	if width >= 0:
		size.x = width
	if height >= 0:
		size.y = height
	if vpFrom == null:
		initialized = false
		self.vpFrom = create_viewport(size)
		add_child(vpFrom)
	else:
		vpFrom.size = size
		for c in vpFrom.get_children():
			if c != cont && c != controlTo:
				c.queue_free()
		if is_playing():
			vpTo.render_target_update_mode = Viewport.UPDATE_ONCE
			if controlFrom.get_parent() != vpFrom:
				if controlFrom.get_parent() != null:
					controlFrom.get_parent().remove_child(controlFrom)
				controlFrom.rect_position = Vector2(0, 0)
				vpFrom.add_child(controlFrom)
		if material != null:
			material.set_shader_param("TEXTURE2", vpFrom.get_texture())


func get_from_control() -> Control:
	return controlFrom


func set_child_index(idx : int):
	childIndex = max(idx, 0)


func get_child_index() -> int:
	return childIndex


func set_callback(value : Array):
	callback = value


func get_callback() -> Array:
	return callback


func set_viewport(viewport : Viewport):
	vpTo = viewport
	if vpTo != null && vpTo.get_texture() != null:
		texture = vpTo.get_texture()


func get_viewport() -> Viewport:
	return vpTo


func set_viewport2(viewport : Viewport):
	vpFrom = viewport
	if (vpFrom != null && vpFrom.get_texture() != null
			&& material != null):
		material.set_shader_param("TEXTURE2", vpFrom.get_texture())


func get_viewport2() -> Viewport:
	return vpFrom


func create_viewport(size : Vector2) -> Viewport:
	var vpTo := Viewport.new()
	vpTo.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	vpTo.render_target_update_mode = Viewport.UPDATE_DISABLED
	vpTo.keep_3d_linear = false
	vpTo.disable_3d = true
	vpTo.msaa = Viewport.MSAA_DISABLED
	vpTo.hdr = false
	vpTo.usage = Viewport.USAGE_2D_NO_SAMPLING
	vpTo.own_world = false
	vpTo.transparent_bg = true
	vpTo.handle_input_locally = true
	vpTo.gui_snap_controls_to_pixels = true
	vpTo.render_target_v_flip = true
	vpTo.size = size
	vpTo.get_texture().set_flags(Texture.FLAG_FILTER)
	
	return vpTo


func set_reverse(value : bool):
	reverse = value
	material.set_shader_param("reverse", reverse)


func get_reverse() -> bool:
	return reverse
