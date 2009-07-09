
package no.priv.garshol.topicmaps.tmphoto;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import net.ontopia.utils.StreamUtils;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.*;
import net.ontopia.topicmaps.entry.TopicMapReferenceIF;
import net.ontopia.topicmaps.entry.TopicMapRepositoryIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

// full    : full
// default : 800x800
// thumb   : 250x250

/**
 * Receives a request of the form tmphoto/image?id;size and returns
 * the corresponding scaled image. 
 */
public class ImageServlet extends HttpServlet {

  final static private String CACHEDIR = null; // FIXME
  
  protected void doGet(HttpServletRequest req,
                       HttpServletResponse resp)
    throws ServletException, IOException {

    // initialize
    String id = getImageId(req);
    String size = getImageSize(req);
    String origfile = getImageFileName(id);
    if (origfile == null) {
      resp.sendError(404, "No such image");
      return;
    }

    // get reference to scaled image (and scale, if necessary)
    File scaledfile = getScaledFile(id, origfile, size);

    // pump it out!
    resp.setHeader("Content-type", "image/jpeg");
    resp.setIntHeader("Content-length", (int) scaledfile.length());
    OutputStream out = resp.getOutputStream();
    FileInputStream in = new FileInputStream(scaledfile);
    StreamUtils.transfer(in, out);
    in.close();
    out.flush();
  }
  
  // --- Internal helpers

  private static File getScaledFile(String id, String origfile, String size) {
    if (size.equals("full"))
      return new File(origfile);

    File scaledfile = new File(CACHEDIR + File.separator + id);
    if (!scaledfile.exists()) {
      // FIXME: scale file and store cached copy in scaledfile
    }
    return scaledfile;
  }
  
  private String getImageFileName(String id) throws IOException {
    // get topic map
    TopicMapRepositoryIF repo =
      NavigatorUtils.getTopicMapRepository(getServletContext());
    TopicMapReferenceIF ref = repo.getReferenceByKey("metadata.xtm");
    TopicMapStoreIF store = ref.createStore(true);
    TopicMapIF tm = store.getTopicMap();

    // get image topic
    LocatorIF base = store.getBaseAddress();
    LocatorIF iid = base.resolveAbsolute("#" + id);
    TopicIF topic = (TopicIF) tm.getObjectByItemIdentifier(iid);
    if (topic == null)
      return null;

    // locate image
    LocatorIF subjloc = (LocatorIF) topic.getSubjectLocators().iterator().next();
    return subjloc.getAddress().substring(6);
  }

  private static String getImageId(HttpServletRequest req) {
    String query = req.getQueryString();
    int pos = query.indexOf(';');
    if (pos == -1)
      return query;
    else
      return query.substring(0, pos);
  }

  private static String getImageSize(HttpServletRequest req) {
    String query = req.getQueryString();
    int pos = query.indexOf(';');
    if (pos == -1)
      return "default";
    else
      return query.substring(pos + 1);
  }
  
}