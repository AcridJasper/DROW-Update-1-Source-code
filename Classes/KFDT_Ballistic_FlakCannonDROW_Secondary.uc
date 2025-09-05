class KFDT_Ballistic_FlakCannonDROW_Secondary extends KFDT_Ballistic_Rifle
	abstract
	hidedropdown;

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
	KDamageImpulse=2250
	KDeathUpKick=-400
	KDeathVel=250

    KnockdownPower=10
	StunPower=50
	StumblePower=200
	GunHitPower=150

	WeaponDef=class'KFWeapDef_FlakCannonDROW'
	ModifierPerkList(0)=class'KFPerk_Support'
}