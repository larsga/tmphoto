#!/usr/bin/python
"""
wsgiref-based photo server.
"""

import os, string, glob, time, threading
#import EXIF

SIZES = {
    # full is also an alternative, but implemented differently
    "default" : "800x800",
    "thumb"   : "250x250"
    }

def read_config(file):
    cfg = {}

    for line in open(file).readlines():
        if line[0] == "#":
            continue

        line = string.strip(line)
        (field, value) = string.split(line, "=")
        cfg[string.strip(field)] = string.strip(value)

    return cfg

cfg = read_config("photoserv.cfg")
cachedir = cfg["cachedir"]
PREFIX = cfg["PREFIX"]
IXFILE = "index.txt"

# --- Index

class Index:
    def __init__(self):
        self._ixtime = lastmod(IXFILE)
        self._load_index()

    def _load_index(self):
        self._idmap = {}
        for line in open(IXFILE).readlines():
            (id, path) = string.split(string.strip(line), "|")
            self._idmap[id] = path
        self._purge_cache()

    def _purge_cache(self):
        "Removes scaled images in the cache if the originals are gone."
        for size in SIZES.keys():
            for fullfile in glob.glob(cachedir + os.sep + size + os.sep + "*"):
                file = os.path.split(fullfile)[1]
                if not self._idmap.has_key(file):
                    os.unlink(fullfile)

    def get_photo(self, id):
        photo = self._idmap.get(id)
        if type(photo) == type(""):
            if photo.lower().endswith(".avi"):
                photo = Video(id, photo)
            else:
                photo = Photo(id, photo)
            self._idmap[id] = photo
        return photo

    def reload(self):
        nixtime = lastmod(IXFILE)
        if nixtime > self._ixtime:
            print "INDEX RELOADED"
            # reload index
            self._ixtime = nixtime
            self._load_index()

# --- Images

class Image:
    def __init__(self, id, filename):
        self._id = id
        self._filename = PREFIX + filename

    def get_filename(self):
        return self._filename

    def get_last_modified(self):
        return lastmod(self._filename)

    def get_scaled(self, size, reload):
        assert 0

class Photo(Image):

    def get_scaled(self, size, reload):
        global count
        if size == "full":
            return self._filename

        scaled = cachedir + os.sep + size + os.sep + self._id
        if not exists(scaled) or lastmod(scaled) < self.get_last_modified() \
           or reload:
            size = SIZES[size]

            while count >= MAX_PROCESSES:
                time.sleep(0.1)

            countlock.acquire()
            count += 1
            countlock.release()

            os.system('convert -size %s -resize %s "%s" "%s"' %
                      (size, size, self._filename, scaled))

            countlock.acquire()
            count -= 1
            countlock.release()

        return scaled

class Video(Image):

    def get_scaled(self, size, reload):
        scaled = cachedir + os.sep + size + os.sep + self._id + ".jpg"
        if not exists(scaled) or lastmod(scaled) < self.get_last_modified() \
           or reload:
            size = SIZES[size]
            cmd = ('convert -size %s -resize %s "%s[1]" "%s"' %
                   (size, size, self._filename, scaled))
            os.system(cmd)

        return scaled

# --- Horrid EXIF code

def calculate_ratio(value):
    if string.find(str(value), "/") != -1:
        (top, bot) = string.split(str(value), "/")
        return float(top) / float(bot)
    else:
        return float(str(value))

def decode_flash(value):
    try:
        v = int(str(value))
        if v & 0x0001:
            r = "Flash fired"
        else:
            r = "Flash did not fire"

        if v & 0x0018 == 24:
            r += ", auto mode"
        elif v & 0x0018 == 16:
            r += ", manually set off"
        elif v & 0x0018 == 8:
            r += ", manually set on"

        if v & 0x0040:
            r += ", red-eye reduction mode"

        return r
    except ValueError:
        # this happens when the library has decoded it for us
        return str(value)

def mode(data):
    v = data["MakerNote ExposureMode"]
    if v == "Easy Shooting":
        v = data["MakerNote EasyShootingMode"]
    return v

lenses = {
    "17-70"  : "Sigma 17-70mm f/2.8-4.5 DC",
    "70-300" : "Canon DL Macro Super 70-300mm f/4-5.6",
    "30-30"  : "Sigma 30mm f/1.4 EX DC",
    "18-55"  : "Canon EF-S 18-55mm f/3.5-5.6 IS",
    }
