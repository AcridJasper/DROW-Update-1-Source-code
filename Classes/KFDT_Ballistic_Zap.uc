class KFDT_Ballistic_Zap extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=50 //40
	StumblePower=100  //70
	GunHitPower=70  //55

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_Zap'
}