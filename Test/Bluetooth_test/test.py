# simple inquiry example
# Run this on windows!! didn't work for me on wsl
import bluetooth


# Define the port number to use for the connection
port = 1


def find_target(target_name: str):
    # Search for nearby Bluetooth devices with the target name
    nearby_devices = bluetooth.discover_devices()
    target_address = None
    for address in nearby_devices:
        name = bluetooth.lookup_name(address)
        if name == target_name:
            target_address = address
            print("found target bluetooth device with address ", target_address)
            break
    return target_address

def set_wifi(sock):
    wifi_name = input("Enter wifi name: ")
    wifi_pwd = input("Enter wifi password: ")
    data = f"SSID={wifi_name}+Password={wifi_pwd}"
    sock.send(data.encode())

def set_city(sock):
    city = input("Enter city: ")
    data = f"City={city}"
    sock.send(data.encode())

def main():
    code = input("Enter Clock code: ")
    target_name = 'ESP32-BT-Slave-' + code
    print(f"Bt name: {target_name}")
    target_address = find_target(target_name)
    while target_address is None:
        target_address = find_target(target_name)

    # Establish a Bluetooth connection with the target device
    sock = bluetooth.BluetoothSocket(bluetooth.Protocols.RFCOMM)
    sock.connect((target_address, port))

    while True:
        func = input("Enter function: ")
        if func.lower() == "wifi":
            set_wifi(sock)
        elif func.lower() == "city":
            set_city(sock)
        elif func.lower() == "exit":
            break
        else:
            print("Invalid function")
    sock.close()


if __name__ == '__main__':
    main()