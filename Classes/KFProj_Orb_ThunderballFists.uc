class KFProj_Orb_ThunderballFists extends KFProj_BallisticExplosive;

var() float SecondsBeforeDetonation;

var GameExplosion VFXExplosionTemplate;

// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	// if ( Role == ROLE_Authority && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.GetDetailMode() > DM_Low  )
	if (Role == ROLE_Authority)
	{
	   SetTimer(SecondsBeforeDetonation, false, 'Timer_Detonate');
	}

	AdjustCanDisintigrate();
}

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

simulated function TriggerVFXExplosion()
{
	local KFExplosionActorReplicated ExploActor;

	if (VFXExplosionTemplate != none)
	{
		// explode using the given template
		ExploActor = Spawn(class'KFExplosionActorReplicated', self,, Location, Rotation,, true);
		if (ExploActor != None)
		{
			ExploActor.InstigatorController = Instigator.Controller;
			ExploActor.Instigator = Instigator;

			// enable muzzle location sync
			// ExploActor.bReplicateInstigator = true;
			// ExploActor.bSyncParticlesToMuzzle = false;

			ExploActor.Explode(VFXExplosionTemplate);
		}
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    // TriggerExplosion(HitLocation, HitNormal, None);
	TriggerVFXExplosion();
	Shutdown();	// cleanup/destroy projectile
}

simulated function bool AllowNuke()
{
    return false;
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	VFXExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Falling
	MaxSpeed=8000 //1500
	Speed=8000
	TerminalVelocity=8000
	TossZ=150
    GravityScale=0.5
    ArmDistSquared=0

	SecondsBeforeDetonation=0.5 //0.4 1.2

	// Net
	bNetTemporary=false
	NetPriority=5
	NetUpdateFrequency=200

    // Shrapnel
   	bSyncToOriginalLocation=true
	bSyncToThirdPersonMuzzleLocation=false
	bNoReplicationToInstigator=false
	bReplicateClientHitsAsFragments=true

	bAlwaysReplicateExplosion=true
	bUpdateSimulatedPosition=true

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_ThunderballFists_Projectile'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_ThunderballFists_Projectile'

	bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=1500.f
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
		Damage=70 //100
	    DamageRadius=400 //300
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_ThunderballFists'

		MomentumTransferScale=10000
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ThunderballFists_ARCH.ThunderballFists_Explosion_Big'
		ExplosionSound=AkEvent'WW_WEP_SealSqueal.Play_WEP_SealSqueal_Shoot_Explode'

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
	VFXExplosionTemplate=ExploTemplate0
}