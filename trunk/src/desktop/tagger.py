
# WARNING: This source code is anything but clean. Prepare to have
# your aesthethic sensibilities offended if you read anything below
# this point.

"""
Video support:
 - extend ontology.ltm & metadata.xtm DONE
   - Abstract superclass: depiction/image
   - Subclass: video
   - new property: duration
 - get videos in
   - also scan for video files OK
   - next unedited must see video files OK
 - display video in scanner.py
    http://java.sun.com/javase/technologies/desktop/media/jmf/1.0/guide/JavaMediaFrame.fm2.html
 - extract first frame as preview image (use for thumbnail!)
    convert MVI_3051.AVI[1] test.jpg
 - convert to flash video for display?
    http://ffmpeg.mplayerhq.hu/
    http://stephenjungels.com/jungels.net/articles/ffmpeg-howto.html
    http://www.haykranen.nl/2007/11/21/howto-install-and-use-ffmpeg-on-mac-os-x-leopard/
 - include a flash widget for display in web app
General editing:
 - improve so we can remove extra values
 - maybe use a validator to pop up a flag saying a photo is invalid
 - then use a generic editor to get rid of extra crap
Copy from previous:
 - improve so we don't get multiple values where only one is allowed

Next:
 - removing people from list of depicteds
 - filtering photos by event (in list of photos)

 - publishing as a menu item
   - settable max resolution
 - get rid of OOM error
 - things depicted in pictures (buildings, objects, etc)
 - simple search support


parent-of($PARENT, $CHILD) :- {
  father-of($PARENT : parent, $CHILD : child) |
  mother-of($PARENT : parent, $CHILD : child)
}.

sibling-of($A, $B) :-
  parent-of($PARENT, $A),
  parent-of($PARENT, $B),
  $A /= $B.
 
"""

# --- Imports

import sys, os, time, thread, string
from glob import glob

from java.lang import System

from java.util import HashMap, ArrayList
from java.io import File
from com.drew.imaging.jpeg import JpegMetadataReader
from com.drew.metadata import MetadataException

from net.ontopia.infoset.impl.basic import URILocator

from net.ontopia.utils import StringUtils
from net.ontopia.topicmaps.utils import ImportExportUtils, TopicStringifiers, AssociationBuilder, DuplicateSuppressionUtils
from net.ontopia.infoset.impl.basic import URILocator

import time

from utils import *

# --- Constants

MAC = (System.getProperty("os.name") == "Mac OS X")
BASE = "http://psi.garshol.priv.no/tmphoto/"
OP_BASE = "http://psi.ontopedia.net/"
DC_BASE = "http://purl.org/dc/elements/1.1/"
MD_BASE = "http://psi.ontopia.net/metadata/#"
TECH_BASE = "http://www.techquila.com/psi/thesaurus/#"
USERMAN = "http://psi.ontopia.net/userman/"
PATH = os.path.split(sys.argv[0])[0] # directory of this file, basically

PREFIXES = """
using op for i"http://psi.ontopedia.net/"
using ph for i"http://psi.garshol.priv.no/tmphoto/"
"""

# --- TM access

def get_first(iterable):
    return iterable.iterator().next()

def get_name(topic):
    names = topic.getTopicNames()
    if not names.isEmpty():
        return names.iterator().next()

def get_psi(topic):
    psis = topic.getSubjectIdentifiers()
    if psis.isEmpty():
        return ""
    else:
        return psis.iterator().next().getAddress()

def get_occurrence(topic, type):
    for occ in topic.getOccurrences():
        if occ.getType() == type:
            return occ

def get_role(topic, roletype, assoctype):
    "Returns role on other side from topic."
    for role in topic.getRoles():
        assoc = role.getAssociation()
        if assoc.getType() == assoctype:
            for role2 in assoc.getRoles():
                if role2.getType() == roletype and role2 != role:
                    return role2

def get_topic_role(topic, roletype, assoctype):
    "Returns role played by topic topic."
    for role in topic.getRoles():
        assoc = role.getAssociation()
        if assoc.getType() == assoctype and role.getType() == roletype:
            return role

def add_topic_id(topic):
    tm = topic.getTopicMap()
    base = tm.getStore().getBaseAddress()

    id = "t" + topic.getObjectId()
    while tm.getObjectByItemIdentifier(base.resolveAbsolute("#" + id)):
        id = id + "_" + StringUtils.makeRandomId(3)

    topic.addItemIdentifier(base.resolveAbsolute("#" + id))

def get_topic_by_id(tm, id):
    base = tm.getStore().getBaseAddress()
    srcloc = base.resolveAbsolute("#" + id)
    return tm.getObjectByItemIdentifier(srcloc)

def has_instances(topic_type):
    tm = topic_type.getTopicMap()
    ix = tm.getIndex("net.ontopia.topicmaps.core.index.ClassInstanceIndexIF")
    return not ix.getTopics(topic_type).isEmpty()

# --- Data binding

class AbstractSynchronizer:

    def __init__(self, object, field):
        self._field = field
        self._object = object
    
    def synchronize(self):
        if self._field.getText():
            if not self._object:
                self._create_object()
            self._object.setValue(self._field.getText())
        elif self._object:
            # text was set to nothing, so object must go
            self._object.remove()

class NameSynchronizer(AbstractSynchronizer):

    def __init__(self, object, field, topic):
        AbstractSynchronizer.__init__(self, object, field)
        self._topic = topic

    def _create_object(self):
        self._object = builder.makeTopicName(self._topic, "")

class PSISynchronizer(AbstractSynchronizer):

    def __init__(self, field, topic):
        AbstractSynchronizer.__init__(self, topic, field)
    
    def synchronize(self):
        for loc in ArrayList(self._object.getSubjectIdentifiers()):
            self._object.removeSubjectIdentifier(loc)
            
        if self._field.getText():
            self._object.addSubjectIdentifier(URILocator(self._field.getText()))

class OccurrenceSynchronizer(AbstractSynchronizer):

    def __init__(self, object, field, topic, type):
        AbstractSynchronizer.__init__(self, object, field)
        self._topic = topic
        self._type = type

    def _create_object(self):
        self._object = builder.makeOccurrence(self._topic, self._type, "")

