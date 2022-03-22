import glob
import io
import multiprocessing
import os
import platform
from pathlib import Path
from typing import List

from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup

BUILD_DIR = "cython_build"


# https://d39l7znklsxxzt.cloudfront.net/zh/blog/2021/01/19/publishing-a-proprietary-python-package-on-pypi-using-poetry/


def get_extension_modules() -> List[Extension]:
    c_sources = [Path(p) for p in glob.glob("trec_eval/*.c")]

    # Remove this file, as it contains the main function which we do not want and need
    c_sources.remove(Path("trec_eval/trec_eval.c"))

    # Add Windows specific source files when running on Windows
    is_windows = any(platform.win32_ver())
    if is_windows:
        c_sources.extend([Path(p) for p in glob.glob("trec_eval/windows/*.c")])

    # Define extensions
    extensions = [Extension("startrec._wrapper", ["startrec/_wrapper.pyx"] + [str(p) for p in c_sources])]

    return extensions


def cythonize_helper(extension_modules: List[Extension]) -> List[Extension]:
    """Cythonize all Python extensions"""

    return cythonize(
        module_list=extension_modules,
        # Don't build in source tree (this leaves behind .c files)
        build_dir=BUILD_DIR,
        # Don't generate an .html output file
        annotate=False,
        # Parallelize our build
        nthreads=multiprocessing.cpu_count() * 2,
        # Tell Cython we're using Python 3. Becomes default in Cython 3
        compiler_directives={"language_level": "3"},
    )


# Package meta-data.
NAME = "startrec"
DESCRIPTION = "Python wrapper for trec_eval"
HOMEPAGE = "https://github.com/jcklie/startrec"
EMAIL = "git@mrklie.com"
AUTHOR = "Jan-Christoph Klie"
REQUIRES_PYTHON = ">=3.6.0"


here = os.path.abspath(os.path.dirname(__file__))

with io.open(os.path.join(here, "README.md"), encoding="utf-8") as f:
    long_description = "\n" + f.read()

# Load the package"s __version__.py module as a dictionary.
about = {}
with open(os.path.join(here, "startrec", "__version__.py")) as f:
    exec(f.read(), about)


test_dependencies = ["pytest==6.2.*"]
dev_dependencies = ["black==22.1.*", "isort==5.10.*"]
install_dependencies = ["Cython==0.29.*"]


setup(
    name=NAME,
    version=about["__version__"],
    description=DESCRIPTION,
    long_description=long_description,
    long_description_content_type="text/markdown",
    author=AUTHOR,
    author_email=EMAIL,
    python_requires=REQUIRES_PYTHON,
    url=HOMEPAGE,
    keywords="trec ir ranking metrics",
    project_urls={
        "Bug Tracker": "https://github.com/jcklie/startrec/issues",
        "Documentation": "https://github.com/jcklie/startrec",
        "Source Code": "https://github.com/jcklie/startrec",
    },
    packages=find_packages(exclude="tests"),
    test_suite="tests",
    tests_require=test_dependencies,
    install_requires=install_dependencies,
    extras_require={"dev": dev_dependencies},
    ext_modules=cythonize_helper(get_extension_modules()),
    zip_safe=False,
    include_package_data=True,
    license="MIT",
    classifiers=[
        # Trove classifiers
        # Full list: https://pypi.python.org/pypi?%3Aaction=list_classifiers
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Topic :: Software Development :: Libraries",
    ],
)
