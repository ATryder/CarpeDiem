extends Reference
class_name CDIO

const PATH_DATA := "user://"
const PATH_SAVE := "user://CDSaves"

const FILE_CONFIG := "cd.cfg"


static func init_directories():
	var dir = Directory.new()
	
	if dir.open(PATH_DATA) != OK:
		return
	
	if !dir.dir_exists(PATH_SAVE):
		var err = dir.make_dir_recursive(PATH_SAVE)


static func get_config_file(mode = File.READ) -> File:
	var dir = Directory.new()
	if mode == File.READ && (dir.open(PATH_DATA) != OK || !dir.file_exists(FILE_CONFIG)):
		return null
	
	var file = File.new()
	file.open("%s/%s" % [PATH_DATA, FILE_CONFIG], mode)
	return file


static func delete_save(filename) -> int:
	var dir := Directory.new()
	var error := dir.open(PATH_SAVE)
	if error == OK:
		error = dir.remove(filename)
	
	return error


static func load_header(filename) -> SavedGame:
	var sg = SavedGame.new("%s/%s" % [PATH_SAVE, filename])
	sg.load_header()
	return sg


static func save_file(game : Spatial, filename) -> int:
	var sg = SavedGame.new("%s/%s" % [PATH_SAVE, filename], File.WRITE)
	if sg.get_error() != OK:
		return sg.get_error()
	
	var error = sg.save(game)
	sg.close()
	return error


static func load_file(filename) -> SavedGame:
	var sg = SavedGame.new("%s/%s" % [PATH_SAVE, filename])
	sg.load_game()
	
	return sg
