extends Control
# Barchart
# An attempt by Mizumo-prjkt on how this plugin work

# @Mizumo-prjkt says:
# Personally, the level codebase would get messy if i
# proceeded with this goddamn idea, and i'm pretty sure
# im gonna get roasted by seasoned Godot devs
#
# Look, i've been in BaSh Programming, then Python, then C/C++
# then back at BaSh (with android modding), then Back at C/C++ (Kernel and 
# Recovery for Android), then Javascript, then Godot and GDScript
# and neating my code isn't my strongest suit
#
# Also 27/Jul/2025, listening to CloneClone by Atena
# Also i just realized that easychart prefers float.
# @end: Mizumo-prjkt, 27/Jul/2025:18:17

# @Mizumo-prjkt
# When adding chart as a UI component, do this
# After adding Chart, right click on that, then "Instantiate Child Scene"
# so the component would work
#
# Holy frick, after few hours of Brainstorming how the hell does this work
# I realized you have to do that or else, you get a freaking error messages
# flooded in the Debugger
#
# Also the Wiki page is also incomplete, so you can't fully blame me on the
# incompetence
# Maybe i should try to help with their wiki??? Idk?
# @end: Mizumo-prjkt, 27/Jul/2025:22:06

@onready var mizuChart: Chart = $VBoxContainer/Chart

var f1: Function

func _ready() -> void:
	var x: Array = ["Day 1", "Day 2", "Day 3", "Day 4"]
	
	# Referring to money
	var y: Array = [10, 5, 6, 8]
	
	# @Mizumo-prjkt says:
	# No i dont call the variable 'cp'
	# See: res://addons/easy_charts/examples/bar_chart/Control.gd
	# line: 18 (ironic)
	# @end: Mizumo-prjkt
	var chartprops: ChartProperties = ChartProperties.new()
	chartprops.colors.frame = Color("#16191d")
	chartprops.colors.background = Color.TRANSPARENT
	chartprops.colors.grid = Color("#283442")
	chartprops.colors.ticks = Color("#283442")
	chartprops.colors.text = Color.WHITE_SMOKE
	chartprops.y_scale = 50
	chartprops.draw_origin = true
	chartprops.draw_bounding_box = false
	chartprops.draw_vertical_grid = false
	# If true, user can allow intercept the chart data by clicking on the plot
	chartprops.interactive = true 
	
	f1 = Function.new(
		x, y, "User",
		{
			# @Mizumo-prjkt says
			# Use Bar Graph
			# Damn i almost added the variables quotes
			# JSON ahh
			# @end: Mizumo-prjkt
			type = Function.Type.BAR,
			bar_size = 5
		}
	)
	
	# Chart Plot
	# Pass the Function instructions and the styling
	mizuChart.plot([f1], chartprops)
	
	# Comment this line if you want the bar to display automatically
	set_process(false)
	
var new_val: float = 29

func _process(delta: float) -> void:
	
	# Add 5 in the newval
	new_val += 5
	
	# Add function.add_point instruction
	# to update data
	f1.add_point(new_val, cos(new_val) * 27)
	mizuChart.queue_redraw()
	

func _on_check_button_pressed() -> void:
	set_process(not is_processing())
