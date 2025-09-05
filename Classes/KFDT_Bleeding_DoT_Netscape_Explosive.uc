class KFDT_Bleeding_DoT_Netscape_Explosive extends KFDT_Bleeding
	abstract;

defaultproperties
{
	//physics
	KDamageImpulse=0
    KDeathUpKick=0
    KDeathVel=0

	DoT_Type=DOT_Bleeding
	DoT_Duration=5.0
    DoT_Interval=1.0
    DoT_DamageScale=0.3
	bStackDoT=true

    BleedPower=150
}