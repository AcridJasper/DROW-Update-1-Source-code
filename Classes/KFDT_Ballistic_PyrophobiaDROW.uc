class KFDT_Ballistic_PyrophobiaDROW extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=20
	StumblePower=30
	GunHitPower=100

	ModifierPerkList(0)=class'KFPerk_Firebug'
	WeaponDef=class'KFWeapDef_PyrophobiaDROW'
}