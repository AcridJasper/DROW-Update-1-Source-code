class KFDT_Toxic_DoT_Netscape extends KFDT_Toxic
	abstract;

// static function bool AlwaysPoisons()
// {
// 	return true;
// }

defaultproperties
{
	// DoT_Type=DOT_None
	DoT_Type=DOT_Toxic
	DoT_Duration=5.0
	DoT_Interval=1.0
	DoT_DamageScale=0.3 //0.5
	bStackDoT=true

	bIgnoreSelfInflictedScale=true
    bNoInstigatorDamage=true

	PoisonPower=200 //100
}