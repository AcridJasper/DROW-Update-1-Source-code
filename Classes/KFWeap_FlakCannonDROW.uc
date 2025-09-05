class KFWeap_FlakCannonDROW extends KFWeap_ShotgunBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** How much to scale recoil when firing in double barrel fire. */
var(Recoil) float DoubleFireRecoilModifier;

/** Shoot animation to play when shooting both barrels from the hip */
var(Animations) const editconst	name FireDoubleAnim;

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

// Toggle between DEFAULT and ALTFIRE
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

    if (AmmoCount[0] == 1)
    {
        StartFire(DEFAULT_FIREMODE);
    }
    else
    {
        StartFire(ALTFIRE_FIREMODE);
    }
}

// Send weapon to proper firing state
simulated function SendToFiringState(byte FireModeNum)
{
	if( FireModeNum == ALTFIRE_FIREMODE && AmmoCount[0] == 1)
    {
		// not enough ammo for altfire
		Super.SendToFiringState(DEFAULT_FIREMODE);
	}
	else
	{
		Super.SendToFiringState(FireModeNum);
	}
}

simulated state WeaponDoubleBarrelFiring extends WeaponSingleFiring
{
    // Overrideen to include the DoubleFireRecoilModifier
    simulated function ModifyRecoil( out float CurrentRecoilModifier )
	{
		super.ModifyRecoil( CurrentRecoilModifier );
	    CurrentRecoilModifier *= DoubleFireRecoilModifier;
	}
}

// Handle one-hand fire anims
simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if ( bUsingSights )
	{
        return FireSightedAnims[FireModeNum];
	}
	else
	{
    	if ( FireModeNum == ALTFIRE_FIREMODE )
    	{
            return FireDoubleAnim;
    	}
    	else
    	{
            return FireAnim;
        }
	}
}

// Causes the muzzle flash to turn on and setup a time to  turn it back off again.
simulated function CauseMuzzleFlash(byte FireModeNum)
{
	// Alternate barrels
    if( FireModeNum == DEFAULT_FIREMODE )
	{
        if( AmmoCount[0] == 1 )
        {
            super.CauseMuzzleFlash(DEFAULT_FIREMODE);
        }
        else
        {
            super.CauseMuzzleFlash(ALTFIRE_FIREMODE);
        }
	}
	// Fire both barrels
	else
	{
        super.CauseMuzzleFlash(DEFAULT_FIREMODE);
        super.CauseMuzzleFlash(ALTFIRE_FIREMODE);
	}
}

// Returns animation to play based on reload type and status (reloads both shells after third shot)
simulated function name GetReloadAnimName(bool bTacticalReload)
{
	if ( AmmoCount[0] < 3 )
	{
		return (bTacticalReload) ? ReloadEmptyMagEliteAnim : ReloadEmptyMagAnim; //empty
	}
	else
	{
		return (bTacticalReload) ? ReloadNonEmptyMagEliteAnim : ReloadNonEmptyMagAnim; //half
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

defaultproperties
{
	// Inventory
	InventorySize=5 //4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_FlakCannonDROW_MAT.UI_WeaponSelect_FlakCannonDROW'
	AssociatedPerkClasses(0)=class'KFPerk_Support'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=80 //75
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=4.0,Y=7.0,Z=-5.0)
	IronSightPosition=(X=3,Y=4.0,Z=-1.5)

	// Content
	PackageKey="FlakCannonDROW"
	FirstPersonMeshName="WEP_FlakCannonDROW_MESH.Wep_1stP_FlakCannonDROW_Rig"
	FirstPersonAnimSetNames(0)="WEP_FlakCannonDROW_ARCH.Wep_1stP_FlakCannonDROW_Anim"
	PickupMeshName="WEP_FlakCannonDROW_MESH.Wep_FlakCannonDROW_Pickup"
	AttachmentArchetypeName="WEP_FlakCannonDROW_ARCH.Wep_FlakCannonDROW_Trail_3P"
	MuzzleFlashTemplateName="WEP_Shotgun_DoubleBarrel_ARCH.Wep_Shotgun_DoubleBarrel_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=4 //2
	SpareAmmoCapacity[0]=84 //92
	InitialSpareMags[0]=15
	AmmoPickupScale[0]=3.0
	bCanBeReloaded=true
	bReloadFromMagazine=true
	bNoMagazine=true

	// Recoil
	maxRecoilPitch=600
	minRecoilPitch=575
	maxRecoilYaw=420
	minRecoilYaw=-420
	RecoilRate=0.085
	RecoilBlendOutRatio=1.1
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
	DoubleFireRecoilModifier=1.0 //1.25
	HippedRecoilModifier=1.25

	// DEFAULT_FIREMODE (Bouncing rubber balls)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_FlakCannonDROW'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_FlakCannonDROW'
	InstantHitDamage(DEFAULT_FIREMODE)=50 //40 //38
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	FireInterval(DEFAULT_FIREMODE)=0.25 // 240 RPM
	NumPellets(DEFAULT_FIREMODE)=12
	Spread(DEFAULT_FIREMODE)=0.09 //0.25
	FireOffset=(X=25,Y=3.5,Z=-4)
	// ForceReloadTimeOnEmpty=0.3

	// ALT_FIREMODE (High damage sharpnel shot with massive spread, sharpnel damages for 80 but rarley hits)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponDoubleBarrelFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_FlakCannonDROW_Secondary'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_FlakCannonDROW_Secondary'
	InstantHitDamage(ALTFIRE_FIREMODE)=200 //250
	PenetrationPower(ALTFIRE_FIREMODE)=4.0
	FireInterval(ALTFIRE_FIREMODE)=0.25 // 240 RPM
	NumPellets(ALTFIRE_FIREMODE)=1
	Spread(ALTFIRE_FIREMODE)=0.007
	AmmoCost(ALTFIRE_FIREMODE)=2

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_DBShotgun'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Fire_1P')
    //WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Alt_Fire_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_FlakCannonDROW_SND.flakDROW_shot_loud_noclip_3P_Cue', FirstPersonCue=SoundCue'WEP_FlakCannonDROW_SND.flakDROW_shot_loud_noclip_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_FlakCannonDROW_SND.flakDROW_shot_loud_noclip_3P_Cue', FirstPersonCue=SoundCue'WEP_FlakCannonDROW_SND.flakDROW_shot_loud_noclip_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
    bHasLaserSight=true
    LaserSightTemplate=KFLaserSightAttachment'DROW_ARCH.LaserSight_DROW_WithAttachment_1P'

	// Animations
	FireAnim=Shoot_Single
	FireDoubleAnim=Shoot_Double
	FireSightedAnims[0]=Shoot_Iron_Single
	FireSightedAnims[1]=Shoot_Iron_Double
    bHasFireLastAnims=false

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
}