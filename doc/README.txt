
  tmphoto
===========

Version:  0.1a1
Homepage: http://code.google.com/p/tmphoto/


This is a web gallery application based on the Ontopia Topic Maps
toolkit. 


  INSTALLATION (1)
====================

We will refer to the directory created when you unzipped tmphoto as
${tmphoto}.

---ONTOPIA

Download Ontopia from
  http://code.google.com/p/ontopia/downloads/list

and unzip the distribution. This creates a directory we will call
${ontopia}.

Put ${ontopia}/lib/ontopia.jar on the classpath. Then put
${tmphoto}/lib/metadata-extractor-2.3.1.jar on the classpath.

---JYTHON

Download Jython from
  http://www.jython.org/

and install it. Version 2.5.x is preferred, but 2.2.x also works.


  TAGGING PHOTOS
==================

You are now ready to start tagging photos. Run the following command:
  jython ${tmphoto}/tagger/tagger.py

This will start the tagging application. Choose File | Scan directory
from the menu, and pick a directory containing photos. These will now
be loaded into the application, and you can start describing them.

Once you are done, choose File | Save, and a file named metadata.xtm
will be created in the current directory. This file contains the
information about your photos.

To continue working with your photos, run 
  jython ${tmphoto}/tagger/tagger.py /path/to/metadata.xtm


  INSTALLATION (2)
====================
  
To actually look at the photos you need to set up the web application.

Copy metadata.xtm to 
  ${ontopia}/apache-tomcat/webapps/omnigator/WEB-INF/topicmaps

Copy ${tmphoto}/tmphoto.war to ${ontopia}/apache-tomcat/webapps. 

Then go to ${ontopia}/apache-tomcat and run
  bin/startup.sh (or bin/startup.bat)

Point your browser at
  http://localhost:8080/tmphoto/