def output_metadata(filename, start_response):
    start_response("200 OK", [('Content-Type', 'text/html')])

    fields = [("File name", filename)]
    data = EXIF.process_file(open(filename))

    if data.get("Image Model"):
        model = str(data["Image Model"])
        make = str(data["Image Make"])
        if model[ : len(make)] != make:
            v = string.split(make)[0] + " " + model
        else:
            v = model
        fields.append(("Camera", v))
    if data.get("MakerNote ExposureMode"):
        fields.append(("Mode", str(mode(data))))
    if data.get("EXIF FNumber"):
        fields.append(("F-number", str(calculate_ratio(data["EXIF FNumber"]))))
    if data.get("EXIF Flash"):
        fields.append(("Flash", decode_flash(data["EXIF Flash"])))
    if data.get("EXIF ExposureTime"):
        fields.append(("Exposure time", str(data["EXIF ExposureTime"])))

    if data.get("EXIF ISOSpeedRatings"):
        fields.append(("ISO", str(data["EXIF ISOSpeedRatings"])))
    elif data.get("MakerNote ISO"):
        fields.append(("ISO", str(data["MakerNote ISO"])))

    if data.get("EXIF WhiteBalance"):
        v = data.get("EXIF WhiteBalance")
        if str(v) == "Manual white balance":
            v = data.get("MakerNote WhiteBalance")
        fields.append(("White balance", v))

    if (data.get("MakerNote ShortFocalLengthOfLensInFocalUnits") and
        data.get("MakerNote LongFocalLengthOfLensInFocalUnits")):
        short = data["MakerNote ShortFocalLengthOfLensInFocalUnits"]
        long = data["MakerNote LongFocalLengthOfLensInFocalUnits"]
        key = "%s-%s" % (short, long)
        if lenses.has_key(key):
            fields.append(("Lens", lenses.get(key, key)))

    return ["<table>%s</table>" % string.join(["<tr><td>%s <td>%s" %
                                               pair for pair in fields], "\n")]

# --- Helpers

def lastmod(file):
    return os.stat(file).st_mtime

def exists(file):
    try:
        os.stat(file)
        return 1
    except OSError, e:
        if e.errno == 2:
            return 0
        else:
            raise

# --- Web application

def parse_query_string(qs):
    if qs.endswith(";reload"):
        reload = 1
        qs = qs[ : -7]
    else:
        reload = 0

    if string.find(qs, ";") != -1:
        (id, size) = string.split(qs, ";")
        return (id, size, reload)
    else:
        return (qs, "default", reload)

def output_photo(photo, size, start_response, reload, environ):
    lastmod = time.gmtime(photo.get_last_modified())
    if environ.has_key("HTTP_IF_MODIFIED_SINCE"):
        req = environ["HTTP_IF_MODIFIED_SINCE"]
        req = time.mktime(time.strptime(req, "%a, %d %b %Y %H:%M:%S %Z"))
        last = time.mktime(lastmod)
        if req >= last:
            start_response("304 Not changed", [])
            return [""]

    t = time.strftime("%a, %d %b %Y %H:%M:%S GMT", lastmod)
    start_response("200 OK", [('Content-Type', 'image/jpeg'),
                              ('Cache-Control', 'max-age=604800'),
                              ('Last-Modified', t)])

    scaled = photo.get_scaled(size, reload)

    inf = open(scaled)
    data = inf.read()
    inf.close

    return [data]

def photo_app(environ, start_response):
    (id, size, reload) = parse_query_string(environ["QUERY_STRING"])
    index.reload()

    photo = index.get_photo(id)
    if not photo:
        start_response("404 Not found", [])
        return ["No such image"]

    if size == "metadata":
        return output_metadata(photo.get_filename(), start_response)
    else:
        return output_photo(photo, size, start_response, reload, environ)

def run_wsgiref(app):
    httpd = make_server('', 8000, app)
    print "Serving HTTP on port 8000..."

    # Respond to requests until process is killed
    httpd.serve_forever()

def main():
    global make_server, index, WSGIServer
    index = Index()
    for size in SIZES.keys():
        try:
            os.mkdir(cachedir + os.sep + size) # make sure the cache directories exist
        except OSError:
            pass

    try:
        from fcgi import WSGIServer
        WSGIServer(photo_app).run()
    except ImportError:
        print "No fcgi"

    try:
        from wsgiref.simple_server import make_server
        run_wsgiref(photo_app)
    except ImportError:
        pass #print "No wsgiref"

    print "Giving up"

MAX_PROCESSES = 4
countlock = threading.Lock()
count = 0 # number of conversion processes running

if __name__ == "__main__":
    main()
else:
    application = photo_app
    index = Index()
    for size in SIZES.keys():
        try:
            os.mkdir(cachedir + os.sep + size) # make sure the cache directories exist
        except OSError:
            pass
