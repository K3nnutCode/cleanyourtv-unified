package com.gathin.tvhome;

import java.io.FilterInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.net.SocketTimeoutException;
import java.util.function.BooleanSupplier;
import java.util.function.LongSupplier;

/** Bounds trickle requests by elapsed time, independently of per-read socket timeouts. */
final class UploadDeadlineInputStream extends FilterInputStream {
    private final LongSupplier clock;
    private final BooleanSupplier active;
    private final long deadline;

    UploadDeadlineInputStream(InputStream input, LongSupplier clock,
                              BooleanSupplier active, long deadline) {
        super(input); this.clock = clock; this.active = active; this.deadline = deadline;
    }

    private void check() throws IOException {
        if (!active.getAsBoolean() || clock.getAsLong() >= deadline)
            throw new SocketTimeoutException("Upload session or request expired");
    }

    @Override public int read() throws IOException {
        check(); int value = in.read(); check(); return value;
    }

    @Override public int read(byte[] bytes, int offset, int length) throws IOException {
        check(); int count = in.read(bytes, offset, length); check(); return count;
    }
}
