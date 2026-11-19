// CSensaPrivate — C layouts for UNDOCUMENTED macOS interfaces.
//
// The System Management Controller (SMC) user client is not documented by Apple.
// These structures mirror the layout used by the AppleSMC kernel extension and are
// declared in C so that Swift's memory layout matches the kernel's byte-for-byte.
// Everything here may change between macOS releases; callers must fail gracefully.

#ifndef CSENSA_PRIVATE_H
#define CSENSA_PRIVATE_H

#include <stdint.h>

enum {
    kSensaSMCHandleYPCEvent = 2,
    kSensaSMCReadKey = 5,
    kSensaSMCWriteKey = 6,
    kSensaSMCGetKeyFromIndex = 8,
    kSensaSMCGetKeyInfo = 9
};

typedef struct {
    uint8_t major;
    uint8_t minor;
    uint8_t build;
    uint8_t reserved;
    uint16_t release;
} SensaSMCVersion;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SensaSMCPLimitData;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t dataAttributes;
} SensaSMCKeyInfo;

typedef struct {
    uint32_t key;
    SensaSMCVersion vers;
    SensaSMCPLimitData pLimitData;
    SensaSMCKeyInfo keyInfo;
    uint8_t result;
    uint8_t status;
    uint8_t data8;
    uint32_t data32;
    uint8_t bytes[32];
} SensaSMCKeyData;

#endif
