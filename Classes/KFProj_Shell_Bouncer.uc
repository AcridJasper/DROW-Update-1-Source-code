class KFProj_Shell_Bouncer extends KFProj_Nail_Nailgun
    hidedropdown;

/*
// Number of projectiles to spawn when projectile hits environment or a pawn before reaching max
var() int ResidualFlamesInExplosion;
// Cone Angle to determine residual flame directions
var float ResidualFlameHalfConeAngle;
// Impulse modiffier apply to residual forces
var float ResidualFlameForceMultiplier;
// Class for spawning residual flames
var class<KFProjectile> ResidualFlameProjClass;
// (Computed) Last Velocity from Explode()
var vector LastVelocity;
*/

// Number of lingering flames to spawn when projectile hits environment or a pawn before reaching max
var() int AmountResidualFlamesInExplosion;
// Offset added to the final velocity computed for residual flames in explosion
var vector OffsetVelocityResidualFlamesInExplosion;
// Magnitude to multiply velocity computed for residual flames in explosion
var float MagnitudeVelocityResidualFlamesInExplosion;
// Class for spawning residual flames 
var class<KFProjectile> ResidualFlameProjClass;
// (Computed) Last Velocity from Explode()
var vector LastVelocity;

// Cone Angle to determine residual flame directions
var float ResidualFlameHalfConeAngle;
// Impulse modiffier apply to residual forces
var float ResidualFlameForceMultiplier;

// Visual component of this projectile
var StaticMeshComponent ChargeMesh;

var() float SecondsBeforeDetonation;
var() bool bIsProjActive;

// // Set the initial velocity and cook time
// simulated event PostBeginPlay()
// {
// 	Super.PostBeginPlay();

// 	// if (Role == ROLE_Authority)
// 	if ( Role == ROLE_Authority && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.GetDetailMode() > DM_Low  )
// 	{
// 	   SetTimer(SecondsBeforeDetonation, false, 'Timer_Detonate');
// 	}

// 	AdjustCanDisintigrate();
// }

// Explode after a certain amount of time
function Timer_Detonate()
{
	Detonate();
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) );
	}
}

