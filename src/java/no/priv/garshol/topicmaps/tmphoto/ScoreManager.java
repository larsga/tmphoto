
package no.priv.garshol.topicmaps.tmphoto;

import java.util.List;
import java.util.Map;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Collection;
import java.util.ArrayList;
import java.net.MalformedURLException;
import java.sql.ResultSet;
import java.sql.SQLException;

import net.ontopia.utils.OntopiaRuntimeException;
import net.ontopia.infoset.core.LocatorIF;
import net.ontopia.infoset.impl.basic.URILocator;
import net.ontopia.topicmaps.core.TopicIF;
import net.ontopia.topicmaps.core.TopicMapIF;
import net.ontopia.topicmaps.core.TopicMapBuilderIF;

public class ScoreManager {

  public static void setScore(String photoid, String username, int score)
    throws SQLException {
    int id = JDBCUtils.queryForInt("select id " +
                                   "from PHOTO_SCORE " +
                                   "where photo = '" + photoid +
                                   "' and username = '" + username + "';", 0);
    String query;
    if (id == 0)
      // this is the first score from this user
      query = "insert into PHOTO_SCORE values (default, '" + photoid + "', " +
              "'" + username + "', " + score + ", now());";
    else
      query = "update PHOTO_SCORE set score = " + score + ", updated=now() " +
              "where id = " + id + ";";

    JDBCUtils.update(query);
  }

  public static int getScore(String photoid, String username)
    throws SQLException {
    return JDBCUtils.queryForInt("select score " +
                                 "from PHOTO_SCORE " +
                                 "where photo = '" + photoid +
                                 "' and username = '" + username + "';", 0);
  }

  public static int getVoteCount(String photoid)
    throws SQLException {
    return JDBCUtils.queryForInt("select count(*) " +
                                 "from PHOTO_SCORE " +
                                 "where photo = '" + photoid + "';", 0);
  }
  
  public static double getAverageScore(String photoid) throws SQLException {
    return JDBCUtils.queryForDouble("select avg(score) " +
                                    "from PHOTO_SCORE " +
                                    "where photo = '" + photoid + "'", 0);
  }

  public static Map getAverageScores(Collection photos) throws SQLException {
    Map averages = new HashMap();
    JDBCUtils.RowMapperIF builder = new StringDoubleMapBuilder(averages);

    List chunks = breakIntoChunks(photos, 50);
    Iterator it = chunks.iterator();
    while (it.hasNext()) {
      Collection chunk = (Collection) it.next();
      String query = "select photo, avg(score) as average " +
                     "from PHOTO_SCORE " +
                     "where photo in (" + JDBCUtils.toParamList(chunk) + ")" +
                     "group by photo ";
      JDBCUtils.queryForList(query, builder);
    }
      
    return averages;
  }  

  private static List breakIntoChunks(Collection items, int chunksize) {
    List chunks = new ArrayList((items.size() / chunksize) + 1);
    Collection chunk = new ArrayList(chunksize);
    chunks.add(chunk);
    
    Iterator it = items.iterator();
    int ix = 0;
    while (it.hasNext()) {
      Object item = it.next();
      chunk.add(item);
      ix++;
      if (ix == chunksize) {
        chunk = new ArrayList(chunksize);
        ix = 0;
        chunks.add(chunk);
      }
    }
    return chunks;
  }

  public static class StringDoubleMapBuilder implements JDBCUtils.RowMapperIF {
    private Map themap;

    public StringDoubleMapBuilder(Map themap) {
      this.themap = themap;
    }
    
    public Object map(ResultSet rs) throws SQLException {
      String id = rs.getString("photo");
      double av = rs.getDouble("average");
      themap.put(id, new Double(av));
      return null;
    }
  }

  public static int getPhotosWithVotesCount() throws SQLException {
    return JDBCUtils.queryForInt("select count(distinct photo) from PHOTO_SCORE",
                                 0);
  }

  public static List getBestPhotos() throws SQLException {
    return getBestPhotos(-1);
  }
  
  public static List getBestPhotos(int offset) throws SQLException {
    String chunk = "";
    if (offset != -1)
      chunk = "limit 50 offset " + offset;
    return JDBCUtils.queryForList(
      "select photo, avg(score) as average, count(score) as votes " +
      "from PHOTO_SCORE " +
      "group by photo " +
      "order by average desc, votes desc " + chunk,
      new PhotoInListBuilder3());
  }

  public static List getUserFavourites(String user, int offset) 
    throws SQLException {
    return JDBCUtils.queryForList(
      "select photo, score " +
      "from PHOTO_SCORE " +
      "where username='" + user + "' " +
      "order by score desc, updated desc limit 50 offset " + offset,
      new PhotoInListBuilder());
  }
  
