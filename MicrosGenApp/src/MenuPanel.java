import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;
import java.util.Optional;
import java.util.prefs.Preferences;

public class MenuPanel extends JPanel {
    public final static String SCRIPT_PATH = System.getProperty("java.io.tmpdir") + File.separator + "microgen_scripts";
    private String directory = null;
    private String directoryName = null;
    private String os;
    private String runCommand;
    private JLabel processInfoLabel;
    private JComboBox<String> comboBox;
    private JButton generateDTOButton;
    private JButton generateDTOMapperButton;
    private JButton mainButton;
    private JButton generateTestsButton;
    private static GenerateAction generateAction = GenerateAction.FULL_SERVICE;

    public MenuPanel(JFileChooser fileChooser, Preferences prefs) {

        generateDTOButton = generateDTOButton();
        generateDTOMapperButton = generateDTOMapperButton();
        generateTestsButton = generateTestsButton();

        //header panel
        JPanel headerPanel = new JPanel();
        headerPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        try {
            BufferedImage logoImage = ImageIO.read(Objects.requireNonNull(getClass().getResourceAsStream("resources/static/logo.png")));
            Image scaledLogoImage = logoImage.getScaledInstance(35, 35, Image.SCALE_SMOOTH); // Resize logo
            ImageIcon logoIcon = new ImageIcon(scaledLogoImage); // Create ImageIcon with resized logo
            JLabel logoLabel = new JLabel(logoIcon);
            headerPanel.add(logoLabel);
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        JLabel title = new JLabel("Microservice Generator");
        Styles.labelNeutralColor(title);
        title.setFont(new Font("Arial", Font.BOLD, 20));
        headerPanel.add(title);

        // Create process info panel
        JPanel processInfoPanel = new JPanel();
        processInfoPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        processInfoLabel = new JLabel("Empty history");
        Styles.labelNeutralColor(processInfoLabel);
        processInfoPanel.add(processInfoLabel);

        JLabel directoryInfoLabel = new JLabel("No directory selected");
        Styles.labelNeutralColor(directoryInfoLabel);
        processInfoPanel.add(directoryInfoLabel);

        comboBox = new JComboBox<>();
        // Create form panel
        JPanel directorySelectPanel = new JPanel();
        directorySelectPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
        JLabel directoryLabel = new JLabel("Select directory:");
        Styles.labelNeutralColor(directoryLabel);
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
                comboBox.setForeground(Styles.fgColor);
                comboBox.setBackground(Styles.bgColor);
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
        secondRowPanel.add(createAndShowGUI());
        secondRowPanel.add(generateTestsButton);

        // Create a container panel for actionPanel and processInfoPanel
        setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
        setBackground(Styles.bgColor);
        JPanel settingsPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        settingsPanel.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 0));
        try {
            settingsPanel.add(settingsButton());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        headerPanel.setOpaque(false);
        directorySelectPanel.setOpaque(false);
        firstRowPanel.setOpaque(false);
        secondRowPanel.setOpaque(false);
        processInfoPanel.setOpaque(false);
        settingsPanel.setOpaque(false);

        Menu.registerThemeChangeListener(this);

        add(headerPanel);
        add(directorySelectPanel);
        add(firstRowPanel);
        add(secondRowPanel);
        add(processInfoPanel);
        add(settingsPanel);

        defineOs();
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

    private JPanel createAndShowGUI() {
        // Main button
        mainButton = new JButton("Generate Service");
        mainButton.addActionListener(e -> {
            if(checkDirectoryIsEmpty()) return;
            String[] scriptPath = Run.defineScriptPath(generateAction,comboBox.getSelectedItem().toString());
            processInfoLabel.setText(scriptPath[2]);
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript(scriptPath, processInfoLabel, directory, runCommand, SCRIPT_PATH, comboBox.getSelectedItem().toString());
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        Styles.button(mainButton);

        // Small attached button
        JButton optionsButton = new JButton("▼");
        optionsButton.setPreferredSize(new Dimension(48, mainButton.getPreferredSize().height));
        optionsButton.setMargin(new Insets(0, 0, 0, 0));
        Styles.button(optionsButton);
        optionsButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                // Show the popup menu
                JPopupMenu popupMenu = createPopupMenu(mainButton);
                popupMenu.show(optionsButton, 0, optionsButton.getHeight());
            }
        });

        JPanel buttonPanel = new JPanel(new BorderLayout());
        buttonPanel.add(mainButton, BorderLayout.CENTER);
        buttonPanel.add(optionsButton, BorderLayout.EAST);

        return buttonPanel;
    }

