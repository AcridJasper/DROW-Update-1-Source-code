class KFCameraLensEmit_IceMonster extends KFEmit_CameraEffect;

defaultproperties
{
	PS_CameraEffect=ParticleSystem'DROW_EMIT.FX_Camera_PowerUp_IceMonster'
	bAllowMultipleInstances=false
	LifeSpan=15
	bDepthTestEnabled=false

	// makes sure I tick after the camera
	// TickGroup=TG_PostAsyncWork
	// Camera lens effects are updated after FOV is changed, so it's safe to run this code during our async work
	// TickGroup=TG_DuringAsyncWork
}