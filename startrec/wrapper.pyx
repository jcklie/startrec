from typing import List

cdef extern from "../trec_eval/trec_eval.h":
    ctypedef struct TREC_MEAS:
        char *name;
        char *explanation;

cdef extern TREC_MEAS *te_trec_measures[];

cdef extern int te_num_trec_measures;


def get_number_of_measures() -> int:
    return te_num_trec_measures

def get_measure_names() -> List[str]:
    result = []
    for i in range(te_num_trec_measures):
        measure = te_trec_measures[i]
        result.append(measure.name.decode('UTF-8'))

    return result
