class KFWeapAttach_SuperHeat extends KFWeaponAttachment;

// `define HEAT_MIC_BARREL_INDEX 0

// var transient float BarrelHeatPerProjectile;
// var transient float MaxBarrelHeat;
// var transient float BarrelCooldownRate;
// var transient float CurrentBarrelHeat;
// var transient float LastBarrelHeat;

/*
var transient int AltAmmo;

const MuzzleSocketName = 'MuzzleFlash';

// The partcile FX to display for the Cryo Projectile
var() ParticleSystemComponent CryoProjectilePSC;
var ParticleSystem CryoProjectileEffectOn;

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();

    // BarrelHeatPerProjectile = class'KFWeap_SuperHeat'.default.BarrelHeatPerProjectile;
    // MaxBarrelHeat           = class'KFWeap_SuperHeat'.default.MaxBarrelHeat;
    // BarrelCooldownRate      = class'KFWeap_SuperHeat'.default.BarrelCooldownRate;
    AltAmmo = class'KFWeap_SuperHeat'.default.AltAmmo;
}
*/

/*
simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    
    // Force start with "Glow_Intensity" of 0.0f
	LastBarrelHeat = MaxBarrelHeat;
	ChangeBarrelMaterial();
}

simulated function ChangeBarrelMaterial()
{
    if( CurrentBarrelHeat != LastBarrelHeat )
    {
        if ( WeaponMIC == None && WeapMesh != None )
        {
            WeaponMIC = WeapMesh.CreateAndSetMaterialInstanceConstant(`HEAT_MIC_BARREL_INDEX);
        }
    
        WeaponMIC.SetScalarParameterValue('Barrel_intensity', CurrentBarrelHeat);
    }
}
*/

/*
simulated function Tick(float Delta)
{
    // if( AltAmmo == 50 )
    // {
    //     CryoProjectilePSC.SetTemplate(CryoProjectileEffectOn);
    //     CryoProjectilePSC.ActivateSystem();
    // }
    // else if( AltAmmo == 100 )
    // {
    //     CryoProjectilePSC.SetTemplate(CryoProjectileEffectOn);
    //     CryoProjectilePSC.ActivateSystem();
    // }

    local int Max;

    Max = int(class'KFWeap_SuperHeat'.default.AltAmmo);

    if(Max == 50)
    {
        CryoProjectilePSC.SetTemplate(CryoProjectileEffectOn);
        CryoProjectilePSC.ActivateSystem();
    }
    else if(Max == 10)
    {
        CryoProjectilePSC.SetTemplate(CryoProjectileEffectOn);
        CryoProjectilePSC.ActivateSystem();
    }

	Super.Tick(Delta);

	// CurrentBarrelHeat = fmax(CurrentBarrelHeat - BarrelCooldownRate * Delta, 0.0f);
	// ChangeBarrelMaterial();
}

// Attach weapon to owner's skeletal mesh
simulated function AttachTo(KFPawn P)
{
    local byte WeaponAnimSetIdx;

    if ( bWeapMeshIsPawnMesh )
    {
        WeapMesh = P.Mesh;
    }
    else if ( WeapMesh != None )
    {
        // Attach Weapon mesh to player skel mesh
        WeapMesh.SetShadowParent(P.Mesh);
        P.Mesh.AttachComponent(WeapMesh, P.WeaponAttachmentSocket);
    }

    // Animation
    if ( CharacterAnimSet != None )
    {
        WeaponAnimSetIdx = P.CharacterArch.GetWeaponAnimSetIdx();
        P.Mesh.AnimSets[WeaponAnimSetIdx] = CharacterAnimSet;
        // update animations will reload all AnimSeqs with the new AnimSet
        P.Mesh.UpdateAnimations();
    }

    // update aim offset nodes with new profile for this weapon
    P.SetAimOffsetNodesProfile(AimOffsetProfileName);

    if (CryoProjectilePSC != none)
    {
        P.Mesh.AttachComponentToSocket(CryoProjectilePSC, MuzzleSocketName);
    }
}

simulated function DetachFrom(KFPawn P)
{
    if (CryoProjectilePSC != none)
    {
        CryoProjectilePSC.DeactivateSystem();
        CryoProjectilePSC.DetachFromAny();
    }

    Super.DetachFrom(P);
}

// Override to update emissive in weapon's barrel after firing
simulated function PlayWeaponFireAnim()
{
    if ( Instigator.bIsWalking )
    {
        if (Instigator.FiringMode == 1)
        {
            CryoProjectilePSC.DeactivateSystem();
        }
    }

	Super.PlayWeaponFireAnim();

    // CurrentBarrelHeat = fmin(CurrentBarrelHeat + BarrelHeatPerProjectile, MaxBarrelHeat);
}

*/

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
    local ParticleSystemComponent PSC;
    local vector Dir;
    local float DistSQ;
    local float TracerDuration;
    local KFTracerInfo TracerInfo;

    if (Instigator == None || Instigator.FiringMode >= TracerInfos.Length)
    {
        return;
    }

    TracerInfo = TracerInfos[Instigator.FiringMode];
    if (((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
        || (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
        && TracerInfo.TracerTemplate != none )
    {
        Dir = HitLocation - EffectLocation;
        DistSQ = VSizeSq(Dir);
        if (DistSQ > TracerInfo.MinTracerEffectDistanceSquared)
        {
            // Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
            TracerDuration = fMin((Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f);
            if (TracerDuration > 0.f)
            {
                PSC = WorldInfo.MyEmitterPool.SpawnEmitter(TracerInfo.TracerTemplate, EffectLocation, rotator(Dir));
                PSC.SetFloatParameter('Tracer_Lifetime', TracerDuration);
                PSC.SetVectorParameter('Shotend', HitLocation);
            }
        }
    }
}

defaultproperties
{
    // Heat
    // MaxBarrelHeat=4.0f
    // BarrelHeatPerProjectile=0.10f
    // BarrelCooldownRate=0.15f
    // CurrentBarrelHeat=0.0f
    // LastBarrelHeat=0.0f

/*    
    Begin Object Class=KFParticleSystemComponent Name=CryoArrowParticleComp0
        bAutoActivate=FALSE
        TickGroup=TG_PostUpdateWork
    End Object
    CryoProjectilePSC=CryoArrowParticleComp0

    CryoProjectileEffectOn=ParticleSystem'DROW_EMIT.FX_SuperHeat_Lens'
    */
}