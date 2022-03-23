from typing import List

import pytest
from numpy.random import default_rng
from pytrec_eval import RelevanceEvaluator

from startrec import Measure, get_measure_names


def test_getting_measure_that_exists_does_not_throw():
    _ = Measure("recall")


def test_measure_have_explanations():
    measure = Measure("recall")

    assert measure.explanation is not None


def test_getting_measure_that_does_not_exists_throws():
    with pytest.raises(ValueError):
        _ = Measure("nonexistent_measure")


# Smoke test


@pytest.mark.parametrize("name", get_measure_names())
def test_metrics_smoke_test(name):
    relevancies = [0, 1, 0]
    judgements = [1.0, 0.0, 1.5]

    measure = Measure(name)
    measure.compute(relevancies, judgements)


# Test specific measures


@pytest.mark.parametrize(
    "judgements,expected_score",
    [
        ([1.0, 0.0, 1.5], 0.5),
        ([1.0, 2.0, 1.5], 1.0),
        ([4.0, 2.0, 1.5], 0.6309297535714575),
    ],
)
def test_ndcg_pytrec_eval(judgements: List[float], expected_score: float):
    # From https://github.com/cvangysel/pytrec_eval/blob/master/tests/pytrec_eval_tests.py#L43
    relevancies = [0, 1, 0]

    measure = Measure("ndcg")
    score = measure.compute(relevancies, judgements)

    assert score == pytest.approx(expected_score)


@pytest.mark.parametrize(
    "judgements,expected_score",
    [
        ([0.1, 0.2, 0.3, 4, 70], 0.69),
        ([0.05, 1.1, 1.0, 0.5, 0.0], 0.49),
    ],
)
def test_ndcg_sklearn(judgements: List[float], expected_score: float):
    # From https://scikit-learn.org/stable/modules/generated/sklearn.metrics.ndcg_score.html
    relevancies = [10, 0, 0, 1, 5]

    measure = Measure("ndcg")
    score = measure.compute(relevancies, judgements)

    assert score == pytest.approx(expected_score, abs=0.01)


def test_ap_sklearn():
    # https://scikit-learn.org/stable/modules/generated/sklearn.metrics.average_precision_score.html#sklearn.metrics.average_precision_score
    relevancies = [0, 0, 1, 1]
    judgements = [0.1, 0.4, 0.35, 0.8]

    measure = Measure("map")
    score = measure.compute(relevancies, judgements)

    assert score == pytest.approx(0.83, abs=0.01)


# Comparison with pytrec-eval


@pytest.mark.parametrize("name", get_measure_names())
def test_check_that_our_results_are_identical_to_pytrec_eval(name):
    # https://github.com/cvangysel/pytrec_eval
    rng = default_rng(42)

    n = 1000
    relevancies: List[int] = rng.integers(low=0, high=1, size=n, endpoint=True).tolist()
    judgements: List[float] = rng.uniform(low=0, high=5, size=n).tolist()

    # Pytrec
    qrel = {f"d{i + 1}": relevancies[i] for i in range(n)}
    run = {f"d{i + 1}": judgements[i] for i in range(n)}

    try:
        evaluator = RelevanceEvaluator({"q1": qrel}, {name})
    except ValueError:
        pytest.skip("pytrec_eval failed to construct this measure")
        return

    pytrec_result = evaluator.evaluate({"q1": run})["q1"]

    if name not in pytrec_result:
        pytest.skip("pytrec_eval returned more than one score")
        return

    pytrec_score = pytrec_result[name]

    # Our implementation
    measure = Measure(name)
    score = measure.compute(relevancies, judgements)

    # Check that our implementation yields the same results as pytrec_eval
    assert score == pytest.approx(pytrec_score)


# trec_eval test files


# Misc


def test_nicknames():
    raise NotImplementedError()


def test_memory_leaks():
    raise NotImplementedError()
