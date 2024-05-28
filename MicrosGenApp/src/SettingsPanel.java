import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;

public class SettingsPanel extends JPanel {

    private JCheckBox generateDependenciesCheckBox;
    private JCheckBox darkThemeCheckBox;

    public SettingsPanel() {
        setLayout(new BorderLayout());
        setBackground(Styles.bgColor);

        // Create and configure the back button
        JButton backButton = new JButton("Back to Menu");
        Styles.button(backButton);
        backButton.addActionListener(e -> Menu.cardLayout.show(Menu.container, "1"));

        // Create a panel for the back button and align it to the right
        JPanel backButtonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        backButtonPanel.setOpaque(false);
        backButtonPanel.add(backButton);

        // Add the back button panel to the top of the BorderLayout
        add(backButtonPanel, BorderLayout.NORTH);

        // Create a panel for the checkboxes
        JPanel checkBoxPanel = new JPanel();
        checkBoxPanel.setLayout(new BoxLayout(checkBoxPanel, BoxLayout.Y_AXIS));
        checkBoxPanel.setOpaque(false);

        // User preferences panel
        JPanel userPreferencesPanel = createTitledPanel("User Preferences");
        generateDependenciesCheckBox = new JCheckBox("Generate necessary dependencies");
        generateDependenciesCheckBox.setFocusable(false);
        generateDependenciesCheckBox.addItemListener(new ItemListener() {
            @Override
            public void itemStateChanged(ItemEvent e) {
                if (e.getStateChange() == ItemEvent.SELECTED) {
                    Run.generateDependencies=true;
                } else {
                    Run.generateDependencies=false;
                }
                saveSettings();
            }
        });
        standardizeCheckBox(generateDependenciesCheckBox);
        userPreferencesPanel.add(generateDependenciesCheckBox);


        // Appearance panel
        JPanel appearancePanel = createTitledPanel("Appearance");
        darkThemeCheckBox = new JCheckBox("Dark Theme");
        darkThemeCheckBox.setFocusable(false);
        darkThemeCheckBox.addItemListener(new ItemListener() {
            @Override
            public void itemStateChanged(ItemEvent e) {
                if (e.getStateChange() == ItemEvent.SELECTED) {
                    Styles.darkTheme(true);
                } else {
                    Styles.darkTheme(false);
                }
                saveSettings();
            }
        });
        standardizeCheckBox(darkThemeCheckBox);
        appearancePanel.add(darkThemeCheckBox);

        // Add the sub-panels to the main checkBoxPanel
        checkBoxPanel.add(userPreferencesPanel);
        checkBoxPanel.add(Box.createVerticalStrut(10)); // Space between panels
        checkBoxPanel.add(appearancePanel);

        // Center the checkBoxPanel in the BorderLayout
        add(checkBoxPanel, BorderLayout.CENTER);

        Menu.registerThemeChangeListener(this);
    }

    private void standardizeCheckBox(JCheckBox checkBox) {
        checkBox.setOpaque(false);
        Dimension size = new Dimension(300, 30); // Standardize size for checkboxes
        checkBox.setPreferredSize(size);
        checkBox.setMaximumSize(size);
        checkBox.setForeground(Styles.fgColor);
        checkBox.setMinimumSize(size);
        checkBox.setAlignmentX(Component.LEFT_ALIGNMENT); // Align checkboxes to the left
    }

    private JPanel createTitledPanel(String title) {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setOpaque(false);

        TitledBorder titledBorder = BorderFactory.createTitledBorder(BorderFactory.createLineBorder(Styles.fgColor), title);
        titledBorder.setTitleColor(Styles.fgColor); // Set the title color
        panel.setBorder(titledBorder);

        return panel;
    }

    private void saveSettings() {
        Properties properties = new Properties();
        properties.setProperty("generateDependencies", Boolean.toString(generateDependenciesCheckBox.isSelected()));
        properties.setProperty("darkTheme", Boolean.toString(darkThemeCheckBox.isSelected()));

        String filePath = MenuPanel.SCRIPT_PATH + File.separator + "settings.properties";

        try (FileOutputStream fos = new FileOutputStream(filePath)) {
            properties.store(fos, "User Preferences");
        } catch (IOException e) {
            System.err.println("Error while saving settings: " + e.getMessage());
        }
    }

    public void loadSettings() {
        Properties properties = new Properties();
        try (FileInputStream fis = new FileInputStream(MenuPanel.SCRIPT_PATH + File.separator + "settings.properties")) {
            properties.load(fis);
            generateDependenciesCheckBox.setSelected(Boolean.parseBoolean(properties.getProperty("generateDependencies", "false")));
            darkThemeCheckBox.setSelected(Boolean.parseBoolean(properties.getProperty("darkTheme", "true")));
        } catch (IOException ignored) {
        }

        Styles.darkTheme(darkThemeCheckBox.isSelected());
    }

}