  public static List getRecentVotes() throws SQLException {
    return JDBCUtils.queryForList(
      "select * " +
      "from PHOTO_SCORE " +
      "where username!='larsga' " +
      "order by updated desc limit 50", new PhotoInListBuilder2());
  }

  public static List getAllVotes() throws SQLException {
    return JDBCUtils.queryForList("select * from PHOTO_SCORE",
                                  new PhotoInListBuilder2());
  }
  
  public static List getVotingStats() throws SQLException {
    return JDBCUtils.queryForList(
      "select username, count(score) as votes, avg(score) as average " +
      "from photo_score " +
      "group by username " +
      "order by votes desc", new UserInListBuilder());
  }

  /**
   * Initializes the 'average vote' occurrences on photo topics.
   */
  public static void getAverageVotes(TopicMapIF topicmap) throws SQLException {
    String query = "select photo, avg(score) as average, count(score) as votes "+
                   "from photo_score " +
                   "group by photo";
    JDBCUtils.queryForList(query, new AverageSetter(topicmap));
  }

  public static class AverageSetter implements JDBCUtils.RowMapperIF {
    private TopicMapIF topicmap;
    private TopicMapBuilderIF builder;
    private TopicIF avg;

    public AverageSetter(TopicMapIF topicmap) {
      this.topicmap = topicmap;
      avg = getTopicByPsi(topicmap, "http://psi.ontopia.net/tmphoto/#average-vote");
      builder = topicmap.getBuilder();
    }
    
    public Object map(ResultSet rs) throws SQLException {
      String id = rs.getString("photo");
      double score = rs.getDouble("average");
      int votes = rs.getInt("votes");
      
      TopicIF photo = getTopic(topicmap, id);
      if (photo != null)
        builder.makeOccurrence(photo, avg, "" + score);

      return null;
    }
  }

  public static void deleteVotesOn(String photoid) throws SQLException {
    JDBCUtils.update("delete from PHOTO_SCORE " +
                     "       where photo = '" + photoid + "'");
  }
  
  // --- internal methods

  private static TopicIF getTopic(TopicMapIF topicmap, String id) {
    LocatorIF base = topicmap.getStore().getBaseAddress();
    LocatorIF srcloc = base.resolveAbsolute('#' + id);
    return (TopicIF) topicmap.getObjectByItemIdentifier(srcloc);
  }

  private static TopicIF getTopicByPsi(TopicMapIF topicmap, String psi) {
    try {
      LocatorIF si = new URILocator(psi);
      return topicmap.getTopicBySubjectIdentifier(si);
    } catch (MalformedURLException e) {
      throw new OntopiaRuntimeException("INTERNAL ERROR: " + e);
    }
  }

  // --- internal class

  public static class PhotoInListBuilder implements JDBCUtils.RowMapperIF {
    public Object map(ResultSet rs) throws SQLException {
      return new PhotoInList(rs.getString("photo"),
                             rs.getInt("score"),
                             0);
    }
  }

  public static class PhotoInListBuilder2 implements JDBCUtils.RowMapperIF {
    public Object map(ResultSet rs) throws SQLException {
      return new PhotoInList(rs.getString("photo"),
                             rs.getInt("score"),
                             -1,
                             rs.getString("username"));
    }
  }

  public static class PhotoInListBuilder3 implements JDBCUtils.RowMapperIF {
    public Object map(ResultSet rs) throws SQLException {
      return new PhotoInList(rs.getString("photo"),
                             rs.getDouble("average"),
                             rs.getInt("votes"));
    }
  }
  
  public static class PhotoInList {
    private String id;
    private double score;
    private int votes;
    private String user;

    public PhotoInList(String id, double score, int votes) {
      this(id, score, votes, null);
    }

    public PhotoInList(String id, double score, int votes, String user) {
      this.id = id;
      this.score = score;
      this.votes = votes;
      this.user = user;
    }

    public String getPhotoId() {
      return id;
    }

    public double getScore() {
      return score;
    }

    public int getVotes() {
      return votes;
    }

    public String getUser() {
      return user;
    }
  }

  public static class UserInListBuilder implements JDBCUtils.RowMapperIF {
    public Object map(ResultSet rs) throws SQLException {
      return new UserInList(rs.getString("username"),
                            rs.getInt("votes"),
                            rs.getDouble("average"));
    }
  }
  
  public static class UserInList {
    private String user;
    private int votes;
    private double average;

    public UserInList(String user, int votes, double average) {
      this.user = user;
      this.votes = votes;
      this.average = average;
    }

    public int getVotes() {
      return votes;
    }

    public String getUser() {
      return user;
    }

    public double getAverage() {
      return average;
    }
  }  
}