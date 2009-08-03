
package no.priv.garshol.topicmaps.tmphoto;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Map;
import java.util.Date;
import java.util.HashMap;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import net.ontopia.utils.StreamUtils;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.*;
import net.ontopia.topicmaps.query.core.QueryResultIF;
import net.ontopia.topicmaps.query.core.QueryProcessorIF;
import net.ontopia.topicmaps.query.core.InvalidQueryException;
import net.ontopia.topicmaps.query.utils.QueryUtils;
import net.ontopia.topicmaps.entry.TopicMapReferenceIF;
import net.ontopia.topicmaps.entry.TopicMapRepositoryIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

import no.priv.garshol.topicmaps.tmphoto.images.*;

/**
 * Receives a request of the form tmphoto/image?id;size and returns
 * the corresponding scaled image. 
 */
public class ImageServlet extends HttpServlet {
  static private int active_workers = 0;
  // last-mod/if-mod headers: Fri, 11 Jul 2008 16:20:56 GMT
  static private SimpleDateFormat f =
    new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz");
  private ImageProcessor improc;
  private String cachedir;
  private int maxworkers;

  public void init(ServletConfig config) throws ServletException {
    super.init(config);

    // set up image processor
    String klass = getParameter(config, "image-processor",
      "no.priv.garshol.topicmaps.tmphoto.images.AWTProcessor");
    improc = (ImageProcessor) instantiate(klass);

    // set up cache directory
    String tmp = getParameter(config, "image-cache-dir",
                              System.getProperty("java.io.tmpdir"));
    cachedir = setupCacheDir(tmp);

    // get max workers
    String max = getParameter(config, "max-image-workers", "2");
    maxworkers = 2; // in case next line throws exception
    maxworkers = Integer.parseInt(max);
  }
  
  protected void doGet(HttpServletRequest req,
                       HttpServletResponse resp)
    throws ServletException, IOException {

    // initialize
    String id = getImageId(req);
    String size = getImageSize(req);
    TopicIF imagetopic = getImageTopic(id);
    if (imagetopic == null) {
      resp.sendError(404, "No such image");
      return;
    }
    File origfile = getImageFile(imagetopic);

    // does the client have the latest?
    String ifmod = req.getHeader("If-Modified-Since");
    if (ifmod != null) {
      long time = parseTime(ifmod);
      if (time >= origfile.lastModified()) {
        resp.sendError(304, "Not changed");
        return;
      }
    }

    // is the user logged in?
    HttpSession session = req.getSession();
    String username = null;
    if (req != null)
      username = (String) session.getAttribute("username");
    if (username == null) {
      // only users which have logged in can get full-size images
      if (size.equals("full") || isImageHidden(imagetopic)) {
        resp.sendError(403, "Forbidden");
        return;
      }
    }
    
    // get reference to scaled image (and scale, if necessary)
    File scaledfile = getScaledFile(id, origfile, size);
    
    // pump it out!
    resp.setHeader("Content-type", "image/jpeg");
    resp.setIntHeader("Content-length", (int) scaledfile.length());
    resp.setHeader("Last-Modified", formatDate(origfile));
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

  private File getScaledFile(String id, File origfile, String size)
    throws IOException {
    if (size.equals("full"))
      return origfile;

    File scaledfile = new File(cachedir + size + File.separator + id + ".jpg");
    if (!scaledfile.exists() || newer(origfile, scaledfile))
      scaleImage(origfile, scaledfile, getMaxSide(size));
    
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

  private boolean newer(File f1, File f2) {
    return f1.lastModified() > f2.lastModified();
  }

  private synchronized boolean canRun() {
    return active_workers < maxworkers;
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
  
  private File getImageFile(TopicIF topic) throws IOException {
    LocatorIF subjloc = (LocatorIF) topic.getSubjectLocators().iterator().next();
    return new File(subjloc.getAddress().substring(6));
  }

  private TopicIF getImageTopic(String id) throws IOException {
    // get topic map
    TopicMapRepositoryIF repo =
      NavigatorUtils.getTopicMapRepository(getServletContext());
    TopicMapReferenceIF ref = repo.getReferenceByKey("metadata.xtm");
    TopicMapStoreIF store = ref.createStore(true);
    TopicMapIF tm = store.getTopicMap();

    // get image topic
    LocatorIF base = store.getBaseAddress();
    LocatorIF iid = base.resolveAbsolute("#" + id);
    return (TopicIF) tm.getObjectByItemIdentifier(iid);
  }

  private static boolean isImageHidden(TopicIF topic) {
    Map params = new HashMap();
    params.put("photo", topic);

    // FIXME: this could be pre-parsed
    QueryProcessorIF qp = QueryUtils.getQueryProcessor(topic.getTopicMap());
    try {
      QueryResultIF result = qp.execute(
        "using ph for i\"http://psi.garshol.priv.no/tmphoto/\" " +
        "using op for i\"http://psi.ontopedia.net/\" " +
        "{ ph:depicted-in(%photo% : ph:depiction, $PERSON : ph:depicted), " +
        "ph:hide($PERSON : ph:hidden) " +
        "| ph:hide(%photo% : ph:hidden) " +
        "| ph:taken-at(%photo% : op:Image, $PLACE : op:Place), " +
        "  ph:hide($PLACE : ph:hidden) " +
        "| ph:taken-during(%photo% : op:Image, $EVENT : op:Event), " +
        "  ph:hide($EVENT : ph:hidden) }?", params);
      return (result.next());
    } catch (InvalidQueryException e) {
      throw new RuntimeException(e);
    }
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

  private static String setupCacheDir(String tmp) {
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

  private static String getParameter(ServletConfig config,
                                     String name,
                                     String default_) {
     String param = config.getServletContext().getInitParameter(name);
    if (param == null)
      param = default_;
    return param;
  }

  private static String formatDate(File file) {
    return f.format(new Date(file.lastModified()));
 }

  private static long parseTime(String time) {
    try {
      return f.parse(time).getTime();
    } catch (ParseException e) {
      System.out.println("Badly formatted date: " + time);
      return 0; // we just ignore this
    }
  }
}