from setuptools import setup
from Cython.Build import cythonize
from distutils.extension import Extension

extensions = [
        Extension("pysscanf.sscanf", ["pysscanf/sscanf.pyx"])]

def find_version(path):
    import re
    # path shall be a plain ascii text file.
    s = open(path, 'rt').read()
    version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]",
                              s, re.M)
    if version_match:
        return version_match.group(1)
    raise RuntimeError("Version not found")

setup(
    name="pysscanf",
    version=find_version("pysscanf/version.py"),
    author="Yu Feng",
    author_email="rainwoodman@gmail.com",
    url="http://github.com/rainwoodman/pysscanf",
    description="A binding of sscanf to Python, producing numpy arrays",
    zip_safe = False,
    package_dir = {'pysscanf': 'pysscanf'},
    install_requires=['pytest', 'coverage'],
    license='BSD-2-Clause',
    packages= ['pysscanf', 'pysscanf.tests'],
    requires=['pytest', 'coverage'],
    ext_modules = cythonize(extensions),
)