class AssociationSynchronizer:

    def __init__(self, topic, otherrole, list, assoctype, rt1, rt2, unique):
        self._topic = topic
        self._otherrole = otherrole
        self._list = list
        self._assoctype = assoctype
        self._rt1 = rt1
        self._rt2 = rt2
        self._unique = unique

    def synchronize(self):
        theassoc = None # might not be set later
        selected = self._list.getTopic()

        # update this association
        if selected and not self._otherrole:
            theassoc = builder.makeAssociation(self._assoctype)
            builder.makeAssociationRole(theassoc, self._rt1, self._topic)
            self._otherrole = builder.makeAssociationRole(theassoc, self._rt2, selected)

        elif self._otherrole:
            if selected:
                self._otherrole.setPlayer(selected)
                theassoc = self._otherrole.getAssociation()
            else:
                # we used to have a role, but now nothing's selected
                # that means we have to remove the whole association
                tm.removeAssociation(self._otherrole.getAssociation())

        # remove duplicate associations, if unique
        if not self._unique:
            return

        for role in list(self._topic.getRoles()):
            assoc = role.getAssociation()
            if (role.getType() == self._rt1 and
                assoc.getType() == self._assoctype and
                assoc != theassoc):
                for role2 in assoc.getRoles():
                    if role2.getType() == self._rt2 and role2 != role:
                        assoc.remove()
                        break

class UnarySynchronizer:

    def __init__(self, topic, role, checkbox, assoctype, roletype):
        self._topic = topic
        self._role = role
        self._checkbox = checkbox
        self._assoctype = assoctype
        self._roletype = roletype

    def synchronize(self):
        selected = self._checkbox.isSelected()
        
        if selected and not self._role:
            assoc = builder.makeAssociation(self._assoctype)
            self._role = builder.makeAssociationRole(assoc, self._roletype, self._topic)

        elif self._role and not selected:
            tm.removeAssociation(self._role.getAssociation())
                
def bind_name(field, topic):
    bn = get_name(topic)
    sync = NameSynchronizer(bn, field, topic)
    if bn:
        field.setText(bn.getValue())
    else:
        field.setText("")
    return sync

def bind_psi(field, topic):
    sync = PSISynchronizer(field, topic)
    psi = get_psi(topic)    
    if psi:
        field.setText(psi)
    else:
        field.setText("")
    return sync

def bind_occurrence(field, topic, type):
    occ = get_occurrence(topic, type)
    sync = OccurrenceSynchronizer(occ, field, topic, type)
    if occ:
        field.setText(occ.getValue())
    else:
        field.setText("")
    return sync

def bind_association(list, topic, assoctype, rt1, rt2, unique = 0):
    """The unique parameter says whether more than one association of this type
    is allowed. If unique is true, the answer is no."""
    assert assoctype and rt1 and rt2
    otherrole = get_role(topic, rt2, assoctype)
    sync = AssociationSynchronizer(topic, otherrole, list, assoctype, rt1, rt2,
                                   unique)
    if otherrole:
        list.setSelectedItem(strify(otherrole.getPlayer()))
    else:
        list.setSelectedItem("")
    return sync

def bind_unary(checkbox, topic, assoctype, roletype):
    role = get_topic_role(topic, roletype, assoctype)
    sync = UnarySynchronizer(topic, role, checkbox, assoctype, roletype)
    checkbox.setSelected(role != None)
    return sync

# --- Topic chooser

from java.awt.event import ActionListener, ItemListener, ItemEvent, WindowListener
from java.awt.event import KeyEvent, ActionEvent
from javax.swing import KeyStroke

class TopicChooser(ActionListener):

    def __init__(self, parent, type):
        frame = JDialog(parent, "Select " + strify(type), 1)
        frame.getContentPane().setLayout(GridBagLayout())

        gbc = get_gbc()
        gbc.fill = GridBagConstraints.VERTICAL
        gbc.gridwidth = GridBagConstraints.REMAINDER
        list = TopicList(type)
        list.setVisibleRowCount(200)
        frame.getContentPane().add(JScrollPane(list), gbc)

        gbc = get_gbc()
        gbc.gridwidth = 1
        choose = JButton("Choose")
        choose.addActionListener(self)
        frame.getContentPane().add(choose, gbc)
        gbc.gridwidth = GridBagConstraints.REMAINDER
        new = JButton("New")
        new.addActionListener(self)
        self._creator = CreateTopicListener(frame, None, type)
        new.addActionListener(self._creator)
        frame.getContentPane().add(new, gbc)

        self._list = list
        self._chosen = None
        self._frame = frame

        # position it inside the parent
        position = parent.getLocation()
        frame.setLocation(int(position.getX()) + 600,
                          int(position.getY()) + 25)

        frame.pack()
        frame.setVisible(1)
        choose.requestFocus()
        
    def actionPerformed(self, event):
        if event.getActionCommand() == "Choose":
            self._chosen = self._list.getTopics()
        else:
            # this must be "New"
            # the other listener actually creates the topic
            self._chosen = [self._creator.get_created()]
        self._frame.dispose()

def choose_topic(parent, type):
    chooser = TopicChooser(parent, type)
    return chooser._chosen

# --- ImagePanel

from javax.imageio import ImageIO

class ImagePanel(JPanel):

    def __init__(self):
        self._image = None
        self._pf = None

    def setPreferredSize(self, dim):
        self._pf = dim
        JPanel.setPreferredSize(self, dim)
    
    def paintComponent(self, g):
        if self._image:
            g.drawImage(self._image,
                        0, 0, self.getWidth(), self.getHeight(), 
                        0, 0, self._image.getWidth(), self._image.getHeight(), 
                        self)

    def setImage(self, image):
        if self._image:
            self._image.flush() # hopefully this gets rid of OOMs
        self._image = image
        self.repaint()

    def setVideo(self, filename):
        tmp = "/tmp/" + os.path.split(filename)[1]
        tmp = tmp[ : -4] + ".jpg" # change .avi to .jpg
        if not exists(tmp):
            cmd = 'convert "%s[1]" "%s"' % (filename, tmp)
            os.system(cmd)
        self.setImage(ImageIO.read(File(tmp)))

    def render_image(self, topic):
        url = get_first(topic.getSubjectLocators()).getAddress()
        filename = url[6 : ]
        extension = filename[-3 : ].lower()

        if extension == "jpg" or extension == "gif":
            self.setImage(ImageIO.read(File(filename)))
        elif extension == "avi":
            self.setVideo(filename)
        
