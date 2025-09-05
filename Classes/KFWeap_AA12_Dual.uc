class KFWeap_AA12_Dual extends KFWeap_DualBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

simulated state WeaponFiring
{
	simulated function FireAmmunition()
    {
    	bFireFromRightWeapon = !bFireFromRightWeapon;
        Super.FireAmmunition();
	}
}

// Returns animation to play based on reload type and status
simulated function name GetReloadAnimName(bool bTacticalReload)
{
	if ( AmmoCount[0] < 39 )
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
	// Content
	PackageKey="AA12_Dual"
	FirstPersonMeshName="WEP_Dual_AA12_MESH.Wep_1stP_Dual_AA12_Rig"
	FirstPersonAnimSetNames(0)="WEP_Dual_AA12_ARCH.Wep_1stP_Dual_AA12_Clip_Anim" //WEP_Dual_AA12_ARCH.Wep_1stP_Dual_AA12_Anim
	PickupMeshName="WEP_Dual_AA12_MESH.Wep_Dual_AA12_Pickup"
	AttachmentArchetypeName="WEP_Dual_AA12_ARCH.Wep_Dual_AA12_3P" //WEP_Dual_AA12_ARCH.WEP_AA12_Dual_3P tracer
	MuzzleFlashTemplateName="WEP_Dual_AA12_ARCH.Wep_Dual_AA12_MuzzleFlash"

	// Zooming/Position
	IronSightPosition=(X=-3,Y=0,Z=0) //disabled
	PlayerViewOffset=(X=5,Y=0,Z=-10) //z-8
	QuickWeaponDownRotation=(Pitch=-8192,Yaw=0,Roll=0)
	FireTweenTime=0.03
	
	SingleClass=class'KFWeap_AA12Exp'

	// FOV
	MeshFOV=70 //84
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Ammo
	MagazineCapacity[0]=40
	SpareAmmoCapacity[0]=160
	InitialSpareMags[0]=2
	AmmoPickupScale[0]=1.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=190
	minRecoilPitch=180
	maxRecoilYaw=95
	minRecoilYaw=-95
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

	// DEFAULT_FIREMODE (Explosive bullets)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_AA12_Dual'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_AA12_Dual'
	FireInterval(DEFAULT_FIREMODE)=0.2 // 300 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=20
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.07
	NumPellets(DEFAULT_FIREMODE)=1
	FireOffset=(X=17,Y=4.0,Z=-3) //20
	LeftFireOffset=(X=8,Y=-4,Z=-2.25) //17

	// ALT_FIREMODE (Explosive bullets)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_AA12_Dual'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_AA12_Dual'
	FireInterval(ALTFIRE_FIREMODE)=0.2 // 300 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=20
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=0.07
	NumPellets(ALTFIRE_FIREMODE)=1

	SelfDamageReductionValue=0.10f; //0.16

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_AA12Shotgun'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=false //true
	bHasFlashlight=true

	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	// Inventory
	InventoryGroup=IG_Primary
	InventorySize=8 //9
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_Dual_AA12_MAT.UI_WeaponSelect_AA12_Dual'
	bIsBackupWeapon=false

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

  	//bHasFireLastAnims=true

  	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=1)))
}