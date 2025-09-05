class KFDT_Freeze_GalvanizedCypressThree_Grenade_Impact extends KFDT_Freeze
	abstract;

defaultproperties
{
	KDamageImpulse=1000
	KDeathUpKick=700
	KDeathVel=350

	StumblePower=50
	GunHitPower=150 //100

	FreezePower=5 //0

	WeaponDef=class'KFWeapDef_GalvanizedCypressThree'

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
}