# --- AbstracTopicListComponent

class AbstracTopicListComponent:

    def __init__(self, criterion):
        self._params = HashMap()
        if type(criterion) == type(""):
            self._query = criterion
            self._topictype = None
        else:
            self.setType(criterion)

    def getType(self):
        return self._topictype

    def setType(self, type):
        self._topictype = type
        self._query = "instance-of($TOPIC, i\"%s\")" % self._get_si()
        self.refresh()

    def getOwnerTopic(self):
        if not self._topictype:
            return self._params["topic"]
    
    def getTopic(self):
        topic = None
        
        result = processor.execute(PREFIXES + """
          select $TOPIC from
          %s, topic-name($TOPIC, $TN),
          value($TN, "%s")?""" % (self._query, self.getSelectedString()),
                                   self._params)
        if result.next():
            topic = result.getValue(0)

        result.close()

        return topic

    def getTopics(self):
        topics = []
        for string in self.getSelectedStrings():
            result = processor.execute(PREFIXES + """
              select $TOPIC from
              %s, topic-name($TOPIC, $TN),
              value($TN, "%s")?""" % (self._query, string), self._params)
            if result.next():
                topics.append(result.getValue(0))

            result.close()

        return topics        

    def refresh(self):
        if not self._topictype and not self._params:
            return # we don't have enough info yet, so don't do anything
        
        model = self.getModel()
        model.removeAllElements()
        model.addElement("")

        result = processor.execute(PREFIXES +
                                   "%s order by $TOPIC?" % self._query,
                                   self._params)
        while result.next():
            model.addElement(strify(result.getValue(0)))

        result.close()
        
    def _get_si(self):
        return self._topictype.getSubjectIdentifiers().iterator().next().getAddress()
        
# --- TopicComboBox

class TopicComboBox(JComboBox, AbstracTopicListComponent):

    def __init__(self, criterion):
        JComboBox.__init__(self)
        AbstracTopicListComponent.__init__(self, criterion)
        self.refresh()

    def getSelectedString(self):
        return self.getModel().getSelectedItem()        
        
# --- TopicList

class TopicList(AbstracTopicListComponent, JList):

    def __init__(self, criterion):
        JList.__init__(self, DefaultListModel())
        AbstracTopicListComponent.__init__(self, criterion)
        self.refresh()

    def getSelectedString(self):
        return self.getSelectedValue()

    def getSelectedStrings(self):
        return self.getSelectedValues()

    def setSelectedItem(self, item):
        if not self._topictype:
            # this is our parameter
            self._params["topic"] = item
            self.refresh()
        else:
            self.setSelectedValue(item, 1)
        
# --- CreateTopicListener

class CreateTopicListener(ActionListener):

    def __init__(self, parent, topiclist, topictype = None):
        self._parent = parent
        self._topiclist = topiclist
        if topictype:
            self._topictype = topictype
        else:
            self._topictype = topiclist.getType()
        self._created = None

    def actionPerformed(self, event):
        name = string.strip(get_text_box(self._parent, "Name"))
        if not name:
            return
        topic = builder.makeTopic()
        add_topic_id(topic)
        builder.makeTopicName(topic, name)
        topic.addType(self._topictype)
        if self._topiclist:
            self._topiclist.refresh()

        self._created = topic

    def get_created(self):
        return self._created

# --- DeleteTopicListener

class DeleteTopicListener(ActionListener):

    def __init__(self, topiclist):
        self._topiclist = topiclist

    def actionPerformed(self, event):
        topic = self._topiclist.getTopic()
        topic.remove()
        self._topiclist.refresh()

# --- Remove topic from list listener
        
class TopicRemoveListener(ActionListener):
    """Removes selected topic(s) from a list in response to a button click
    event."""

    def __init__(self, list, assoctype, nearrole, farrole):
        self._list = list
        self._assoctype = assoctype
        self._nearrole = nearrole
        self._farrole = farrole
        
    def actionPerformed(self, event):
        # the user has pressed the button, so we now need to remove the
        # associations between the topics selected in the list and the
        # topic that owns the list.
        owner = self._list.getOwnerTopic()
        toberemoved = self._list.getTopics()
        for role in jlist(owner.getRoles()):
            if role.getType() != self._nearrole:
                continue

            assoc = role.getAssociation()
            if assoc.getType() != self._assoctype:
                continue

            for otherrole in assoc.getRoles():
                if otherrole != role:
                    break

            assert otherrole.getType() == self._farrole

            if otherrole.getPlayer() in toberemoved:
                assoc.remove()

        self._list.refresh()
        
# --- Topic Type Editor

from java.awt import Dimension, BorderLayout, GridBagLayout, GridBagConstraints

class TopicTypeEditor(ListSelectionListener):

    def __init__(self, heading, topictype):
        frame = JFrame(heading)
        self._frame = frame
        frame.getContentPane().setLayout(BorderLayout())

        list = TopicList(topictype)
        list.setVisibleRowCount(20)
        list.addListSelectionListener(self)
        frame.getContentPane().add(JScrollPane(list), BorderLayout.WEST)
        self._list = list

        container = JPanel()
        container.setLayout(GridBagLayout())

        self._add_field_controls(container)

        frame.getContentPane().add(container, BorderLayout.EAST)
        frame.pack()
        frame.setVisible(1)

        self._synchronizers = []

    def valueChanged(self, event):
        self._store()
        topic = self._list.getTopic()
        if not topic:
            return
        
        self._synchronizers = self._get_synchronizers(topic)

    def _store(self):
        for synchronizer in self._synchronizers:
            synchronizer.synchronize()
        
# --- Person editor

