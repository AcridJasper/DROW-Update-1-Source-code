class KFWeap_RPG7_PHO extends KFWeap_ScopedBase; //KFWeap_GrenadeLauncher_Base

// Ironsights Audio
var AkComponent       IronsightsComponent;
var AkEvent           IronsightsZoomInSound;
var AkEvent           IronsightsZoomOutSound;

/** Sound Effects to play when Locking */
// var AkBaseSoundObject LockAcquiredSoundFirstPerson;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// How long to wait after firing to force reload
var() float	ForceReloadTime;

// Back blash explosion template
var() GameExplosion ExplosionTemplate;
// Holds an offest for spawning back blast effects
var() vector BackBlastOffset;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

// Given an potential target TA determine if we can lock on to it. By default only allow locking on to pawns
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

		// Plays sound/FX when locking on to a new target
		// PlayTargetLockOnEffects();

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
	local KFProj_Rocket_RPG7_PHO RocketProj;
	local KFPawn TargetPawn;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }
    
    if ( CurrentFireMode == DEFAULT_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Rocket_RPG7_PHO( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

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

/** Play FX or sounds when locking on to a new target */
// simulated function PlayTargetLockOnEffects()
// {
// 	if( Instigator != none && Instigator.IsHumanControlled() )
// 	{
// 		PlaySoundBase( LockAcquiredSoundFirstPerson, true );
// 	}
// }

simulated function ZoomIn(bool bAnimateTransition, float ZoomTimeToGo)
{
    super.ZoomIn(bAnimateTransition, ZoomTimeToGo);

    if (IronsightsZoomInSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomInSound, false);
    }
}

// Clear all locked targets when zooming out, both server and client
simulated function ZoomOut( bool bAnimateTransition, float ZoomTimeToGo )
{
	super.ZoomOut( bAnimateTransition, ZoomTimeToGo );

    if (IronsightsZoomOutSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomOutSound, false);
    }
}

/*
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated function Projectile ProjectileFireCustom()
{
	local vector StartTrace, RealStartLoc, AimDir;
	local rotator AimRot;
	local class<KFProjectile> MyProjectileClass;

	// tell remote clients that we fired, to trigger effects
	if ( ShouldIncrementFlashCountOnFire() )
	{
		IncrementFlashCount();
	}

    MyProjectileClass = GetKFProjectileClass();

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{
		// This is where we would start an instant trace. (what CalcWeaponFire uses)
		MySkelMesh.GetSocketWorldLocationAndRotation( 'MuzzleFlash', StartTrace, AimRot );
		GetMuzzleLocAndRot(StartTrace, AimRot );

		// AimDir = Vector(Owner.Rotation);
		AimDir = Vector(AimRot);

		// this is the location where the projectile is spawned.
		RealStartLoc = StartTrace;

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

simulated function GetMuzzleLocAndRot(out vector MuzzleLoc, out rotator MuzzleRot)
{
	if (KFSkeletalMeshComponent(Mesh).GetSocketWorldLocationAndRotation('MuzzleFlash', MuzzleLoc, MuzzleRot) == false)
	{
		`Log("MuzzleFlash not found!");
	}

	// To World Coordinates. (Rotation should be 0 so no taken into account)
	// MuzzleLoc = Location + QuatRotateVector(QuatFromRotator(Rotation), MuzzleLoc);
}
*/

// Fires a projectile, but also does the back blast
simulated function CustomFire()
{
	local KFExplosionActorReplicated ExploActor;
	local vector SpawnLoc;
	local rotator SpawnRot;

    ProjectileFire();
    // ProjectileFireCustom(); // "mortar"

	if ( Instigator.Role < ROLE_Authority )
	{
		return;
	}

	GetBackBlastLocationAndRotation(SpawnLoc, SpawnRot);

	// explode using the given template
	ExploActor = Spawn(class'KFExplosionActorReplicated', self,, SpawnLoc, SpawnRot,, true);
	if (ExploActor != None)
	{
		ExploActor.InstigatorController = Instigator.Controller;
		ExploActor.Instigator = Instigator;

		// So we get backblash decal from this explosion
		ExploActor.bTraceForHitActorWhenDirectionalExplosion = true;

		ExploActor.Explode(ExplosionTemplate, vector(SpawnRot));
	}

	if ( bDebug )
	{
        DrawDebugCone(SpawnLoc, vector(SpawnRot), ExplosionTemplate.DamageRadius, ExplosionTemplate.DirectionalExplosionAngleDeg * DegToRad,
			ExplosionTemplate.DirectionalExplosionAngleDeg * DegToRad, 16, MakeColor(64,64,255,0), TRUE);
	}
}

