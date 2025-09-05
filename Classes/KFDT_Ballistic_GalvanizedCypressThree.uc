class KFDT_Ballistic_GalvanizedCypressThree extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	//KnockdownPower=50 //40
	StumblePower=100
	GunHitPower=40

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_GalvanizedCypressThree'
}