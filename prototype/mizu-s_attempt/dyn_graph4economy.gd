extends Control

# Graph4Economy v2
# using Easy-charts: Pie Graph
# 
# Dynamically Processed

@onready var pChart: Chart = $VBoxContainer/Chart

var f1: Function

# Turn these into a member variable instead
# i dont think isolating these to only in a
# _ready() is a good idea
# for a proper dynamic graphing
var x_values: Array
var y_labels: Array
var chart_props: ChartProperties
var pie_gradient: Gradient

func _ready():
	# Prepare values in an array at start
	x_values = [24.0, 18.0, 19.0, 39.0]
	y_labels = ["Intel Inc.", "Advanced Micro Devices, Inc.", "VIA Computing Ltd.", "Motorola Computers Corporated"]
	
	# Set chart's properties
	chart_props = ChartProperties.new()
	chart_props.colors.frame = Color("#161a1d")
	chart_props.colors.background = Color.TRANSPARENT
	chart_props.colors.grid = Color("#283342")
	chart_props.colors.text = Color.WHITE_SMOKE
	chart_props.draw_bounding_box = false
	chart_props.title = "CPU Market shares"
	chart_props.draw_grid_box = false
	chart_props.show_legend = true
	chart_props.interactive = true
	
	pie_gradient = Gradient.new()
	pie_gradient.set_color(0, Color.AQUAMARINE)
	pie_gradient.set_color(1, Color.MAROON)
	
	f1 = Function.new(
		x_values, y_labels, "", # Use member vars
		{
			gradient = pie_gradient,
			type = Function.Type.PIE
		}
	)
	
	# Plot data
	pChart.plot([f1], chart_props)
	
	set_process(false)
	
# Keep track of company sales
var intel_share = 24.0
var amd_share = 18.0
var via_share = 19.0
var motorola_share = 39.0

func _process(delta: float) -> void:
	# Simulate changes using sin/cos for oscilation
	
	intel_share = 24.0 + sin(Time.get_ticks_msec() / 1000.0 * 0.8) * 5.0
	amd_share = 18.0 + cos(Time.get_ticks_msec() / 1000.0 * 0.7) * 4.0
	via_share = 19.0 + sin(Time.get_ticks_msec() / 1000.0 * 0.9) * 3.0
	motorola_share = 39.0 + cos(Time.get_ticks_msec() / 1000.0 * 0.6) * 6.0
	
	# Unify result
	var total_share_market = motorola_share + intel_share + amd_share + via_share
	
	# Avoid any division if the shares hit zero or the game engine would
	# freak out lmao
	if total_share_market > 0:
		x_values[0] = (intel_share/total_share_market) * 100.0
		x_values[1] = (amd_share/total_share_market) * 100.0
		x_values[2] = (via_share/total_share_market) * 100.0
		x_values[3] = (motorola_share/total_share_market) * 100.0
	else:
		x_values[0] = 25.0
		x_values[1] = 25.0
		x_values[2] = 25.0
		x_values[3] = 25.0

	# @Mizumo-prjkt
	# Uncomment if you want to check what's the issue
	# if you are done with it, recomment
	# because it will flood your Debug console and would eventually
	# lag your system lol
	# @end: Mizumo-prjkt
	#print("Values")
	#print("Total share report: ", total_share_market)
	#print("Intel: ", x_values[0])
	#print("AMD: ", x_values[1])
	#print("VIA: ", x_values[2])
	#print("MTD: ", x_values[3])
	
	f1 = Function.new(
		x_values, y_labels, "",
		{
			gradient = pie_gradient,
			type = Function.Type.PIE
		}
	)
	
	pChart.plot([f1], chart_props)
	
	# Replot the chart with new instance
	pChart.queue_redraw()
	
	

func _on_check_button_pressed() -> void:
	set_process(not is_processing())
	
