extends Node

# List of events
var events = []

# Track the in-game time (in seconds or any unit you prefer)
var current_time = 0.0
var time_increment = 1.0  # How much time passes per second (adjust as needed)

# Event class structure
class Event:
	var description: String
	var conditions = []  # Conditions list (resources, situations, time)
	var options = []  # Each option will have text and consequences
	var time_reset: float = -1.0  # Used for events that need to re-trigger periodically (set to -1 for one-time events)
	var next_time_trigger: float = -1.0  # Time when the event should next trigger (for recurring events)
	var completed: bool = false  # Track whether the event has been triggered already
	var priority: int  # Priority of the event

	# Constructor that accepts description, conditions, options, time_reset, and priority
	func _init(description: String, conditions: Array, options: Array, time_reset: float = -1.0, priority: int = 0):
		self.description = description
		self.conditions = conditions
		self.options = options
		self.time_reset = time_reset  # Optionally set the time reset (for periodic events)
		self.priority = priority  # Set event priority (default to 0 if not specified)
		self.completed = false

# Function to load events and resources on game start
func _ready():
	# Set up a timer to track in-game time
	set_process(true)
	
	# Define existing events with conditions, options, and priorities
	var event_1 = Event.new(
		"A strange traveler offers you a deal.",
		[{"type": "resource", "name": "Gold", "amount": 2}, {"type": "situation", "name": "outpost_built", "state": false}],
		[ 
			{"text": "Accept the deal", "consequences": [{"type": "resource", "name": "Gold", "amount": -50}, {"type": "resource", "name": "Knowledge", "amount": 10}]},
			{"text": "Refuse the deal", "consequences": [{"type": "resource", "name": "Knowledge", "amount": -5}]}
		],
		-1,  # No time reset, one-time event
		5  # Priority 5
	)
	
	var event_2 = Event.new(
		"You find an abandoned outpost.",
		[{"type": "resource", "name": "Wood", "amount": 100}],
		[
			{"text": "Take the wood", "consequences": [{"type": "resource", "name": "Wood", "amount": -100}, {"type": "situation", "name": "outpost_built", "state": true}]},
			{"text": "Leave it", "consequences": []}
		],
		-1,  # No time reset, one-time event
		3  # Priority 3
	)

	# New event with time condition and a time reset (1-5 seconds)
	var event_3 = Event.new(
		"A comet appears in the sky!",
		[{"type": "time", "value": 300}],  # First trigger after 1 second
		[
			{"text": "Wish upon the comet", "consequences": [{"type": "resource", "name": "Knowledge", "amount": 50}]},
			{"text": "Ignore it", "consequences": [{"type": "resource", "name": "Knowledge", "amount": 0}]}
		],
		randi_range(300, 600),  # Reset randomly every 5-10 seconds
		10  # Highest priority
	)

	# Add events to the event manager
	events.append(event_1)
	events.append(event_2)
	events.append(event_3)

	# Initialize time-based events with next trigger times
	for event in events:
		if event.time_reset > 0:
			event.next_time_trigger = current_time + event.time_reset

# Check conditions for events, including time, and prioritize events by priority
func check_events(passed: bool = false):
	# Sort events by priority (higher priority first)
	events.sort_custom(Callable(self, "_sort_by_priority"))

	for event in events:
		# Only trigger the event if conditions are met
		if not event.completed and not passed and check_conditions(event.conditions):
			trigger_event(event)
			# If the event has a higher priority, pass others below it
			return

# Custom sort function by event priority (higher priority first)
func _sort_by_priority(a: Event, b: Event) -> int:
	return b.priority - a.priority

# Check if event conditions are met (including time)
func check_conditions(conditions: Array) -> bool:
	for condition in conditions:
		if condition["type"] == "resource":
			if HandlerResources.ref.get_resource(condition["name"]) < condition["amount"]:
				return false
		elif condition["type"] == "situation":
			if HandlerResources.ref.situations[condition["name"]] != condition["state"]:
				return false
		elif condition["type"] == "time":
			# Check if the current in-game time has passed the required time condition
			if current_time < condition["value"]:
				return false
	return true

# Trigger the event popup when conditions are met
func trigger_event(event: Event):
	var event_popup = get_node("/root/Game/EventPopup")
	event_popup.show_event(event)

	# If the event has a time reset, update the time condition to re-trigger later
	if event.time_reset > 0:
		for condition in event.conditions:
			if condition["type"] == "time":
				condition["value"] = current_time + event.time_reset
				# Reset with a new random time if it's supposed to reoccur
				event.time_reset = randi_range(5, 10)

	# Mark the event as completed (one-time events will stop here)
	event.completed = true

# Process function to increment time and check events
func _process(delta):
	current_time += delta * time_increment  # Increment time based on delta and time increment rate

	# Check if any event with a time condition is ready to trigger
	for event in events:
		if event.time_reset > 0 and current_time >= event.next_time_trigger:
			event.completed = false  # Mark event as incomplete if time has passed its next trigger
			event.next_time_trigger = current_time + event.time_reset  # Reset the time for the next trigger
	
	check_events()  # Continuously check for events based on updated conditions
