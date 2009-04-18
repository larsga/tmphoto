
from java.lang import System, String
from java.io import File
from java.util import Vector, ArrayList
from java.awt import Dimension, CardLayout, GridLayout, BorderLayout, Cursor
from java.awt import GridBagLayout, GridBagConstraints
from java.awt.event import ActionListener
from javax.swing import *
from javax.swing.event import ListSelectionListener

# --- General Python utilities

def sort(list, keygen):
    list = map(lambda item, keygen=keygen: (keygen(item), item), list)
    list.sort()
    return map(lambda pair: pair[1], list)

# --- General Jython utilities

def jvector(list):
    vector = Vector(len(list))
    map(vector.add, list)
    return vector

def jlist(list):
    vector = ArrayList(list.size())
    map(vector.add, list)
    return vector

def jstring(str):
    return String(str)

# --- General swing utilities

# Get text dialog box

def get_text_box(parent, title):
    field = JTextField()
    pane = JOptionPane(field, JOptionPane.QUESTION_MESSAGE)
    dialog = pane.createDialog(parent, title)
    field.requestFocus()
    dialog.show()
    return field.getText()

# Error dialog box

def errorbox(parent, message):
    JOptionPane.showMessageDialog(parent, message, "Error",
                                  JOptionPane.ERROR_MESSAGE)

# Yes/no dialog box

def yesnobox(parent, message):
    return (JOptionPane.showConfirmDialog(parent, message, "Please decide", 
                                          JOptionPane.YES_NO_OPTION)
            == JOptionPane.YES_OPTION)
    
# Value-sharing combo box model

class ComboBoxModelWrapper(ComboBoxModel):

    def __init__(self, sub):
        self._sub = sub
        self._selected = None

    def addListDataListener(self, listener):
        self._sub.addListDataListener(listener)

    def getElementAt(self, ix):
        return self._sub.getElementAt(ix)

    def getSize(self):
        return self._sub.getSize()

    def removeListDataListener(self, listener):
        self._sub.removeListDataListener(listener)

    def getSelectedItem(self):
        return self._selected

    def setSelectedItem(self, item):
        self._selected = item
        
    
# Generic listeners

class ActionListenerFunction(ActionListener):

    def __init__(self, function):
        self._function = function

    def actionPerformed(self, event):
        self._function()

class ListSelectionListenerRowFunction(ListSelectionListener):

    def __init__(self, function, list):
        self._function = function
        self._list = list

    def valueChanged(self, event):
        self._function(self._list.getSelectedRow())
        
# Menu builder
        
def make_menu_bar(menus):
    menubar = JMenuBar()

    for (title, items) in menus:
        menu = JMenu(title)

        for (item_title, action, key) in items:
            item = menu.add(item_title)
            item.addActionListener(ActionListenerFunction(action))
            if key:
                item.setAccelerator(key)

        menubar.add(menu)

    return menubar

# File chooser

def choose_file(parent):
    chooser = JFileChooser(File("."))

    if chooser.showOpenDialog(parent) == JFileChooser.APPROVE_OPTION:
        return chooser.getSelectedFile().getName()
    else:
       return None

def choose_directory(parent):
    chooser = JFileChooser(File("."))
    chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY)

    if chooser.showOpenDialog(parent) == JFileChooser.APPROVE_OPTION:
        return chooser.getSelectedFile().getAbsolutePath()
    else:
       return None
   
def save_file(parent):
    chooser = JFileChooser(File("."))

    if chooser.showSaveDialog(parent) == JFileChooser.APPROVE_OPTION:
        return chooser.getSelectedFile().getName()
    else:
       return None

# Grid bag helping stuff

def get_gbc():
    gbc = GridBagConstraints()
    gbc.weightx = 1.0
    gbc.anchor = GridBagConstraints.NORTHWEST
    gbc.ipady = 2
    return gbc

def add_text_field(container, label):
    gbc = get_gbc()
    container.add(JLabel(label), gbc)

    gbc.gridwidth = GridBagConstraints.REMAINDER
    field = JTextField(40)
    container.add(field, gbc)
    
    return field

def add_text_area(container, label):
    gbc = get_gbc()
    container.add(JLabel(label), gbc)

    gbc.gridwidth = GridBagConstraints.REMAINDER
    field = JTextArea(8, 40)
    field.setWrapStyleWord(1)
    field.setLineWrap(1)
    container.add(JScrollPane(field), gbc)
    
    return field

def add_checkbox(container, label):
    gbc = get_gbc()
    container.add(JLabel(label), gbc)

    gbc.gridwidth = GridBagConstraints.REMAINDER
    field = JCheckBox()
    container.add(field, gbc)
    
    return field

def add_label(container, label):
    gbc = get_gbc()
    container.add(JLabel(label), gbc)

    gbc.gridwidth = GridBagConstraints.REMAINDER
    field = JLabel("")
    container.add(field, gbc)
    
    return field

