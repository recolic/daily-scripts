#!/usr/bin/python
import dbus
import dbus.mainloop.glib
from gi.repository import GLib
adapter = "hci0"
device = "CF:58:23:11:3D:0B"
device_path = '/org/bluez/' + adapter + "/dev_" + device.replace(":", "_")
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
system_bus = dbus.SystemBus()
device_object = system_bus.get_object('org.bluez', device_path)
device_interface = dbus.Interface(device_object, 'org.bluez.Device1')
def device_info(_arg0, event, _arg2):
    if event.get("Connected"):
        print("Mouse connected, attempt to pair...")
        try:
            device_interface.Pair()
        except dbus.exceptions.DBusException:
            pass
system_bus.add_signal_receiver(
    device_info,
    dbus_interface='org.freedesktop.DBus.Properties',
    signal_name="PropertiesChanged",
    arg0='org.bluez.Device1')
GLib.MainLoop().run()

# https://felixc.at/2019/01/dirty-hack-to-workaround-cursor-not-move-issue-after-ble-mouse-reconnect/
