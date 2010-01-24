
package no.priv.garshol.topicmaps.tmphoto;

import java.util.List;
import java.util.ArrayList;
import java.io.IOException;
import java.net.MalformedURLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.DriverManager;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.*;

import net.ontopia.utils.OntopiaRuntimeException;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.infoset.impl.basic.URILocator;
import net.ontopia.topicmaps.core.TopicIF;
import net.ontopia.topicmaps.core.TopicMapIF;
import net.ontopia.topicmaps.core.TopicMapStoreIF;
import net.ontopia.topicmaps.core.TopicMapBuilderIF;
import net.ontopia.topicmaps.utils.ImportExportUtils;
import net.ontopia.topicmaps.entry.TopicMapReferenceIF;
import net.ontopia.topicmaps.entry.TopicMapRepositoryIF;
import net.ontopia.topicmaps.nav2.utils.NavigatorUtils;

/**
 * Tool to delete votes for photos which no longer exist, and also
 * comments on deleted photos. Can be run from command-line or as
 * a servlet.
 */
public class RemoveBadVotes extends HttpServlet {
  private static TopicMapIF topicmap;
  private static LocatorIF base;

  // command-line interface
  public static void main(String[] args) throws IOException, SQLException {
    String jdbcurl = args[0];
    String username = args[1];
    String passwd = args[2];
    
    JDBCUtils.init(jdbcurl, username, passwd);
    
    topicmap = ImportExportUtils.getReader(args[0]).read();
    base = topicmap.getStore().getBaseAddress();
    remove();
  }

  // servlet interface
  protected void doGet(HttpServletRequest req,
                       HttpServletResponse resp)
    throws ServletException, IOException {
    
    ServletContext ctxt = getServletContext();
    JDBCUtils.init(ctxt.getInitParameter("jdbcurl"),
                   ctxt.getInitParameter("jdbcuser"),
                   ctxt.getInitParameter("jdbcpasswd"));

    TopicMapRepositoryIF repo =
      NavigatorUtils.getTopicMapRepository(getServletContext());
    TopicMapReferenceIF ref = repo.getReferenceByKey("metadata.xtm");
    TopicMapStoreIF store = ref.createStore(true);
    topicmap = store.getTopicMap();
    base = store.getBaseAddress();

    // set topicmap & base
    try {
      remove();
    } catch (SQLException e) {
      throw new ServletException(e);
    }

    // say something
    String message = "Successful!";
    resp.setHeader("Content-type", "text/plain");
    resp.setIntHeader("Content-length", message.length());
    resp.getWriter().write(message);
  }

  private static void remove() throws SQLException {
    List votes = ScoreManager.getAllVotes();
    for (int ix = 0; ix < votes.size(); ix++) {
      ScoreManager.PhotoInList photo = (ScoreManager.PhotoInList) votes.get(ix);
      if (!topicExists(photo.getPhotoId()))
        ScoreManager.deleteVotesOn(photo.getPhotoId());
    }

    List comments = CommentManager.getAllComments();
    for (int ix = 0; ix < comments.size(); ix++) {
      CommentManager.Comment comment = (CommentManager.Comment) comments.get(ix);
      if (!topicExists(comment.getPhotoId()))
        CommentManager.deleteComment(comment.getId());
    }
  }

  private static boolean topicExists(String id) {
    LocatorIF itemid = base.resolveAbsolute("#" + id);
    return topicmap.getObjectByItemIdentifier(itemid) != null;
  }
}