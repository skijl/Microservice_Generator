import java.awt.*;
import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;

public class ThemeChangeListener implements PropertyChangeListener {
    @Override
    public void propertyChange(PropertyChangeEvent evt) {
        if ("theme".equals(evt.getPropertyName())) {
            Component component = (Component) evt.getSource();
            component.setBackground(Styles.bgColor);
            component.setForeground(Styles.fgColor);
            component.repaint();
        }
    }
}