function Detonate()
{
	local vector ExplosionNormal;

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
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

simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	local TraceHitInfo HitInfo;

    if (bIsProjActive)
    {
		if (Role == ROLE_Authority)
		{
		   SetTimer(SecondsBeforeDetonation, false, 'Timer_Detonate');
		}
	}

    // Don't bounce any more if being used to pin a zed
    if( bSpawnedForPin )
    {
        BouncesLeft=0;
    }

	SetRotation(rotator(Normal(Velocity)));
    SetPhysics(PHYS_Falling);

    // Should hit destructibles without bouncing
	if (!Wall.bStatic && bDamageDestructiblesOnTouch && Wall.bProjTarget)
	{
		Wall.TakeDamage(Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), MyDamageType, HitInfo, self);
		Explode(Location, HitNormal);
	}
	// check if we should do a bounce, otherwise stick
    else if( !Bounce(HitNormal, Wall) )
    {
        // Turn off the corona when it stops
    	if ( WorldInfo.NetMode != NM_DedicatedServer && ProjEffects!=None )
    	{
            ProjEffects.DeactivateSystem();
        }

        // if our last hit is a destructible, don't stick
        if ( !Wall.bStatic && !Wall.bWorldGeometry && Wall.bProjTarget )
    	{
            Explode(Location, HitNormal);
            ImpactedActor = None;
    	}
        else
        {
        	// Play the bullet impact sound and effects
        	if ( WorldInfo.NetMode != NM_DedicatedServer )
        	{
        		`ImpactEffectManager.PlayImpactEffects(Location, Instigator, HitNormal);
        	}

            SetPhysics(PHYS_None);

        	// Stop ambient sounds when this projectile ShutsDown
        	if( bStopAmbientSoundOnExplode )
        	{
                StopAmbientSound();
        	}

			//@todo: check for pinned victim
        }

        bBounce = false;
    }
}

// Overriden to get explode on touching a pawn
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
    if (bIsProjActive)
    {
		if (Role == ROLE_Authority)
		{
			// Detonate on hiting pawn
			if (ClassIsChildOf(Other.class, class'KFPawn'))
			{
				Detonate();
			}
		}
	}

	if ( Other != Instigator && !Other.bWorldGeometry && Other.bCanBeDamaged )
	{
		if ( Pawn(other) != None )
		{
            Super.ProcessTouch(Other, HitLocation, HitNormal);
		}
		else
        {
            ProcessDestructibleTouchOnBounce( Other, HitLocation, HitNormal );
        }
	}
	else
	{
        Super.ProcessTouch(Other, HitLocation, HitNormal);;
	}
}

/*
// Spawn several projectiles that explode on impact on explosion
simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local bool bDoExplosion;

    // Spawn projectiles
    if(Role < Role_Authority)
    {
        return;
    }

	if (bHasDisintegrated)
	{
		return;
	}

	bDoExplosion = !bHasExploded && Instigator.Role == ROLE_Authority;

	if (bDoExplosion)
	{
		SpawnResidualFlames(HitLocation, HitNormal, LastVelocity);
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

// Spawn several projectiles that explode and linger on impact
function SpawnResidualFlames(vector HitLocation, vector HitNormal, vector HitVelocity)
{
	local int i;
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, SpawnVel;

	HitVelMag = VSize( HitVelocity );
	HitVelDir = Normal( HitVelocity );

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	for( i = 0; i < ResidualFlamesInExplosion; ++i )
	{
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag );
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, SpawnVel );
	}
}

function vector CalculateResidualFlameVelocity( vector HitNormal, vector HitVelDir, float HitVelMag )
{
    local vector SpawnDir;

    // apply some spread
    SpawnDir = VRandCone( HitNormal, ResidualFlameHalfConeAngle * DegToRad );

    return SpawnDir * ResidualFlameForceMultiplier;
} 

simulated function Explode (vector HitLocation, vector HitNormal)
{
	LastVelocity = Velocity;
	super.Explode (HitLocation, HitNormal);
}

simulated function SyncOriginalLocation()
{
	local Actor HitActor;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;

	if (Role < ROLE_Authority && Instigator != none && Instigator.IsLocallyControlled())
	{
		HitActor = Trace(HitLocation, HitNormal, OriginalLocation, Location,,, HitInfo, TRACEFLAG_Bullet);
		if (HitActor != none)
		{
			Explode(HitLocation, HitNormal);
		}
	}

    Super.SyncOriginalLocation();
}
*/

// Spawn several projectiles that explode and linger on impact
function SpawnResidualFlames (vector HitLocation, vector HitNormal, vector HitVelocity)
{
	local int i;
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, SpawnVel;

	HitVelMag = VSize (HitVelocity)*MagnitudeVelocityResidualFlamesInExplosion;
	HitVelDir = Normal (HitVelocity);

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	// spawn random lingering fires (rather, projectiles that cause little fires)
	for( i = 0; i < AmountResidualFlamesInExplosion; ++i )
	{
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag );
		SpawnVel = SpawnVel + OffsetVelocityResidualFlamesInExplosion;
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, SpawnVel );
	}
}

function vector CalculateResidualFlameVelocity( vector HitNormal, vector HitVelDir, float HitVelMag )
{
    local vector SpawnDir;

    // apply some spread
    SpawnDir = VRandCone( HitNormal, ResidualFlameHalfConeAngle * DegToRad );

    return SpawnDir * ResidualFlameForceMultiplier;
} 

// Spawn several projectiles that explode and linger on impact on explosion and one projectile to explode where this projectile hit
simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local bool bDoExplosion;

	if (bHasDisintegrated)
	{
		return;
	}

	bDoExplosion = !bHasExploded && Instigator.Role == ROLE_Authority;

	if (bDoExplosion)
	{
		SpawnResidualFlames (HitLocation, HitNormal, LastVelocity);
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

simulated function SyncOriginalLocation()
{
	local Actor HitActor;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;

	if (Role < ROLE_Authority && Instigator != none && Instigator.IsLocallyControlled())
	{
		HitActor = Trace(HitLocation, HitNormal, OriginalLocation, Location,,, HitInfo, TRACEFLAG_Bullet);
		if (HitActor != none)
		{
			Explode(HitLocation, HitNormal);
		}
	}

    Super.SyncOriginalLocation();
}

simulated function bool AllowNuke()
{
    return false;
}

// simulated protected function PrepareExplosionTemplate()
// {
// 	super.PrepareExplosionTemplate();

// 	// Since bIgnoreInstigator is transient, its value must be defined here
// 	ExplosionTemplate.bIgnoreInstigator = true;
// }

defaultproperties
{
	Physics=PHYS_Falling
    MaxSpeed=2000 //2500
    Speed=2000
	TerminalVelocity=2000
	TossZ=150 //60
	GravityScale=2.0 //1.5
    MomentumTransfer=10000

	LifeSpan=10.0 //fall back
	SecondsBeforeDetonation=0.2 //1.2
    bIsProjActive=true

	// projectile mesh
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh=StaticMesh'DROW_EMIT.FX_Bomblet_Mesh_Big'
		bCastDynamicShadow=FALSE
		CollideActors=false
		LightingChannels=(bInitialized=True,Dynamic=True,Indoor=True,Outdoor=True)
	End Object
	ChargeMesh=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Bomblet_Trail_Big'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_Bomblet_Trail_Big'

	bPinned=false;
    BouncesLeft=3
    DampingFactor=3.0
    RicochetEffects=KFImpactEffectInfo'WEP_Bouncer_ARCH.Bouncer_Impact'

	AmountResidualFlamesInExplosion=8
	MagnitudeVelocityResidualFlamesInExplosion=1 //0.5 25
	ResidualFlameHalfConeAngle=35 //72
	ResidualFlameForceMultiplier=800f;
	OffsetVelocityResidualFlamesInExplosion=(X=0,Y=0,Z=600) //1000
	ResidualFlameProjClass=class'KFProj_Explosive_Bouncer_Dropplets'

	// ResidualFlamesInExplosion=8
	// ResidualFlameHalfConeAngle=30 //72
	// ResidualFlameForceMultiplier=1100f; 
	// ResidualFlameProjClass=class'KFProj_Explosive_Bouncer_Dropplets'

	bCollideComplex=TRUE // Ignore simple collision on StaticMeshes, and collide per poly

	Begin Object Name=CollisionCylinder
		CollisionRadius=30.f
		CollisionHeight=30.f
		// CollideActors=true
		// BlockNonZeroExtent=false
		// PhysMaterialOverride=PhysicalMaterial'WEP_HRG_BallisticBouncer_EMIT.BloatPukeMine_PM'
	End Object

	ExtraLineCollisionOffsets.Add((Y=-30))
	ExtraLineCollisionOffsets.Add((Y=30))
	ExtraLineCollisionOffsets.Add((Z=-30))
	ExtraLineCollisionOffsets.Add((Z=30))
	// Since we're still using an extent cylinder, we need a line at 0
	ExtraLineCollisionOffsets.Add(())

	// Net
	bNetTemporary=false
	NetPriority=5
	NetUpdateFrequency=200

    // Shrapnel
   	bSyncToOriginalLocation=true
	bSyncToThirdPersonMuzzleLocation=false
	bNoReplicationToInstigator=false
	bReplicateLocationOnExplosion=true
	bAlwaysReplicateExplosion=true

	bBlockedByInstigator=true
	bUpdateSimulatedPosition=true
	bUseClientSideHitDetection=true

	ExplosionActorClass=class'KFExplosionActor'

	// explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2000.f
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
		Damage=160 //500
	    DamageRadius=600 //800
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Bouncer'

		MomentumTransferScale=10000
		// bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		// ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		// ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

		ExplosionEffects=KFImpactEffectInfo'WEP_Bouncer_ARCH.Bouncer_Explosion'
		ExplosionSound=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Impact_Explosion_Alt_Fire'

		// Shards
		// ShardClass=class'KFProj_Explosive_Pimpernel_Dropplets'
		// NumShards=8

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}