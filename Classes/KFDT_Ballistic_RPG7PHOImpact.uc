class KFDT_Ballistic_RPG7PHOImpact extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=200
	StumblePower=340
	GunHitPower=275

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	WeaponDef=class'KFWeapDef_RPG7_PHO'
}