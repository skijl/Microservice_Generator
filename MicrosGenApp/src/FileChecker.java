import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.CodeSource;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class FileChecker {
    public static void createTempFiles() {
        String tempDirPath = System.getProperty("java.io.tmpdir");
        String microgenScriptsDirPath = tempDirPath + File.separator + "microgen_scripts";

        File microgenScriptsDir = new File(microgenScriptsDirPath);
        microgenScriptsDir.mkdirs();

        copyResourcesToDir("resources/scripts", microgenScriptsDirPath);
        copyStaticToDir("resources/static_files", microgenScriptsDirPath+File.separator+"static");
    }

    private static void copyResourcesToDir(String resourcePath, String destDirPath) {
        try {
            byte[] buffer = new byte[1024];
            int bytesRead;
            CodeSource codeSource = FileChecker.class.getProtectionDomain().getCodeSource();
            URL jarUrl = codeSource.getLocation();
            String jarPath = jarUrl.toURI().getPath();
            // Decode URL if it's URL-encoded
            jarPath = URLDecoder.decode(jarPath, StandardCharsets.UTF_8);
            // Extract the directory containing the JAR file
            JarFile jarFile = new JarFile(jarPath);
            Enumeration<JarEntry> entries = jarFile.entries();

            // Process each entry in the JAR file
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String entryName = entry.getName();

                // Check if the entry belongs to the specified resource path
                if (entryName.startsWith(resourcePath) && !entryName.equals(resourcePath + "/")) {
                    // Extract the filename from the entry
                    String fileName = entryName.substring(resourcePath.length() + 1);

                    // Create streams for reading from the JAR and writing to the destination directory
                    InputStream inputStream = jarFile.getInputStream(entry);
                    File outputFile = new File(destDirPath + File.separator + fileName);
                    OutputStream outputStream = new FileOutputStream(outputFile);

                    // Copy data from the input stream to the output stream
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        outputStream.write(buffer, 0, bytesRead);
                    }

                    // Close streams
                    inputStream.close();
                    outputStream.close();
                }
            }

            // Close the JAR file
            jarFile.close();

            System.out.println("Scripts are ready.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void copyStaticToDir(String resourcePath, String destDirPath) {
        try {
            byte[] buffer = new byte[1024];
            CodeSource codeSource = FileChecker.class.getProtectionDomain().getCodeSource();
            URL jarUrl = codeSource.getLocation();
            String jarPath = jarUrl.toURI().getPath();
            // Decode URL if it's URL-encoded
            jarPath = URLDecoder.decode(jarPath, StandardCharsets.UTF_8);
            // Extract the directory containing the JAR file
            JarFile jarFile = new JarFile(jarPath);
            Enumeration<JarEntry> entries = jarFile.entries();

            // Process each entry in the JAR file
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String entryName = entry.getName();
                if (entryName.startsWith(resourcePath) && !entryName.equals(resourcePath + "/")) {
                    String relativePath = entryName.substring(resourcePath.length());
                    File outputFile = new File(destDirPath + File.separator + relativePath);
                    if (entry.isDirectory()) {
                        outputFile.mkdirs();
                    } else {
                        InputStream inputStream = jarFile.getInputStream(entry);
                        OutputStream outputStream = new FileOutputStream(outputFile);

                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            outputStream.write(buffer, 0, bytesRead);
                        }

                        inputStream.close();
                        outputStream.close();
                    }
                }
            }
            jarFile.close();
        }catch (Exception e){
            e.printStackTrace();
        }
    }

    public static boolean deleteTempDirectory(String directoryPath) {
        File directory = new File(directoryPath);
        if (directory.exists()) {
            File[] files = directory.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isDirectory()) {
                        deleteTempDirectory(file.getAbsolutePath());
                    } else {
                        file.delete();
                    }
                }
            }
            return directory.delete();
        }
        return false;
    }
}
