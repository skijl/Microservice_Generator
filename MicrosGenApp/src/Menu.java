import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Objects;
import java.util.prefs.Preferences;

public class Menu extends JFrame {
    public static Color bgColor = new Color(30, 30, 30);
    public static CardLayout cardLayout;
    public static Container container;

    public Menu() {
        super("MicrosGen");
        Preferences prefs = Preferences.userNodeForPackage(Menu.class);
        String lastDirectory = prefs.get("lastDirectory", null);
        JFileChooser fileChooser = new JFileChooser(lastDirectory);

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(400, 350);
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
        titleLabel.setForeground(new Color(50, 170, 255));
        titleLabel.setFont(new Font("Arial", Font.BOLD, 18)); // Change font and size as needed
        headerPanel.add(titleLabel);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 0));
        JButton settingsButton = createSettingsButton();
        buttonPanel.add(settingsButton);

        headerPanel.add(buttonPanel, BorderLayout.NORTH);

        // Set up card layout for content switching
        container = getContentPane();
        cardLayout = new CardLayout();
        container.setLayout(cardLayout);

        // Initialize panels
        MenuPanel menuPanel = new MenuPanel(fileChooser, prefs);
        SettingsPanel settingsPanel = new SettingsPanel();

        container.add(menuPanel, "1");
        container.add(settingsPanel, "2");

        // Display the menu panel initially
        cardLayout.show(container, "1");
    }

    private JButton createSettingsButton() {
        JButton settingsButton = new JButton("");
        settingsButton.setSize(new Dimension(25, 25)); // Set the button size
        settingsButton.setContentAreaFilled(false); // Make the button transparent
        settingsButton.setBorderPainted(false); // Remove border
        settingsButton.setFocusPainted(false); // Remove focus indication
        settingsButton.addActionListener(e -> cardLayout.show(container, "2"));
        try {
            // Load the image
            BufferedImage originalImg = ImageIO.read(getClass().getResource("resources/static/settings_button.png"));

            // Resize the image
            int newWidth = 30; // New width in pixels
            int newHeight = 33; // New height in pixels
            Image resizedImg = originalImg.getScaledInstance(newWidth, newHeight, Image.SCALE_SMOOTH);

            // Set the resized image as the button's icon
            settingsButton.setIcon(new ImageIcon(resizedImg));
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        return settingsButton;
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            Menu menu = new Menu();
            menu.setVisible(true);
        });
    }
}
