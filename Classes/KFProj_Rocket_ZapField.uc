class KFProj_Rocket_ZapField extends KFProj_BallisticExplosive;

/** Explosion actor class to use for ground fire */
var const protected class<KFExplosionActorLingering> GroundFireExplosionActorClass;
/** Explosion template to use for ground fire */
var KFGameExplosion GroundFireExplosionTemplate;

/** How long the ground fire should stick around */
var const protected float BurnDuration;
/** How often, in seconds, we should apply burn */
var const protected float BurnDamageInterval;

var bool bSpawnGroundFire;

replication
{
	if (bNetInitial)
		bSpawnGroundFire;
}

// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	local KFWeap_Zap Cannon;

	if (Role == ROLE_Authority)
	{
		Cannon = KFWeap_Zap(Owner);
		if (Cannon != none)
		{
			bSpawnGroundFire = true;
		}
	}

	Super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFExplosionActorLingering GFExplosionActor;
	local vector GroundExplosionHitNormal;

	if (bHasDisintegrated)
	{
		return;
	}

	if (!bHasExploded && bSpawnGroundFire)
	{
		GroundExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(GroundFireExplosionActorClass, self, , HitLocation + (HitNormal * 32.f), rotator(HitNormal));
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			GroundFireExplosionTemplate.HitLocation = HitLocation;
			GroundFireExplosionTemplate.HitNormal = GroundExplosionHitNormal;

			// Apply explosion direction
			if (GroundFireExplosionTemplate.bDirectionalExplosion)
			{
				GroundExplosionHitNormal = GetExplosionDirection(GroundExplosionHitNormal);
			}

			// Set our duration
			GFExplosionActor.MaxTime = BurnDuration;

			// Set our burn interval
			GFExplosionActor.Interval = BurnDamageInterval;

			// Boom
			GFExplosionActor.Explode(GroundFireExplosionTemplate, GroundExplosionHitNormal);
		}
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

// Don't spawn ground fire if projectile hits pawn (zeds)
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (ClassIsChildOf(Other.class, class'KFPawn'))
	{
		bSpawnGroundFire = false;
	}

	super.ProcessTouch(Other, HitLocation, HitNormal);
}

// Trace down and get the location to spawn the explosion effects and decal
simulated function GetExplodeEffectLocation(out vector HitLocation, out vector HitRotation, out Actor HitActor)
{
    local vector EffectStartTrace, EffectEndTrace;
	local TraceHitInfo HitInfo;

	EffectStartTrace = Location + vect(0,0,1) * 4.f;
	EffectEndTrace = EffectStartTrace - vect(0,0,1) * 32.f;

    // Find where to put the decal
	HitActor = Trace(HitLocation, HitRotation, EffectEndTrace, EffectStartTrace, false,, HitInfo, TRACEFLAG_Bullet);

	// If the locations are zero (probably because this exploded in the air) set defaults
    if (IsZero(HitLocation))
    {
        HitLocation = Location;
    }

	if (IsZero(HitRotation))
    {
        HitRotation = vect(0,0,1);
    }
}

// Ignore damage over time for ice floor
simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	GroundFireExplosionTemplate.bIgnoreInstigator = true;
}

// Can be overridden in subclasses to exclude specific projectiles from nuking
simulated function bool AllowNuke()
{
    return false;
}

defaultproperties
{
	Physics=PHYS_Projectile
    MaxSpeed=8000
	Speed=8000
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000
	LifeSpan=17.f

	// Ground electricity
	BurnDuration=15.f // 10 seconds
	BurnDamageInterval=0.5f // 2.5x
	GroundFireExplosionActorClass=class'KFExplosion_Zap_GroundEMP'

	// Collisions for ground fire
	Begin Object Name=CollisionCylinder
		CollisionRadius=12 //6
		CollisionHeight=6
	End Object
	ExtraLineCollisionOffsets.Add((Y=-12))
	ExtraLineCollisionOffsets.Add((Y=12)) // 8
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())
	
	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Zap_Rocket'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_Zap_Rocket'

    bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=1000.f
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
		Damage=80 // 100
	    DamageRadius=300 //200
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Zap'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=200
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0

	// Ground fire light
	Begin Object Class=PointLightComponent Name=FlamePointLight
		LightColor=(R=,G=171,B=200,A=255)
		Brightness=4.f
		Radius=400.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// Ground EMP
	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=40 //10
		DamageRadius=220 //300
		DamageFalloffExponent=1.f
		DamageDelay=0.f

        bIgnoreInstigator=true // don't passively kill player
		MomentumTransferScale=1
		bDirectionalExplosion=true // rotate fire effect based on angle ( don't, rotate effect inside sdk for wall and ceiling )

		// Damage Effects
		MyDamageType=class'KFDT_GroundEMP_ZapField' // it should - continuously hurt zed then emp him and repeat
		KnockDownStrength=0
		FractureMeshRadius=0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_GroundFire' // ground fire effect is inside KFExplosion_Zap_GroundEMP

		// Camera Shake
		CamShake=none
	End Object
	GroundFireExplosionTemplate=ExploTemplate1
}