class PersonEditor(TopicTypeEditor):

    def __init__(self):
        TopicTypeEditor.__init__(self, "Edit people", person)

    def _add_field_controls(self, container):
        # text fields
        self._name = add_text_field(container, "Name")
        self._description = add_text_area(container, "Description")
        self._psi = add_text_field(container, "PSI")
        self._username = add_text_field(container, "Username")
        self._password = add_text_field(container, "Password")

        # partner
        gbc = get_gbc()
        container.add(JLabel("Partner of"), gbc)
        self._partner = TopicComboBox(person)
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(self._partner, gbc)

        # father
        gbc = get_gbc()
        container.add(JLabel("Father"), gbc)
        self._father = TopicComboBox(person)
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(self._father, gbc)

        # mother
        gbc = get_gbc()
        container.add(JLabel("Mother"), gbc)
        self._mother = TopicComboBox(person)
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(self._mother, gbc)

        # delete button
        delete_location = JButton("Delete")
        delete_location.addActionListener(DeleteTopicListener(self._list))
        gbc = get_gbc()
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(delete_location, gbc)

        # hide checkbox
        self._hide = add_checkbox(container, "Hide")

    def _get_synchronizers(self, topic):
        return [
            bind_name(self._name, topic),
            bind_psi(self._psi, topic),
            bind_occurrence(self._description, topic, desc),
            bind_occurrence(self._username, topic, username),
            bind_occurrence(self._password, topic, password),
            bind_association(self._partner, topic, partner_of, partner, partner, 1),
            bind_association(self._father, topic, father_of, child, parent, 1),
            bind_association(self._mother, topic, mother_of, child, parent, 1),
            bind_unary(self._hide, topic, hide, hidden)]

# --- Place editor

class PlaceEditor(TopicTypeEditor):

    def __init__(self):
        TopicTypeEditor.__init__(self, "Edit places", location)

    def _add_field_controls(self, container):
        self._name = add_text_field(container, "Name")
        self._description = add_text_area(container, "Description")
        self._psi = add_text_field(container, "PSI")
        self._latitude = add_text_field(container, "Latitude")
        self._longitude = add_text_field(container, "Longitude")

        # location
        gbc = get_gbc()
        container.add(JLabel("Location"), gbc)
        self._location = TopicComboBox(location)
        container.add(self._location, gbc)
        add_location = JButton("Add")
        add_location.addActionListener(CreateTopicListener(self._frame, self._location))
        container.add(add_location, gbc)
        delete_location = JButton("Delete")
        delete_location.addActionListener(DeleteTopicListener(self._list))
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(delete_location, gbc)

        # hide checkbox
        gbc.gridwidth = GridBagConstraints.REMAINDER
        self._hide = add_checkbox(container, "Hide")

    def _get_synchronizers(self, topic):
        return [
            bind_name(self._name, topic),
            bind_psi(self._psi, topic),
            bind_occurrence(self._description, topic, desc),
            bind_occurrence(self._latitude, topic, latitude),
            bind_occurrence(self._longitude, topic, longitude),
            bind_association(self._location, topic, contained_in, containee, container, 1),
            bind_unary(self._hide, topic, hide, hidden)]

# --- Event editor

class EventEditor(TopicTypeEditor):

    def __init__(self):
        TopicTypeEditor.__init__(self, "Edit events", event)

    def _add_field_controls(self, container):
        self._name = add_text_field(container, "Name")
        self._description = add_text_area(container, "Description")
        self._start_date = add_text_field(container, "Start date")
        self._end_date = add_text_field(container, "End date")
        self._is_processed = add_checkbox(container, "Processed")
        self._hide = add_checkbox(container, "Hide")
        self._psi = add_text_field(container, "PSI")

    def _get_synchronizers(self, topic):
        return [
            bind_name(self._name, topic),
            bind_occurrence(self._description, topic, desc),
            bind_occurrence(self._start_date, topic, start_date),
            bind_occurrence(self._end_date, topic, end_date),
            bind_unary(self._is_processed, topic, is_processed, processed),
            bind_unary(self._hide, topic, hide, hidden),
            bind_psi(self._psi, topic)]

# --- Category editor

class CategoryEditor(TopicTypeEditor):

    def __init__(self):
        TopicTypeEditor.__init__(self, "Edit categories", category)

    def _add_field_controls(self, container):
        self._name = add_text_field(container, "Name")
        self._description = add_text_area(container, "Description")
        self._psi = add_text_field(container, "PSI")

        # parent
        gbc = get_gbc()
        container.add(JLabel("Parent(s)"), gbc)
        self._parent = TopicComboBox(category)
        container.add(self._parent, gbc)
        self._parent2 = TopicComboBox(category)
        container.add(self._parent2, gbc)
        
        add_parent = JButton("Add")
        add_parent.addActionListener(CreateTopicListener(self._frame, self._parent))
        add_parent.addActionListener(CreateTopicListener(self._frame, self._parent2))
        container.add(add_parent, gbc)
        delete_parent = JButton("Delete")
        delete_parent.addActionListener(DeleteTopicListener(self._list))
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(delete_parent, gbc)

    def _get_synchronizers(self, topic):
        return [
            bind_name(self._name, topic),
            bind_psi(self._psi, topic),
            bind_occurrence(self._description, topic, desc),
            bind_association(self._parent, topic, broader_narrower, narrower, broader),
            
            bind_association(self._parent2, topic, broader_narrower, narrower, broader)]
    
# --- Gallery metadata editor

from java.awt.event import WindowAdapter # get WindowListener with empty impls

class MetadataEditor(WindowAdapter):

    def __init__(self):
        frame = JFrame("Edit gallery metadata")
        frame.addWindowListener(self)
        frame.getContentPane().setLayout(BorderLayout())

        container = frame.getContentPane()
        container.setLayout(GridBagLayout())

        self._title = add_text_field(container, "Title")
        self._description = add_text_area(container, "Description")

        # creator
        gbc = get_gbc()
        container.add(JLabel("Creator"), gbc)
        self._creator = TopicComboBox(person)
        container.add(self._creator, gbc)
        add_person = JButton("Add")
        add_person.addActionListener(CreateTopicListener(frame, self._creator))
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(add_person, gbc)

        # OK/cancel
        # FIXME: add

        # get/make reifying topic
        topic = tm.getReifier()
        if not topic:
            topic = builder.makeTopic()
            base = tm.getStore().getBaseAddress()
            tm.setReifier(topic)

        self._synchronizers = [
            bind_name(self._title, topic),
            bind_occurrence(self._description, topic, desc),
            bind_association(self._creator, topic, creator, resource, value, 1)]

        frame.pack()
        frame.setVisible(1)
        
    def windowClosing(self, event):
        for synchronizer in self._synchronizers:
            synchronizer.synchronize()
            
# --- Photo organizer

