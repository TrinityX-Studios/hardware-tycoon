# Main Menu script
# Fun fact:
# @Mizumo-prjkt is upset about the Anchors, too confusing for him

extends Control

@onready var MOTD_HOLDER = $MOTD

func _ready() -> void:
	print_motd_service()

func print_motd_service() -> void:
	# Checks if MOTD has content
	if check_if_motd_has_text() == false:
		random_and_print_motd()
	else:
		clear_motd()
		random_and_print_motd()
		

func check_if_motd_has_text() -> bool:
	if MOTD_HOLDER != null:
		print("Text not empty")
		return true
	else:
		return false

func clear_motd() -> void:
	print("Clearing MOTD")
	MOTD_HOLDER.set_text("")

func random_and_print_motd() -> void:
	randomize()
	var arrayMotd = ["Always in development", "Make some CPU!", "Hot Chips from the oven!", "Godot is the Best", "E-cores? What's that?"]
	var result = randi_range(0, arrayMotd.size() - 1)
	MOTD_HOLDER.add_text(arrayMotd[result])
	

func _on_play_pressed() -> void:
#	# This is temporary, after that, just comment the dummy code
	print("Pressed Play")
	get_tree().change_scene_to_file("res://level/gameplay.tscn")


func _on_settings_pressed() -> void:
	print("Settings Pressed")
	get_tree().change_scene_to_file("res://settings.tscn")


func _on_quit_pressed() -> void:
	print("Quit Pressed")
	get_tree().quit();


func _on_easter_chart_pressed() -> void:
	# get_tree().change_scene_to_file("res://addons/easy_charts/examples/bar_chart/Control.tscn")
	get_tree().change_scene_to_file("res://prototype/mizu-s_attempt/graphline.tscn")
