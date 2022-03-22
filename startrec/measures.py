import textwrap
from typing import List

from startrec._wrapper import MeasureWrapper


class Measure(MeasureWrapper):
    def __init__(self, name: str):
        super().__init__(name)

    @property
    def explanation(self) -> str:
        explanation = self.get_explanation()
        return textwrap.dedent(explanation).strip()

    def compute(self, relevancies: List[int], judgements: List[float]) -> float:
        return self.compute_single(relevancies, judgements)