class ItemSelectionListener(ItemListener):

    def __init__(self, table, rt1, atype, rt2, list):
        self._table = table
        self._assocbuilder = AssociationBuilder(atype, rt1, rt2)
        self._rt1 = rt1
        self._rt2 = rt2
        self._atype = atype
        self._list = list

    def itemStateChanged(self, e):
        if e.getStateChange() != ItemEvent.SELECTED:
            return

        chosen = self._list.getTopic()
        
        for row in self._table.getSelectedRows():
            photo = self._table.getModel().getPhoto(row)

            found = 0
            for role in photo.getRoles():
                if role.getType() == self._rt1:
                    assoc = role.getAssociation()
                    if assoc.getType() == self._atype:
                        for role2 in assoc.getRoles():
                            if role2.getType() == self._rt2:
                                found = 1
                                role2.setPlayer(chosen)
                                break

                if found:
                    break

            if not found:
                self._assocbuilder.makeAssociation(photo, chosen)
        
class PhotoOrganizer:

    def __init__(self):
        top = JFrame("Photo organizer")

        container = top.getContentPane()
        container.setLayout(GridBagLayout())

        # location
        gbc = get_gbc()
        container.add(JLabel("Location"), gbc)
        self._location = TopicComboBox(location)
        container.add(self._location, gbc)
        
        # event
        gbc = get_gbc()
        container.add(JLabel("Event"), gbc)
        self._event = TopicComboBox(event)
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(self._event, gbc)

        # photos
        gbc = get_gbc()
        gbc.gridwidth = GridBagConstraints.REMAINDER
        table = make_photo_table()
        container.add(JScrollPane(table), gbc)

        # set up listeners
        self._location.addItemListener(ItemSelectionListener(table, image, taken_at, location, self._location))
        self._event.addItemListener(ItemSelectionListener(table, image, taken_during, event, self._event))

        # make visible
        top.pack()
        top.setVisible(1)
            
# --- Photo chooser list

from javax.swing.table import AbstractTableModel, TableCellEditor, DefaultTableColumnModel, TableCellRenderer

class TopicRenderer(TableCellRenderer):

    def getTableCellRendererComponent(self, table, object, issel, hasfoc, row, col):
        return JLabel(strify(object))

class PhotoColumnModel(DefaultTableColumnModel):
    pass

class PhotoTableModel(AbstractTableModel):

    column_names = ["Title", "Time", "Location", "Event"]
    
    def __init__(self):
        photos = []
        result = processor.execute(PREFIXES +
                                   """select $PHOTO, $NAME, $TIME, $PLACE, $EVENT, $LOC from
                                      instance-of($PHOTO, op:Image),
                                      topic-name($PHOTO, $TNAME),
                                      value($TNAME, $NAME),
                                      { ph:time-taken($PHOTO, $TIME) },
                                      { ph:taken-at($PHOTO : op:Image, $PLACE : op:Place) },
                                      { ph:taken-during($PHOTO : op:Image, $EVENT : op:Event) },
                                      subject-locator($PHOTO, $LOC)
                                      order by $TIME, $LOC?""")
        while result.next():
            photos.append((result.getValue("PHOTO"),
                           result.getValue("NAME"),
                           result.getValue("TIME"),
                           result.getValue("PLACE"),
                           result.getValue("EVENT")))

        self._photos = photos

    def getRowCount(self):
        return len(self._photos)

    def getColumnCount(self):
        return 4

    def getValueAt(self, row, column):
        return self._photos[row][column + 1]

    def getColumnName(self, column):
        return PhotoTableModel.column_names[column]

    def getPhoto(self, row):
        return self._photos[row][0]

#     def isCellEditable(self, row, column):
#         return column in (2, 3)

class PhotoSelectListener(ListSelectionListener):

    def __init__(self, table):
        self._table = table

    def valueChanged(self, event):
        row = self._table.getSelectedRow()
        if row != -1:
            editor.set_image(self._table.getModel().getPhoto(row))

def make_photo_table():
    table = JTable(PhotoTableModel())

    # set up the location column
    column = table.getColumn("Location")
    column.setCellRenderer(TopicRenderer())

    # set up the event column
    column = table.getColumn("Event")
    column.setCellRenderer(TopicRenderer())
    return table
            
def photo_list(editor):
    frame = JFrame("Choose photo")
    #frame.getContentPane().setLayout(BorderLayout())

    table = make_photo_table()
    table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION)
    listener = PhotoSelectListener(table)
    table.getSelectionModel().addListSelectionListener(listener)
    frame.getContentPane().add(JScrollPane(table))

    frame.pack()
    frame.setVisible(1)       
        
# --- PhotoMetadataEditor

from javax.imageio import IIOException

class CreateAssociationListener(ActionListener):

    # pops up a topic chooser
    # associates the topic chosen with the current topic

    def __init__(self, parent, topictype, assoctype, rt1, rt2, list, functions = []):
        self._parent = parent # parent frame (swing)
        self._topictype = topictype
        self._current = None
        self._list = list
        self._functions = functions # to be called when event triggered

        tm = assoctype.getTopicMap()
        self._assocb = AssociationBuilder(assoctype, rt1, rt2)

    def setCurrentTopic(self, current):
        self._current = current

    def actionPerformed(self, event):
        if self._current:
            for topic in choose_topic(self._parent, self._topictype) or []:
                assoc = self._assocb.makeAssociation(self._current, topic)
            self._list.refresh()

            for fun in self._functions:
                fun()

