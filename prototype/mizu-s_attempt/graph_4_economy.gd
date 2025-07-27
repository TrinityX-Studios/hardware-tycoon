extends Control


# Graph4Economy, for simulating economic competitions
# With Easy-charts: Pie Graph 
# See how many market shares earned from competitors

@onready var piechart: Chart = $VBoxContainer/Chart

var f1: Function

func _ready():
	
	# Prepare Values in an Array
	# This one goes to 100
	var x: Array = [24, 18, 19, 39]
	var y: Array = ["Intel Inc.", "Advanced Micro Devices, Corp.", "VIA Computers", "Motorolla Computing Ltd."]
	
	# Modify chart Properties
	var chartProps: ChartProperties = ChartProperties.new()
	chartProps.colors.frame = Color("#161a1d")
	chartProps.colors.background = Color.TRANSPARENT
	chartProps.colors.grid = Color("#283342")
	chartProps.colors.text = Color.WHITE_SMOKE
	chartProps.draw_bounding_box = false
	chartProps.title = "Market share of CPU products"
	chartProps.draw_grid_box = false
	chartProps.show_legend = true
	chartProps.interactive = true # Set to false or comment this code, it wont
									# respond to user input
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color.AQUAMARINE)
	gradient.set_color(1, Color.MAROON)
	
	f1 = Function.new(
		x, y, "",
		{
			gradient = gradient,
			type = Function.Type.PIE
		}
	)
	
	# Plot data
	piechart.plot([f1], chartProps)
	
	# Commenting the code below, will generate random data
	set_process(false)
	
var new_val: float = 5

func _process(delta: float) -> void:
	new_val += 5
	
	f1.add_point(new_val, cos(new_val) * 20)
	piechart.queue_sort()
	piechart.queue_redraw()
	

func _on_check_button_pressed() -> void:
	set_process(not is_processing())
