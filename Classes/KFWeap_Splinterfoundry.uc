class KFWeap_Splinterfoundry extends KFWeap_ShotgunBase;

// struct WeaponFireSoundInfo
// {
// 	var() SoundCue	DefaultCue;
// 	var() SoundCue	FirstPersonCue;
// };

// var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

var protected const array<vector2D> PelletSpread;

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

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAltRecharge();
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

// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

// Disable normal bullet spread
simulated function rotator AddSpread(rotator BaseAim)
{
	return BaseAim; // do nothing
}

// Returns number of projectiles to fire from SpawnProjectile
simulated function byte GetNumProjectilesToFire(byte FireModeNum)
{
	return NumPellets[CurrentFireMode];
}

// Same as AddSpread(), but used with MultiShotSpread
static function rotator AddMultiShotSpread( rotator BaseAim, float CurrentSpread, byte PelletNum )
{
	local vector X, Y, Z;
	local float RandY, RandZ;

	if (CurrentSpread == 0) // 0.3214
	{
		return BaseAim;
	}
	else
	{
        // No randomized spread, it's controlled in PelletSpread down bellow
		GetAxes(BaseAim, X, Y, Z);
		RandY = default.PelletSpread[PelletNum].Y; //* RandRange( 0.5f, 1.5f
		RandZ = default.PelletSpread[PelletNum].X;
		return rotator(X + RandY * CurrentSpread * Y + RandZ * CurrentSpread * Z);
	}
}

/*
// Allows weapon to calculate its own damage for display in trader
// Overridden to multiply damage by number of pellets
static simulated function float CalculateTraderWeaponStatDamage()
{
    local float BaseDamage, DoTDamage;
    local class<KFDamageType> DamageType;

    local GameExplosion ExplosionInstance;

    ExplosionInstance = class<KFProjectile>(default.WeaponProjectiles[DEFAULT_FIREMODE]).default.ExplosionTemplate;

    BaseDamage = default.InstantHitDamage[DEFAULT_FIREMODE] + ExplosionInstance.Damage;

    DamageType = class<KFDamageType>(ExplosionInstance.MyDamageType);
    if( DamageType != none && DamageType.default.DoT_Type != DOT_None )
    {
        DoTDamage = (DamageType.default.DoT_Duration / DamageType.default.DoT_Interval) * (BaseDamage * DamageType.default.DoT_DamageScale);
    }

    return BaseDamage * default.NumPellets[DEFAULT_FIREMODE] + DoTDamage;
}
*/

// Tight choke skill - remove if you want slugs ("combines" 9 bullets into one)
simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFPerk InstigatorPerk;

	if (CurrentFireMode == DEFAULT_FIREMODE)
	{
		InstigatorPerk = GetPerk();
		if (InstigatorPerk != none)
		{
			Spread[CurrentFireMode] = default.Spread[CurrentFireMode] * InstigatorPerk.GetTightChokeModifier();
		}
	}

	return super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) || 
		!HasAmmo(ALTFIRE_FIREMODE))
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
	local KFProj_Rocket_Splinterfoundry RocketProj;
	local KFPawn TargetPawn;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    if ( CurrentFireMode == ALTFIRE_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Rocket_Splinterfoundry( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

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
		// CurrentFireMode = DEFAULT_FIREMODE;

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

/*
simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
	}
}
*/

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}

defaultproperties
{
	// Inventory
	InventorySize=6
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Splinterfoundry_MAT.UI_WeaponSelect_Splinterfoundry'
	AssociatedPerkClasses(0)=class'KFPerk_Support'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshIronSightFOV=60 //52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=10.0,Y=8.0,Z=-3.5) //8
	IronSightPosition=(X=0.0,Y=5.0,Z=-1.0)

	// Content
	PackageKey="Splinterfoundry"
	FirstPersonMeshName="WEP_Splinterfoundry_MESH.Wep_1stP_Splinterfoundry_Rig"
	FirstPersonAnimSetNames(0)="WEP_Splinterfoundry_ARCH.Wep_1stp_Splinterfoundry_Anim"
	PickupMeshName="WEP_Splinterfoundry_MESH.Wep_Splinterfoundry_Pickup"
	AttachmentArchetypeName="WEP_Splinterfoundry_ARCH.WEP_Splinterfoundry_3P"
	MuzzleFlashTemplateName="WEP_Splinterfoundry_ARCH.Wep_Splinterfoundry_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=8
	SpareAmmoCapacity[0]=96
	InitialSpareMags[0]=3
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=false

	// Recoil
	maxRecoilPitch=575
	minRecoilPitch=500
	maxRecoilYaw=355
	minRecoilYaw=-355
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

	// DEFAULT_FIREMODE (Custom pellet spread)
	FireModeIconPaths(DEFAULT_FIREMODE)="ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle"
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Splinterfoundry'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Splinterfoundry'
	InstantHitDamage(DEFAULT_FIREMODE)=35 //45 //50 80
	FireInterval(DEFAULT_FIREMODE)=0.77 // 78 RPM
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	FireOffset=(X=30,Y=3,Z=-3)

	Spread(DEFAULT_FIREMODE)=0.1f
	NumPellets(DEFAULT_FIREMODE)=9
	PelletSpread(0)=(X=0.0f,Y=0.0f)
	PelletSpread(1)=(X=0.0f,Y=0.2f)
	PelletSpread(2)=(X=0.2f,Y=0.0f)
	PelletSpread(3)=(X=-0.2f,Y=0.0f)
	PelletSpread(4)=(X=0.0f,Y=-0.2f)
	PelletSpread(5)=(X=0.0f,Y=0.3f)
	PelletSpread(6)=(X=0.0f,Y=0.4f)
	PelletSpread(7)=(X=0.0f,Y=-0.3f)
	PelletSpread(8)=(X=0.0f,Y=-0.4f)

	// ALT_FIREMODE (Rocket that explodes proximity to ZED (2 meters) and stuns them)
	// FireModeIconPaths(ALTFIRE_FIREMODE)="ONE_MAT.UI_FireModeSelect_Percentage"
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_Splinterfoundry'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Splinterfoundry'
	InstantHitDamage(ALTFIRE_FIREMODE)=35
	FireInterval(ALTFIRE_FIREMODE)=0.77 // 78 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=0
	NumPellets(ALTFIRE_FIREMODE)=1
	Spread(ALTFIRE_FIREMODE)=0.025
	
	MaxTargetAngle=55 //30

	AltAmmo=100
	MagazineCapacity[1]=100
	AmmoCost(ALTFIRE_FIREMODE)=60
	AltFullRechargeSeconds=8
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	// bAllowClientAmmoTracking=true

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_MB500'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'DROW_SND.Play_WEP_Splinterfoundry_3P_Shoot', FirstPersonCue=AkEvent'DROW_SND.Play_WEP_Splinterfoundry_1P_Shoot')
    WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'DROW_SND.Play_WEP_Splinterfoundry_3P_Alt', FirstPersonCue=AkEvent'DROW_SND.Play_WEP_Splinterfoundry_1P_Alt')
	// WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Splinterfoundry_SND.sf_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Splinterfoundry_SND.sf_fire_Cue')
	// WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Splinterfoundry_SND.sf_fire_fullauto_3P_Cue', FirstPersonCue=SoundCue'WEP_Splinterfoundry_SND.sf_fire_fullauto_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_M4.Play_WEP_SA_M4_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_M4.Play_WEP_SA_M4_Handling_DryFire'
	EjectedShellForegroundDuration=1.5f

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true

	// Animations
    bHasFireLastAnims=true

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}