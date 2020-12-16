extends Node


func initiate_load_scene(current_scene, new_scene_path : String, curtainControl, savedFilename = null):
	call_deferred("load_scene", current_scene, new_scene_path, curtainControl, savedFilename)


func load_scene(current_scene, new_scene_path : String, curtainControl, savedFilename = null):
	if savedFilename != null:
		if !savedFilename.to_lower().ends_with(SavedGame.EXTENSION):
			savedFilename = "%s.%s" % [savedFilename, SavedGame.EXTENSION]
		
		var dir = Directory.new()
		var err = dir.open(CDIO.PATH_SAVE)
		if err != OK:
			curtainControl.error_out(tr("error_dir_noopen") % [CDIO.PATH_SAVE, err])
			return
		
		if !dir.file_exists("%s/%s" % [CDIO.PATH_SAVE, savedFilename]):
			curtainControl.error_out(tr("error_file_not_found") % [savedFilename])
			return
	
	current_scene.propagate_call("cleanup")
	current_scene.free()
	
	var new_scene
	if savedFilename != null:
		var savedGame = CDIO.load_file(savedFilename)
		
		if savedGame.get_error() == OK:
			new_scene = load(new_scene_path).instance()
			new_scene.get_node("Loader").savedGame = savedGame
		else:
			new_scene = load("res://scenes/UI/menus/MainMenu.tscn").instance()
			var cc = new_scene.get_node("CurtainArea/CurtainControl")
			cc.initialIntro = false
			cc.error = tr("error_file_noread") % [savedFilename, savedGame.get_error()]
		savedGame.close()
			
	elif new_scene_path != "res://scenes/Arena.tscn":
		new_scene = load(new_scene_path).instance()
		new_scene.get_node("CurtainArea/CurtainControl").initialIntro = false
	else:
		new_scene = load(new_scene_path).instance()
	
	get_tree().set_pause(false)
	get_tree().get_root().add_child(new_scene)
	get_tree().set_current_scene(new_scene)
