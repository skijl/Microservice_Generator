import javax.swing.*;

import javax.swing.*;
import java.awt.*;

public class SettingsPanel extends JPanel {

    public SettingsPanel() {
        setLayout(new FlowLayout(FlowLayout.RIGHT));
        setBackground(Menu.bgColor);

        JButton backButton = new JButton("Back to Menu");
        backButton.addActionListener(e -> Menu.cardLayout.show(Menu.container, "1"));
        add(backButton);
    }
}
