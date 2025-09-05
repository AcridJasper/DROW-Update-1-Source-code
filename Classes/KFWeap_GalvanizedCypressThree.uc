class KFWeap_GalvanizedCypressThree extends KFWeap_PistolBase;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// Ironsights Audio
var AkComponent IronsightsComponent;
var AkEvent     IronsightsZoomInSound;
var AkEvent     IronsightsZoomOutSound;

// Secondary animations
const NadeThrowAnim = 'Nade_Throw';
// Holds an offest for spawning nades
var(Positioning) vector	NadeFireOffset;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		AltAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(AltAmmo))
	{
		AmmoCount[ALTFIRE_FIREMODE] = AltAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAltRecharge();
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

function StartAltRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAltRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAltRechargeTime = AltFullRechargeSeconds;
	    AltRechargePerSecond = MagazineCapacity[ALTFIRE_FIREMODE] / UsedAltRechargeTime;
		AltIncrement = 0;
	}
}

function RechargeAlt(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AltIncrement += AltRechargePerSecond * DeltaTime;

		if( AltIncrement >= 1.0 && AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
		{
			AmmoCount[ALTFIRE_FIREMODE]++;
			AltIncrement -= 1.0;
			AltAmmo = AmmoCount[ALTFIRE_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAltRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	{
        RechargeAlt(DeltaTime);
	}

	Super.Tick(DeltaTime);
}

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
simulated function bool HasAnyAmmo()
{
	return HasSpareAmmo() || HasAmmo(DEFAULT_FIREMODE);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
}

// Allow reloads for primary weapon to be interupted by firing secondary weapon
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return true;
	}

	return Super.CanOverrideMagReload(FireModeNum);
}

// Instead of a toggle, immediately fire alternate fire
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated state NadeThrowing extends WeaponSingleFiring
{
	simulated function bool TryPutDown() { return false; }

	// Overriden to not call FireAmmunition right at the start of the state
    simulated event BeginState( Name PreviousStateName )
	{
        local KFPerk InstigatorPerk;

		`LogInv("PreviousStateName:" @ PreviousStateName);

		// Force exit ironsights (affects IS toggle key bind)
		if ( bUsingSights )
		{
			ZoomOut(false, default.ZoomOutTime);
		}

        InstigatorPerk = GetPerk();
        if( InstigatorPerk != none )
        {
            SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
        }

		ConsumeAmmo(CurrentFireMode);

		// set timer for spawning projectile
		PlayNadeThrow();
		TimeWeaponFiring(CurrentFireMode);
		ClearPendingFire(CurrentFireMode);

		NotifyBeginState();
	}

 	// This function returns the world location for spawning the visual effects
 	// Overridden to use a special offset for throwing grenades
    simulated event vector GetMuzzleLoc()
    {
        local Rotator ViewRotation;

		if( Instigator != none )
		{
			ViewRotation = Instigator.GetViewRotation();

			// Add in the free-aim rotation
			if ( KFPlayerController(Instigator.Controller) != None )
			{
				ViewRotation += KFPlayerController(Instigator.Controller).WeaponBufferRotation;
			}

			return Instigator.GetPawnViewLocation() + (NadeFireOffset >> ViewRotation);
		}

		return Location;
    }

	// thirdperson anim doesn't play instantly
	simulated function EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);
		NotifyEndState();

		// Spawn projectile
		// (don't use FireAmmunition because that causes FireAnim to be played again)
		ProjectileFire();
		NotifyWeaponFired(CurrentFireMode);
	}
}

simulated function PlayNadeThrow()
{
    local name WeaponFireAnimName;

    if( Instigator != none && Instigator.IsFirstPerson() )
    {
    	WeaponFireAnimName = GetNadeThrowAnim();

    	if ( WeaponFireAnimName != '' )
    	{
    		PlayAnimation(WeaponFireAnimName, MySkelMesh.GetAnimLength(WeaponFireAnimName),,FireTweenTime);
    	}
    }
}

simulated function name GetNadeThrowAnim()
{
	return NadeThrowAnim;
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) || 
		!HasAmmo(DEFAULT_FIREMODE))
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
	local KFProj_Rocket_GalvanizedCypressThree RocketProj;
	local KFPawn TargetPawn;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    if ( CurrentFireMode == DEFAULT_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Rocket_GalvanizedCypressThree( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( RocketProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				RocketProj.SetLockedTarget( TargetPawn );
			}
		}

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

simulated function ZoomIn(bool bAnimateTransition, float ZoomTimeToGo)
{
    super.ZoomIn(bAnimateTransition, ZoomTimeToGo);

    if (IronsightsZoomInSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomInSound, false);
    }
}

simulated function ZoomOut( bool bAnimateTransition, float ZoomTimeToGo )
{
   super.ZoomOut( bAnimateTransition, ZoomTimeToGo );

    if (IronsightsZoomOutSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomOutSound, false);
    }
}

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
}

defaultproperties
{
	// Inventory
	InventoryGroup=IG_Primary
	InventorySize=4 //3
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_GalvanizedCypressThree_MAT.UI_WeaponSelect_GalvanizedCypressthree'
	bIsBackupWeapon=false
	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'
	AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshFOV=86
	MeshIronSightFOV=77
    PlayerIronSightFOV=77

	// Zooming/Position
	PlayerViewOffset=(X=29.0,Y=13,Z=-4)
	IronSightPosition=(X=15,Y=0,Z=-0.3)

	//Content
	PackageKey="GalvanizedCypressThree"
	FirstPersonMeshName="WEP_GalvanizedCypressThree_MESH.Wep_1stP_GalvanizedCypressThree_Rig"
	FirstPersonAnimSetNames(0)="WEP_GalvanizedCypressThree_ARCH.WEP_1P_GalvanizedCypressThree_ANIM"
	PickupMeshName="WEP_GalvanizedCypressThree_MESH.Wep_GalvanizedCypressThree_Pickup"
	AttachmentArchetypeName="WEP_GalvanizedCypressThree_ARCH.WEP_GalvanizedCypressThree_3P"
	MuzzleFlashTemplateName="WEP_GalvanizedCypressThree_ARCH.Wep_GalvanizedCypressThree_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=10 //15
	SpareAmmoCapacity[0]=90 //100
	InitialSpareMags[0]=3 //4
	AmmoPickupScale[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=250
	minRecoilPitch=200
	maxRecoilYaw=100
	minRecoilYaw=-100
	RecoilRate=0.07
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=250
	RecoilISMinPitchLimit=65485

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring //WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Rocket_GalvanizedCypressThree'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_GalvanizedCypressThree'
	FireInterval(DEFAULT_FIREMODE)=+0.25 //+0.20  0.35
	InstantHitDamage(DEFAULT_FIREMODE)=90 //95
	Spread(DEFAULT_FIREMODE)=0.015
	PenetrationPower(DEFAULT_FIREMODE)=0.0
	FireOffset=(X=20,Y=4.0,Z=-3)

	MaxTargetAngle=15 //45
	SelfDamageReductionValue=0.10f; //0.16

	// ALTFIRE_FIREMODE (reach 100% and then throw a grenade by pressing alt fire button)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	FiringStatesArray(ALTFIRE_FIREMODE)=NadeThrowing
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Grenade_GalvanizedCypressThree'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Freeze_GalvanizedCypressThree_Grenade_Impact'
	InstantHitDamage(ALTFIRE_FIREMODE)=65
	FireInterval(ALTFIRE_FIREMODE)=0.60
	PenetrationPower(ALTFIRE_FIREMODE)=0.0
	NumPellets(ALTFIRE_FIREMODE)=1
	NadeFireOffset=(X=25,Y=-15)

	AltAmmo=100
	MagazineCapacity[1]=100
	AmmoCost(ALTFIRE_FIREMODE)=100
	AltFullRechargeSeconds=17 //15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	// bAllowClientAmmoTracking=true

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Pistol_Medic'
	InstantHitDamage(BASH_FIREMODE)=24

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Seeker_6.Play_WEP_Seeker_6_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

    // Ironsights Audio
    Begin Object Class=AkComponent name=IronsightsComponent0
       bForceOcclusionUpdateInterval=true
       OcclusionUpdateInterval=0.f // never update occlusion for footsteps
       bStopWhenOwnerDestroyed=true
    End Object
    IronsightsComponent=IronsightsComponent0
    Components.Add(IronsightsComponent0)

    // Ironsights zoom in/out sounds
    IronsightsZoomInSound=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locking'
    IronsightsZoomOutSound=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Lost'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4)

	bHasFireLastAnims=false
	BonesToLockOnEmpty=(RW_Bolt)

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.3f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
}