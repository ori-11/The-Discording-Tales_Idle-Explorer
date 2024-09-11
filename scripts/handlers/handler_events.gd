extends Node

# List of events
var events = []

# Event class structure
class Event:
	var description: String
	var conditions = []  # Conditions list (resources, situations)
	var options = []  # Each option will have text and consequences

	# Constructor that accepts the description, conditions, and options
	func _init(description: String, conditions: Array, options: Array):
		self.description = description
		self.conditions = conditions
		self.options = options

# Function to load events and resources on game start
func _ready():
	# Define an event with conditions and options
	var event_1 = Event.new(
		"A strange traveler offers you a deal. Take it dammit I can't stay here for long you n'wah! I despise you",
		[{"type": "resource", "name": "Gold", "amount": 2}, {"type": "situation", "name": "outpost_built", "state": false}],
		[
			{"text": "Accept the deal", "consequences": [{"type": "resource", "name": "Gold", "amount": -50}, {"type": "resource", "name": "Knowledge", "amount": 10}]},
			{"text": "Refuse the deal", "consequences": [{"type": "resource", "name": "Knowledge", "amount": -5}]}
		]
	)
	
	var event_2 = Event.new(
		"You find an abandoned outpost.",
		[{"type": "resource", "name": "Wood", "amount": 100}],
		[
			{"text": "Take the wood", "consequences": [{"type": "resource", "name": "Wood", "amount": -100}, {"type": "situation", "name": "outpost_built", "state": true}]},
			{"text": "Leave it", "consequences": []}
		]
	)

	# Add events to the event manager
	events.append(event_1)
	events.append(event_2)

# Check conditions for events
func check_events():
	for event in events:
		if check_conditions(event.conditions):
			trigger_event(event)

# Check if event conditions are met
func check_conditions(conditions: Array) -> bool:
	for condition in conditions:
		if condition["type"] == "resource":
			if HandlerResources.ref.get_resource(condition["name"]) < condition["amount"]:
				return false
		elif condition["type"] == "situation":
			# Assuming you have another system managing situations (similar to HandlerResources)
			if HandlerResources.ref.situations[condition["name"]] != condition["state"]:
				return false
	return true

# Trigger the event popup when conditions are met
func trigger_event(event: Event):
	var event_popup = get_node("/root/Game/EventPopup")
	event_popup.show_event(event)