class PhotoMetadataEditor:

    def __init__(self, images):
        global top
        top = JFrame("TMPhoto")
        top.getContentPane().setLayout(BorderLayout())

        panel = ImagePanel()
        panel.setPreferredSize(Dimension(800, 600))
        top.getContentPane().add(panel, BorderLayout.WEST)

        container = JPanel()
        container.setLayout(GridBagLayout())

        self._title = add_text_field(container, "Title")
        self._description = add_text_area(container, "Description")

        # location
        gbc = get_gbc()
        container.add(JLabel("Location"), gbc)
        self._location = TopicComboBox(location)
        container.add(self._location, gbc)
        add_location = JButton("Add")
        add_location.addActionListener(CreateTopicListener(top, self._location))
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(add_location, gbc)

        # people
        gbc = get_gbc()
        gbc.fill = GridBagConstraints.VERTICAL
        container.add(JLabel("People"), gbc)
        self._person = TopicList("ph:depicted-in(%topic% : ph:depiction, $TOPIC : ph:depicted)")
        self._person.setVisibleRowCount(10)
        scroll = JScrollPane(self._person)
        scroll.setMinimumSize(Dimension(200, 50))
        container.add(scroll, gbc)
        gbc = get_gbc()
        add = JButton("+")
        remove = JButton("-")
        remove.addActionListener(TopicRemoveListener(self._person,
                                                     depicted_in,
                                                     depiction,
                                                     depicted))
        self._personlistener = CreateAssociationListener(top, person,
                                                         depicted_in, depiction, depicted,
                                                         self._person,
                                                         [top.pack])
        add.addActionListener(self._personlistener)
        gbc.gridwidth = GridBagConstraints.REMAINDER

        b1panel = JPanel()
        b1panel.setLayout(BorderLayout())
        b1panel.add(add, BorderLayout.WEST)
        b1panel.add(remove, BorderLayout.EAST)
        
        bpanel = JPanel()
        bpanel.setLayout(BorderLayout())
        bpanel.add(b1panel, BorderLayout.NORTH)

        create = JButton("Create")
        create.addActionListener(CreateTopicListener(top, None, person))
        bpanel.add(create, BorderLayout.SOUTH)
        
        container.add(bpanel, gbc)

        # categories
        gbc = get_gbc()
        gbc.fill = GridBagConstraints.VERTICAL
        container.add(JLabel("Categories"), gbc)
        self._categories = TopicList("ph:in-category(%topic% : ph:categorized, $TOPIC : ph:categorization)")
        self._categories.setVisibleRowCount(10)
        scroll = JScrollPane(self._categories)
        scroll.setMinimumSize(Dimension(200, 50))
        container.add(scroll, gbc)
        gbc = get_gbc()
        add = JButton("+")
        remove = JButton("-")
        remove.addActionListener(TopicRemoveListener(self._categories,
                                                     categorized,
                                                     classified,
                                                     classification))
        self._catlistener = \
          CreateAssociationListener(top, category, categorized,
                                    classified, classification,
                                    self._categories, [top.pack])
        add.addActionListener(self._catlistener)
        gbc.gridwidth = GridBagConstraints.REMAINDER

        b1panel = JPanel()
        b1panel.setLayout(BorderLayout())
        b1panel.add(add, BorderLayout.WEST)
        b1panel.add(remove, BorderLayout.EAST)
        
        bpanel = JPanel()
        bpanel.setLayout(BorderLayout())
        bpanel.add(b1panel, BorderLayout.NORTH)

        create = JButton("Create")
        create.addActionListener(CreateTopicListener(top, None, category))
        bpanel.add(create, BorderLayout.SOUTH)
        
        container.add(bpanel, gbc)

        # event
        gbc = get_gbc()
        container.add(JLabel("Event"), gbc)
        self._event = TopicComboBox(event)
        container.add(self._event, gbc)
        add = JButton("Add")
        add.addActionListener(CreateTopicListener(top, self._event))
        gbc.gridwidth = GridBagConstraints.REMAINDER
        container.add(add, gbc)

        # hide etc
        self._hide = add_checkbox(container, "Hide")
        self._time = add_text_field(container, "Time")
        self._filename = add_label(container, "File")
        
        top.getContentPane().add(container, BorderLayout.EAST)

        if MAC:
            mask = ActionEvent.META_MASK
        else:
            mask = ActionEvent.CTRL_MASK
        
        ctl_d = KeyStroke.getKeyStroke(KeyEvent.VK_D, mask)
        ctl_n = KeyStroke.getKeyStroke(KeyEvent.VK_N, mask)
        ctl_p = KeyStroke.getKeyStroke(KeyEvent.VK_P, mask)
        ctl_s = KeyStroke.getKeyStroke(KeyEvent.VK_S, mask)
        ctl_q = KeyStroke.getKeyStroke(KeyEvent.VK_Q, mask)
        ctl_g = KeyStroke.getKeyStroke(KeyEvent.VK_G, mask)
        ctl_l = KeyStroke.getKeyStroke(KeyEvent.VK_L, mask)
        ctl_r = KeyStroke.getKeyStroke(KeyEvent.VK_R, mask)
        ctl_k = KeyStroke.getKeyStroke(KeyEvent.VK_K, mask)
        ctl_e = KeyStroke.getKeyStroke(KeyEvent.VK_E, mask)
        ctl_o = KeyStroke.getKeyStroke(KeyEvent.VK_O, mask)
        
        menubar = make_menu_bar([("File",
                                  [("Next", self.next, ctl_n),
                                   ("Next unedited", self.next_unedited, None),
                                   ("Previous", self.previous, ctl_p),
                                   ("Select photo", self._photo_list, None),
                                   ("Scan directory", self._scan_directory, None),
                                   ("Prune", self._prune, None),
                                   ("Save", self._save, ctl_s),
                                   ("Quit", self._exit, ctl_q)]),
                                 ("Edit",
                                  [("Edit gallery metadata", MetadataEditor, None),
                                   ("Edit places", self._edit_places, None),
                                   ("Edit events", EventEditor, None),
                                   ("Edit people", PersonEditor, None),
                                   ("Edit categories", CategoryEditor, None),
                                   ("Photo organizer", PhotoOrganizer, None),
                                   ("Copy from previous", self._copy_from_previous, ctl_k),
                                   ("Delete photo", self._delete, ctl_d),
                                   ("Open in GraphicConverter", self._open_in_gimp, ctl_g),
                                   ("Open in Preview", self._open_in_preview, ctl_e),
                                   ("Open", self._open_in_default, ctl_o),
                                   ("Rotate right", self._rotate_right, ctl_r),
                                   ("Rotate left", self._rotate_left, ctl_l),
                                   ("Go to image with ID", self._goto_by_id, None)])])

        top.setJMenuBar(menubar)
        
        top.pack()
        top.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE)
        top.setVisible(1)
        top.addWindowListener(CloseListener())

        self._top = top
        self._panel = panel
        self._synchronizers = []
        self._images = images
        self._current = -1

    def next(self):
        self._set_image(self._current + 1)

    def next_unedited(self):
        ix = 1
        while self._current + ix < len(self._images):
            image = self.get_image(self._current + ix)
            name = pick(image.getTopicNames())
            if name and name.getValue()[-4 : ] in FORMATS:
                self._set_image(self._current + ix)
                break
            ix += 1

    def previous(self):
        if self._current > 0:
            self._set_image(self._current - 1)

    def set_image(self, photo):
        for ix in range(len(self._images)):
            if self._images[ix] == photo:
                self._set_image(ix)

    def get_image(self, ix):
        return self._images[ix]

    def get_current_image(self):
        return self.get_image(self._current)

    def get_previous_image(self):
        if self._current > 0:
            return self.get_image(self._current - 1)
        else:
            return None
    
    def set_images(self, images):
        self._images = images
        self._set_image(0)

    def refresh(self, store = 1, force_reload = 0):
        self._set_image(self._current, store, force_reload)

    def _delete(self):
        if yesnobox(self._top, "Are you sure you want to delete this photo?"):
            os.unlink(get_first(self._images[self._current].getSubjectLocators()).getAddress()[6 : ])
            self._images[self._current].remove()
            del self._images[self._current]
            if self._current == 0:
                self._set_image(self._current + 1, 0)
            else:
                self._set_image(self._current - 1, 0)
                
    def _set_image(self, ix, store = 1, force_reload = 1):
        if ix >= len(self._images):
            return

        if store:
            self._store()

        topic = self._images[ix]
        if (self._current != ix or  # don't reload image file if it's the same
            force_reload):
            self._current = ix
            try:
                self._panel.render_image(topic)
            except IIOException, e:
                errorbox(self._top, str(e))

        self._synchronizers = [
            bind_name(self._title, topic),
            bind_occurrence(self._description, topic, desc),
            bind_occurrence(self._time, topic, time_taken),
            bind_association(self._location, topic, taken_at, image, location, 1),
            bind_association(self._event, topic, taken_during, image, event, 1),
            bind_unary(self._hide, topic, hide, hidden)]

        self._person.setSelectedItem(topic)
        self._personlistener.setCurrentTopic(topic)
        self._categories.setSelectedItem(topic)
        self._catlistener.setCurrentTopic(topic)
        self._filename.setText(get_first(topic.getSubjectLocators()).getAddress()[6 : ])

    def _photo_list(self):
        self._store()
        photo_list(self)

    def _store(self):
        for synchronizer in self._synchronizers:
            synchronizer.synchronize()
        
    def _save(self):
        self._store()
        if exists(outfile + ".bak"):
            os.unlink(outfile + ".bak")
        if exists(outfile):
            os.rename(outfile, outfile + ".bak")
        writer = ImportExportUtils.getWriter(outfile)
        writer.setVersion(1)
        writer.write(tm)

    def _open_in_gimp(self):
        self._open_in_app("GraphicConverter")

    def _open_in_preview(self):
        self._open_in_app("Preview")

    def _open_in_default(self):
        self._open_in_app()

    def _open_in_app(self, app = None):
        topic = self._images[self._current]
        filename = get_first(topic.getSubjectLocators()).getAddress()[6 : ]
        if app:
            os.system('open -a %s "%s"' % (app, filename))
        else:
            os.system('open "%s"' % (filename))
        self.refresh(1, 1)
        
    def _rotate_left(self):
        self._rotate(270)

    def _rotate_right(self):
        self._rotate(90)

    def _rotate(self, degrees):
        topic = self._images[self._current]
        filename = get_first(topic.getSubjectLocators()).getAddress()[6 : ]
        tmp = "/tmp/rotated.jpg"
        os.system('convert -rotate %s "%s" "%s"' % (degrees, filename, tmp))
        os.system('mv "%s" "%s"' % (tmp, filename))
        self.refresh(1, 1)
        
    def _scan_directory(self):
        the_event = None
        if has_instances(event):
            the_event = choose_topic(self._top, event)
            if the_event:
                the_event = the_event[0]
        
        dir = choose_directory(self._top)
        if dir:
            tm = scan(dir, the_event)
            set_globals(tm)
            
            self.set_images(get_image_topics(tm))
            self._event.refresh() # scan() may create a new event

    def _prune(self):
        remove = []
        for image in self._images:
            fname = get_first(image.getSubjectLocators()).getAddress()[6 : ]
            if not exists(fname):
                remove.append(image)

        for image in remove:
            self._images.remove(image)
            image.remove()

    def _exit(self):
        confirm_and_exit()

    def _copy_from_previous(self):
        # 1: get topic for this photo
        current = self.get_current_image()
        
        # 2: get topic for previous photo
        previous = self.get_previous_image()
        
        # 3: copy name
        pname = pick(previous.getTopicNames())
        if pname:
            cname = pick(current.getTopicNames())
            if not cname:
                builder.makeTopicName(current, pname.getValue())
            else:
                cname.setValue(pname.getValue())
        
        # 4: copy description
        pdesc = get_by_type(previous.getOccurrences(), desc)
        if pdesc:
            cdesc = get_by_type(current.getOccurrences(), desc)
            if cdesc:
                cdesc.setValue(pdesc.getValue())
            else:
                builder.makeOccurrence(current, desc, pdesc.getValue())
                
        # 5: copy associations
        for prole1 in previous.getRoles():
            passoc = prole1.getAssociation()
            cassoc = builder.makeAssociation(passoc.getType())
            for prole in passoc.getRoles():
                if prole == prole1:
                    continue
                builder.makeAssociationRole(cassoc,
                                            prole.getType(),
                                            prole.getPlayer())

            builder.makeAssociationRole(cassoc, prole1.getType(), current)
        
        # 6: resync right-hand side fields
        DuplicateSuppressionUtils.removeDuplicates(current)
        self.refresh(0, 0)
        self._top.pack()

    def _edit_places(self):
        PlaceEditor()
        self._location.refresh() # might create a new place

    def _goto_by_id(self):
        id = get_text_box(self._top, "Photo ID")
        topic = get_topic_by_id(tm, id)
        if not topic:
            errorbox(self._top, "No topic with that ID")
            return
        self.set_image(topic)

