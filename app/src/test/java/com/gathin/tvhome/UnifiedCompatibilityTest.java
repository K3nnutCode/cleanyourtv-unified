package com.gathin.tvhome;

import org.junit.Test;
import static org.junit.Assert.*;

public class UnifiedCompatibilityTest {
    @Test public void missingVendorCapabilitiesNeverImplyCertification() {
        String report = UnifiedCompatibility.summary(26, false, false, false, false, true);
        assertTrue(report.contains("meets Android 8+ minimum"));
        assertTrue(report.contains("vendor settings may be required"));
        assertTrue(report.contains("not been certified"));
        assertTrue(report.contains("low RAM"));
    }
    @Test public void oldAndroidIsUnsupportedEvenWhenFeaturesExist() {
        assertTrue(UnifiedCompatibility.summary(25, true, true, true, true, false).contains("unsupported"));
    }
}
