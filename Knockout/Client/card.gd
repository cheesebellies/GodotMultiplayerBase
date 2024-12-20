class_name Card

var number: int
var suit: int

func _init(number: int, suit: int):
	self.number = number
	self.suit = suit

func _to_string():
	return str(number) + ":" + str(suit)
