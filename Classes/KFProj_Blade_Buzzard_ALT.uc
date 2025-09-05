class KFProj_Blade_Buzzard_ALT extends KFProj_BallisticExplosive
	hidedropdown;

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=6000 //4000
	MaxSpeed=6000
	TerminalVelocity=6000
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000.0
    ArmDistSquared=0 // Arm instantly
	LifeSpan=8.0f

	ProjFlightTemplate=ParticleSystem'WEP_BladedPistol_EMIT.FX_bladed_projectile_01'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_BladedPistol_EMIT.FX_bladed_projectile_01'
	bCanDisintegrate=false

    AmbientSoundPlayEvent=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Bolt_Fly_By'
    AmbientSoundStopEvent=AkEvent'WW_WEP_HRG_Crossboom.Stop_WEP_HRG_Crossboom_Bolt_Fly_By'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=400.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=160 //90
		DamageRadius=200
		DamageFalloffExponent=2
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_BuzzardALT'

		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_SeekerSix_ARCH.FX_SeekerSix_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Shards
		ShardClass=class'KFProj_Blade_Buzzard_Shards'
		NumShards=7

		// Camera Shake
		CamShake=none
	End Object
	ExplosionTemplate=ExploTemplate0
}