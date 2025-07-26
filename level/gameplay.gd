extends Control

@onready var optionsContainer = $OptionsContainer
@onready var moneyUIBelow = $HBoxContainer/Money
@onready var researchUIBelow = $HBoxContainer/Research
@onready var daysUIBelow = $HBoxContainer/Days
@onready var tealUIBG = $TealUIBG
@onready var confirmLeave = $ConfirmwindowLeave
@onready var gameplaycomp = $GameplayComponents
@onready var newCPU_UI = $CreateCPUCoreUI
@onready var productUserEntryBox_Brand = $NameBrandCPU/ProductUserEntry_B
@onready var NameBrandCPUDialog = $NameBrandCPU
@onready var productUserEntryBox_Series = $NameSeriesCPU/ProductUserEntry_S
@onready var NameSeriesCPUDialog = $NameSeriesCPU
@onready var accountancy_window = $Accountancy




func _ready() -> void:
	if productUserEntryBox_Brand != null:
		print("DEBUG: Type of TextBox: ", productUserEntryBox_Brand.get_class())
		productUserEntryBox_Brand.max_length = 15
		print("Sucessfully limit entry to 15")

func _on_button_pressed() -> void:
	print("Showing up the Menu")
	#get_tree().change_scene_to_file("res://main_menu.tscn")
	optionsMenu_Window()
#	Set all buttons to not work
	$Actions.disabled = true
	$HBoxContainer/Money.disabled = true
	$HBoxContainer/Research.disabled = true
	$HBoxContainer/Days.disabled = true
	

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
		$Actions.disabled = false
		$HBoxContainer/Money.disabled = false
		$HBoxContainer/Research.disabled = false
		$HBoxContainer/Days.disabled = false
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

func checkifCPU_CORE_UI_can_be_summoned() -> bool:
	if newCPU_UI.visible == true:
		return false
	else:
		return true

func _on_create_cpu_pressed() -> void:
	# When creating a new cpu
	# Actions > CreateCPU
	if checkifCPU_CORE_UI_can_be_summoned() == true:
		newCPU_UI.show()
		gameplaycomp.hide() # Hide the selection
	else:
		print("It's already showing...")


func _on_close_cpu_creation_pressed() -> void:
	# on CPU creation
	if checkifCPU_CORE_UI_can_be_summoned() == false:
		newCPU_UI.hide()
	else:
		print("It's already hidden")


func _on_cpu_change_name_btn_pressed() -> void:
#	CreateCPUCoreUI
	if NameBrandCPUDialog.visible == true:
		NameBrandCPUDialog.move_to_center()
		NameBrandCPUDialog.grab_focus()
	else:
		NameBrandCPUDialog.show()
		NameBrandCPUDialog.move_to_center()
		NameBrandCPUDialog.grab_focus()


func _on_cancel_prod_name_b_pressed() -> void:
	if NameBrandCPUDialog.visible == true:
		productUserEntryBox_Brand.clear()
		NameBrandCPUDialog.hide()


func _on_clear_textbox_b_pressed() -> void:
	print("Being called")
	if productUserEntryBox_Brand.text != null:
		productUserEntryBox_Brand.clear()


func _on_series_change_name_btn_2_pressed() -> void:
	if NameSeriesCPUDialog.visible == false:
		NameSeriesCPUDialog.show()
		NameSeriesCPUDialog.move_to_center()
		NameSeriesCPUDialog.grab_focus()
	else:
		NameSeriesCPUDialog.move_to_center()
		NameSeriesCPUDialog.grab_focus()


func _on_clear_textbox_s_pressed() -> void:
	if productUserEntryBox_Series.text != null:
		productUserEntryBox_Series.clear()



func _on_cancel_prod_name_s_pressed() -> void:
	if NameSeriesCPUDialog.visible == true:
		productUserEntryBox_Series.clear()
		NameSeriesCPUDialog.hide()


func _on_name_brand_cpu_close_requested() -> void:
	if NameBrandCPUDialog.visible == true:
		productUserEntryBox_Brand.clear()
		NameBrandCPUDialog.hide()


func _on_name_series_cpu_close_requested() -> void:
	if NameSeriesCPUDialog.visible == true:
		productUserEntryBox_Series.clear()
		NameSeriesCPUDialog.hide()
		


func _on_money_pressed() -> void:
	if accountancy_window.visible == false:
		accountancy_window.show()
		accountancy_window.move_to_center()
		accountancy_window.grab_focus()
	else:
		accountancy_window.hide()