    private JPopupMenu createPopupMenu(JButton mainButton) {
        JPopupMenu popupMenu = new JPopupMenu();
        popupMenu.setForeground(Styles.fgColor);
        popupMenu.setBackground(Styles.bgColor);

        JMenuItem option1 = new JMenuItem("Generate Service");
        option1.addActionListener(e -> {
            mainButton.setText(option1.getText());
            generateAction = GenerateAction.FULL_SERVICE;
        });
        popupMenu.add(option1);

        JMenuItem option3 = new JMenuItem("Exception Classes");
        option3.addActionListener(e -> {
            mainButton.setText(option3.getText());
            generateAction = GenerateAction.EXCEPTION;
        });
        popupMenu.add(option3);

        JMenuItem option4 = new JMenuItem("Repository Layer");
        option4.addActionListener(e -> {
            mainButton.setText(option4.getText());
            generateAction = GenerateAction.REPOSITORY;
        });
        popupMenu.add(option4);

        JMenuItem option5 = new JMenuItem("Service Layer");
        option5.addActionListener(e -> {
            mainButton.setText(option5.getText());
            generateAction = GenerateAction.SERVICE;
        });
        popupMenu.add(option5);

        JMenuItem option6 = new JMenuItem("Controller Layer");
        option6.addActionListener(e -> {
            mainButton.setText(option6.getText());
            generateAction = GenerateAction.CONTROLLER;
        });
        popupMenu.add(option6);

        return popupMenu;
    }

    private JButton generateDTOButton() {
        JButton generateDTOButton = new JButton("Generate DTOs");
        Styles.button(generateDTOButton);
        generateDTOButton.addActionListener(e -> {
            if(checkDirectoryIsEmpty()) return;
            String[] scriptPath = Run.defineScriptPath(GenerateAction.DTO, comboBox.getSelectedItem().toString());
            processInfoLabel.setText(scriptPath[2]);
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript(scriptPath, processInfoLabel, directory, runCommand, SCRIPT_PATH, comboBox.getSelectedItem().toString());
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
            if(checkDirectoryIsEmpty()) return;
            String[] scriptPath = Run.defineScriptPath(GenerateAction.MAPPER, comboBox.getSelectedItem().toString());
            processInfoLabel.setText(scriptPath[2]);
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript(scriptPath, processInfoLabel, directory, runCommand, SCRIPT_PATH, comboBox.getSelectedItem().toString());
                    setButtonsEnabled(true);
                    return null;
                }
            }.execute();
        });
        return generateDTOButton;
    }

    private JButton generateTestsButton() {
        JButton generateTestsButton = new JButton("Generate Tests");
        Styles.button(generateTestsButton);
        generateTestsButton.addActionListener(e -> {
            if(checkDirectoryIsEmpty()) return;
            String[] scriptPath = Run.defineScriptPath(GenerateAction.TEST, comboBox.getSelectedItem().toString());
            processInfoLabel.setText(scriptPath[2]);
            Styles.labelNeutralColor(processInfoLabel);
            setButtonsEnabled(false);
            new SwingWorker<Void, Void>() {
                @Override
                protected Void doInBackground() {
                    Run.runScript(scriptPath, processInfoLabel, directory, runCommand, SCRIPT_PATH, comboBox.getSelectedItem().toString());
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
        Styles.buttonSetEnabled(mainButton, enabled);
        Styles.buttonSetEnabled(generateTestsButton, enabled);
    }

    private JButton settingsButton() throws IOException {
        JButton settingsButton = new JButton("");
        settingsButton.setPreferredSize(new Dimension(35, 36)); // Set the button size
        settingsButton.setContentAreaFilled(false); // Make the button transparent
        settingsButton.setBorderPainted(false); // Remove border
        settingsButton.setFocusPainted(false); // Remove focus indication
        settingsButton.addActionListener(e -> Menu.cardLayout.show(Menu.container, "2"));

        // Load the image
        BufferedImage originalImg = ImageIO.read(getClass().getResource("resources/static/settings_button.png"));
        BufferedImage hoverImg = ImageIO.read(getClass().getResource("resources/static/settings_button_hover.png"));

        // Resize the image
        int newWidth = 45; // New width in pixels
        int newHeight = 47; // New height in pixels
        Image resizedImg = originalImg.getScaledInstance(newWidth, newHeight, Image.SCALE_SMOOTH);
        Image resizedImgHovered = hoverImg.getScaledInstance(newWidth, newHeight, Image.SCALE_SMOOTH);

        // Set the resized image as the button's icon
        ImageIcon originalIcon = new ImageIcon(resizedImg);
        ImageIcon hoverIcon = new ImageIcon(resizedImgHovered);
        settingsButton.setIcon(originalIcon);

        settingsButton.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                settingsButton.setIcon(hoverIcon);
            }

            @Override
            public void mouseExited(MouseEvent e) {
                settingsButton.setIcon(originalIcon);
            }
        });

        return settingsButton;
    }

    private boolean checkDirectoryIsEmpty(){
        if(directory==null){
            processInfoLabel.setForeground(new Color(160,0,0));
            processInfoLabel.setText("No directory selected!");
            return true;
        }else return false;
    }
}
