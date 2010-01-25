
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import net.ontopia.utils.StreamUtils;

/**
 * Processor which calls ImageMagick on the command-line.
 */
public class ImageMagickCLIProcessor implements ImageProcessor {

  public void scaleImage(File source, File destination, int maxside)
    throws IOException {
    String size = "" + maxside + "x" + maxside;
    String[] cmd = new String[] {"convert",
                                 "-size",
                                 size,
                                 "-resize",
                                 size,
                                 source.getPath(),
                                 destination.getPath() };
    Process convert = Runtime.getRuntime().exec(cmd, null, null);
    try {
      int result = convert.waitFor();
      if (result != 0) {
        InputStreamReader reader =
          new InputStreamReader(convert.getErrorStream());
        String msg = StreamUtils.read(reader);
        throw new IOException("Error in conversion: " + msg);
      }
    } catch (InterruptedException e) {
    }
  }

}