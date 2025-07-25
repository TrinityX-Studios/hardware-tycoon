extends Control

@onready var optionsContainer = $OptionsContainer
@onready var moneyUIBelow = $HBoxContainer/Money
@onready var researchUIBelow = $HBoxContainer/Research
@onready var daysUIBelow = $HBoxContainer/Days
@onready var tealUIBG = $TealUIBG
@onready var confirmLeave = $ConfirmwindowLeave
@onready var gameplaycomp = $GameplayComponents

func _on_button_pressed() -> void:
	print("Showing up the Menu")
	#get_tree().change_scene_to_file("res://main_menu.tscn")
	optionsMenu_Window()
	

func tealUICall() -> void:
	if tealUIBG.visible == true:
#		Assume that the call was meant to hide the UI cover
		tealUIBG.hide()
	else:
		tealUIBG.show()

func optionsMenu_Window() -> void:
	if optionsContainer.visible == true:
		tealUICall()
		optionsContainer.hide()
	else:
		tealUICall()
		optionsContainer.show()
		

func _on_close_options_pressed() -> void:
	optionsMenu_Window()

func confirm2menu_ok2call() -> bool:
	if confirmLeave.visible == true:
		return false
	else:
		return true
		
func summonconfirm() -> void:
	# Check if Its ok to summon the popup
	if confirm2menu_ok2call() == true:
		confirmLeave.show()
	else:
		print("It is already being summoned")

func _on_main_menu_go_pressed() -> void:
	summonconfirm()


func _on_confirm_leave_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_go_back_pressed() -> void:
#	From confirm exit
	if confirm2menu_ok2call() == false:
		confirmLeave.hide()
		
		

func on_check_actions_ok2summon() -> bool:
	if gameplaycomp.visible == true:
		return false
	else:
		return true

func _on_actions_pressed() -> void:
	if on_check_actions_ok2summon() == true:
		gameplaycomp.show()
	else:
		gameplaycomp.hide()
		


func _on_close_pressed() -> void:
#	This is on the GameplayComp
	if on_check_actions_ok2summon() == false:
		gameplaycomp.hide()
	else:
		print("Wait, how did you do that?")
