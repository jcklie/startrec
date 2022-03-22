import textwrap

from startrec._wrapper import MeasureWrapper


class Measure(MeasureWrapper):
    def __init__(self, name: str):
        super().__init__(name)

    @property
    def explanation(self) -> str:
        explanation = self.get_explanation()
        return textwrap.dedent(explanation).strip()
