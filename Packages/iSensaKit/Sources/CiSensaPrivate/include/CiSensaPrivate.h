// CiSensaPrivate — C layouts for UNDOCUMENTED macOS interfaces.
//
// The System Management Controller (SMC) user client is not documented by Apple.
// These structures mirror the layout used by the AppleSMC kernel extension and are
// declared in C so that Swift's memory layout matches the kernel's byte-for-byte.
// Everything here may change between macOS releases; callers must fail gracefully.

#ifndef CISENSA_PRIVATE_H
#define CISENSA_PRIVATE_H

#include <stdint.h>

enum {
    kiSensaSMCHandleYPCEvent = 2,
    kiSensaSMCReadKey = 5,
    kiSensaSMCWriteKey = 6,
    kiSensaSMCGetKeyFromIndex = 8,
    kiSensaSMCGetKeyInfo = 9
};

typedef struct {
    uint8_t major;
    uint8_t minor;
    uint8_t build;
    uint8_t reserved;
    uint16_t release;
} iSensaSMCVersion;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} iSensaSMCPLimitData;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t dataAttributes;
} iSensaSMCKeyInfo;

typedef struct {
    uint32_t key;
    iSensaSMCVersion vers;
    iSensaSMCPLimitData pLimitData;
    iSensaSMCKeyInfo keyInfo;
    uint8_t result;
    uint8_t status;
    uint8_t data8;
    uint32_t data32;
    uint8_t bytes[32];
} iSensaSMCKeyData;

#endif
