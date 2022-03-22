from typing import Dict, List

import cython


cdef extern from "../trec_eval/trec_eval.h":
    # trec_eval session structure.
    ctypedef struct EPI:
        pass

    ctypedef struct REL_INFO:
        pass

    ctypedef struct RESULTS:
        pass

    ctypedef struct TREC_EVAL:
        pass

    # measure definition
    ctypedef struct TREC_MEAS:
        char *name;
        char *explanation;

        # Store parameters for measure in meas_params. Reserve space in
        # TREC_EVAL.values for results of measure. Store individual measure
        # names (possibly altered by parameters) in TREC_EVAL.values and
        # initialize value to 0.0.
        # Set tm->eval_index to start of reserved space
        int (*init_meas)(EPI *epi, TREC_MEAS *tm, TREC_EVAL *eval)  except -1

    # nicknames
    ctypedef struct TREC_MEASURE_NICKNAMES:
        char *name;
        char ** name_list;

cdef extern int te_num_trec_measures;
cdef extern TREC_MEAS *te_trec_measures[];

cdef extern int te_num_trec_measure_nicknames;
cdef extern TREC_MEASURE_NICKNAMES te_trec_measure_nicknames[];

cdef class MeasureWrapper:
    cdef EPI _epi
    cdef TREC_EVAL _eval
    cdef TREC_MEAS *_measure

    def __init__(self, name: str):
        self._measure = get_measure_by_name(name)
        self._measure.init_meas(&self._epi, self._measure, &self._eval)

    def get_explanation(self) -> str:
        return self._measure.explanation.decode("ascii")

cdef TREC_MEAS * get_measure_by_name(str name) except NULL:
    for i in range(te_num_trec_measures):
        measure = te_trec_measures[i]
        if name == measure.name.decode("ascii"):
            return measure


    raise ValueError(f"Unknown measure: [{name}]")

def get_measure_names() -> List[str]:
    result = []
    for i in range(te_num_trec_measures):
        measure = te_trec_measures[i]
        result.append(measure.name.decode('UTF-8'))

    return result

def get_nicknames() -> Dict[str, List[str]]:
    result = {}
    for i in range(te_num_trec_measure_nicknames):
        entry = te_trec_measure_nicknames[i]
        name = entry.name.decode('UTF-8')

        # Collect nicknames for current entry
        nicknames = []
        j = 0
        while entry.name_list[j] is not cython.NULL:
            nicknames.append(entry.name_list[j].decode("UTF-8"))
            j += 1

        result[name] = nicknames

    return result
