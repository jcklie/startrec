from libc.stdlib cimport free, malloc

from typing import Dict, List

import cython


cdef extern from "limits.h":
    cdef long LONG_MAX

cdef extern from "../trec_eval/trec_eval.h":
    ctypedef struct MEAS_ARG:
        char *measure_name;
        char *parameters;

    # trec_eval session structure.
    ctypedef struct EPI:
        # 0. If set, evaluation output will be
        # printed for each query, in addition
        # to summary at end.
        long query_flag

        # 1. If set, evaluation output will be printed for summary
        long summary_flag

        # 0. if level is 1 or 2, measure debug info
        # printed. If 3 or more, other info may
        # be printed (file format etc).
        long debug_level

        # NULL. if non-NULL then only debug_query will be evaluated
        char *debug_query

        # 1. If set, print in relational form
        long relation_flag

        # 0. If set, average over the complete set
        # of relevance judgements (qrels), instead
        # of the number of queries
        # in the intersection of qrels and result
        long average_complete_flag

        # 0. If set, throw out all unjudged docs
        # for the retrieved set before calculating
        # any measures.
        long judged_docs_only_flag

        # 0. number of docs in collection
        long num_docs_in_coll

        # In relevance judgements, the level at
        # which a doc is considered relevant for
        # this evaluation
        long relevance_level

        # MAXLONG. evaluate only this many docs
        long max_num_docs_per_topic

        # "qrels", format of input rel_info_file
        char *rel_info_format

        # "trec_results"  format of input results
        char *results_format

        # 0. If set, output Z score for measure instead of raw score
        long zscore_flag

        # List of command line arguments giving individual measure parameters.
        # meas_arg is NULL if there are no such arguments.
        # If arguments, final list member contains a NULL measure_name
        MEAS_ARG *meas_arg


    # This struct contains information about the documents (id and relevancies)
    # The q_rel_info pointer points to a struct of type `TEXT_QRELS_INFO`
    # if `rel_format` == "qrels". We do not implement other formats here.
    ctypedef struct REL_INFO:
        char *qid;          # query id
        char *rel_format;   # format of `q_rel_info`,  e.g. "qrels"
        TEXT_QRELS_INFO *q_rel_info;   # relevance info for this qid

    # This struct contains information about the given ranking (id and judgements)
    # The q_results pointer points to a struct of type `TEXT_RESULTS_INFO`
    # if `ret_format` == "trec_results". We do not implement other formats here.
    ctypedef struct RESULTS:
        char *qid           # query id
        char *run_id        # run_id
        char *ret_format    # format of `q_results`,  e.g. "qrels"
        void *q_results     # retrieval ranking for this qid

    # This contains the calculated evaluation metrics
    ctypedef struct TREC_EVAL:
        char *qid                   # query id
        long num_queries            # Number of queries for this eval
        TREC_EVAL_VALUE *values     # Actual measures and their values
        long num_values             # Number of individual measures
        long max_num_values         # Private: Max number of measures space is reserved for

    ctypedef struct TREC_EVAL_VALUE:
        char *name      # Full measure name for a trec_eval value.  This includes root measure name, plus
				        # any changes due to cutoffs, parameters
        double value    # Actual value


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

        # Calculate actual measure for single query
        int (*calc_meas)(EPI *epi, REL_INFO *rel, RESULTS *results, const TREC_MEAS* tm, TREC_EVAL* eval)

        # Print final summary value, and cleanup measure malloc's
        int (*print_final_and_cleanup_meas)(const EPI *epi, TREC_MEAS *tm, TREC_EVAL* eval)

    # nicknames
    ctypedef struct TREC_MEASURE_NICKNAMES:
        char *name;
        char ** name_list;

