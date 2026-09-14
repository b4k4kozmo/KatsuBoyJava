@icon("res://assets/npc/oldman_down_01.png")
@tool
class_name NpcDialogue
extends Resource
## One conversation: the lines a character says in a single exchange, in order.
##
## A character with several of these cycles through them on repeat talks, the
## way the old man does - which is what makes a village feel written rather
## than recorded. The last one repeats forever once you reach it.
##
## Lines are wrapped for you now, so you do not have to count characters, but
## \n still forces a break where you want one.

## Optional note to yourself about when this conversation is for. Never shown
## in game; it is here so a list of six conversations is readable in the
## Inspector.
@export var label: String = ""

## The lines, in order. One press of Confirm moves to the next.
@export_multiline var lines: Array[String] = []


func is_empty() -> bool:
	return lines.is_empty()
