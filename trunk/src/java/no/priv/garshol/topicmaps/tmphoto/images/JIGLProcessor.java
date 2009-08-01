
package no.priv.garshol.topicmaps.tmphoto.images;

import java.io.File;
import java.io.IOException;

import jigl.image.Image;
import jigl.image.ImageNotSupportedException;
import jigl.image.io.ImageInputStream;
import jigl.image.io.ImageOutputStream;
import jigl.image.io.ImageOutputStreamJAI;
import jigl.image.io.IllegalPBMFormatException;
import jigl.image.ops.levelOps.Scale;
  
/**
 * Processor implemented using Java Image and Graphics Library (JIGL) 1.6.
 */
public class JIGLProcessor implements ImageProcessor {

  public void scaleImage(File source, File destination, int maxside)
    throws IOException {
    try {
      ImageInputStream in = new ImageInputStream(source.getPath());
      Image sourcei = in.read();
      in.close();
  
      Image scaled = new Scale(maxside, maxside).apply(sourcei);
      
      ImageOutputStreamJAI out = new ImageOutputStreamJAI(destination.getPath());
      out.writeJPEG(scaled);
      // no close method. sigh.
    } catch (InterruptedException e) {
      throw new RuntimeException(e); // not very likely, really
    } catch (ImageNotSupportedException e) {
      throw new RuntimeException(e); // not very likely, really
    } catch (IllegalPBMFormatException e) {
      throw new RuntimeException(e); 
    }
  }

}