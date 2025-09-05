class KFWeap_Martian extends KFWeap_PistolBase;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

// Back blash explosion template
var() GameExplosion ExplosionTemplate;
// Holds an offest for spawning back blast effects
var() vector BackBlastOffset;

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

// Allow reloads for primary weapon to be interupted by firing secondary weapon
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return true;
	}

	return Super.CanOverrideMagReload(FireModeNum);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
}

// Instead of switch fire mode switch projectile type and damage type
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

// ***************** lock-on *****************

// Given an potential target TA determine if we can lock on to it.  By default only allow locking onto pawns.
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

/** Finds a new lock on target */
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

/** Adjusts our destination target impact location */
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

/** Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out */
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Bullet_Martian BulletProj;
	local KFPawn TargetPawn;

    if ( CurrentFireMode == DEFAULT_FIREMODE )
	{
		FindTarget(TargetPawn);

		BulletProj = KFProj_Bullet_Martian( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( BulletProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				BulletProj.SetLockedTarget( TargetPawn );
			}
		}

		return BulletProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

// ***************** Explosion blast *****************

/** Fires a projectile, but also does the back blast */
simulated function CustomFire()
{
	local KFExplosionActorReplicated ExploActor;
	local vector SpawnLoc;
	local rotator SpawnRot;

    // ProjectileFire();

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

            BlastRotation = Rotator(Vector(ViewRotation) * 1); //-1 would cast it backwards
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

            BlastRotation = Rotator(Vector(ViewRotation) * 1);
            BlastLocation = Instigator.GetPawnViewLocation() + (BackBlastOffset >> ViewRotation);
		}
	}
}

// ***************** Misc *****************

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
    // FOV
	MeshFOV=96
	MeshIronSightFOV=77
    PlayerIronSightFOV=77

	// Zooming/Position
	PlayerViewOffset=(X=12.0,Y=12,Z=-6)
	IronSightPosition=(X=10,Y=5.5,Z=-0.5)

	// Content
	PackageKey="Martian"
	FirstPersonMeshName="WEP_Martian_MESH.WEP_1P_Martian_Rig"
	FirstPersonAnimSetNames(0)="WEP_Martian_ARCH.Wep_1stP_Martian_Anim"
	PickupMeshName="WEP_Martian_MESH.Wep_Martian_Pickup"
	AttachmentArchetypeName="WEP_Martian_ARCH.WEP_Martian_3P"
	MuzzleFlashTemplateName="WEP_Martian_ARCH.Wep_Martian_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=30
	SpareAmmoCapacity[0]=330 //240
	InitialSpareMags[0]=3
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=100 //160
	minRecoilPitch=90 //140
	maxRecoilYaw=60
	minRecoilYaw=-60
	RecoilRate=0.01
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=250
	RecoilISMinPitchLimit=65485

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'UI_SecondaryAmmo_TEX.UI_FireModeSelect_AutoTarget'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Martian'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Martian'
	FireInterval(DEFAULT_FIREMODE)=+.067 // 900 RPM //+.05455 // 1100 RPM 
	InstantHitDamage(DEFAULT_FIREMODE)=35 //50 24
	Spread(DEFAULT_FIREMODE)=0.5 //0.015
	PenetrationPower(DEFAULT_FIREMODE)=1.0 //0.0f
	FireOffset=(X=20,Y=4.0,Z=-3)

	MaxTargetAngle=10 //30

	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Custom
	// WeaponProjectiles(ALTFIRE_FIREMODE)=class''
	// InstantHitDamageTypes(ALTFIRE_FIREMODE)=class''
	FireInterval(ALTFIRE_FIREMODE)=0.4 // 150 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=28
	Spread(ALTFIRE_FIREMODE)=0.25 //0.015
	BackBlastOffset=(X=20,Y=4.0,Z=-3) // same as muzzle location
	ExplosionTemplate=KFGameExplosion'WEP_Martian_ARCH.Wep_Martian_BlastExplosion'

	AltAmmo=100
	MagazineCapacity[1]=100
	AmmoCost(ALTFIRE_FIREMODE)=30 //20
	AltFullRechargeSeconds=8 //15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	// bAllowClientAmmoTracking=true

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_93R'
	InstantHitDamage(BASH_FIREMODE)=20

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Auto_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Auto_Loop')
	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Fire_3P_EndLoop', FirstPersonCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Fire_1P_EndLoop')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_SonicGun.Play_WEP_HRG_SonicGun_3P_Fire_High', FirstPersonCue=AkEvent'WW_WEP_HRG_SonicGun.Play_WEP_HRG_SonicGun_1P_Fire_High')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_9mm.Play_WEP_SA_9mm_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_9mm.Play_WEP_SA_9mm_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=true
	WeaponFireSnd(2)=(DefaultCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_G18.Play_WEP_G18_Fire_1P_Single')
	SingleFireSoundIndex=2

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'WEP_Martian_ARCH.LaserSight_Martian_1P'

	// Inventory
	InventorySize=4
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_Martian_MAT.UI_WeaponSelect_Martian'
	bIsBackupWeapon=false
   	AssociatedPerkClasses(0)=class'KFPerk_Gunslinger'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

	// DualClass=class''

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4)

	bHasFireLastAnims=true

	BonesToLockOnEmpty=(RW_Bolt, RW_Bullets1)

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.35f), (Stat=EWUS_Weight, Add=2)))
}