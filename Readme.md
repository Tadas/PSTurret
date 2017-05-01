# USB Missile Launcher control module in PowerShell

Works with the one that looks like this:
- http://www.drinkstuff.com/products/product.asp?ID=2640
- http://www.instructables.com/id/Hack-your-usb-missile-launcher-into-an-quotAuto-/
- https://www.youtube.com/watch?v=EmZ-QKglyrc

Vendor ID = 1130  
Product ID = 0202

Uses https://github.com/MightyDevices/MightyHID to talk USB


## How to...

	Initialize-USBTurret
	Move-USBTurretToCenter
	Invoke-USBTurretForDuration @{ Right = 5100; Up = 1500 }
	Approve-USBTurretLaunch
	Move-USBTurretToCenter