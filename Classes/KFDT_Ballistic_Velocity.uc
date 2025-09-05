class KFDT_Ballistic_Velocity extends KFDT_Ballistic_Submachinegun
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	StumblePower=10
	GunHitPower=20
	FreezePower=11 //17
	EffectGroup=FXG_Freeze

	WeaponDef=class'KFWeapDef_Velocity'
	ModifierPerkList(0)=class'KFPerk_SWAT'
}