class KFPowerUp_HellishRaging extends KFPowerUp_DROW; // set SetAbolute to particle system

/** Health removed from the player when the power up is activated */
var int HealthCost;
/** Damage cost applied when the power up is activated */
var class<KFDamageType> PowerUpCostDamageType;

/** Damage modifier for all damage done by the owner of this power up */
var float DamageModifier;
/** Speed modifier for run speed by the owner of this power up */
var float SpeedModifier;
/** Speed modifier for sprint speed by the owner of this power up */
var float SprintSpeedModifier;

function ActivatePowerUp()
{
	super.ActivatePowerUp();
	if(Role == Role_Authority && bPowerUpActive)
	{
		ApplyPowerUpCost();
	}
}

function ReactivatePowerUp()
{
	super.ReactivatePowerUp();
	if(Role == Role_Authority && bPowerUpActive)
	{
		ApplyPowerUpCost();
	}
}

function ApplyPowerUpCost()
{
	OwnerPawn.TakeDamage(HealthCost, OwnerPC, vect(0,0,0), vect(0,0,0), PowerUpCostDamageType);
}

function ModifyDamageGiven( out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx )
{
	local float TempDamage;
	TempDamage = InDamage;

	if( DamageCauser != none )
	{
		TempDamage += InDamage * DamageModifier;
	}

	InDamage = Round( TempDamage );
}

simulated function ModifySpeed( out float Speed )
{
	Speed += Speed * SpeedModifier;
}

simulated function ModifySprintSpeed( out float Speed )
{
	Speed += Speed * SprintSpeedModifier;
}

function ApplySecondaryDamage( KFPawn Victim, int DamageTaken, optional Controller InstigatedBy )
{
	if( Victim != none && Victim != OwnerPawn )
	{
		Victim.ApplyDamageOverTime(SecondaryDamage, InstigatedBy, default.SecondaryDamageType);
	}
}

DefaultProperties
{
	PowerUpCostDamageType=class'KFDT_HellishRageCost'
	HealthCost=10 //5

	PowerUpDuration=15.f
	CanBeHealedWhilePowerUpIsActive=true

	DamageModifier=0.2f
	SpeedModifier=0.15f
	SprintSpeedModifier=0.15f

	SecondaryDamageType=class'KFDT_Fire_HellishRage'
	SecondaryDamage=50

	ScreenMaterialName=Effect_PowerUp_HellishRage
	CameraLensEffectTemplate=class'KFCameraLensEmit_PowerUp_HellishRage'
	PowerUpEffect=ParticleSystem'FX_Gameplay_EMIT.FX_Char_PowerUp_HellishRage'
}