<#
	Sprinkled a bunch of Start-Sleeps in an attempt to make it more reliable. Sometimes the turret just ignores packets...

	Invoke-USBTurretForDuration @{ Left = 3600; Up=1500 }
				↓↓
		Send-USBTurretCommand
				↓
		Send-USBTurretPacket
#>

$ErrorActionPreference = "Stop"

$ControlPath = "\\?\hid#vid_1130&pid_0202&mi_00*" # This device should receive control commands
$SetupPath = "\\?\hid#vid_1130&pid_0202&mi_01*" # This device should receive the magic packets

$script:ControlDevice = $null
$script:MagicPacketDevice = $null

$CommandIndexes = @{
	Left = 2
	Right = 3
	Up = 4
	Down = 5
	Fire = 6
}

function Initialize-USBTurret {
	Add-Type -Path (Join-Path $PSScriptRoot "MightyHID.dll")
	$HIDDevices = [Mighty.HID.HIDBrowse]::Browse()

	$ControlHID = $HIDDevices | ? Path -Like $ControlPath
	if ($ControlHID.Count -gt 1) { throw "More than one control device found. Do you have multiple turrets connected?" }
	if ($ControlHID.Count -eq 0) { throw "No turrets connected?" }
	$script:ControlDevice = [Mighty.HID.HIDDev]::new()
	if (-not $script:ControlDevice.Open($ControlHID)) { throw "Could not open control device" }

	$SetupHID = $HIDDevices | ? Path -Like $SetupPath
	if ($SetupHID.Count -gt 1) { throw "More than one control device found. Do you have multiple turrets connected?" }
	if ($SetupHID.Count -eq 0) { throw "No turrets connected?" }
	$script:MagicPacketDevice = [Mighty.HID.HIDDev]::new()
	if (-not $script:MagicPacketDevice.Open($SetupHID)) { throw "Could not open control device" }
	Start-Sleep -Milliseconds 500
}
Export-ModuleMember -Function Initialize-USBTurret


function Approve-USBTurretLaunch {
	Write-Verbose "FIRE ON THE NOOBS!!!!"
	Invoke-USBTurretForDuration @{ Fire = 3200 }
	Write-Verbose ""
}
Export-ModuleMember -Function Approve-USBTurretLaunch


function Move-USBTurretToCenter {
	Write-Verbose "MOVING TO CENTER (not really...)"
	# Parks it at max down-left. Trying to center it by measuring time will be inaccurate
	# ~10s and ~3s cover the whole range of turret movement, add a little bit more to be safe we're at the end of travel
	Invoke-USBTurretForDuration @{ Left = 11000; Down = 4500 }
	Write-Verbose ""
}
Export-ModuleMember -Function Move-USBTurretToCenter


<#
.SYNOPSIS
	Sends one or more commands that move/fire the turret for a requested period of time

.DESCRIPTION
	In theory you can send the fire command amongst movement commands (it would have to be timed correctly). For simplicity's sake 
	send the fire command in a separate call

.EXAMPLE
	Invoke-USBTurretForDuration @{ Left = 3600; Up = 1230 }

.EXAMPLE
	Invoke-USBTurretForDuration @{ Right = 3600; Down = 1230 }
#>

function Invoke-USBTurretForDuration {
	Param(
		[System.Collections.Hashtable]$Destination
	)
	# Select the longest command in the request - this will be our stop
	$MaxDuration = ($Destination.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Value

	$i = 0;
	while ($i -lt $MaxDuration) {
		# The command will change at the next min value. Take into acount that we've moved forward in time by $i amount of time
		$NextCommandChangeAt = ($Destination.GetEnumerator() | ? Value -gt $i | Sort-Object -Property Value | Select-Object -First 1).Value
		
		$Duration = $NextCommandChangeAt - $i # We're counting command duration from the last point in time which was $i

		# Build command packet with all the commands we need to send at this time
		$ControlPacket = New-Object byte[] 65
		$ControlPacket[7] = 8
		$ControlPacket[8] = 8

		$CommandsToSend = ($Destination.GetEnumerator() | Sort-Object -Property Value -Descending | ? Value -gt $i).Name
		foreach ($Command in $CommandsToSend) {
			# Look up index of a command and mark that location as 1 in the control packet
			$ControlPacket[$CommandIndexes[$Command]] = 1
		}
		Write-Verbose "Invoke-USBTurretForDuration| Sending '$($CommandsToSend -join '+')' for $Duration ms"
		Send-USBTurretCommand $ControlPacket -ForDuration $Duration
		Start-Sleep -Milliseconds 1 # Sometimes commands get ignored, a slight delay seems to help
		$i += $Duration
	}
	Start-Sleep -Milliseconds 100
	Write-Verbose ""
}
Export-ModuleMember -Function Invoke-USBTurretForDuration


<#
.SYNOPSIS
	Sends one command for a time period, repeating the packets as necessary (because command packets time out)
#>
function Send-USBTurretCommand {
	Param(
		[byte[]]$Command,

		[int]$ForDuration = 1000 # Milliseconds
	)
	Write-Verbose "Send-USBTurretCommand| Will send for $ForDuration ms"

	# When you send a command and don't send a "stop" command the turret will automatically stop after this much time
	$COMMAND_TIMEOUT_MS = 3000


	$StopPacket = New-Object byte[] 65
	$StopPacket[7] = 8
	$StopPacket[8] = 8

	# Calculate how many "full" commands and how much remaining time we will have
	$Remainder = 0
	$Times = [math]::divrem( $ForDuration, $COMMAND_TIMEOUT_MS, [ref]$Remainder )

	for ($i = 0; $i -lt $Times; $i++) {
		Write-Verbose "Send-USBTurretCommand| Sending a command for: $COMMAND_TIMEOUT_MS"
		Send-USBTurretPacket $Command
		Start-Sleep -Milliseconds $COMMAND_TIMEOUT_MS
	}

	if ($Remainder -gt 0){
		Write-Verbose "Send-USBTurretCommand| Sending a short command for: $Remainder"
		Send-USBTurretPacket $Command
		Start-Sleep -Milliseconds $Remainder
		
		# Stop the turret by sending an empty command. If there was no remainder of time
		# then we assume the turret will timeout the last command and stop on it's own
		Write-Verbose "Send-USBTurretCommand| Sending a stop packet"
		Send-USBTurretPacket $StopPacket
	}
	Start-Sleep -Milliseconds 100
	Write-Verbose ""
}

<#
.SYNOPSIS
	Sends a HID command with some magic packets to make it work
#>
function Send-USBTurretPacket {
	Param(
		[byte[]]$Command
	)
	# Turret needs two magic packets before it accepts actual commands
	$script:MagicPacketDevice.Write(@(0, [byte][char]'U', [byte][char]'S', [byte][char]'B', [byte][char]'C', 0, 0, 4, 0 ))
	$script:MagicPacketDevice.Write(@(0, [byte][char]'U', [byte][char]'S', [byte][char]'B', [byte][char]'C', 0, 0x40, 2, 0 ))

	Write-Verbose "Send-USBTurretPacket| $($Command[0..8] -join ', ') ...<snip>"
	$script:ControlDevice.Write($Command)

	Write-Verbose ""
}