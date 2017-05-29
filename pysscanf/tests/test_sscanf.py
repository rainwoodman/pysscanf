from pysscanf import sscanf, fscanf
import numpy
from numpy.testing import assert_array_equal
def test_scalar():
    dt = numpy.dtype([
                      ('S10', 'S10'),
                      ('b', 'b'),
                      ('B', 'B'),
                      ('h', 'i2'),
                      ('H', 'u2'),
                      ('i', 'i4'),
                      ('I', 'u4'),
                      ('l', 'i8'),
                      ('L', 'u8'),
                      ('d', 'f8'),
                      ('f', 'f4'),

    ])

    line = b' '.join([b"str"] + [b'1'] * (len(dt) - 1))
    data = b'\n'.join([line] * 10)
    a = sscanf(data, dt)
    assert_array_equal(a['S10'],  b'str')
    for key in dt.names[1:]:
        assert_array_equal(a[key],  1)

    assert len(a) == 10

def test_vector():
    dt = numpy.dtype([
                      ('b', ('b', 3)),
                      ('f', ('f4', 2)),
    ])

    line = b'1 1 1 2 2 '
    data = b'\n'.join([line] * 10)
    a = sscanf(data, dt)
    assert_array_equal(a['b'], [(1, 1, 1)] * 10)
    assert_array_equal(a['f'], [(2, 2)] * 10)
    assert len(a) == 10

def test_fscanf():
    dt = numpy.dtype([
                      ('b', ('b', 3)),
                      ('f', ('f4', 2)),
    ])

    line = b'1 1 1 2 2 '
    data = [line] * 10
    a = fscanf(data, dt)
    assert_array_equal(a['b'], [(1, 1, 1)] * 10)
    assert_array_equal(a['f'], [(2, 2)] * 10)
    assert len(a) == 10
