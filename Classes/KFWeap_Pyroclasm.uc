class KFWeap_Pyroclasm extends KFWeap_ShotgunBase;

var transient KFParticleSystemComponent FirePSC;
var const ParticleSystem FireFXTemplate;

/*
var transient bool bIsFolded;

const ChangeModeAnim = 'Switch';

var const int FoldedDamage;
var const class<Projectile> FoldedProjectile;
var const class<DamageType> FoldedDamageType;
var const int FoldedFireInterval;

var const int UnfoldedDamage;
var const class<Projectile> UnFoldedProjectile;
var const class<DamageType> UnfoldedDamageType;
var const int UnFoldedFireInterval;
*/

var float MicroRocketChance;

var const WeaponFireSndInfo MicroRocketSound;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);

    // ChangeMode(true, false);
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking onto pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) /*|| 
		!HasAmmo(DEFAULT_FIREMODE)*/)
	{
		return false;
	}

	// Make sure and only lock onto players on the same team
	return !WorldInfo.GRI.OnSameTeam(Instigator, TA);
}

// Finds a new lock on target
simulated function bool FindTarget( out KFPawn RecentlyLocked )
{
	local KFPawn P, BestTargetLock;
	local byte TeamNum;
	local vector AimStart, AimDir, TargetLoc, Projection, DirToPawn, LinePoint;
	local Actor HitActor;
	local float PointDistSQ, Score, BestScore, TargetSizeSQ;

	TeamNum   = Instigator.GetTeamNum();
	AimStart  = GetSafeStartTraceLocation();
	AimDir    = vector( GetAdjustedAim(AimStart) );
	BestScore = 0.f;

	foreach WorldInfo.AllPawns( class'KFPawn', P )
	{
		if (!CanLockOnTo(P))
		{
			continue;
		}
		// Want alive pawns and ones we already don't have locked
		if( P != none && P.IsAliveAndWell() && P.GetTeamNum() != TeamNum )
		{
			TargetLoc  = GetLockedTargetLoc( P );
			Projection = TargetLoc - AimStart;
			DirToPawn  = Normal( Projection );

			// Filter out pawns too far from center
			
			if( AimDir dot DirToPawn < CosTargetAngle )
			{
				continue;
			}

			// Check to make sure target isn't too far from center
            PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            // Make sure it's not obstructed
            HitActor = class'KFAIController'.static.ActorBlockTest(self, TargetLoc, AimStart,, true, true);
            if( HitActor != none && HitActor != P )
            {
            	continue;
            }

            // Distance from target has much more impact on target selection score
            Score = VSizeSQ( Projection ) + PointDistSQ;
            if( BestScore == 0.f || Score < BestScore )
            {
            	BestTargetLock = P;
            	BestScore = Score;
            }
		}
	}

	if( BestTargetLock != none )
	{
		RecentlyLocked = BestTargetLock;

		return true;
	}

	RecentlyLocked = none;

	return false;
}

// Adjusts our destination target impact location
static simulated function vector GetLockedTargetLoc( Pawn P )
{
	// Go for the chest, but just in case we don't have something with a chest bone we'll use collision and eyeheight settings
	if( P.Mesh.SkeletalMesh != none && P.Mesh.bAnimTreeInitialised )
	{
		if( P.Mesh.MatchRefBone('Spine2') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine2' );
		}
		else if( P.Mesh.MatchRefBone('Spine1') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine1' );
		}
		
		return P.Mesh.GetPosition() + ((P.CylinderComponent.CollisionHeight + (P.BaseEyeHeight  * 0.5f)) * vect(0,0,1)) ;
	}

	// General chest area, fallback
	return P.Location + ( vect(0,0,1) * P.BaseEyeHeight * 0.75f );	
}

// Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_MicroRocket_Pyroclasm RocketProj;
	local KFPawn TargetPawn;

    if ( CurrentFireMode == CUSTOM_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_MicroRocket_Pyroclasm( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( RocketProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				RocketProj.SetLockedTarget( TargetPawn );
			}
		}

		// Resetting the firemode to default.
		CurrentFireMode = DEFAULT_FIREMODE;

    	if ( CurrentFireMode == ALTFIRE_FIREMODE )
    	{
			CurrentFireMode = ALTFIRE_FIREMODE;
    	}

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

// Overriden to fire a projectile from CUSTOM_FIREMODE at random intervals
simulated function Projectile ProjectileFire()
{
	local KFPawn TargetPawn;
	
	if ( CurrentFireMode == DEFAULT_FIREMODE || CurrentFireMode == CUSTOM_FIREMODE )
	{
		if ( FindTarget(TargetPawn) )
		{
			if ( FRand() < MicroRocketChance )
			{
				CurrentFireMode = CUSTOM_FIREMODE;
				// FireModeNum = CUSTOM_FIREMODE;
				// BeginFire(CUSTOM_FIREMODE);
				// StartFire(CUSTOM_FIREMODE);
				
				KFPawn(Instigator).SetWeaponAmbientSound(MicroRocketSound.DefaultCue, MicroRocketSound.FirstPersonCue);
			}
		}
	}

	if ( CurrentFireMode == ALTFIRE_FIREMODE || CurrentFireMode == CUSTOM_FIREMODE )
	{
		if ( FindTarget(TargetPawn) )
		{
			if ( FRand() < MicroRocketChance )
			{
				CurrentFireMode = CUSTOM_FIREMODE;
				// FireModeNum = CUSTOM_FIREMODE;
				// BeginFire(CUSTOM_FIREMODE);
				// StartFire(CUSTOM_FIREMODE);
				
				KFPawn(Instigator).SetWeaponAmbientSound(MicroRocketSound.DefaultCue, MicroRocketSound.FirstPersonCue);
			}
		}
	}

	return super.ProjectileFire();
}

// Tight choke skill
simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFPerk InstigatorPerk;

	if (CurrentFireMode == DEFAULT_FIREMODE || CurrentFireMode == ALTFIRE_FIREMODE)
	{
		InstigatorPerk = GetPerk();
		if (InstigatorPerk != none)
		{
			Spread[CurrentFireMode] = default.Spread[CurrentFireMode] * InstigatorPerk.GetTightChokeModifier();
		}
	}

	return super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);
}

simulated state WeaponEquipping
{
	simulated event BeginState( name PreviousStateName )
	{
		super.BeginState( PreviousStateName );

		ActivatePSC(FirePSC, FireFXTemplate, 'FireFX');
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		OutPSC.SetAbsolute(false, false, false);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
	}
}

auto state Inactive
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		if (FirePSC != none)
		{
			FirePSC.DeactivateSystem();
		}
	}
}

/*
// Instead of switch fire mode switch projectile type and damage type
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	GotoState('WeaponKeeper');
    bIsFolded = !bIsFolded;
	ChangeMode(bIsFolded);

	StartFire(ALTFIRE_FIREMODE);
}

simulated state WeaponKeeper
{
    simulated function BeginState(name PreviousStateName)
	{
		local name AnimName;
		local float Duration;

        AnimName = ChangeModeAnim;

		Duration = MySkelMesh.GetAnimLength(AnimName);
		if ( Duration > 0.f )
		{
			if ( Instigator.IsFirstPerson() )
			{
				PlayAnimation(AnimName);
                SetTimer(Duration, FALSE, nameof(SwapComplete));
			}
    	}
		else
		{
			`warn("Duration is zero!!!"@AnimName);
			SetTimer(0.001, FALSE, nameof(SwapComplete));
		}

		NotifyBeginState();
	}

	simulated function BeginFire(byte FireModeNum)
	{}

	simulated event EndState(Name NextStateName)
	{
		ClearTimer(nameof(SwapComplete));
        Super.EndState(NextStateName);
        NotifyEndState();
	}
    
    simulated function SwapComplete()
    {
        if (Role == ROLE_Authority)
        {
            GotoState('Active');
        }
        else
        {
            GotoState('Active');
            ServerSwapComplete();
        }
    }
}

server reliable function ServerSwapComplete()
{
    GotoState('Active');
}

simulated function ChangeMode(bool IsFolded, bool bApplyBlend = true)
{
	if (IsFolded)
	{
	    InstantHitDamage[DEFAULT_FIREMODE] = FoldedDamage;
	    InstantHitDamageTypes[DEFAULT_FIREMODE] = FoldedDamageType;
		WeaponProjectiles[DEFAULT_FIREMODE] = FoldedProjectile;
		FireInterval[DEFAULT_FIREMODE] = FoldedFireInterval;
	}
	else 
	{
	    InstantHitDamage[DEFAULT_FIREMODE] = UnfoldedDamage;
	    InstantHitDamageTypes[DEFAULT_FIREMODE] = UnfoldedDamageType;
		WeaponProjectiles[DEFAULT_FIREMODE] = UnFoldedProjectile;
		FireInterval[DEFAULT_FIREMODE] = UnFoldedFireInterval;
	}
}
*/

