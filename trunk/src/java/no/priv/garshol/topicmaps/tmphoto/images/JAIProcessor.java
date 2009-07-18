
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;

import javax.media.jai.JAI;
import javax.media.jai.RenderedOp;
import javax.media.jai.Interpolation;

/**
 * Processor implemented using Sun's Java Advanced Imaging API.
 */
public class JAIProcessor implements ImageProcessor {

  public void scaleImage(File source, File destination, int maxside) {
    RenderedOp src = JAI.create("fileload", source.getPath());
    RenderedOp scaled = src;

    int biggest = Math.max(src.getHeight(), src.getWidth());
    float scale = maxside / (float) biggest;
    if (scale < 1.0)
      scaled = JAI.create("scale", src, scale, scale, 0, 0,
                        Interpolation.getInstance(Interpolation.INTERP_BILINEAR));

    RenderedOp saved = 
      JAI.create("filestore", scaled, destination.getPath(), "JPEG", null);

    src.dispose();
    if (scaled != src)
      scaled.dispose();
    saved.dispose();
  }

}