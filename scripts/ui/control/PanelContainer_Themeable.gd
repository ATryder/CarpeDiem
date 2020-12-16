extends PanelContainer
class_name PanelContainer_Themeable


func _ready():
	if Opts.theme != Opts.THEME_LIGHT:
		change_theme(Opts.THEME_LIGHT, Opts.theme)


func change_theme(oldTheme, newTheme):
	add_stylebox_override("panel", CD.get_window_background_style(false, Opts.theme))
