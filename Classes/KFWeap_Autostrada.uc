class KFWeap_Autostrada extends KFWeap_RifleBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

/** Time interval for updating radar positions */
var const float RadarUpdateEntitiesTime;
/** Distance the radar can track enemies */
var const float MaxRadarDistance;
/** Speed at which the radar moves (rad/sec) */
var const float RadarSpeed;

var transient array<KFPawn_Monster> EnemiesInRadar;
var transient float PrevAngle;
var transient bool bRequiresRadarClear;

var class<KFGFxWorld_WeaponRadar> RadarUIClass;
var KFGFxWorld_WeaponRadar RadarUI;

simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		PrevAngle = 0.0f;

	 	if (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone)
		{
			StartRadar();
		}
	}
} 

simulated state WeaponPuttingDown
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

	 	if (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone)
		{
			StopRadar();
		}
	}
}

simulated function StartRadar()
{
	EnemiesInRadar.Length = 0;
	SetTimer(RadarUpdateEntitiesTime, true, nameof(UpdateRadarEntities));
}

simulated function StopRadar()
{
	ClearTimer(nameof(UpdateRadarEntities));
}

simulated function UpdateRadarEntities()
{
	local KFPawn_Monster KFPM;
	local int RadarIndex;
	local bool bIsAlive;

	bIsAlive = false;

	// Get nearby enemies
	foreach CollidingActors(class'KFPawn_Monster', KFPM, MaxRadarDistance, Location, true)
	{
		RadarIndex = FindEnemyTrackedByRadar(KFPM);
		bIsAlive = KFPM.IsAliveAndWell();

		if (RadarIndex == INDEX_NONE)
		{
			if (bIsAlive)
			{
				EnemiesInRadar.AddItem(KFPM);
			}
		}
		else if(!bIsAlive)
		{
			EnemiesInRadar.RemoveItem(KFPM);
		}
	}
}

simulated function int FindEnemyTrackedByRadar(KFPawn_Monster KFPM)
{
	local int i;

	for (i = 0; i < EnemiesInRadar.Length; ++i)
	{
		if (KFPM == EnemiesInRadar[i] )
		{
			return i;
		}
	}

	return INDEX_NONE;
}

simulated function Tick(float Delta)
{
	local float DistanceSqrd;
	local vector Distance, ScreenDirection, UILocation;
	local rotator ViewRotation;
	local int i;
	local array<vector> RadarElements;

	super.Tick(Delta);

	if (RadarUI != none)
	{
		if (bRequiresRadarClear)
		{
			RadarUI.Clear();
		}

		if (EnemiesInRadar.Length == 0)
		{
			if (bRequiresRadarClear)
			{
				bRequiresRadarClear = false;
			}

			return;
		}

		ViewRotation = Rotation;
		ViewRotation.Yaw  *= -1;
		ViewRotation.Pitch = 0;
		ViewRotation.Roll  = 0;

		RadarElements.Length = 0;

		for (i = EnemiesInRadar.Length - 1; i >= 0; --i)
		{
			if (!EnemiesInRadar[i].IsAliveAndWell())
			{
				EnemiesInRadar.Remove(i, 1);
				continue;
			}

			Distance = EnemiesInRadar[i].Location - Location;
			DistanceSqrd = VSizeSQ(Distance);

			if (DistanceSqrd > MaxRadarDistance * MaxRadarDistance)
			{
				EnemiesInRadar.Remove(i, 1);
				continue;
			}

			Distance.Z = 0;
			ScreenDirection = Distance >> ViewRotation;

			UILocation.X = ScreenDirection.Y / MaxRadarDistance;
			UILocation.Y = ScreenDirection.X / MaxRadarDistance;

			RadarElements.AddItem(UILocation);
		}

		if (RadarElements.length > 0)
		{
			RadarUI.AddRadarElements(RadarElements);
			bRequiresRadarClear = true;
		}
	}
}

// Radar UI
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFInventoryManager KFIM;

	super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	if (RadarUI == none && RadarUIClass != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			RadarUI = KFGFxWorld_WeaponRadar(KFIM.GetRadarUIMovie(RadarUIClass));
		}
	}
}

function ItemRemovedFromInvManager()
{
	local KFInventoryManager KFIM;

	Super.ItemRemovedFromInvManager();

	if (RadarUI != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			KFIM.RemoveRadarUIMovie(RadarUI.class);

			RadarUI.Close();
			RadarUI = none;
		}
	}
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

// Overriden to use instant hit vfx. Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    MyProjectileClass = GetKFProjectileClass();

	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	if( Instigator != None )
	{
		Instigator.SetFlashLocation( Self, CurrentFireMode, TestImpact.HitLocation );
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{

		if( StartTrace != RealStartLoc )
		{	
            DirB = AimDir;

			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

    		DirA = AimDir;

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

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
	// FOV
	MeshFOV=75
	MeshIronSightFOV=60 //33
	PlayerIronSightFOV=65 //70

	// Zooming/Position
	PlayerViewOffset=(X=2.0,Y=8,Z=-3)
	IronSightPosition=(X=0.0,Y=6.0,Z=1.3)

	// Content
	PackageKey="Autostrada"
	FirstPersonMeshName="WEP_Autostrada_MESH.Wep_1stP_Autostrada_Rig"
	FirstPersonAnimSetNames(0)="WEP_Autostrada_ARCH.Wep_1st_Autostrada_Anim"
	PickupMeshName="WEP_Autostrada_MESH.Wep_Autostrada_Pickup"
	AttachmentArchetypeName="WEP_Autostrada_ARCH.Wep_Autostrada_3P"
	MuzzleFlashTemplateName="WEP_Autostrada_ARCH.Wep_Autostrada_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=30
	SpareAmmoCapacity[0]=150 //180 210 300
	InitialSpareMags[0]=3
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=200
	minRecoilPitch=150
	maxRecoilYaw=175
	minRecoilYaw=-125
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	IronSightMeshFOVCompensationScale=2.5

	// Inventory / Grouping
	InventorySize=6
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Autostrada_MAT.UI_WeaponSelect_Autostrada'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

	// DEFAULT_FIREMODE (Explosive bullets)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Autostrada'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Autostrada'
	FireInterval(DEFAULT_FIREMODE)=0.25 // 240 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=30 //40
	Spread(DEFAULT_FIREMODE)=0.025 //0.0085
	FireOffset=(X=32,Y=4.0,Z=-5)

	SelfDamageReductionValue=0.10f; //0.16

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_AK12'
	InstantHitDamage(BASH_FIREMODE)=26

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_SCAR.Play_WEP_SA_SCAR_Single_Fire_M', FirstPersonCue=AkEvent'WW_WEP_SA_SCAR.Play_WEP_SA_SCAR_Single_Fire_S')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Autostrada_SND.autostrada1_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Autostrada_SND.autostrada1_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_AK12.Play_WEP_SA_AK12_Handling_DryFire'

	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
    bHasLaserSight=true
    LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.Default_LaserSight_1P'

	RadarUpdateEntitiesTime=0.1f
	MaxRadarDistance=2000
	RadarSpeed=2.0f
	RadarUIClass=class'KFGFxWorld_WeaponRadar'

	bRequiresRadarClear=false

	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=2)))
}