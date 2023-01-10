package server;

import java.io.*;
import java.net.Socket;
import java.util.Date;

public class ServerThread extends Thread {
    private Socket socket;
    private String pathToRoot;
    private BufferedReader br;
    private PrintWriter logWriter;
    private int serverPort;
    private String serverURL;

    public ServerThread(Socket socket, int serverPort, String pathToRoot, String pathTolog){
        this.socket = socket;
        this.serverPort = serverPort;
        this.pathToRoot = pathToRoot;
        try {
            this.logWriter = new PrintWriter(new FileOutputStream(new File(pathTolog+"//log.txt"), true /* append = true */));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        try {
            this.br = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        } catch (IOException e) {
            e.printStackTrace();
        }
        this.serverURL = "http://localhost:"+ serverPort;

    }

    public ServerThread(Socket socket)
    {
        this.socket = socket;
    }

    public void run() {
        // buffers

        String httpRequest = null;
        try {
            httpRequest = br.readLine();
            //System.out.println(httpRequest);
            logWriter.println("HTTP request:\n"+httpRequest+"\n");
        } catch(IOException e) {
            e.printStackTrace();
        }

        String[] requestParts = null;
        if(httpRequest != null) {
            requestParts = httpRequest.split(" ");
        } else {
            try {
                socket.close();
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                return ;
            }
        }

        String requestType = requestParts[0];

        if(requestType.equals("GET")) {
            String uri = requestParts[1];
            String path = getPathFromURI(uri);
            try {
                handleGetRequest(path);
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else if(requestType.equals("UPLOAD")) {
            String fileName = requestParts[1];
            try {
                handleUploadRequest(fileName);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }


        try {
            logWriter.close();
            br.close();
            socket.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

    }

    private void handleGetRequest (String path) throws IOException {
        File file = null;
        if(path.equals("")) {
            file = new File(pathToRoot);
        } else {
            file = new File(pathToRoot+path);
        }
        PrintWriter pw = new PrintWriter(socket.getOutputStream());
        //System.out.println("path 101:"+path);
        StringBuilder htmlContent = handleFile(file, path);
        StringBuilder httpResponse = new StringBuilder();
        if(file.exists() && file.isDirectory()) {
            httpResponse.append("HTTP/1.1 200 OK\r\n");
            httpResponse.append("Server: Java HTTP Server: 1.0\r\n");
            httpResponse.append("Date: " + new Date() + "\r\n");
            httpResponse.append("Content-Type: text/html\r\n");
            httpResponse.append("Content-Length: " + htmlContent.length() + "\r\n");
            httpResponse.append("\r\n");

            logWriter.println("HTTP response:\n"+httpResponse);
            logWriter.println("=========================================================================");

            httpResponse.append(htmlContent.toString());

            pw.write(httpResponse.toString());
            pw.flush();
        } else if(file.exists() && file.isFile()) {
            httpResponse.append("HTTP/1.1 200 OK\r\n");
            httpResponse.append("Server: Java HTTP Server: 1.0\r\n");
            httpResponse.append("Date: " + new Date() + "\r\n");
            if(file.getName().endsWith(".txt")) {
                httpResponse.append("Content-Type: text/plain\r\n");
            } else if(file.getName().endsWith(".jpg")) {
                httpResponse.append("Content-Type: image/png\r\n");
            } else if(file.getName().endsWith(".png")) {
                httpResponse.append("Content-Type: image/png\r\n");
            } else {
                httpResponse.append("Content-Type: application/octet-stream\r\n");
            }

            httpResponse.append("Content-Length: " + (int)file.length() + "\r\n");
            httpResponse.append("\r\n");

            logWriter.println("HTTP response:\n"+httpResponse);
            logWriter.println("=========================================================================");

            pw.write(httpResponse.toString());
            pw.flush();
            sendFile(file);

        } else if(!file.exists()) {
            httpResponse.append("HTTP/1.1 200 OK\r\n");
            httpResponse.append("Server: Java HTTP Server: 1.0\r\n");
            httpResponse.append("Date: " + new Date() + "\r\n");
            httpResponse.append("Content-Type: text/html\r\n");
            httpResponse.append("Content-Length: " + htmlContent.length() + "\r\n");
            httpResponse.append("\r\n");

            logWriter.println("HTTP response:\n"+httpResponse);
            logWriter.println("=========================================================================");

            httpResponse.append(htmlContent.toString());

            pw.write(httpResponse.toString());
            pw.flush();
        }
        pw.close();
    }

    private void handleUploadRequest (String uploadedFileName) throws IOException {
        String isValid = br.readLine();
        String uploadPath = "F:\\3-2\\CSE 322 Computer Networks Sessional\\Offline-1 Socket\\Offline 1\\Uploaded";
        if(isValid.startsWith("invalid")) {
            //System.out.println(isValid);
        } else {
            String fileName = "F:\\3-2\\CSE 322 Computer Networks Sessional\\Offline-1 Socket\\Offline 1\\Uploaded\\" + uploadedFileName;
            receiveFile(fileName);
        }
    }
    private String getPathFromURI(String uri) {
        String[] pathArray = uri.split("/");
        String path = "";
        int noIterations = pathArray.length-1;
        for(int i = 0; i < noIterations; i++) {
                path += pathArray[i]+"\\";
        }

        if(noIterations > 0) {
            path += pathArray[noIterations];
            //System.out.println("path 183:"+path);
        }
        //System.out.println("path 186:"+path);
        return path;
    }

    private StringBuilder handleFile(File file, String path) {
        StringBuilder htmlString = new StringBuilder();
        if(file.exists()) {
            if(file.isDirectory()) {
                File[] listOfFiles = file.listFiles();
                htmlString.append("<html>\n\t<head>\n\t\t<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\t</head>\n\t<body>\n");
                htmlString.append("\t\t<ul>");
                for(File fileContent : listOfFiles) {
                    String fileName = fileContent.getName();
//                    System.out.println("A:"+path);
//                    System.out.println("B:"+path+"/"+fileName);
//                    System.out.println("C:"+serverURL +"/"+path.replace("\\", "/")+"/"+fileName);
                    if(fileContent.isDirectory()) {
                        htmlString.append("\t\t<li><b><a href=\""+ serverURL + path.replace("\\", "/") + "/" + fileName + "\"> " + fileName+" </a></b></li>\n");
                    } else if(fileContent.isFile()) {
                        if(fileContent.getName().endsWith(".txt") || fileContent.getName().endsWith(".jpg")
                                || fileContent.getName().endsWith(".png") ) {
                            htmlString.append("\t\t<li><a href=\"" + serverURL + path.replace("\\", "/") + "/" + fileName + "\" target=\"_blank\" > " + fileName + " </a></li>\n");
                        } else {
                            htmlString.append("\t\t<li><a href=\"" + serverURL + path.replace("\\", "/") + "/" + fileName + "\" > " + fileName + " </a></li>\n");
                        }
                    }
                }
                htmlString.append("\t\t</ul>");
                htmlString.append("\t</body>\n</html>");
            }
        } else {
            htmlString.append("<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n</head>\n<body>\n");
            htmlString.append("\t\t<h1> 404: Page not found </h1>\n");
            htmlString.append("\t</body>\n</html>");
        }
        return htmlString;
    }

    private void sendFile(File file) throws IOException {
        int bytes = 0;
        FileInputStream fileInputStream = new FileInputStream(file);
        DataOutputStream dataOutputStream = new DataOutputStream(socket.getOutputStream());

        // Here we send the File to Client
//        dataOutputStream.writeLong(file.length());
//        dataOutputStream.flush();
        // Here we  break file into chunks
        byte[] buffer = new byte[32];
        while ((bytes = fileInputStream.read(buffer)) != -1) {
            // Send the file to Client Socket
            dataOutputStream.write(buffer, 0, bytes);
            dataOutputStream.flush();
        }
        fileInputStream.close();
        //dataOutputStream.close();
    }

    private void receiveFile(String fileName) throws IOException {
        DataInputStream dataInputStream = new DataInputStream(socket.getInputStream());

        int bytes = 0;
        FileOutputStream fileOutputStream = new FileOutputStream(fileName);
        long size = dataInputStream.readLong(); // read file size
        //System.out.println(size);
        byte[] buffer = new byte[32];
        while (size > 0 && (bytes = dataInputStream.read(buffer, 0, (int)Math.min(buffer.length, size))) != -1) {
            // Here we write the file using write method
            fileOutputStream.write(buffer, 0, bytes);
            size -= bytes; // read upto file size
        }
        // Here we received file
        fileOutputStream.close();
        dataInputStream.close();
    }
}
