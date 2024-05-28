import javax.swing.*;
import java.awt.*;
import java.io.*;

public class Run {

    public static boolean generateDependencies;
    public static void runScript(String[] scriptPath, JLabel label, String directory, String runCommand, String SCRIPT_PATH, String model){
        try {
            String[] command = new String[]{runCommand, SCRIPT_PATH+ File.separator+scriptPath[0], model, directory};
            ProcessBuilder pb = new ProcessBuilder(command);
            Process p = pb.start();
            int exitCode = p.waitFor();

            InputStream inputStream = p.getInputStream();
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String line;

            if (exitCode == 0) {
                label.setText(scriptPath[1]);
                label.setForeground(new Color(0, 160, 0));
            } else {
                label.setForeground(new Color(160, 0, 0));
                String cause = (line = reader.readLine()) != null ? ":<br>"+line : " code:<br>"+exitCode;
                label.setText("<html>Failed execution with status" + cause+"</html>");
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        } catch (InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }

    public static String[] defineScriptPath(GenerateAction action, String model){
        switch (action){
            case GenerateAction.DTO -> {
                return new String[]{"microservice-generator1.sh", "DTOs for /"+model+" generated successfully!", "Generating DTOs for /"+model+"..."};
            }
            case GenerateAction.TEST -> {
                return new String[]{"test-generator.sh", "Tests for /"+model+" generated successfully!", "Generating Tests for /"+model+"..."};
            }
            case GenerateAction.FULL_SERVICE -> {
                return new String[]{"microservice-generator2.sh", "Service structure for /"+model+" generated successfully!", "Generating service structure for /"+model+"..."};
            }
            case GenerateAction.MAPPER -> {
                return new String[]{"mapper-generator.sh", "DTO Mappers for /"+model+" generated successfully!", "Generating DTO Mappers for /"+model+"..."};
            }
            case GenerateAction.SERVICE -> {
                return new String[]{"service-generator.sh", "Service layer for /"+model+" generated successfully!", "Generating service layer for /"+model+"..."};
            }
            case GenerateAction.CONTROLLER -> {
                return new String[]{"controller-generator.sh", "Controller layer for /"+model+" generated successfully!", "Generating controller layer for /"+model+"..."};
            }
            case GenerateAction.EXCEPTION -> {
                return new String[]{"exception-generator.sh", "Exception classes for /"+model+" generated successfully!", "Generating exception classes for /"+model+"..."};
            }
            case GenerateAction.REPOSITORY -> {
                return new String[]{"repository-generator.sh", "Repository layer for /"+model+" generated successfully!", "Generating repository layer for /"+model+"..."};
            }
            default -> {
                return new String[]{"", "Error occurred", "Error occurred"};
            }
        }
    }
}
