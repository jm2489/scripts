import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
import time
from datetime import datetime
import logging
import subprocess

# Define the keyword to listen for
KEYWORD = "meshtest"
RESPONSE_MESSAGE = "Keyword received!"

# Optionally specify a channel (default is the primary channel if None)
CHANNEL = None  # Set to an integer (e.g., 1, 2) to specify a channel

# Configure logging
logging.basicConfig(
    filename="meshtastic_debug.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logging.info("Meshtastic keyword listener started.")

def on_receive(packet, interface):
    """Callback function to process received messages."""
    try:
        if "decoded" in packet and "payload" in packet["decoded"]:
            try:
                text = packet["decoded"]["payload"].decode("utf-8")  # Try decoding as UTF-8
            except UnicodeDecodeError:
                warning_msg = "Warning: Received a non-text message. Skipping..."
                print(warning_msg)
                logging.warning(warning_msg)
                return  # Ignore and skip this packet

            node_id = packet["from"]
            hop_limit = packet.get("hop_limit", 0)
            hop_start = packet.get("hop_start", 0)
            hops = hop_limit - hop_start
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            if KEYWORD == text.lower():
                message_log = f"[{timestamp}] Keyword detected in message from {node_id} (Hops: {hops}): {text}"
                print(message_log)
                logging.info(message_log)
                response = f"{RESPONSE_MESSAGE}\nTime: {timestamp}\nHops: {hops if hops > 0 else 'Direct'}"

                # Send response back to the sender
                interface.sendText(response, destinationId=node_id, channelIndex=CHANNEL if CHANNEL is not None else 0)
                response_log = f"[{timestamp}] Replied to {node_id} with confirmation message on channel {CHANNEL if CHANNEL is not None else 'primary'}."
                print(response_log)
                logging.info(response_log)
                
                # Execute a command
                interface.close()
                # Pause for 2 seconds
                time.sleep(2)
                # Restart or shutdown the device gracefully
                #subprocess.run(["init 6"], shell=True)                
                subprocess.run(["init 0"], shell=True)

    except Exception as e:
        error_msg = f"Error processing received message: {e}"
        print(error_msg)
        logging.error(error_msg)

# Connect to Meshtastic device
interface = SerialInterface()

# Set up the message handler correctly
pub.subscribe(on_receive, "meshtastic.receive")

startup_msg = f"Listening for messages on channel {CHANNEL if CHANNEL is not None else 'primary'}..."
print(startup_msg)
logging.info(startup_msg)

# Keep the script running
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    shutdown_msg = "Stopping script..."
    print(shutdown_msg)
    logging.info(shutdown_msg)
    interface.close()
    print("Disconnected from the Meshtastic device.")
    logging.info("Disconnected from the Meshtastic device.")