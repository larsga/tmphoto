
package no.priv.garshol.topicmaps.tmphoto;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import net.ontopia.utils.StreamUtils;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.*;
import net.ontopia.topicmaps.entry.TopicMapReferenceIF;
import net.ontopia.topicmaps.entry.TopicMapRepositoryIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

import no.priv.garshol.topicmaps.tmphoto.images.*;

/**
 * Receives a request of the form tmphoto/image?id;size and returns
 * the corresponding scaled image. 
 */
public class ImageServlet extends HttpServlet {
  final static private int MAX_WORKERS = 2;
  final static private String CACHEDIR = getCacheDir();
  static private int active_workers = 0;
  private ImageProcessor improc;

  public void init(ServletConfig config) throws ServletException {
    super.init(config);
    String klass = config.getServletContext().getInitParameter("image-processor");
    if (klass == null)
      klass = "no.priv.garshol.topicmaps.tmphoto.images.JAIProcessor";
    improc = (ImageProcessor) instantiate(klass);
  }
  
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
    try {
      StreamUtils.transfer(in, out);
    } finally {
      in.close();
    }
    out.flush();
  }
  
  // --- Internal helpers

  private File getScaledFile(String id, String origfile, String size)
    throws IOException {
    if (size.equals("full"))
      return new File(origfile);

    File scaledfile = new File(CACHEDIR + size + File.separator + id + ".jpg");
    if (!scaledfile.exists())
      scaleImage(new File(origfile), scaledfile, getMaxSide(size));
    
    return scaledfile;
  }

  private void scaleImage(File source, File destination, int maxside)
    throws IOException {
    while (!canRun()) {
      try {
        Thread.sleep(25);
      } catch (InterruptedException e) {
      }
    }

    try {
      increment();
      improc.scaleImage(source, destination, maxside);
    } finally {
      decrement();
    }
  }

  private static synchronized boolean canRun() {
    return active_workers < MAX_WORKERS;
  }

  private static synchronized void increment() {
    active_workers++;
  }

  private static synchronized void decrement() {
    active_workers--;
  }

  private static int getMaxSide(String size) {
    if (size.equals("default"))
      return 800;
    else if (size.equals("thumb"))
      return 250;
    else
      throw new RuntimeException("Unknown size: '" + size + "'");
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

  private static String getCacheDir() {
    String tmp = System.getProperty("java.io.tmpdir");
    if (!tmp.endsWith(File.separator))
      tmp += File.separator;

    // create subdirs
    File cache = new File(tmp + File.separator + "default");
    if (!cache.exists())
      cache.mkdir();
    cache = new File(tmp + File.separator + "thumb");
    if (!cache.exists())
      cache.mkdir();
    
    return tmp;
  }

  private static Object instantiate(String classname) {
    try {
      Class theclass = Class.forName(classname);
      return theclass.newInstance();
    } catch (Exception e) { // too many damn detail exceptions
      e.printStackTrace(); // for the log
      return null;
    }
  }
}