class KFWeap_SkyKiller extends KFWeap_RifleBase;

var transient KFParticleSystemComponent ParticlePSC;
var ParticleSystem ParticleFX;

const ParticleSocketName = 'ParticleFX';

const SecondaryFireAnim      = 'Shoot_Secondary';
const SecondaryFireIronAnim  = 'Shoot_Secondary_Iron';

simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}

	return super.GetWeaponFireAnim(FireModeNum);
}

simulated function AltFireMode()
{
	local KFPawn_Human P;

	super.AltFireMode();
	
	// LocalPlayer Only
	if( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	if( WorldInfo.NetMode == NM_DedicatedServer )
	{
		return;
	}
	
	if(bUseAltFireMode)
	{
		ParticlePSC.SetTemplate(ParticleFX);
		ParticlePSC.ActivateSystem();
	}
	else
	{
		ParticlePSC.DeactivateSystem();
	}
	
	P = KFPawn_Human(Instigator);
	if(P != none)
	{
		P.SetUsingAltFireMode(bUseAltFireMode, true);
		P.bNetDirty = true;
	}
}

simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo(MeshCpnt, SocketName);

	if( ParticlePSC == none )
	{
		ParticlePSC = new(self) class'KFParticleSystemComponent';
		ParticlePSC.SetDepthPriorityGroup(SDPG_Foreground);
		ParticlePSC.SetTickGroup(TG_PostUpdateWork);
		ParticlePSC.SetFOV(MySkelMesh.FOV);
		
		MySkelMesh.AttachComponentToSocket(ParticlePSC, ParticleSocketName);
	}

	if( bUseAltFireMode )
	{
		ParticlePSC.SetTemplate(ParticleFX);
		ParticlePSC.ActivateSystem();
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if(ParticlePSC != none)
	{
		ParticlePSC.SetFOV(NewFOV);
	}
}

simulated function DetachWeapon()
{
	if(ParticlePSC != none)
	{
		ParticlePSC.DeactivateSystem();
		MySkelMesh.DetachComponent(ParticlePSC);
		ParticlePSC = none;
	}
	
    super.DetachWeapon();
}

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

defaultproperties
{
	// Inventory / Grouping
	InventorySize=6 //7
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_SkyKiller_MAT.UI_WeaponSelect_SkyKiller'
   	AssociatedPerkClasses(0)=class'KFPerk_Sharpshooter'
   	AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=70
	MeshIronSightFOV=45 //27
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=11.5,Z=-4)
	IronSightPosition=(X=0.0,Y=-0.05,Z=0.4)

	// Content
	PackageKey="SkyKiller"
	FirstPersonMeshName="WEP_SkyKiller_MESH.WEP_1stP_SkyKiller_Rig"
	FirstPersonAnimSetNames(0)="WEP_SkyKiller_ARCH.Wep_1stP_SkyKiller_Anim" //WEP_1P_M14EBR_ANIM.Wep_1stP_M14_EBR_Anim
	PickupMeshName="WEP_SkyKiller_MESH.Wep_SkyKiller_Pickup"
	AttachmentArchetypeName="WEP_SkyKiller_ARCH.WEP_SkyKiller_FX_3P" //WEP_SkyKiller_ARCH.Wep_SkyKiller_3P
	MuzzleFlashTemplateName="WEP_SkyKiller_ARCH.Wep_SkyKiller_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=20
	SpareAmmoCapacity[0]=180 //160
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Recoil
	maxRecoilPitch=225
	minRecoilPitch=200
	maxRecoilYaw=200
	minRecoilYaw=-200
	RecoilRate=0.08
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.6

	// DEFAULT_FIREMODE (On impact spawns lightning strike (it's just delayed explosive))
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_SkyKiller'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_SkyKiller'
	InstantHitDamage(DEFAULT_FIREMODE)=92
	FireInterval(DEFAULT_FIREMODE)=0.22 //0.2
	PenetrationPower(DEFAULT_FIREMODE)=0 //2.0
	Spread(DEFAULT_FIREMODE)=0.006
	FireOffset=(X=30,Y=3.0,Z=-2.5)

	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_HeavyBulletSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_SkyKiller_ALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_SkyKiller_ALT'
	InstantHitDamage(ALTFIRE_FIREMODE)=150 //110
	FireInterval(ALTFIRE_FIREMODE)=0.4 // 150 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=5.0
	Spread(ALTFIRE_FIREMODE)=0.006

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M14EBR'
	InstantHitDamage(BASH_FIREMODE)=27

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Fire_Single_S')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Shoot_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.LaserSight_WithAttachment_1P'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Medium_Recoil'

	ParticleFX=ParticleSystem'DROW_EMIT.FX_SkyKiller_ALT_Particle'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Weight, Add=2)))
}