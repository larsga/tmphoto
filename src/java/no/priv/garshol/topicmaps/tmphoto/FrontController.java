
package no.priv.garshol.topicmaps.tmphoto;

import java.io.IOException;
import java.io.PrintStream;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import net.ontopia.topicmaps.nav2.core.NavigatorApplicationIF;
import net.ontopia.topicmaps.nav2.core.NavigatorConfigurationIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

public class FrontController extends HttpServlet {

  protected void doGet(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
    processRequest(request, response);
  }

  private final void processRequest(HttpServletRequest aRequest,
                                    HttpServletResponse aResponse)
    throws IOException, ServletException  {
//     aResponse.setContentType("text/html; charset=" + NavigatorUtils.getNavigatorApplication(aRequest.getSession().getServletContext()).getConfiguration().getProperty("defaultCharacterEncoding"));
    String forward = aRequest.getRequestURI();
    String contextPath = aRequest.getContextPath();
    String org = null;
    
    if(forward.length() > contextPath.length()) {
      forward = forward.substring(contextPath.length() + 1);
      org = forward;
      
      if (forward.equals("get-illustration"))
        forward = "illustration.jsp";
      else
        throw new ServletException("Cannot forward URI '" + forward + '\'');
    } else 
      throw new ServletException("Cannot forward URI '" + forward + '\'');

    forward = "WEB-INF/pages/" + forward;
    aRequest.getRequestDispatcher(forward).forward(aRequest, aResponse);
  }
}
