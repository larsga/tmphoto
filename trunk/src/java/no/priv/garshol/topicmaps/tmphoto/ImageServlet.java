
package no.priv.garshol.topicmaps.tmphoto;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import java.awt.image.RenderedImage;
import javax.media.jai.JAI;
import javax.media.jai.Interpolation;

import net.ontopia.utils.StreamUtils;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.topicmaps.core.*;
import net.ontopia.topicmaps.entry.TopicMapReferenceIF;
import net.ontopia.topicmaps.entry.TopicMapRepositoryIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

/**
 * Receives a request of the form tmphoto/image?id;size and returns
 * the corresponding scaled image. 
 */
public class ImageServlet extends HttpServlet {

  final static private String CACHEDIR = getCacheDir(); 
  
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

    File scaledfile = new File(CACHEDIR + size + File.separator + id);
    if (!scaledfile.exists())
      scaleImage(new File(origfile), scaledfile, getMaxSide(size));
    
    return scaledfile;
  }

  private static void scaleImage(File source, File destination, int maxside) {
    RenderedImage src = JAI.create("fileload", source.getPath());
    RenderedImage scaled = src;

    int biggest = Math.max(src.getHeight(), src.getWidth());
    float scale = maxside / (float) biggest;
    if (scale < 1.0)
      scaled = JAI.create("scale", src, scale, scale, 0, 0,
                        Interpolation.getInstance(Interpolation.INTERP_BILINEAR));

    JAI.create("filestore", scaled, destination.getPath(), "JPEG", null);
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
}