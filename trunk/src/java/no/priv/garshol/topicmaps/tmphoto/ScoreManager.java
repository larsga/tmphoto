
package no.priv.garshol.topicmaps.tmphoto;

import java.util.List;
import java.util.Map;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Collection;
import java.util.ArrayList;
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

public class ScoreManager {
  private static String JDBCURL = "jdbc:postgresql:tmphoto";
  private static String USER = "larsga";
  private static String PASSWORD = "u54raud";

  public static void setScore(String photoid, String username, int score)
    throws SQLException {
    int id = queryForInt("select id " +
                         "from PHOTO_SCORE " +
                         "where photo = '" + photoid +
                         "' and username = '" + username + "';", 0);
    if (id == 0)
      // this is the first score from this user
      update("insert into PHOTO_SCORE values (default, '" + photoid + "', " +
             "'" + username + "', " + score + ", now());");
    else
      update("update PHOTO_SCORE set score = " + score + ", updated=now() " +
             "where id = " + id + ";");
  }

  public static int getScore(String photoid, String username)
    throws SQLException {
    return queryForInt("select score " +
                       "from PHOTO_SCORE " +
                       "where photo = '" + photoid +
                       "' and username = '" + username + "';", 0);
  }

  public static int getVoteCount(String photoid)
    throws SQLException {
    return queryForInt("select count(*) " +
                       "from PHOTO_SCORE " +
                       "where photo = '" + photoid + "';", 0);
  }
  
  public static double getAverageScore(String photoid) throws SQLException {
    return queryForDouble("select avg(score) " +
                          "from PHOTO_SCORE " +
                          "where photo = '" + photoid + "'", 0);
  }

  public static Map getAverageScores(Collection photos) throws SQLException {
    Map averages = new HashMap();
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();

      List chunks = breakIntoChunks(photos, 50);
      Iterator it = chunks.iterator();
      while (it.hasNext()) {
        Collection chunk = (Collection) it.next();
        stmt.execute("select photo, avg(score) as average " +
                     "from PHOTO_SCORE " +
                     "where photo in (" + toParamList(chunk) + ")" +
                     "group by photo ");
        rs = stmt.getResultSet();
        List list = new ArrayList(50);
        while (rs.next()) {
          String id = rs.getString("photo");
          double av = rs.getDouble("average");
          averages.put(id, new Double(av));
        }
      }
      
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
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

  private static String toParamList(Collection topics) {
    StringBuffer buf = new StringBuffer();
    Iterator it = topics.iterator();
    while (it.hasNext()) {
      TopicIF topic = (TopicIF) it.next();
      buf.append("'" + getId(topic) + "'");
      if (it.hasNext())
        buf.append(", ");
    }
    return buf.toString();
  }

  private static String getId(TopicIF photo) {
    Iterator it = photo.getItemIdentifiers().iterator();
    while (it.hasNext()) {
      LocatorIF loc = (LocatorIF) it.next();
      String url = loc.getAddress();
      int pos = url.indexOf('#');
      if (pos != -1)
        return url.substring(pos + 1);
    }
    return null;
  }

  public static int getPhotosWithVotesCount() throws SQLException {
    return queryForInt("select count(distinct photo) from PHOTO_SCORE", 0);
  }

  public static List getBestPhotos() throws SQLException {
    return getBestPhotos(-1);
  }
  
  public static List getBestPhotos(int offset) throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      String chunk = "";
      if (offset != -1)
        chunk = "limit 50 offset " + offset;
      stmt.execute("select photo, avg(score) as average, count(score) as votes " +
                   "from PHOTO_SCORE " +
                   "group by photo " +
                   "order by average desc, votes desc " + chunk);
      rs = stmt.getResultSet();
      List list = new ArrayList(50);
      while (rs.next())
        list.add(new PhotoInList(rs.getString("photo"),
                                 rs.getDouble("average"),
                                 rs.getInt("votes")));
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  public static List getUserFavourites(String user, int offset)
    throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute("select photo, score " +
                   "from PHOTO_SCORE " +
                   "where username='" + user + "' " +
                   "order by score desc, updated desc limit 50 offset " + offset);
      rs = stmt.getResultSet();
      List list = new ArrayList(50);
      while (rs.next())
        list.add(new PhotoInList(rs.getString("photo"),
                                 rs.getInt("score"),
                                 0));
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }
  
