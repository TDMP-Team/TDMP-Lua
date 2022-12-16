#include "../tdmp/hooks.lua"
#include "../tdmp/ballistics.lua"
#include "../tdmp/utilities.lua"

TDMP_DefaultTools = TDMP_DefaultTools or {}

function InitHands()
	RegisterTool("tdmp_hands", "Hands", "vox/invis.vox", 1)
	SetBool("game.tool.tdmp_hands.enabled", true)
end

function HandsTickPly(ply)
	local body = PlayerBodies[ply.steamId]
	if not body or (ply.grabbed and ply.grabbed ~= 0) then return end

	TDMP_SetRightArmTarget(ply.steamId, {
		pos = ply:IsInputDown("rmb") and TransformToParentPoint(ply:GetCamera(), Vec(.5, 0, -1)) or TransformToParentTransform(body.Transform, Transform(ply:IsInputDown("lmb") and Vec(-.3 + .1*math.sin(GetTime()*10), 1.7, .4) or Vec(-.3, 0, .2))).pos
		-- bias = Transform(Vec(-.5, 1, .4))
	})

	TDMP_SetLeftArmTarget(ply.steamId, {
		pos = TransformToParentTransform(body.Transform, Transform(Vec(.35, 0, .2))).pos
		-- bias = Transform(Vec(-.5, 1, .4))
	})
end