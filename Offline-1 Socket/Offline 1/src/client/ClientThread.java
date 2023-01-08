package client;

import java.io.*;
import java.net.Socket;

public class ClientThread extends Thread{
    private Socket socket;
    private File fileToUpload;
    public ClientThread(Socket socket, String fileName) {
        this.socket = socket;
        this.fileToUpload = new File(fileName);
    }
    @Override
    public void run() {
        PrintWriter pw = null;
        try {
            pw = new PrintWriter(socket.getOutputStream());
        } catch(IOException e) {
            e.printStackTrace();
        }

        pw.write("UPLOAD "+fileToUpload.getName()+"\r\n");
        pw.flush();
        if(fileToUpload.exists()) {
            if(fileToUpload.getName().endsWith(".txt") || fileToUpload.getName().endsWith(".jpg")
                    || fileToUpload.getName().endsWith(".png") || fileToUpload.getName().endsWith(".mp4")) {
                pw.write("valid file and format\r\n");
                pw.flush();
                try {
                    int bytes = 0;
                    FileInputStream fileInputStream = new FileInputStream(fileToUpload);
                    DataOutputStream dataOutputStream = new DataOutputStream(socket.getOutputStream());

                    // Here we send the File to Server
                    //System.out.println(fileToUpload.length());
                    dataOutputStream.writeLong(fileToUpload.length());
                    dataOutputStream.flush();
                    // Here we  break file into chunks
                    byte[] buffer = new byte[1024];
                    while ((bytes = fileInputStream.read(buffer)) != -1) {
                        // Send the file to Server Socket
                        dataOutputStream.write(buffer, 0, bytes);
                        dataOutputStream.flush();
                    }
                    fileInputStream.close();
                    dataOutputStream.close();
                } catch(IOException e) {
                    e.printStackTrace();
                }
            } else {
                pw.write("invalid format\r\n");
                pw.flush();
                System.out.println("Error: invalid format");
                try {
                    pw.close();
                    socket.close();
                    return;
                } catch(IOException e) {
                    e.printStackTrace();
                }
            }
        } else {
            pw.write("invalid name\r\n");
            pw.flush();
            System.out.println("Error: invalid name");
            try {
                pw.close();
                socket.close();
                return;
            } catch(IOException e) {
                e.printStackTrace();
            }
        }

        try {
            pw.close();
            socket.close();
        } catch(IOException e) {
            e.printStackTrace();
        }

    }
}
