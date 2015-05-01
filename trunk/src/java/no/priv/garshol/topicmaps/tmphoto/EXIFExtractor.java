
package no.priv.garshol.topicmaps.tmphoto;

import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;
import java.io.File;
import java.io.IOException;

import com.drew.metadata.Tag;
import com.drew.metadata.Metadata;
import com.drew.metadata.Directory;
import com.drew.metadata.MetadataException;
import com.drew.imaging.jpeg.JpegMetadataReader;
import com.drew.imaging.jpeg.JpegProcessingException;

/**
 * Module which turns EXIF data into something nice and readable.
 */
public class EXIFExtractor {

  // simple driver for test usage
  public static void main(String argv[]) throws IOException {
    int ix = 0;
    boolean showall = false;
    if (argv.length > 0 && argv[0].equals("--all")) {
      ix = 1;
      showall = true;
    }

    for (; ix < argv.length; ix++) {
      System.out.println("---------------------------------------------------------------------------");
      System.out.println("File: " + argv[ix]);
      Map<String, String> metadata = extractMetadata(new File(argv[ix]), showall);
      for (String field : metadata.keySet())
        System.out.println(field + ": " + metadata.get(field));
    }
  }

  public static Map<String, String> extractMetadata(File imagefile,
                                                    boolean showall)
    throws IOException {
    HashMap<String, String> map = new HashMap<String, String>();
    Metadata m;
    try {
      m = JpegMetadataReader.readMetadata(imagefile);
    } catch (JpegProcessingException e) {
      throw new RuntimeException(e);
    }

    Iterator it = m.getDirectoryIterator();
    while (it.hasNext()) {
      Directory d = (Directory) it.next();

      Iterator it2 = d.getTagIterator();
      while (it2.hasNext()) {
        Tag t = (Tag) it2.next();
        try {
          if (showall)
            map.put(t.getTagName(), t.getDescription());
          else if (tags.containsKey(t.getTagName()))
            map.put(tags.get(t.getTagName()), t.getDescription());
        } catch (MetadataException e) {
          // probably OK
        }
      }
    }

    // some cameras report just model number under "Model" and not maker.
    // we fix this by retrieving it from "Make" if necessary.
    String model = map.get("Camera");
    String maker = map.get("Make");
    if (model != null && model.indexOf(' ') == -1 && maker != null)
      map.put("Camera", maker + " " + model);
    map.remove("Make");
    return map;
  }

  private static Map<String, String> tags = new HashMap<String, String>();

  // how to decide lens?
  static {
    tags.put("F-Number",            "F-Number");
    tags.put("Model",               "Camera");
    tags.put("Focal Length",        "Focal Length");
    tags.put("Flash Mode",          "Flash");
    tags.put("Flash",               "Flash");
    tags.put("Easy Shooting Mode",  "Mode");
    tags.put("ISO Speed Ratings",   "ISO");
    tags.put("Shutter Speed Value", "Exposure");
    tags.put("White Balance",       "White Balance");
    tags.put("Make",                "Make"); // special, see code above
  }
}
