package com.gathin.tvhome;

/** Capability reporting is not a claim of model certification. No identifiers collected. */
final class UnifiedCompatibility {
    private UnifiedCompatibility() { }

    static String summary(int sdk, boolean television, boolean homeSettings,
                          boolean dreamSettings, boolean photoPicker, boolean lowRam) {
        return "Android API " + sdk + (sdk >= 26 ? " (meets Android 8+ minimum)" : " (unsupported)")
                + "\nTV interface: " + (television ? "detected" : "not reported by firmware")
                + "\nHome settings: " + availability(homeSettings)
                + "\nScreensaver settings: " + availability(dreamSettings)
                + "\nUSB/file picker: " + availability(photoPicker)
                + "\nMemory profile: " + (lowRam ? "low RAM; use smaller photos" : "standard")
                + "\nCapabilities detected only. This TV model has not been certified.";
    }

    private static String availability(boolean value) {
        return value ? "available" : "vendor settings may be required";
    }
}
