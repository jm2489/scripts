import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
import time

def on_receive(packet, interface):
    print(f"Received: {packet}")

def on_connection(interface, topic=pub.AUTO_TOPIC):
    interface.sendText("Hello, Mesh!")

pub.subscribe(on_receive, "meshtastic.receive")
pub.subscribe(on_connection, "meshtastic.connection.established")

interface = SerialInterface()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    interface.close()
    print("Disconnected from the Meshtastic device.")
