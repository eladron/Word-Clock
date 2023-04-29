# simple inquiry example
# Run this on windows!! didn't work for me on wsl
import bluetooth
target_name = 'ESP32-BT-Slave'

# Define the port number to use for the connection
port = 1

# Search for nearby Bluetooth devices with the target name
nearby_devices = bluetooth.discover_devices()
print("Found {} devices.".format(len(nearby_devices)))
for device in nearby_devices:
    print(device, bluetooth.lookup_name(device))

target_address = None
for address in nearby_devices:
    name = bluetooth.lookup_name(address)
    if name == target_name:
        target_address = address
        break


if target_address is not None:
    # Establish a Bluetooth connection with the target device
    print("found device!")
    sock = bluetooth.BluetoothSocket(bluetooth.Protocols.RFCOMM)
    sock.connect((target_address, port))

    wifi_name = input("Enter wifi name: ")
    wifi_pwd = input("Enter wifi password: ")
    data = f"Name={wifi_name}+Password={wifi_pwd}"
    sock.send(data.encode())
    # Close the Bluetooth connection
    sock.close()

else:
    print(f"Could not find Bluetooth device with name '{target_name}'")