import javax.swing.*;
import java.awt.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.prefs.Preferences;

public class MenuPanel extends JPanel {
    private final String SCRIPT_PATH = System.getProperty("java.io.tmpdir") + File.separator + "microgen_scripts";
    private String directory = null;
    private String directoryName = null;
    private String os;
    private String runCommand;
    private JLabel processInfoLabel;
    private JComboBox<String> comboBox;
    private JButton generateDTOButton;
    private JButton generateDTOMapperButton;
    private JButton generateServiceButton;
    private JButton generateTestsButton;

    public MenuPanel(JFileChooser fileChooser, Preferences prefs) {
        setLayout(new GridBagLayout());
        setBackground(Menu.bgColor);

        generateDTOButton = generateDTOButton();
        generateDTOMapperButton = generateDTOMapperButton();
        generateServiceButton = generateServiceButton();
        generateTestsButton = generateTestsButton();

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
        Styles.button(chooseButton);
        chooseButton.addActionListener(e -> {
            fileChooser.setDialogTitle("Select a directory");
            fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);

            int returnValue = fileChooser.showOpenDialog(this);
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
                    basePath.ifPresent((path) -> {
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
                    });
                } catch (Exception ex) {
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
        // Create buttons

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

        add(formPanel);

        defineOs();
        FileChecker.createTempFiles();
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

    private JButton generateDTOButton() {
        JButton generateDTOButton = new JButton("Generate DTOs");
        Styles.button(generateDTOButton);
        generateDTOButton.addActionListener(e -> {
            processInfoLabel.setText("Generating DTOs for /" + directoryName + " for " + comboBox.getSelectedItem() + "...");
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript("microservice-generator1.sh", processInfoLabel, "DTOs", directory, runCommand, SCRIPT_PATH, comboBox);
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        return generateDTOButton;
    }

    private JButton generateDTOMapperButton() {
        JButton generateDTOButton = new JButton("Generate DTO Mappers");
        Styles.button(generateDTOButton);
        generateDTOButton.addActionListener(e -> {
            processInfoLabel.setText("Generating DTO Mappers for /" + directoryName + " for " + comboBox.getSelectedItem() + "...");
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript("mapper-generator.sh", processInfoLabel, "Mappers", directory, runCommand, SCRIPT_PATH, comboBox);
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        return generateDTOButton;
    }

    private JButton generateServiceButton() {
        JButton generateServiceButton = new JButton("Generate Service");
        Styles.button(generateServiceButton);
        generateServiceButton.addActionListener(e -> {
            processInfoLabel.setText("Generating Service for /" + directoryName + " for " + comboBox.getSelectedItem() + "...");
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript("microservice-generator2.sh", processInfoLabel, "Service", directory, runCommand, SCRIPT_PATH, comboBox);
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        return generateServiceButton;
    }

    private JButton generateTestsButton() {
        JButton generateTestsButton = new JButton("Generate Tests");
        Styles.button(generateTestsButton);
        generateTestsButton.addActionListener(e -> {
            processInfoLabel.setText("Generating Tests for /" + directoryName + " for " + comboBox.getSelectedItem() + "...");
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript("test-generator.sh", processInfoLabel, "Tests", directory, runCommand, SCRIPT_PATH, comboBox);
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        return generateTestsButton;
    }

    private void setButtonsEnabled(boolean enabled) {
        Styles.buttonSetEnabled(generateDTOButton, enabled);
        Styles.buttonSetEnabled(generateDTOMapperButton, enabled);
        Styles.buttonSetEnabled(generateServiceButton, enabled);
        Styles.buttonSetEnabled(generateTestsButton, enabled);
    }
}
