
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
 * Command-line tool to delete votes for photos which no longer exist.
 */
public class RemoveBadVotes {
  private static TopicMapIF topicmap;

  public static void main(String[] args) throws IOException, SQLException {
    topicmap = ImportExportUtils.getReader(args[0]).read();
    List votes = ScoreManager.getAllVotes();
    for (int ix = 0; ix < votes.size(); ix++) {
      ScoreManager.PhotoInList photo = (ScoreManager.PhotoInList) votes.get(ix);
      if (!topicExists(photo.getPhotoId()))
        ScoreManager.deleteVotesOn(photo.getPhotoId());
    }
  }

  private static boolean topicExists(String id) {
    LocatorIF base = topicmap.getStore().getBaseAddress();
    LocatorIF srcloc = base.resolveAbsolute("#" + id);
    return topicmap.getObjectByItemIdentifier(srcloc) != null;
  }
}