# These are the internal structs for the `qrel` format
cdef extern from "../trec_eval/trec_format.h":
    void te_form_res_rels_cleanup()

    # Information about relevancies
    ctypedef struct TEXT_QRELS_INFO:
        long num_text_qrels         # Number of judged documents
        TEXT_QRELS *text_qrels      # Array of judged TEXT_QRELS

    ctypedef struct TEXT_QRELS:
        char *docno     # Document identifier
        long rel        # Document relevancy

    # Information about judgements
    ctypedef struct TEXT_RESULTS_INFO:
        long num_text_results       # number of judged documents
        long max_num_text_results   # Private
        TEXT_RESULTS *text_results  # Array of TEXT_RESULTS results

    ctypedef struct TEXT_RESULTS:
        char *docno     # Document identifier
        float sim        # Judgement given by ranker (similarity)

cdef extern int te_num_trec_measures;
cdef extern TREC_MEAS *te_trec_measures[];

cdef extern int te_num_trec_measure_nicknames;
cdef extern TREC_MEASURE_NICKNAMES te_trec_measure_nicknames[];

cdef class MeasureWrapper:
    cdef EPI _epi
    cdef TREC_EVAL _eval
    cdef TREC_MEAS *_measure
    cdef bint _initialized

    def __init__(self, name: str):
        self._initialized = False

        cdef MEAS_ARG meas_arg
        name_as_byte_string = name.encode("ascii")
        meas_arg.measure_name = cython.NULL
        meas_arg.parameters = cython.NULL

        # Setup EPI
        self._epi.query_flag = 0
        self._epi.average_complete_flag = 0
        self._epi.judged_docs_only_flag = 0
        self._epi.summary_flag = 0
        self._epi.relation_flag = 1
        self._epi.debug_level = 0
        self._epi.debug_query = cython.NULL
        self._epi.num_docs_in_coll = 0
        self._epi.relevance_level = 1
        self._epi.max_num_docs_per_topic = LONG_MAX
        self._epi.rel_info_format = "qrels"
        self._epi.results_format = "trec_results"
        self._epi.zscore_flag = 0
        self._epi.meas_arg = &meas_arg
        
        self._measure = get_measure_by_name(name)
        self._measure.init_meas(&self._epi, self._measure, &self._eval)
        self._initialized = True

    def __dealloc__(self):
        if self._initialized:
            self._measure.print_final_and_cleanup_meas(&self._epi, self._measure, &self._eval)
            te_form_res_rels_cleanup()

    def get_explanation(self) -> str:
        return self._measure.explanation.decode("ascii")

    def compute_single(self, relevancies: List[int], judgements: List[float]) -> float:
        if len(relevancies) != len(judgements):
            raise ValueError("Relevancies and judgements have different lengths!")

        n = len(relevancies)
        qid = b"q1"
        doc_ids = [f"doc{i + 1}".encode("ascii") for i in range(n)]

        # Fill out relevancies
        cdef REL_INFO query
        cdef TEXT_QRELS_INFO relevancy_infos

        query.rel_format = b"qrels"
        query.qid = qid
        query.q_rel_info = &relevancy_infos

        text_qrels = <TEXT_QRELS *> malloc(n * cython.sizeof(TEXT_QRELS))
        if text_qrels is NULL:
            raise MemoryError()

        relevancy_infos.num_text_qrels = n
        relevancy_infos.text_qrels = text_qrels

        for i, r in enumerate(relevancies):
            text_qrels[i].docno = doc_ids[i]
            text_qrels[i].rel = r

        # Fill out judgements
        cdef RESULTS results
        cdef TEXT_RESULTS_INFO judgement_infos

        results.qid = qid
        results.run_id = b"r0"
        results.ret_format = b"trec_results"
        results.q_results = &judgement_infos

        text_results = <TEXT_RESULTS *> malloc(n * cython.sizeof(TEXT_RESULTS))
        if text_results is NULL:
            raise MemoryError()

        judgement_infos.num_text_results = n
        judgement_infos.text_results = text_results

        for i, j in enumerate(judgements):
            text_results[i].docno = doc_ids[i]
            text_results[i].sim = j

        self._eval.qid = qid
        self._eval.num_queries = 1

        self._measure.calc_meas(&self._epi, &query, &results, self._measure, &self._eval)

        # Free stuff
        free(text_qrels)
        free(text_results)

        return self._eval.values[0].value



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
        name = measure.name.decode('UTF-8')

        if name == "runid":
            continue

        result.append(name)

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
