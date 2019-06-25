<#
.SYNOPSIS
	Sends a payload preceded by some magic packets that are required for it to work
#>
function Send-USBTurretControlPacket {
	Param(
		[byte[]]$ControlPacket,

		[Alias('ToTurret')]
		[ValidateNotNull()]
		$Turret = (Get-USBTurret | Select-Object -First 1)
	)

	Write-Verbose "Send-USBTurretControlPacket| Sending magic bytes..."

	# Turret needs two magic packets before it accepts actual commands
	$Turret.MagicDevice.Write(@(0, [byte][char]'U', [byte][char]'S', [byte][char]'B', [byte][char]'C', 0, 0, 4, 0 ))
	$Turret.MagicDevice.Write(@(0, [byte][char]'U', [byte][char]'S', [byte][char]'B', [byte][char]'C', 0, 0x40, 2, 0 ))

	Write-Verbose "Send-USBTurretControlPacket| Payload: $($ControlPacket[0..8] -join ', ') ...<snip>"
	$Turret.ControlDevice.Write($ControlPacket)

	Write-Verbose ""
}