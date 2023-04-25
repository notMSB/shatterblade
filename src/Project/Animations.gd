extends Node2D

var animList = {
	"Slash": {"texture": "MGC_Slash_1"},
	"Dark": {"texture": "FireBall-Purple-Complete", "scale": Vector2(20,20), "speed": 5, "varia": true},
	"Poison": {"texture": "MGC_W3_BloodExplosion_Dome", "scale": Vector2(50,50), "speed": 1, "color": Color.green},
}

func set_params(animNode, animName, variaAngle = null):
	var animationPath = "res://effects/" + animList[animName]["texture"] + ".efkefc"
	animNode.effect = ResourceLoader.load(animationPath)
	
	if animList[animName].has("scale"): animNode.scale = animList[animName]["scale"]
	else: animNode.scale = Vector2(10,10)
	
	if animList[animName].has("speed"): animNode.speed = animList[animName]["speed"]
	else: animNode.speed = 2
	
	if animList[animName].has("varia"): animNode.orientation.z = variaAngle
	else: animNode.orientation.z = 0
	
	if animList[animName].has("color"): animNode.color = animList[animName]["color"]
	else: animNode.color = Color(1,1,1,1)
