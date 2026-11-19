#include "CiSensaHardware.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/nvme/NVMeSMARTLibExternal.h>

/// The entry publishing "NVMe SMART Capable" differs by Mac (controller on Intel/T2,
/// IOEmbeddedNVMeBlockDevice on Apple silicon), so match on the property itself.
static io_service_t sensa_smart_capable_controller(void) {
    CFMutableDictionaryRef property = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(property, CFSTR("NVMe SMART Capable"), kCFBooleanTrue);
    CFMutableDictionaryRef matching = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey), property);
    CFRelease(property);
    // IOServiceGetMatchingService consumes the matching dictionary.
    return IOServiceGetMatchingService(kIOMainPortDefault, matching);
}

int sensa_nvme_read_health(iSensaNVMeHealth *out) {
    if (!out) return kIOReturnBadArgument;
    io_service_t controller = sensa_smart_capable_controller();
    if (!controller) return kIOReturnNotFound;

    // The SMART plug-in is published by the entry or one of its ancestors (the NVMe
    // controller on Apple silicon); try each until one creates the interface.
    IOCFPlugInInterface **plugin = NULL;
    SInt32 score = 0;
    kern_return_t result = kIOReturnNotFound;
    io_registry_entry_t entry = controller;
    for (int depth = 0; entry && depth < 4; depth++) {
        result = IOCreatePlugInInterfaceForService(entry, kIONVMeSMARTUserClientTypeID, kIOCFPlugInInterfaceID, &plugin, &score);
        io_registry_entry_t parent = 0;
        if (result != KERN_SUCCESS) IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent);
        IOObjectRelease(entry);
        entry = (result == KERN_SUCCESS) ? 0 : parent;
    }
    if (entry) IOObjectRelease(entry);
    if (result != KERN_SUCCESS || !plugin) return result ? result : kIOReturnError;

    IONVMeSMARTInterface **smart = NULL;
    HRESULT query = (*plugin)->QueryInterface(plugin, CFUUIDGetUUIDBytes(kIONVMeSMARTInterfaceID), (LPVOID *)&smart);
    if (query != S_OK || !smart) {
        IODestroyPlugInInterface(plugin);
        return kIOReturnUnsupported;
    }

    // The plug-in owns the user-client connection: keep it alive until the read completes.
    NVMeSMARTData data = {0};
    IOReturn status = (*smart)->SMARTReadData(smart, &data);
    (*smart)->Release(smart);
    IODestroyPlugInInterface(plugin);
    if (status != kIOReturnSuccess) return status;

    out->criticalWarning = data.CRITICAL_WARNING;
    out->temperatureKelvin = data.TEMPERATURE;
    out->availableSpare = data.AVAILABLE_SPARE;
    out->availableSpareThreshold = data.AVAILABLE_SPARE_THRESHOLD;
    out->percentageUsed = data.PERCENTAGE_USED;
    // 128-bit counters: the low 64 bits are sufficient for any consumer drive.
    out->dataUnitsRead = data.DATA_UNITS_READ[0];
    out->dataUnitsWritten = data.DATA_UNITS_WRITTEN[0];
    out->powerCycles = data.POWER_CYCLES[0];
    out->powerOnHours = data.POWER_ON_HOURS[0];
    out->unsafeShutdowns = data.UNSAFE_SHUTDOWNS[0];
    out->mediaErrors = data.MEDIA_ERRORS[0];
    return 0;
}
