# startrec

This is a work-in-progress Python wrapper for the [trec_eval](https://github.com/usnistgov/trec_eval) library. `trec_eval` is the standard tool used by the TREC community for evaluating an ad hoc retrieval run.

## Usage

```python
from startrec import Measure

measure = Measure("ndcg")
result = measure.compute([1, 0, 1], [0, 1, 1])
print(result)
```
