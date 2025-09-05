class KFDT_Ballistic_NorthFleetDROW extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=30
	StumblePower=50
	GunHitPower=200

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	// ModifierPerkList(1)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_NorthFleetDROW'
}