extends Control

# --- Reference your EasyCharts Nodes ---
# Make sure these paths exactly match where your chart nodes are in the scene tree.
@onready var my_bar_chart = $Chart
@onready var my_line_chart = $Chart2
@onready var my_pie_chart = $Chart3

func _ready():
	print("Setting up EasyCharts...")
	setup_bar_chart()
	setup_line_chart()
	setup_pie_chart()


func setup_bar_chart():
	if not my_bar_chart:
		printerr("Error: MyBarChart node not found!")
		return

	# --- 1. Basic Bar Chart ---
	print("Setting up Bar Chart...")

	# The data values for each bar
	var bar_values = [150.0, 220.0, 180.0, 300.0, 90.0, 250.0]
	# Labels for each bar (e.g., months, categories)
	var bar_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
	# Optional: Colors for each bar. If not provided, EasyCharts uses default colors.
	var bar_colors = [
		Color("red"),
		Color("green"),
		Color("blue"),
		Color("orange"),
		Color("purple"),
		Color("teal")
	]

	# Assign the data to the chart's properties
	my_bar_chart.chart_data = bar_values
	my_bar_chart.chart_labels = bar_labels
	my_bar_chart.chart_colors = bar_colors # Optional
	# You might also set other properties like 'title', 'show_values', etc.
	my_bar_chart.title = "Monthly Revenue"
	my_bar_chart.show_values = true
	my_bar_chart.y_axis_label = "Amount ($)"
	my_bar_chart.x_axis_label = "Month"
	print("Bar Chart setup complete.")


func setup_line_chart():
	if not my_line_chart:
		printerr("Error: MyLineChart node not found!")
		return

	# --- 2. Basic Line Chart ---
	print("Setting up Line Chart...")

	# Data for the line chart (Y-values, X-values often assumed as index 0, 1, 2...)
	# For EasyCharts, 'chart_data' often expects an Array of floats or Vector2 points.
	# Let's assume an array of floats for Y-values, and X-values are implied steps.
	var line_values = [10.0, 12.5, 11.0, 14.2, 13.0, 15.5, 17.0, 16.8]
	var line_labels = ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7", "Day 8"]
	var line_color = Color("cyan") # Single color for the line

	my_line_chart.chart_data = line_values
	my_line_chart.chart_labels = line_labels
	# EasyCharts may have a specific property for line color, check its docs/inspector
	my_line_chart.line_color = line_color # Assuming 'line_color' property exists
	my_line_chart.title = "Daily Player Count"
	my_line_chart.show_points = true # Show markers at data points
	my_line_chart.y_axis_label = "Players"
	my_line_chart.x_axis_label = "Day"
	print("Line Chart setup complete.")


func setup_pie_chart():
	if not my_pie_chart:
		printerr("Error: MyPieChart node not found!")
		return

	# --- 3. Basic Pie Chart ---
	print("Setting up Pie Chart...")

	# Data for the pie chart (proportions/counts)
	var pie_values = [30.0, 20.0, 50.0] # Sum can be 100 or any total
	# Labels for each slice
	var pie_labels = ["Wood", "Stone", "Iron"]
	# Colors for each slice (crucial for pie charts)
	var pie_colors = [
		Color("brown"),
		Color("gray"),
		Color("silver")
	]

	my_pie_chart.chart_data = pie_values
	my_pie_chart.chart_labels = pie_labels
	my_pie_chart.chart_colors = pie_colors # Essential for pie slices
	my_pie_chart.title = "Resource Distribution"
	my_pie_chart.show_values = true # Show numerical values on slices
	my_pie_chart.show_percentage = true # Show percentage on slices
	print("Pie Chart setup complete.")


# --- Example: Updating a chart dynamically ---
func update_bar_chart_data(new_values: Array[float]):
	if my_bar_chart:
		my_bar_chart.chart_data = new_values
		# If labels or colors need to change, update them too
		# my_bar_chart.chart_labels = new_labels
		print("Bar Chart data updated dynamically.")

# Example function to be called from another script or a timer
func _on_some_event_to_update_charts():
	var new_bar_data = [50, 100, 75, 120, 60, 150]
	update_bar_chart_data(new_bar_data)

	# Update pie chart for example
	var new_pie_data = [40, 30, 30]
	var new_pie_labels = ["Wood (updated)", "Stone (updated)", "Iron (updated)"]
	if my_pie_chart:
		my_pie_chart.chart_data = new_pie_data
		my_pie_chart.chart_labels = new_pie_labels
		print("Pie Chart data updated dynamically.")
