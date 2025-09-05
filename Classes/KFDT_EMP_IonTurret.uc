class KFDT_EMP_IonTurret extends KFDT_EMP
	abstract
	hidedropdown;

var ParticleSystem ForceImpactEffect;
var AkEvent ForceImpactSound;

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
			SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
		}
	}
}

defaultproperties
{
    KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	//StumblePower=15
	EMPPower=10 //9 5
	GunHitPower=5
	
	// GoreDamageGroup=DGT_EMP
	// EffectGroup=FXG_Electricity

	ForceImpactEffect=ParticleSystem'WEP_HVStormCannon_EMIT.FX_HVStormCannon_Impact_Zed'
	ForceImpactSound=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Impact'

	WeaponDef=class'KFWeapDef_Grenade_IonTurret'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
}