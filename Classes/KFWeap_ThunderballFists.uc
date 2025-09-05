class KFWeap_ThunderballFists extends KFWeap_PistolBase;

// Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion)
// var() float SelfDamageReductionValue;

/*
//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
    super.AdjustDamage(InDamage, DamageType, DamageCauser);

    if (Instigator != none && DamageCauser.Instigator == Instigator)
    {
        InDamage *= SelfDamageReductionValue;
    }
}
*/

// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
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

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

defaultproperties
{
    // FOV
	MeshFOV=86
	MeshIronSightFOV=77
    PlayerIronSightFOV=77

	// Zooming/Position
	PlayerViewOffset=(X=14.0,Y=10,Z=-4)
	IronSightPosition=(X=11,Y=0,Z=-0.9)

	// Content
	PackageKey="ThunderballFists"
	FirstPersonMeshName="WEP_ThunderballFists_MESH.Wep_1stP_ThunderballFists_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_Deagle_ANIM.Wep_1st_Deagle_Anim"
	PickupMeshName="WEP_ThunderballFists_MESH.Wep_ThunderballFists_Pickup"
	AttachmentArchetypeName="WEP_ThunderballFists_ARCH.Wep_ThunderballFists_3P"
	MuzzleFlashTemplateName="WEP_Deagle_ARCH.Wep_Deagle_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=7
	SpareAmmoCapacity[0]=70
	InitialSpareMags[0]=5
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=550
	minRecoilPitch=450
	maxRecoilYaw=140
	minRecoilYaw=-140
	RecoilRate=0.07
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1250
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485

	// DEFAULT_FIREMODE (On impact explodes into electricity and spawns a dropplet that launches upwards and explodes on fuze)
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_ThunderballFists'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_ThunderballFists'
	FireInterval(DEFAULT_FIREMODE)=+0.2
	InstantHitDamage(DEFAULT_FIREMODE)=100 //91
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.01
	FireOffset=(X=20,Y=4.0,Z=-3)

    // SelfDamageReductionValue=0.18f;

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Deagle'
	InstantHitDamage(BASH_FIREMODE)=22

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Fire_Single_S')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
    bHasLaserSight=true
    LaserSightTemplate=KFLaserSightAttachment'WEP_ThunderballFists_ARCH.LaserSight_ThunderballFists_1P'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

	// Inventory
	InventorySize=4 //3
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_ThunderballFists_MAT.UI_WeaponSelect_ThunderballFists'
	bIsBackupWeapon=false
	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'
	AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4)

	bHasFireLastAnims=true

	BonesToLockOnEmpty=(RW_Slide, RW_Bullets1)

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Medium_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
}