// CSensaHardware — thin C shims over PUBLIC IOKit interfaces that are awkward to call
// from Swift (COM-style CFPlugIn vtables).

#ifndef CSENSA_HARDWARE_H
#define CSENSA_HARDWARE_H

#include <stdint.h>

/// NVMe SMART / Health Information log (NVM Express 1.0c §5.10.1.2), reduced to the fields Sensa uses.
typedef struct {
    uint8_t criticalWarning;
    uint16_t temperatureKelvin;
    uint8_t availableSpare;
    uint8_t availableSpareThreshold;
    uint8_t percentageUsed;
    uint64_t dataUnitsRead;
    uint64_t dataUnitsWritten;
    uint64_t powerCycles;
    uint64_t powerOnHours;
    uint64_t unsafeShutdowns;
    uint64_t mediaErrors;
} SensaNVMeHealth;

/// Reads the SMART log of the first SMART-capable NVMe controller.
/// Returns 0 on success, a non-zero IOKit/plug-in status otherwise.
int sensa_nvme_read_health(SensaNVMeHealth *out);

#endif
