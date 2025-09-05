class KFDT_GroundEMP_ZapField extends KFDT_EMP;
	//abstract;

defaultproperties
{
	//return `DAMZ_Freeze;
	//return `KILL_Freeze;

	WeaponDef=class'KFWeapDef_Zap'

    // DoT
	DoT_Type=DOT_None // don't disturb the zed
	DoT_Duration=2.0
	DoT_Interval=0.5
	DoT_DamageScale=0.4

	bIgnoreSelfInflictedScale=true

	EMPPower=12
}