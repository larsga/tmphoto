
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

import net.ontopia.utils.OntopiaRuntimeException;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.infoset.impl.basic.URILocator;
import net.ontopia.topicmaps.core.TopicIF;
import net.ontopia.topicmaps.core.TopicMapIF;
import net.ontopia.topicmaps.core.TopicMapBuilderIF;
import net.ontopia.topicmaps.utils.ImportExportUtils;

/**
 * Command-line tool to delete votes for photos which no longer exist,
 * and also comments on deleted photos.
 */
public class RemoveBadVotes {
  private static TopicMapIF topicmap;
  private static LocatorIF base;

  public static void main(String[] args) throws IOException, SQLException {

    JDBCUtils.init("jdbc:postgresql:tmphoto", "larsga", "secret");
    
    topicmap = ImportExportUtils.getReader(args[0]).read();
    base = topicmap.getStore().getBaseAddress();
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