import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Objects;
import java.util.prefs.Preferences;

public class Menu extends JFrame {

    public static CardLayout cardLayout;
    public static Container container;

    public Menu() {
        super("Microsgen");
        Preferences prefs = Preferences.userNodeForPackage(Menu.class);
        String lastDirectory = prefs.get("lastDirectory", null);
        JFileChooser fileChooser = new JFileChooser(lastDirectory);
        FileChecker.createTempFiles();

        try {
            BufferedImage logoImage = ImageIO.read(Objects.requireNonNull(getClass().getResourceAsStream("resources/static/logo.png")));
            setIconImage(logoImage);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(420, 410);
        setMinimumSize(new Dimension(380, 380));
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
        settingsPanel.loadSettings();
    }

    public static void registerThemeChangeListener(Component component) {
        ThemeChangeListener listener = new ThemeChangeListener();
        component.addPropertyChangeListener("theme", listener);

        if (component instanceof JPanel) {
            for (Component child : ((JPanel) component).getComponents()) {
                registerThemeChangeListener(child);
            }
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            Menu menu = new Menu();
            menu.setVisible(true);
        });
    }
}
