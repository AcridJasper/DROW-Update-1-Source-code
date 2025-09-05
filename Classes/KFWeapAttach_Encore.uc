class KFWeapAttach_Encore extends KFWeaponAttachment;

var protected transient float ReloadAnimRateMod;
// var protected transient name  SomeName;

/** Caching reload anim name */
simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

	ReloadAnimRateMod = class'KFWeap_Encore'.default.ReloadAnimRateModifier;
	ReloadAnimRateMod = class'KFWeap_Encore'.default.ReloadAnimRateModifierElite;
}

/*
simulated function PlayWeaponMeshAnim(name AnimName, AnimNodeSlot SyncNode, bool bLoop)
{
	local float Duration;

	// Weapon shoot anims
	if( !bWeapMeshIsPawnMesh )
	{
		Duration = WeapMesh.GetAnimLength(AnimName);
		WeapMesh.PlayAnim(AnimName, Duration / ThirdPersonAnimRate, bLoop);

		if (AnimName == SomeName)
		{
			Duration *= ReloadAnimRateMod;
		}

		// syncronize this with the character anim
		if ( SyncNode != None )
		{
			bSynchronizeWeaponAnim = true;
			SyncPawnNode = SyncNode;
			SyncAnimName = AnimName;
			bSyncAnimCheckRelevance = false;
		}
	}
}
*/

defaultproperties
{

}