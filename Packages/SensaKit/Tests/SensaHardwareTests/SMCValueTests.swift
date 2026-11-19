import SensaPrivateAPI
import Testing

@Suite("SMC value decoding")
struct SMCValueTests {
    @Test func keyRoundTrip() {
        let key: SMCKey = "F0Ac"
        #expect(key.description == "F0Ac")
        #expect(SMCKey(String("TOOLONG")) == nil)
    }

    @Test func littleEndianFloat() {
        // 2317.0 as observed for F0Mn on Mac15,6: bytes 00 d0 10 45.
        let value = SMCValue(key: "F0Mn", dataType: "flt ", bytes: [0x00, 0xD0, 0x10, 0x45])
        #expect(value.doubleValue == 2_317)
    }

    @Test func bigEndianIntegers() {
        #expect(SMCValue(key: "#KEY", dataType: "ui32", bytes: [0, 0, 8, 247]).doubleValue == 2_295)
        #expect(SMCValue(key: "F0CR", dataType: "ui16", bytes: [0x96, 0x00]).doubleValue == 38_400)
        #expect(SMCValue(key: "FNum", dataType: "ui8 ", bytes: [2]).doubleValue == 2)
    }

    @Test func fixedPointFormats() {
        #expect(SMCValue(key: "TC0P", dataType: "sp78", bytes: [0x2A, 0x80]).doubleValue == 42.5)
        #expect(SMCValue(key: "F0Ac", dataType: "fpe2", bytes: [0x1F, 0x40]).doubleValue == 2_000)
        #expect(SMCValue(key: "TG0B", dataType: "ioft", bytes: [0, 0x80, 0x1F, 0, 0, 0, 0, 0]).doubleValue == 31.5)
    }

    @Test func unknownTypesAreNotGuessed() {
        #expect(SMCValue(key: "FBAC", dataType: "hex_", bytes: [0]).doubleValue == nil)
    }
}
