
package no.priv.garshol.topicmaps.tmphoto;

import java.util.Iterator;
import java.net.MalformedURLException;
import javax.servlet.http.*;
import net.ontopia.utils.OntopiaRuntimeException;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.infoset.impl.basic.URILocator;
import net.ontopia.topicmaps.core.*;
import net.ontopia.topicmaps.utils.PSI;
import net.ontopia.topicmaps.nav2.core.NavigatorApplicationIF;
import net.ontopia.topicmaps.nav2.core.NavigatorRuntimeException;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

import org.apache.log4j.Logger;

/**
 * Servlet to be run automatically at startup. Initializes the
 * vote-score occurrence.
 */
public class LoadAveragesServlet extends HttpServlet {
  static Logger log = Logger.getLogger(LoadAveragesServlet.class.getName());
  private static boolean hasrun = false;
  
  public void init() {
    try {
      run();
    } catch (Throwable e) {
      log.error(e);
    }
  }

  private void run() {
    if (hasrun)
      return;

    // initialize JDBC utilities
    JDBCUtils.init(getServletContext().getInitParameter("jdbcurl"),
                   getServletContext().getInitParameter("jdbcuser"),
                   getServletContext().getInitParameter("jdbcpasswd"));
    
    log.info("running");
    hasrun = true;
    String id = "metadata.xtm";
    NavigatorApplicationIF navApp =
      NavigatorUtils.getNavigatorApplication(getServletContext());
    TopicMapIF tm;
    try {
      tm = navApp.getTopicMapById(id);
    } catch (NavigatorRuntimeException e) {
      log.error("error loading TM", e);
      throw new OntopiaRuntimeException(e);
    }
    log.info("TM loaded");
        
    LocatorIF base = tm.getStore().getBaseAddress();
    TopicMapBuilderIF builder = tm.getBuilder();

    LocatorIF psi = base.resolveAbsolute("http://psi.garshol.priv.no/tmphoto/vote-score");
    TopicIF score = tm.getTopicBySubjectIdentifier(psi);
    if (score == null) {
      score = builder.makeTopic();
      score.addSubjectIdentifier(psi);
    }

    log.info("set up TM");
    Iterator it;
    try {
      it = ScoreManager.getBestPhotos().iterator();
    } catch (java.sql.SQLException e) {
      log.error("Can't get photos", e);
      throw new OntopiaRuntimeException(e);
    }
    int count = 0;
    int total = 0;
    LocatorIF datatype = PSI.getXSDDecimal();
    while (it.hasNext()) {
      total++;
      ScoreManager.PhotoInList data = (ScoreManager.PhotoInList) it.next();
      LocatorIF itemid = base.resolveAbsolute('#' + data.getPhotoId());
      TopicIF photo = (TopicIF) tm.getObjectByItemIdentifier(itemid);
      if (photo == null)
        continue;

      count++;
      double average = ((data.getVotes() * data.getScore()) + 2.5) / 
                       (data.getVotes() + 1);
      builder.makeOccurrence(photo, score, "" + average, datatype);
    }
    log.info("looked at " + total + " photos, added " + count + " averages");
  }
}
