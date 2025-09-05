class KFProj_Blade_Buzzard extends KFProj_RicochetStickBulletNoPickup
	hidedropdown;

simulated function bool ShouldProcessBulletTouch()
{
	return BouncesLeft > 0 && GravityScale == default.GravityScale;
}

defaultproperties
{
	Physics=PHYS_Falling
	MaxSpeed=5000 //4000
	Speed=5000
	GravityScale=0.1 //0.75

	DamageRadius=0

	bWarnAIWhenFired=true

    BouncesLeft=3 //2
    DampingFactor=0.8 //0.95
    RicochetEffects=KFImpactEffectInfo'WEP_BladedPistol_ARCH.BladedImpacts'
    LifeSpan=8
    LifeSpanAfterStick=12

	Begin Object Name=CollisionCylinder
		CollisionRadius=6
		CollisionHeight=2
	End Object

	// Additional zero-extent line traces
	ExtraLineCollisionOffsets.Add((Y=-16))
	ExtraLineCollisionOffsets.Add((Y=16))
	ExtraLineCollisionOffsets.Add((Z=-6))
	ExtraLineCollisionOffsets.Add((Z=6))
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())

    bAmbientSoundZedTimeOnly=false
	bNoReplicationToInstigator=false
	bUseClientSideHitDetection=true
	bUpdateSimulatedPosition=true
	bRotationFollowsVelocity=false
	bNetTemporary=False

	ProjFlightTemplate=ParticleSystem'WEP_BladedPistol_EMIT.FX_bladed_projectile_01'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_BladedPistol_EMIT.FX_bladed_projectile_01'

	ImpactEffects=KFImpactEffectInfo'WEP_BladedPistol_ARCH.BladedEmbedFX'

	AmbientSoundPlayEvent=AkEvent'WW_WEP_BladedPistol.Play_WEP_BladedPistol_Projectile_Loop'
	AmbientSoundStopEvent=AkEvent'WW_WEP_BladedPistol.Stop_WEP_BladedPistol_Projectile_Loop'

    TouchTimeThreshhold=0.15
}