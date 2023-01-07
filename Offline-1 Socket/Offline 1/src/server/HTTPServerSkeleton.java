package server;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;

public class HTTPServerSkeleton {
    private static final int PORT = 5067;
    private static final String PATH_TO_ROOT = "F:\\3-2\\CSE 322 Computer Networks Sessional\\Offline-1 Socket\\Offline 1\\root";
    private static final String PATH_TO_LOG = "F:\\3-2\\CSE 322 Computer Networks Sessional\\Offline-1 Socket\\Offline 1\\log";

    public static void main(String[] args) throws IOException {
        
        ServerSocket serverConnect = new ServerSocket(PORT);


        while(true)
        {
            Socket socket = serverConnect.accept();
            Thread serverThread = new ServerThread(socket, PORT, PATH_TO_ROOT, PATH_TO_LOG);
            serverThread.start();

        }
        
    }
    
}
