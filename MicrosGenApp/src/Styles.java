import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.border.TitledBorder;
import java.awt.*;

public class Styles {

    public static void button(JButton button) {
        button.setFocusPainted(false);
        button.setFont(new Font("Arial", Font.PLAIN, 15));
        button.setBackground(new Color(46, 169, 255));
        button.setForeground(new Color(241, 241, 241));
        button.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(175, 217, 255)),
                BorderFactory.createEmptyBorder(5, 15, 5, 15)));
    }

    public static void buttonSetEnabled(JButton button, boolean enabled) {
        button.setEnabled(enabled);
        if (enabled) {
            button.setBackground(new Color(46, 169, 255));
            button.setForeground(new Color(241, 241, 241));
        } else {
            button.setBackground(new Color(75, 176, 255));
            button.setForeground(new Color(0, 0, 0));
        }
    }

    public static void labelNeutralColor(JLabel label) {
        label.setForeground(fgColor);
    }

    public static Color bgColor = new Color(30, 30, 30);
    public static Color fgColor = new Color(222, 222, 222);

    public static void darkTheme(boolean dark) {
        if(!dark){
            fgColor = new Color(30, 30, 30);
            bgColor = new Color(222, 222, 222);
        }else {
            bgColor = new Color(30, 30, 30);
            fgColor = new Color(222, 222, 222);
        }

        // Assuming Menu.container is the main container of your application
        ThemeChangeListener themeChangeListener = new ThemeChangeListener();
        Menu.container.addPropertyChangeListener("theme", themeChangeListener);

        // Trigger theme change for all components
        updateComponentColors(Menu.container);
    }

    private static void updateComponentColors(Component component) {
        if (component instanceof Container) {
            for (Component child : ((Container) component).getComponents()) {
                updateComponentColors(child);
            }
        }
        if (!(component instanceof JButton)) {
            component.setBackground(bgColor);
            component.setForeground(fgColor);
        }
        if (component instanceof JComponent) {
            Border border = ((JComponent) component).getBorder();
            if (border instanceof TitledBorder) {
                TitledBorder titledBorder = (TitledBorder) border;
                titledBorder.setBorder(BorderFactory.createLineBorder(Styles.fgColor));
                titledBorder.setTitleColor(Styles.fgColor);
            }
        }

    }
}

