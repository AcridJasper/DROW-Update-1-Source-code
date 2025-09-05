class KFWeap_FlareGlowstick extends KFWeap_ThrownBase;

// How many DEF ammo to recharge per second
var float DEFFullRechargeSeconds;
var transient float DEFRechargePerSecond;
var transient float DEFIncrement;
var repnotify byte DEFAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		DEFAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(DEFAmmo))
	{
		AmmoCount[DEFAULT_FIREMODE] = DEFAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartDEFRecharge();
}

function StartDEFRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedDEFRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedDEFRechargeTime = DEFFullRechargeSeconds;
	    DEFRechargePerSecond = MagazineCapacity[DEFAULT_FIREMODE] / UsedDEFRechargeTime;
		DEFIncrement = 0;
	}
}

function RechargeDEF(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		DEFIncrement += DEFRechargePerSecond * DeltaTime;

		if( DEFIncrement >= 1.0 && AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
		{
			AmmoCount[DEFAULT_FIREMODE]++;
			DEFIncrement -= 1.0;
			DEFAmmo = AmmoCount[DEFAULT_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartDEFRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
	{
        RechargeDEF(DeltaTime);
	}

	Super.Tick(DeltaTime);
}

simulated function string GetSpecialAmmoForHUD()
{
	return int(DEFAmmo)$"%";
}

simulated function bool CanBuyAmmo()
{
	return false;
}

function bool CanUpgradeWeapon()
{
	return false;
}

// Route ironsight player input to bash
simulated function SetIronSights(bool bNewIronSights)
{
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	if ( bNewIronSights )
	{
		StartFire(BASH_FIREMODE);
	}
}

// Instead of a toggle, immediately fire alternate fire to bash
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	StartFire(BASH_FIREMODE);
}

/** Allow weapons with abnormal state transitions to always use zed time resist*/
simulated function bool HasAlwaysOnZedTimeResist()
{
    return true;
}

simulated state Active
{
	/** Overridden to prevent playing fidget if play has no more ammo */
	simulated function bool CanPlayIdleFidget(optional bool bOnReload)
	{
		if( !HasAmmo(0) )
		{
			return false;
		}

		return super.CanPlayIdleFidget( bOnReload );
	}
}

simulated state WeaponThrowing
{
	/** Never refires.  Must re-enter this state instead. */
	simulated function bool ShouldRefire()
	{
		return false;
	}

    simulated function EndState(Name NextStateName)
    {
        local KFPerk InstigatorPerk;

        Super.EndState(NextStateName);

        //Targeted fix for Demolitionist w/ the C4.  It should remain in zed time  while waiting on
        //      the fake reload to be triggered.  This will return 0 for other perks.
        InstigatorPerk = GetPerk();
        if( InstigatorPerk != none )
        {
            SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
        }
    }
}

simulated state WeaponEquipping
{
	simulated event BeginState( name PreviousStateName )
	{
		super.BeginState( PreviousStateName );

		// perform a "reload" if we refilled our ammo from empty while it was unequipped
		if( !HasAmmo(THROW_FIREMODE) && HasSpareAmmo() )
		{
			PerformArtificialReload();
		}
	}
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Projectile;
}

defaultproperties
{
	// Zooming/Position
	PlayerViewOffset=(X=6.0,Y=2,Z=-4)
	FireOffset=(X=25,Y=15)

	// Content
	PackageKey="FlareGlowstic"
	FirstPersonMeshName="WEP_FlareGlowstick_MESH.Wep_1stP_FlareGlowstick_Rig"
	FirstPersonAnimSetNames(0)="WEP_FlareGlowstick_ARCH.Wep_1P_FlareGlowstick_ANIM"
	PickupMeshName="WEP_FlareGlowstick_MESH.Wep_FlareGlowstick_Pickup"
	AttachmentArchetypeName="WEP_FlareGlowstick_ARCH.Wep_FlareGlowstick_3P"

	// Anim
	FireAnim=C4_Throw
	FireLastAnim=C4_Throw_Last

	// Ammo
	SpareAmmoCapacity[0]=0 //2 //5
	InitialSpareMags[0]=1
	AmmoPickupScale[0]=1.0

	DEFAmmo=100
	MagazineCapacity[0]=100
	AmmoCost(DEFAULT_FIREMODE)=100
	DEFFullRechargeSeconds=30 //20
	// bAllowClientAmmoTracking=true

	// THROW_FIREMODE
	FireInterval(THROW_FIREMODE)=0.25
	FireModeIconPaths(THROW_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	WeaponProjectiles(THROW_FIREMODE)=class'KFProj_FlareGlowstick'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_C4'
	InstantHitDamage(BASH_FIREMODE)=23

	// Inventory / Grouping
	InventoryGroup=IG_Equipment
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_FlareGlowstick_MAT.UI_WeaponSelect_FlareGlowstick'
	InventorySize=1

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Mythical_DROW' // Loot beam fx (no offset)

   	// AssociatedPerkClasses(0)=class'KFPerk_Survivalist'
	AssociatedPerkClasses(0)=none
}