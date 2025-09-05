class KFDT_Ballistic_NetscapeALT extends KFDT_Ballistic_Rifle
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=2250
	KDeathUpKick=-400
	KDeathVel=250

    KnockdownPower=5
	StunPower=20 //40 //8
	StumblePower=100
	GunHitPower=300 //50

	WeaponDef=class'KFWeapDef_Netscape'
	ModifierPerkList(0)=class'KFPerk_Commando'
	ModifierPerkList(1)=class'KFPerk_Swat'
}