def pick(list): # Java List, really
    if not list.isEmpty():
        return list.iterator().next()

def get_by_type(list, type):
    for obj in list:
        if obj.getType() == desc:
            return obj

class CloseListener(WindowListener):

    def windowActivated(self, e):
        pass

    def windowOpened(self, e):
        pass
    
    def windowClosing(self, e):
        confirm_and_exit()

    def windowDeactivated(self, e):
        pass
        
def confirm_and_exit():
    if yesnobox(top, "Are you sure you want to quit?"):
        sys.exit(1)

# --- Helpers

def exists(filename):
    return File(filename).exists()

def get_metadata(filename):
    f = File(filename)
    metadata = {}

    if filename.lower().endswith(".jpg"):
        m = JpegMetadataReader.readMetadata(f)
        for d in m.getDirectoryIterator():
            for t in d.getTagIterator():
                try:
                    metadata[t.getTagName()] = t.getDescription()
                except MetadataException:
                    pass # probably OK

    datetime = metadata.get("Date/Time Original") or metadata.get("Date/Time")
    if not datetime:
        metadata["Date/Time"] = get_last_modified(filename)
    else:
        # usual format is YYYY:MM:DD HH:MM:SS
        if datetime[4] == ":" and datetime[7] == ":":
            datetime = datetime[ : 4] + "-" + datetime[5 : 7] + "-" + datetime[8 : ]
            metadata["Date/Time"] = datetime
            print datetime

    return metadata

