import glob
import multiprocessing
import platform
from pathlib import Path
from typing import List

from Cython.Build import cythonize
from Cython.Distutils.build_ext import new_build_ext as cython_build_ext
from setuptools import Extension, Distribution

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
    extensions = [
        Extension("startrec.wrapper", ["startrec/wrapper.pyx"] + [str(p) for p in c_sources])
    ]

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
        compiler_directives={"language_level": "3"}
    )


def build():
    # Collect and cythonize all files
    extension_modules = cythonize_helper(get_extension_modules())

    # Use Setuptools to collect files
    distribution = Distribution({
        "ext_modules": extension_modules,
        "cmdclass": {
            "build_ext": cython_build_ext,
        },
    })

    # Grab the build_ext command and copy all files back to source dir.
    # Done so Poetry grabs the files during the next step in its build.
    distribution.run_command("build_ext")
    build_ext_cmd = distribution.get_command_obj("build_ext")
    build_ext_cmd.copy_extensions_to_source()


if __name__ == '__main__':
    build()
