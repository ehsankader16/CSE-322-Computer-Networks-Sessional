package client;

import java.io.IOException;
import java.net.Socket;
import java.util.Scanner;

public class Client {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        /* taking file name and starting process */
        while(true) {

            Socket socket = null;
            try {
                socket = new Socket("localhost", 5067);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            Thread clientThread = new ClientThread(socket, scanner.nextLine());
            clientThread.start();
        }
    }
}