def get_last_modified(filename):
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(os.stat(filename)[8]))

def get_resolution(filename):
    from java.io import File
    from javax.imageio import ImageIO
    from javax.imageio.stream import FileImageInputStream

    reader = ImageIO.getImageReadersByMIMEType("image/jpeg").next()
    stream = FileImageInputStream(File(filename))
    reader.setInput(stream)
    image = reader.read(0)
    value = "%sx%s" % (image.getWidth(), image.getHeight())
    reader.dispose()
    stream.close()
    return value

def get_image_topics(tm):
    processor = QueryUtils.getQueryProcessor(tm)
    
    topics = []
    result = processor.execute(PREFIXES +
                               """instance-of($PHOTO, op:Image),
                                  { ph:time-taken($PHOTO, $TIME) },
                                  subject-locator($PHOTO, $LOC)
                                  order by $TIME, $LOC?""")
    while result.next():
        topics.append(result.getValue("PHOTO"))

    return topics

def set_globals(tm):
    def get(uri):
        topic = tm.getTopicBySubjectIdentifier(URILocator(uri))
        if not topic:
            print "No topic for", uri
            sys.exit(1)
        return topic
    
    DuplicateSuppressionUtils.removeDuplicates(tm)
    strify = TopicStringifiers.getDefaultStringifier().toString
    builder = tm.getTransaction().getBuilder()
    processor = QueryUtils.getQueryProcessor(tm)

    image = get(OP_BASE + "Image")
    photo = get(OP_BASE + "Photo")
    video = get(OP_BASE + "Video")
    taken_at = get(BASE + "taken-at")
    time_taken = get(BASE + "time-taken")
    desc = get(DC_BASE + "description")
    location = get(OP_BASE + "Place")
    person = get(OP_BASE + "Person")
    event = get(OP_BASE + "Event")
    depicted_in = get(BASE + "depicted-in")
    depicted = get(BASE + "depicted")
    depiction = get(BASE + "depiction")
    taken_during = get(BASE + "taken-during")
    contained_in = get(OP_BASE + "located_in")
    containee = get(OP_BASE + "Containee")
    container = get(OP_BASE + "Container")
    hide = get(BASE + "hide")
    hidden = get(BASE + "hidden")
    start_date = get(BASE + "start-date")
    end_date = get(BASE + "end-date")

    creator = get(DC_BASE + "creator")
    resource = get(MD_BASE + "resource")
    value = get(MD_BASE + "value")

    partner_of = get(BASE + "partnership")
    partner = get(BASE + "partner")

    mother_of = get(BASE + "motherhood")
    father_of = get(BASE + "fatherhood")
    parent = get(BASE + "parent")
    child = get(BASE + "child")

    category = get(OP_BASE + "Category")
    categorized = get(BASE + "in-category") #AT
    classified = get(BASE + "categorized")  #RT
    classification = get(BASE + "categorization") #RT
    is_processed = get(BASE + "is-processed")
    processed = get(BASE + "processed")

    broader_narrower = get(TECH_BASE + "broader-narrower")
    narrower = get(TECH_BASE + "narrower")
    broader = get(TECH_BASE + "broader")

    latitude = get(BASE + "latitude")
    longitude = get(BASE + "longitude")
    username = get(USERMAN + "username")
    password = get(USERMAN + "password")

    for (var, val) in locals().items():
        globals()[var] = val

# --- Scan pictures to create TM

def walk(directory):
    files = []
    for item in os.listdir(directory):
        if os.path.isdir(directory + "/" + item):
            files += walk(directory + "/" + item)
        else:
            files.append(directory + "/" + item)
    return files

FORMATS = (".jpg", ".gif", ".JPG", ".GIF", ".avi", ".AVI")
def scan(directory, the_event):
    files = filter(lambda x: x[-4 : ] in FORMATS,
                   walk(directory))
    
    for file in files:
        locator = URILocator("file:/" + file)
        if tm.getTopicBySubjectLocator(locator):
            continue # we already have this picture

        print file

        topic = builder.makeTopic()
        add_topic_id(topic)
        topic.addSubjectLocator(locator)
        if file.lower().endswith(".avi"):
            topic.addType(video)
        else:
            topic.addType(photo)

        metadata = get_metadata(file)
        #print metadata["Make"] + ", " + metadata["Model"]
        #print metadata["Date/Time"]
        builder.makeTopicName(topic, os.path.split(file)[1])
        builder.makeOccurrence(topic, time_taken, metadata["Date/Time"])
        # FIXME: add duration!

        if the_event:
            assoc = builder.makeAssociation(taken_during)
            builder.makeAssociationRole(assoc, image, topic)
            builder.makeAssociationRole(assoc, event, the_event)

        # create SHA1 occurrence?
        # create size (in kB) occurrence?
        # represent MIME type

    return tm

# --- Main program

from net.ontopia.topicmaps.query.utils import QueryUtils

if len(sys.argv) > 1:
    infile = sys.argv[1]
    outfile = infile
else:
    infile = PATH + os.sep + "ontology.ctm"
    outfile = "metadata.xtm"

# --- Set globals

set_globals(ImportExportUtils.getReader(infile).read())

# --- Set up UI

def edit_photos():
    global editor
    editor = PhotoMetadataEditor(get_image_topics(tm))
    editor.next()

edit_photos()
