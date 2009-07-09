
package no.priv.garshol.topicmaps.tmphoto;

import java.util.Date;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import javax.servlet.http.HttpServletRequest;

public class Logger {
  final private static boolean ON = false;

  public static synchronized void log(String user, HttpServletRequest request) {
    if (!ON)
      return;
    
    try {
      String ua = request.getHeader("User-Agent").replace('|', '_');
      String q = request.getQueryString();
      if (q == null)
        q = "";
      String uri = request.getRequestURI() + "?" + q.replace("|", "%7C");
      String refer = request.getHeader("Referer");
      if (refer != null)
        refer = refer.replace("|", "%7C");
      
      SimpleDateFormat format =
        new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      String now = format.format(new Date());
      
      FileWriter out = new FileWriter("/opt/tomcat5/logs/tmphoto.log", true);
      out.write(user + "|" +
                request.getRemoteAddr() + "|" +
                ua + "|" +
                uri + "|" +
                now + "|" +
                refer + "\n");
      out.close();
    } catch (IOException e) {
      // whoops
    }
  } 
}