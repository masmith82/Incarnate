extends Skills_Library
class_name Bloodthane_Skills

var skill_list = {	PASS	:	preload("res://skills/Bloodthane/bound_in_blood.tres"),
					MOVE	:	preload("res://skills/basic_move.tres"),
					BASIC	:	preload("res://skills/Bloodthane/blade_fury.tres"),
					HEAVY	:	null,
					AREA	:	preload("res://skills/Bloodthane/bloody_rush.tres"),
					DEF		:	preload("res://skills/Bloodthane/acute_coagulant.tres"),
					MNVR	:	preload("res://skills/Bloodthane/verve_magnet.tres"),
					UTIL	:	preload("res://skills/Bloodthane/adrenaline_surge.tres"),
					ULT		:	null,
					}

var bt_heavy_1 = {"name" : "Reaving Claws",
	"icon" : "res://GFX/Units/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 2,
	"tt" : "Big attack",
	"func" : Callable(self, "-----")
	}

var bt_ult_1 = {"name" : "Bloodlust",
	"icon" : "res://GFX/Units/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 0,
	"tt" : "Here's a tooltip.",
	"func" : Callable(self, "-----")
	}
