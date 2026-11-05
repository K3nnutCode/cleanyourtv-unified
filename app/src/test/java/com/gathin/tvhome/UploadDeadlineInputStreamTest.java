package com.gathin.tvhome;

import java.io.ByteArrayInputStream;
import java.net.SocketTimeoutException;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.Test;
import static org.junit.Assert.*;

public class UploadDeadlineInputStreamTest {
    @Test public void trickleTrafficCannotExtendAbsoluteDeadline() throws Exception {
        AtomicLong now = new AtomicLong(10);
        UploadDeadlineInputStream stream = new UploadDeadlineInputStream(
                new ByteArrayInputStream(new byte[]{1, 2}), now::get, () -> true, 30);
        assertEquals(1, stream.read());
        now.set(30);
        assertThrows(SocketTimeoutException.class, stream::read);
    }
    @Test public void closingSessionRejectsBufferedBulkRead() {
        UploadDeadlineInputStream stream = new UploadDeadlineInputStream(
                new ByteArrayInputStream(new byte[100]), () -> 1, () -> false, 30);
        assertThrows(SocketTimeoutException.class, () -> stream.read(new byte[50]));
    }
}
