class KFDT_Ballistic_AA12_Dual extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=5
	StumblePower=15
	GunHitPower=50

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_AA12_Dual'
}