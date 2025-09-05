class KFWeap_AA12Exp extends KFWeap_PistolBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

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
	// Inventory
	InventoryGroup=IG_Primary
	InventorySize=8 //9
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Dual_AA12_MAT.UI_WeaponSelect_AA12Exp'
	bCanThrow=true
	bDropOnDeath=true
	bIsBackupWeapon=false

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

	DualClass=class'KFWeap_AA12_Dual'

     // FOV
 	MeshFOV=86
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=8.5,Z=0.0)
	IronSightPosition=(X=8,Y=0,Z=0)

	// Ammo
	MagazineCapacity[0]=20
	SpareAmmoCapacity[0]=160
	InitialSpareMags[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true
	bHasFireLastAnims=false

	// Recoil
	maxRecoilPitch=220
	minRecoilPitch=180
	maxRecoilYaw=125
	minRecoilYaw=-125
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
    
	// Content
	PackageKey="AA12"
	FirstPersonMeshName="Wep_1P_AA12_MESH.Wep_1stP_AA12_Rig"
	FirstPersonAnimSetNames(0)="Wep_1P_AA12_ANIM.Wep_1stP_AA12_Anim"
	PickupMeshName="WEP_3P_AA12_MESH.Wep_AA12_Pickup"
	AttachmentArchetypeName="WEP_Dual_AA12_ARCH.Wep_AA12Exp_3P"
	MuzzleFlashTemplateName="WEP_AA12_ARCH.Wep_AA12_MuzzleFlash"

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
	FireOffset=(X=30,Y=5,Z=-4)

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
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_1P')
    // WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Fire_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Dual_AA12_SND.aa12_c_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_AA12.Play_WEP_SA_AA12_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Shooting Animations
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3

	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Damage1, Scale=1.4f), (Stat=EWUS_Weight, Add=1)))
}