  public static List getRecentVotes() throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute("select * " +
                   "from PHOTO_SCORE " +
                   "where username!='larsga' " +
                   "order by updated desc limit 50");

      rs = stmt.getResultSet();
      List list = new ArrayList(50);
      while (rs.next())
        list.add(new PhotoInList(rs.getString("photo"),
                                 rs.getDouble("score"),
                                 -1,
                                 rs.getString("username")));
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  public static List getAllVotes() throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute("select * " +
                   "from PHOTO_SCORE");

      rs = stmt.getResultSet();
      List list = new ArrayList(50);
      while (rs.next())
        list.add(new PhotoInList(rs.getString("photo"),
                                 rs.getDouble("score"),
                                 -1,
                                 rs.getString("username")));
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }
  
  public static List getVotingStats() throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute("select username, count(score) as votes, avg(score) as average " +
                   "from photo_score " +
                   "group by username " +
                   "order by votes desc");
      rs = stmt.getResultSet();
      List list = new ArrayList(50);
      while (rs.next())
        list.add(new UserInList(rs.getString("username"),
                                rs.getInt("votes"),
                                rs.getDouble("average")));
      return list;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  /**
   * Initializes the 'average vote' occurrences on photo topics.
   */
  public static void getAverageVotes(TopicMapIF topicmap) throws SQLException {
    TopicIF avg = getTopicByPsi(topicmap,
                                "http://psi.ontopia.net/tmphoto/#average-vote");
    TopicMapBuilderIF builder = topicmap.getBuilder();
    
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute("select photo, avg(score) as average, count(score) as votes "+
                   "from photo_score " +
                   "group by photo");

      rs = stmt.getResultSet();
      while (rs.next()) {
        String id = rs.getString("photo");
        double score = rs.getDouble("average");
        int votes = rs.getInt("votes");

        TopicIF photo = getTopic(topicmap, id);
        if (photo != null)
          builder.makeOccurrence(photo, avg, "" + score);
      }
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        if (rs != null)
          rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  public static void deleteVotesOn(String photoid) throws SQLException {
    update("delete from PHOTO_SCORE " +
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
    
  // --- private stuff

  private static Statement getStatement() throws SQLException {
    try {
      Class.forName("org.postgresql.Driver");
    } catch (Exception e) {
      throw new net.ontopia.utils.OntopiaRuntimeException(e);
    }
    
    Connection conn = DriverManager.getConnection(JDBCURL, USER, PASSWORD);
    return conn.createStatement();
  }

  private static int queryForInt(String query, int default_) throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute(query);
      rs = stmt.getResultSet();
      if (rs.next())
        return rs.getInt(1);
      else
        return default_;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  private static double queryForDouble(String query, double default_) throws SQLException {
    Statement stmt = null;
    ResultSet rs = null;
    try {
      stmt = getStatement();
      stmt.execute(query);
      rs = stmt.getResultSet();
      if (rs.next())
        return rs.getDouble(1);
      else
        return default_;
    } finally {
      if (stmt != null) {
        Connection conn = stmt.getConnection();
        rs.close();
        stmt.close();
        conn.close();
      }
    }
  }

  private static void update(String query) throws SQLException {
    Statement stmt = null;
    try {
      stmt = getStatement();
      stmt.executeUpdate(query);
    } finally {
      Connection conn = stmt.getConnection();
      stmt.close();
      conn.close();
    }    
  }
}