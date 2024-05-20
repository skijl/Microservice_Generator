/*
 *    MIT License
 *
 *    Copyright (c) 2024 Maksym Makhrevych
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to deal
 *    in the Software without restriction, including without limitation the rights
 *    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *    copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in all
 *    copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *    SOFTWARE.
 */

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Objects;
import java.util.Optional;
import java.util.prefs.Preferences;

public class Menu extends JFrame {
    private final String SCRIPT_PATH = System.getProperty("java.io.tmpdir")+File.separator+"microgen_scripts";
    private String directory = null;
    private String directoryName = null;
    private String os;
    private String runCommand;
    private JLabel processInfoLabel;
    private JComboBox<String> comboBox;
    public Menu() {
        super("MicrosGen");
        Preferences prefs = Preferences.userNodeForPackage(Menu.class);
        String lastDirectory = prefs.get("lastDirectory", null);
        JFileChooser fileChooser = new JFileChooser(lastDirectory);

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(400, 300);
        setLocationRelativeTo(null);
        // Create header panel
        JPanel headerPanel = new JPanel();
        headerPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        try {
            BufferedImage logoImage = ImageIO.read(Objects.requireNonNull(getClass().getResourceAsStream("resources/static/logo.png")));
            setIconImage(logoImage);
            Image scaledLogoImage = logoImage.getScaledInstance(30, 30, Image.SCALE_SMOOTH); // Resize logo
            ImageIcon logoIcon = new ImageIcon(scaledLogoImage); // Create ImageIcon with resized logo
            JLabel logoLabel = new JLabel(logoIcon);
            headerPanel.add(logoLabel);
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        JLabel titleLabel = new JLabel("Microservice Generator");
        titleLabel.setForeground(new Color(50,170,255));
        titleLabel.setFont(new Font("Arial", Font.BOLD, 18)); // Change font and size as needed
        headerPanel.add(titleLabel);

        // Create process info panel
        JPanel processInfoPanel = new JPanel();
        processInfoPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        processInfoLabel = new JLabel("Empty history");
        processInfoPanel.add(processInfoLabel);

        JLabel directoryInfoLabel = new JLabel("No Directory Selected");
        processInfoPanel.add(directoryInfoLabel);

        comboBox = new JComboBox<>();
        // Create form panel
        JPanel directorySelectPanel = new JPanel();
        directorySelectPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        JLabel directoryLabel = new JLabel("Select a directory:");
        JButton chooseButton = new JButton("Choose Directory");
        chooseButton.setBackground(new Color(30, 144, 255)); // Dark blue color
        chooseButton.setForeground(Color.WHITE); // White text color
        chooseButton.setFocusable(false);
        chooseButton.addActionListener(e -> {
            fileChooser.setDialogTitle("Select a directory");
            fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);

            int returnValue = fileChooser.showOpenDialog(Menu.this);
            if (returnValue == JFileChooser.APPROVE_OPTION) {
                File selectedDirectory = fileChooser.getSelectedFile();
                directory = selectedDirectory.getAbsolutePath();
                directoryName = new File(directory).getName();
                directoryInfoLabel.setText(directory);
                prefs.put("lastDirectory", directory);
                comboBox.removeAllItems();
                comboBox.addItem("All Models");
                try {
                    Optional<Path> basePath = findModelDirectory(new File(directory + "/src"));
                    basePath.ifPresent((path)-> {
                                File directory = new File(path + File.separator + "model"); // Replace with your directory path
                                if (directory.isDirectory()) {
                                    File[] files = directory.listFiles();
                                    if (files != null) {
                                        for (File file : files) {
                                            if (file.isFile()) {
                                                String fileName = file.getName();
                                                String nameWithoutExtension = fileName.replaceFirst("[.][^.]+$", ""); // Remove file extension
                                                comboBox.addItem(nameWithoutExtension);
                                            }
                                        }
                                    }
                                }
                            }
                    );
                }catch (Exception ex){
                    ex.printStackTrace();
                }

            }
        });
        directorySelectPanel.add(directoryLabel);
        directorySelectPanel.add(chooseButton);
        directorySelectPanel.add(comboBox);

        // Create action panel
        JPanel firstRowPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        JPanel secondRowPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));

        //Create buttons
        JButton generateDTOButton = generateDTOButton();
        JButton generateDTOMapperButton = generateDTOMapperButton();
        JButton generateServiceButton = generateServiceButton();
        JButton generateTestsButton = generateTestsButton();

        firstRowPanel.add(generateDTOButton);
        firstRowPanel.add(generateDTOMapperButton);
        secondRowPanel.add(generateServiceButton);
        secondRowPanel.add(generateTestsButton);

        // Create a container panel for actionPanel and processInfoPanel
        JPanel formPanel = new JPanel();
        formPanel.setLayout(new BoxLayout(formPanel, BoxLayout.Y_AXIS));
        formPanel.add(directorySelectPanel);
        formPanel.add(firstRowPanel);
        formPanel.add(secondRowPanel);
        formPanel.add(processInfoPanel);

        // Add components to content pane
        getContentPane().setLayout(new BorderLayout());
        getContentPane().add(headerPanel, BorderLayout.NORTH);
        getContentPane().add(formPanel, BorderLayout.CENTER);
        defineOs();
        FileChecker.createTempFiles();
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE); // Don't close automatically
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent e) {
                FileChecker.deleteTempDirectory(SCRIPT_PATH);
                dispose();
            }
        });

    }

    private void defineOs() {
        os = System.getProperty("os.name").toLowerCase();

        if (os.contains("windows")) {
            os = "win";
        } else if (os.contains("mac")) {
            os = "mac";
        } else {
            os = "linux";
        }
        runCommand = os.equals("win") ? "C:\\Program Files\\Git\\bin\\bash.exe" : "sh";
    }

    void runScript(String scriptPath, JLabel label){
        if(directory==null){
            label.setForeground(new Color(120,0,0));
            label.setText("No directory selected!");
            return;
        }
        try {
            String[] command = new String[]{runCommand, SCRIPT_PATH+File.separator+scriptPath, comboBox.getSelectedItem().toString(), directory};
            ProcessBuilder pb = new ProcessBuilder(command);
            Process p = pb.start();
            int exitCode = p.waitFor();

            InputStream inputStream = p.getInputStream();
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
            String line;

            String action;

            if(scriptPath.equals("test-generator.sh")) {
                action = "Tests for /" + directoryName;
            }else if(scriptPath.equals("microservice-generator1.sh")) {
                action = "DTOs for /" + directoryName;
            }else if(scriptPath.equals("mapper-generator.sh")) {
                action = "DTO Mappers for /" + directoryName;
            }else{
                action = "Service for /" + directoryName;
            }
            if (exitCode == 0) {
                label.setText(action + " generated successfully.");
                label.setForeground(new Color(0,120,0));
            } else {
                label.setForeground(new Color(120,0,0));
                String cause = (line = reader.readLine()) != null ? ":<br>"+line : " code:<br>"+exitCode;
                label.setText("<html>Failed execution with status" + cause+"</html>");
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        } catch (InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }

    private static Optional<Path> findModelDirectory(File directory) {
        try {
            return Files.walk(directory.toPath())
                    .filter(path -> path.endsWith("model"))
                    .map(Path::getParent)
                    .findFirst();
        } catch (Exception e) {
            e.printStackTrace();
            return Optional.empty();
        }
    }

    public JButton generateDTOButton(){
        JButton generateDTOButton = new JButton("Generate DTOs");
        generateDTOButton.setBackground(new Color(30, 144, 255)); // Dark blue color
        generateDTOButton.setForeground(Color.WHITE); // White text color
        generateDTOButton.setFocusable(false);
        generateDTOButton.addActionListener(e -> {
            processInfoLabel.setText("Generating DTOs for /" + directoryName+"for "+comboBox.getSelectedItem()+"...");
            runScript("microservice-generator1.sh", processInfoLabel);
        });
        return generateDTOButton;
    }
    public JButton generateDTOMapperButton(){
        JButton generateDTOButton = new JButton("Generate DTO Mappers");
        generateDTOButton.setBackground(new Color(30, 144, 255)); // Dark blue color
        generateDTOButton.setForeground(Color.WHITE); // White text color
        generateDTOButton.setFocusable(false);
        generateDTOButton.addActionListener(e -> {
            processInfoLabel.setText("Generating DTO Mappers for /" + directoryName+"for "+comboBox.getSelectedItem()+"...");
            runScript("mapper-generator.sh", processInfoLabel);
        });
        return generateDTOButton;
    }
    public JButton generateServiceButton(){
        JButton generateServiceButton = new JButton("Generate Service");
        generateServiceButton.setBackground(new Color(30, 144, 255)); // Dark blue color
        generateServiceButton.setForeground(Color.WHITE); // White text color
        generateServiceButton.setFocusable(false);
        generateServiceButton.addActionListener(e -> {
            processInfoLabel.setText("Generating Service for /" + directoryName+"for"+comboBox.getSelectedItem()+"...");
            runScript("microservice-generator2.sh", processInfoLabel);
        });
        return generateServiceButton;
    }
    public JButton generateTestsButton(){
        JButton generateTestsButton = new JButton("Generate Tests");
        generateTestsButton.setBackground(new Color(30, 144, 255)); // Dark blue color
        generateTestsButton.setForeground(Color.WHITE); // White text color
        generateTestsButton.setFocusable(false);
        generateTestsButton.addActionListener(e -> {
            processInfoLabel.setText("Generating Tests for /" + directoryName+" for"+comboBox.getSelectedItem()+"...");
            runScript("test-generator.sh", processInfoLabel);
        });
        return generateTestsButton;
    }
}