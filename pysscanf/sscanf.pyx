from libc.stdio cimport sscanf as c_sscanf
from libc.string cimport strcpy, strncpy
from libc.string cimport strlen
cimport numpy
import numpy

ctypedef struct FMT:
    int offset
    int size
    int elsize
    char fmt[16]

def dtype2fmt(dtype):

    cdef numpy.ndarray r = numpy.zeros(sizeof(FMT) * len(dtype), dtype='b')
    cdef FMT * p = <FMT*> r.data
    d = {
        'b': '%hhi',
        'B': '%hhu',
        'h': '%hi',
        'H': '%hu',
        'i': '%i',
        'I': '%u',
        'l': '%li',
        'L': '%lu',
        'd': '%lf',
        'f': '%f',
    }

    for name in dtype.names:
        field = dtype.fields[name]
        if len(field) == 3:
            subdtype, offset, title = field
        else:
            subdtype, offset = field
        if subdtype.char == 'S':
            fmt = ('%' + '%d' % subdtype.itemsize + 's' + '%n').encode()
            p.size = 1
            p.elsize = 0
        elif subdtype.char == 'V':
            p.size = numpy.prod(subdtype.shape)
            fmt = (d[subdtype.base.char] + '%n').encode()
            p.elsize = subdtype.base.itemsize
        else:
            fmt = (d[subdtype.char] + '%n').encode()
            p.size = 1
            p.elsize = subdtype.itemsize

        strncpy(p.fmt, <bytes>fmt, 12)

        p.offset = offset
        p = p + 1
    return r

def fscanf(object file, numpy.dtype dtype, nrows=-1):
    def yield_chunk(file):
        lines = []
        N = 0
        for i, line in enumerate(file):
            lines.append(line)
            N = N + 1
            if N == 1024:
                yield b''.join(lines)
                lines = []
                N = 0
            if i == nrows: break
        yield b'\n'.join(lines)
    data = []

    for chunk in yield_chunk(file):
        d1 = sscanf(chunk, dtype)
        data.append(d1)

    return numpy.concatenate(data, axis=0)

def sscanf(bytes bytestr, numpy.dtype dtype):
    """ Build a structured array from a byte string with sscanf.
    """
    cdef char * buf = bytestr
    cdef numpy.intp_t size = strlen(buf)
    cdef numpy.ndarray fmta = dtype2fmt(dtype)
    cdef FMT * fmt = <FMT*> fmta.data
    cdef numpy.intp_t nfmt = len(dtype.fields)
    cdef char * p = buf;
    cdef numpy.intp_t used = 0
    cdef numpy.intp_t bufsize = 128

    cdef numpy.ndarray data = numpy.zeros(bufsize, dtype=dtype)
    cdef char * datap = <char*> data.data
    cdef int nbytes
    cdef int nitem
    cdef int iitem
    cdef int finished = 0
    cdef int nitem_full = 0
    cdef int r
    for ifmt in range(nfmt):
        nitem_full = nitem_full + fmt[ifmt].size

    while True:
        nitem = 0
        for ifmt in range(nfmt):
            for iitem in range(fmt[ifmt].size):
                r = c_sscanf(p, fmt[ifmt].fmt, datap + fmt[ifmt].offset + iitem * fmt[ifmt].elsize, &nbytes)
                if r >= 0 :
                    nitem += r
                else:
                    break
                p = p + nbytes
                if p >= buf + size:
                    break

        if nitem == 0:
            # no more item to read; good
            break

        if nitem == nitem_full:
            # one full row is read
            datap = datap + dtype.itemsize
            used = used + 1
        else:
            raise RuntimeError("incomplete row %d %d" % (nitem, nitem_full))

        if used == bufsize:
            data = numpy.append(data, numpy.zeros(bufsize, dtype=dtype))
            bufsize = len(data)
            datap = <char*> data.data
            datap =  datap + used * dtype.itemsize
    return data[:used]
