class KFDT_Ballistic_ArcaTrinitron extends KFDT_Ballistic_Shotgun
	abstract
	hidedropdown;

/** Allows the damage type to customize exactly which hit zones it can dismember */
static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
	if( super.CanDismemberHitZone( InHitZoneName ) )
	{
		return true;
	}

	switch ( InHitZoneName )
	{
		case 'lupperarm':
		case 'rupperarm':
		case 'chest':
		case 'heart':
	 		return true;
	}

	return false;
}

defaultproperties
{
	BloodSpread=0.4
	BloodScale=0.6

	KDamageImpulse=2000
	KDeathUpKick=-500
	KDeathVel=500

    KnockdownPower=0
	StumblePower=100
	GunHitPower=300
	EMPPower=35 //50 100

	WeaponDef=class'KFWeapDef_ArcaTrinitron'
}