/*
// Overriden to cause backfire damage on any EWFT_Projectile fire types for this weapon
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir, SpawnLoc;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

	local KFExplosionActorReplicated ExploActor;
	local rotator SpawnRot;

	GetBackBlastLocationAndRotation(SpawnLoc, SpawnRot);

	// explode using the given template
	ExploActor = Spawn(class'KFExplosionActorReplicated', self,, SpawnLoc, SpawnRot,, true);
	if (ExploActor != None)
	{
		ExploActor.InstigatorController = Instigator.Controller;
		ExploActor.Instigator = Instigator;

		// So we get backblash decal from this explosion
		ExploActor.bTraceForHitActorWhenDirectionalExplosion = true;

		ExploActor.Explode(ExplosionTemplate, vector(SpawnRot));
	}

	if ( bDebug )
	{
        DrawDebugCone(SpawnLoc, vector(SpawnRot), ExplosionTemplate.DamageRadius, ExplosionTemplate.DirectionalExplosionAngleDeg * DegToRad,
			ExplosionTemplate.DirectionalExplosionAngleDeg * DegToRad, 16, MakeColor(64,64,255,0), TRUE);
	}

	// tell remote clients that we fired, to trigger effects
	if ( ShouldIncrementFlashCountOnFire() )
	{
		IncrementFlashCount();
	}

    MyProjectileClass = GetKFProjectileClass();

	if (MyProjectileClass == none)
	{
		return none;
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{
		// This is where we would start an instant trace. (what CalcWeaponFire uses)
		StartTrace = GetSafeStartTraceLocation();
		AimDir = Vector(GetAdjustedAim( StartTrace ));

		// this is the location where the projectile is spawned.
		if (UseFixedPhysicalFireLocation)
		{
			RealStartLoc = GetFixedPhysicalFireStartLoc();
		}
		else
		{
			RealStartLoc = GetPhysicalFireStartLoc(AimDir);
		}

		if( StartTrace != RealStartLoc )
		{
			// if projectile is spawned at different location of crosshair,
			// then simulate an instant trace where crosshair is aiming at, Get hit info.
			EndTrace = StartTrace + AimDir * GetTraceRange();
			TestImpact = CalcWeaponFire( StartTrace, EndTrace );
			// Store the original aim direction without correction
            DirB = AimDir;

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            // Store the desired corrected aim direction
    		DirA = AimDir;

    		// Clamp the maximum aim adjustment for the AimDir so you don't get wierd
    		// cases where the projectiles velocity is going WAY off of where you
    		// are aiming. This can happen if you are really close to what you are
    		// shooting - Ramm
    		if ( (DirA dot DirB) < MaxAimAdjust_Cos )
    		{
    			Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), MaxAimAdjust_Angle);
    			AimDir = QuatRotateVector(Q,DirB);
    		}
		}

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}
*/

// This function returns the world location for spawning back blast and the direction to send the back blast in
simulated function GetBackBlastLocationAndRotation(out vector BlastLocation, out rotator BlastRotation)
{
    local vector X, Y, Z;
    local Rotator ViewRotation;

	if( Instigator != none )
	{
        if( bUsingSights )
        {
            ViewRotation = Instigator.GetViewRotation();

        	// Add in the free-aim rotation
        	if ( KFPlayerController(Instigator.Controller) != None )
        	{
        		ViewRotation += KFPlayerController(Instigator.Controller).WeaponBufferRotation;
        	}

            GetAxes(ViewRotation, X, Y, Z);

            BlastRotation = Rotator(Vector(ViewRotation) * -1);
            BlastLocation =  Instigator.GetWeaponStartTraceLocation() + X * BackBlastOffset.X;
		}
		else
		{
            ViewRotation = Instigator.GetViewRotation();

        	// Add in the free-aim rotation
        	if ( KFPlayerController(Instigator.Controller) != None )
        	{
        		ViewRotation += KFPlayerController(Instigator.Controller).WeaponBufferRotation;
        	}

            BlastRotation = Rotator(Vector(ViewRotation) * -1);
            BlastLocation = Instigator.GetPawnViewLocation() + (BackBlastOffset >> ViewRotation);
		}
	}
}

// Locks the bolt bone in place to the open position (Called by animnotify)
simulated function ANIMNOTIFY_LockBolt()
{
	// Consider us empty after every shot so the rocket gets hidden
	EmptyMagBlendNode.SetBlendTarget(1, 0);
}

