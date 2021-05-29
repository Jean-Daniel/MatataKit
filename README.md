#  Matata Devices

Bot and Controller are Bluetooth LE devices with a single Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
 
 The Service exposes 2 characteristics:
 
 - One `write` /  `writeNoReply` characteristic: `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
 - One `notify` characteristic: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
 
 ## Handshake
 
 To control a device, first lookup for a device with the right characteristics.

On dicover -> start listening on the `notify` characteristic.
When `notify` starts, write a handshake request in the `write` characteristic: `[0xfe, 0x07, 0x7e, 0x2, 0x2, 0x0, 0x0, 0x97, 0x77]`

The device should answer a 8 bytes sequence like: `[0xfe, 0x06, 0x7e, 0x02, 0x00, 0x00, 0x52, 0xc6]`


### Payload encoding

Each packet is composed of a 1 byte header with value `254`, followed by the encoded payload.

Encoded payload are generated by appending a crc16 to the original payload and then encoding the result as follow:

- replace `253` by the 2 bytes sequence `253` / `221`
- replace `254` by the 2 bytes equence `253` / `222`

#### Checksum

The crc16 checksum is a 2 bytes value computed like this:

```swift
func crc16(_ data: [UInt8]) -> UInt16 {
    var crc: UInt16 = 0xffff;
    for byte in data {
        crc = crc.byteSwapped ^ UInt16(byte);
        crc = crc ^ (crc & 255) >> 4;
        crc = crc ^ (crc << 12);
        crc = crc ^ (crc & 255) << 5;
    }
    return crc;
}
```