defaultproperties
{
	// Inventory
	InventorySize=6 //8 10
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Pyroclasm_MAT.UI_WeaponSelect_Pyroclasm'
	AssociatedPerkClasses(0)=class'KFPerk_Firebug'
	AssociatedPerkClasses(1)=class'KFPerk_Support'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

    // FOV
 	MeshFOV=86
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=8.5,Z=0.0)
	IronSightPosition=(X=8,Y=0,Z=0)

	// Content
	PackageKey="Pyroclasm"
	FirstPersonMeshName="WEP_Pyroclasm_MESH.Wep_1stP_Pyroclasm_Rig"
	FirstPersonAnimSetNames(0)="WEP_Pyroclasm_ARCH.Wep_1stP_Pyroclasm_Anim"
	PickupMeshName="WEP_Pyroclasm_MESH.Wep_Pyroclasm_Pickup"
	AttachmentArchetypeName="WEP_Pyroclasm_ARCH.WEP_Pyroclasm_FireFX_3P" //WEP_Pyroclasm_ARCH.Wep_Pyroclasm_3P
	MuzzleFlashTemplateName="WEP_AA12_ARCH.Wep_AA12_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=20
	SpareAmmoCapacity[0]=140 //120
	InitialSpareMags[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true
	bHasFireLastAnims=false

	// Recoil
	maxRecoilPitch=200
	minRecoilPitch=190
	maxRecoilYaw=100
	minRecoilYaw=-100
	RecoilRate=0.075
	RecoilBlendOutRatio=0.25
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.7
	FallingRecoilModifier=1.5
	HippedRecoilModifier=1.75
    
	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Pyroclasm'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Pyroclasm'
	InstantHitDamage(DEFAULT_FIREMODE)=35 //20
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	FireInterval(DEFAULT_FIREMODE)=0.2 // 300 RPM
	Spread(DEFAULT_FIREMODE)=0.1
	NumPellets(DEFAULT_FIREMODE)=4
	FireOffset=(X=30,Y=5,Z=-4)

/*
	// ALT_FIREMODE
	// FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	// WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

    bIsFolded=true

	FoldedDamage=30
	FoldedProjectile=class'KFProj_Bullet_Pyroclasm'
	FoldedDamageType=class'KFDT_Ballistic_Pyroclasm'
	FoldedFireInterval=0.8;

	UnfoldedDamage=95
	UnFoldedProjectile=class'KFProj_MicroRocket_Pyroclasm'
	UnfoldedDamageType=class'KFDT_Ballistic_MicroRocketImpact'
	UnFoldedFireInterval=0.8;
*/
	
	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_Pyroclasm'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Pyroclasm'
	InstantHitDamage(ALTFIRE_FIREMODE)=35 //20
	PenetrationPower(ALTFIRE_FIREMODE)=2.0
	FireInterval(ALTFIRE_FIREMODE)=0.2 // 300 RPM
	Spread(ALTFIRE_FIREMODE)=0.1
	NumPellets(ALTFIRE_FIREMODE)=4

	// CUSTOM_FIREMODE (micro rocket trait)
	FiringStatesArray(CUSTOM_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(CUSTOM_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(CUSTOM_FIREMODE)=class'KFProj_MicroRocket_Pyroclasm'
	InstantHitDamageTypes(CUSTOM_FIREMODE)=class'KFDT_Ballistic_MicroRocketImpact'
	FireInterval(CUSTOM_FIREMODE)=+.067 // 900 RPM
	InstantHitDamage(CUSTOM_FIREMODE)=95
	Spread(CUSTOM_FIREMODE)=0.75

	MaxTargetAngle=30
	MicroRocketChance=0.20
	MicroRocketSound=(DefaultCue = AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_AA12Shotgun'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_1P')
    WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'

	FireFXTemplate=ParticleSystem'DROW_EMIT.FX_Pyroclasm_FireFX'
	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	FirePSC=BasePSC0

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Shooting Animations
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}