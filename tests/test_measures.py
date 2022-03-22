import pytest

from startrec import Measure


def test_getting_measure_that_exists_does_not_throw():
    measure = Measure("recall")


def test_measure_have_explanations():
    measure = Measure("recall")

    assert measure.explanation is not None


def test_getting_measure_that_does_not_exists_throws():
    with pytest.raises(ValueError):
        measure = Measure("nonexistent_measure")


# Test specific measures


def test_ndcg():
    relevancies = [0, 1, 0]
    judgements = [1.0, 0.0, 1.5]

    measure = Measure("ndcg")
    score = measure.compute(relevancies, judgements)

    assert score == pytest.approx(0.5)
