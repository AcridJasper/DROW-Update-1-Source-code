class KFDT_Ballistic_FlakCannonDROW extends KFDT_Ballistic_Shotgun
	abstract
	hidedropdown;

// Allows the damage type to customize exactly which hit zones it can dismember
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

// Can't 'Spawn' in damage types
/*
static function PlayImpactHitEffects(KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator)
{
    local KFDroppedPickup_Cash SpawnedActor;

	SpawnedActor = Spawn(class'KFDroppedPickup_Cash', self,, HitLocation, Rotation,,true);
   	if (SpawnedActor != none)
   	{
   		SpawnedActor.SetPhysics(PHYS_Falling);
   	}
}
*/

defaultproperties
{
	BloodSpread=0.4
	BloodScale=0.6

	KDamageImpulse=3500
	KDeathUpKick=800 //600
	KDeathVel=650 //450
	GibImpulseScale=1.0
	
	//KDamageImpulse=160 //600 //350
	//KDeathUpKick=250 //350
	//KDeathVel=15 //20 

    StumblePower=45
	GunHitPower=50
	
	ModifierPerkList(0)=class'KFPerk_Support'
	WeaponDef=class'KFWeapDef_FlakCannonDROW'
}