extends Control

# Onready Vars
@onready var OptPanelUI = $OptPanel
@onready var ResumeGameProgress = $OptPanel/ResumeBtn


# UI Elements and Interactivity within the Game
func _on_option_summon_menu_pressed() -> void:
	print("Options Summon Menu Pressed")
	# Pause gameplay logic should be added tbh
	if OptPanelUI.visible  == false:
		OptPanelUI.show()
	else:
		OptPanelUI.hide()
		

func _on_resume_btn_pressed() -> void:
	print("Going back to Main UI gameplay")
	# Resume Gameplay logic should be added tbh
	if OptPanelUI.visible == true:
		OptPanelUI.hide()
	else:
		print("Bruh... Har har har har")
	