simulated function float GetForceReloadDelay()
{
	return fMax( ForceReloadTime - FireInterval[CurrentFireMode], 0.f );
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

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
	// Inventory
	InventoryGroup=IG_Primary
	GroupPriority=21 // funny number
	InventorySize=7 //9 10
	WeaponSelectTexture=Texture2D'WEP_RPG7_PHO_MAT.UI_WeaponSelect_RPG7_PHO'
	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Uncommon_DROW' // Loot beam fx (no offset)

    // FOV
	MeshFOV=75
	MeshIronSightFOV=30 //40 65
	PlayerIronSightFOV=70
	PlayerSprintFOV=95

	// Zooming/Position
	PlayerViewOffset=(X=10.0,Y=10,Z=-2)
	//IronSightPosition=(X=0,Y=0,Z=0)
	IronSightPosition=(X=0,Y=4.7,Z=1.7)
	FastZoomOutTime=0.3 //0.2

	// 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
		TextureTarget=TextureRenderTarget2D'Wep_Mat_Lib.WEP_ScopeLense_Target'
		FieldOfView=12.5 // "2.0X" = 25.0(our real world FOV determinant)/2.0
	End Object

	ScopedSensitivityMod=12.0
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_RPG7_PHO_MAT.WEP_1P_RPG7_PHO_Reticle_MAT' //WEP_RPG7_PHO_MAT.WEP_1P_RPG7_PHO_Reticle_MAT
	ScopeMICIndex=2 //WEP_1P_RailGun_MAT.Wep_1stP_RailGun_Lens_MIC

	// Content
	PackageKey="RPG7_PHO"
	FirstPersonMeshName="WEP_RPG7_PHO_MESH.Wep_1stP_RPG7_PHO_Rig"
	FirstPersonAnimSetNames(0)="WEP_RPG7_PHO_ARCH.Wep_1stP_RPG7_PHO_Anim"
	PickupMeshName="WEP_RPG7_PHO_MESH.WEP_RPG7_PHO_Pickup"
	AttachmentArchetypeName="WEP_RPG7_PHO_ARCH.Wep_RPG7_PHO_3P"
	MuzzleFlashTemplateName="WEP_RPG7_ARCH.Wep_RPG7_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=15 //10
	InitialSpareMags[0]=4
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true
	ForceReloadTime=0.10f

	// Recoil
	maxRecoilPitch=900
	minRecoilPitch=775
	maxRecoilYaw=500
	minRecoilYaw=-500
	RecoilRate=0.085
	RecoilBlendOutRatio=0.35
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1500
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	RecoilViewRotationScale=0.8
	FallingRecoilModifier=1.5
	HippedRecoilModifier=1.25

	// DEFAULT_FIREMODE (Homing rocket + high damage)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Custom //EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Rocket_RPG7_PHO' //KFProj_Rocket_RPG7_PHO_NH
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_RPG7PHOImpact'
	FireInterval(DEFAULT_FIREMODE)=+0.25
	InstantHitDamage(DEFAULT_FIREMODE)=150.0
	Spread(DEFAULT_FIREMODE)=0.025
	FireOffset=(X=20,Y=4.0,Z=-3)
	BackBlastOffset=(X=-20,Y=4.0,Z=-3)

    SelfDamageReductionValue=0.10f;

	MaxTargetAngle=30 //25

	// ALT_FIREMODE
    FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
    WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	// ALT_FIREMODE (mortar mode: ProjectileFireCustom)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'UI_FireModes_TEX.UI_FireModeSelect_Rocket'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Custom
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_RPG7_PHO'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_RPG7PHOImpact'
	FireInterval(ALTFIRE_FIREMODE)=+0.25
	InstantHitDamage(ALTFIRE_FIREMODE)=150.0
	Spread(ALTFIRE_FIREMODE)=0.025
	NumPellets(ALTFIRE_FIREMODE)=1
*/

	// Back blash explosion settings. Using archetype so that clients can serialize the content
	// without loading the 1st person weapon content (avoid 'Begin Object')!
	ExplosionTemplate=KFGameExplosion'WEP_RPG7_ARCH.Wep_RPG7_BackBlastExplosion'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_RPG7'
	InstantHitDamage(BASH_FIREMODE)=30 //29

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Fire_1P')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_DryFire'

	// Animation
	bHasFireLastAnims=true
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2)

	BonesToLockOnEmpty=(RW_Grenade1)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Locked'

    // Ironsight sounds
    Begin Object Class=AkComponent name=IronsightsComponent0
        bForceOcclusionUpdateInterval=true
		OcclusionUpdateInterval=0.f // never update occlusion for footsteps
		bStopWhenOwnerDestroyed=true
    End Object
    IronsightsComponent=IronsightsComponent0
    Components.Add(IronsightsComponent0)
    IronsightsZoomInSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In'
    IronsightsZoomOutSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In_Out'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}