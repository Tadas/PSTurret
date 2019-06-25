# USB Missile Launcher control module in PowerShell

*2019-06-25 Works with PowerShellCore on RaspberryPi*

Works with the one that looks like this:
- http://www.drinkstuff.com/products/product.asp?ID=2640
- http://www.instructables.com/id/Hack-your-usb-missile-launcher-into-an-quotAuto-/
- https://www.youtube.com/watch?v=EmZ-QKglyrc

Vendor ID = 1130
Product ID = 0202

Uses https://www.zer7.com/software/hidsharp to talk USB


## How to...

	Reset-USBTurretPosition
	Move-USBTurret -Right 5100 -Up 2000
	Fire-USBTurret
	Reset-USBTurretPosition