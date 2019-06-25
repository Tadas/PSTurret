function Reset-USBTurretPosition {
	Param(
		[ValidateNotNull()]
		$Turret = (Get-USBTurret | Select-Object -First 1)
	)

	Move-USBTurret -Left 11000 -Down 4500 -Turret $Turret
}