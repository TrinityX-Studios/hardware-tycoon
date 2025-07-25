extends Control

# Initializes Window
@onready var aboutPopup = $AboutWindowPopup

func _ready() -> void:
	aboutPopup.hide()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_about_menu_press_pressed() -> void:
	if aboutPopup.visible == true :
		print("Is already shown, but hiding it now as fallback")
		aboutPopup.hide()
	else:
		aboutPopup.show()

func _on_about_window_popup_close_requested() -> void:
	aboutPopup.hide()
