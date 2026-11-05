package com.gathin.tvhome;

import org.junit.Test;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import static org.junit.Assert.*;

public final class RejectedUploadResponseTest {
    @Test(timeout = 7000) public void rejectedUploadCanDeliverFullResponseOverTcp() throws Exception {
        var worker = Executors.newSingleThreadExecutor();
        try (ServerSocket listener = new ServerSocket(0, 1, InetAddress.getLoopbackAddress())) {
            var result = worker.submit(() -> {
                try (Socket socket = listener.accept()) {
                    socket.setSoTimeout(3000);
                    var request = AmbientUploadProtocol.parse(socket.getInputStream());
                    AmbientUploadProtocol.discardRejectedBody(socket.getInputStream(), request.length);
                    socket.getOutputStream().write(("HTTP/1.1 403 Forbidden\r\n"
                            + "Content-Length: 21\r\nConnection: close\r\n\r\nIncorrect access code")
                            .getBytes(StandardCharsets.US_ASCII));
                }
                return true;
            });
            try (Socket client = new Socket(InetAddress.getLoopbackAddress(), listener.getLocalPort())) {
                client.setSoTimeout(3000);
                client.getOutputStream().write(("POST /upload HTTP/1.1\r\nHost: localhost\r\n"
                        + "Content-Length: 1048576\r\n\r\n").getBytes(StandardCharsets.US_ASCII));
                byte[] fragment = new byte[4096];
                for (int n = 0; n < 256; n++) client.getOutputStream().write(fragment);
                String response = new String(client.getInputStream().readAllBytes(), StandardCharsets.US_ASCII);
                assertTrue(response.startsWith("HTTP/1.1 403 "));
                assertTrue(response.endsWith("Incorrect access code"));
            }
            assertTrue(result.get(3, TimeUnit.SECONDS));
        } finally { worker.shutdownNow(); }
    }

    @Test public void discardLeavesBytesBeyondDeclaredBodyUntouched() throws Exception {
        var input = new ByteArrayInputStream(new byte[] {1, 2, 3, 4});
        AmbientUploadProtocol.discardRejectedBody(input, 3);
        assertEquals(4, input.read());
    }

    @Test public void truncatedAndUnboundedBodiesFailWithoutUnboundedReads() throws Exception {
        for (long length : new long[] {-1, AmbientUploadProtocol.MAX_UPLOAD_BYTES + 1, 2}) {
            try {
                AmbientUploadProtocol.discardRejectedBody(new ByteArrayInputStream(new byte[] {1}), length);
                fail("Expected rejected body length/EOF");
            } catch (IOException expected) { }
        }
    }
}
