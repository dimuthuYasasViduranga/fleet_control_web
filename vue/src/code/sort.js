import { firstBy } from 'thenby';
import fuzzysort from 'fuzzysort';

export function orderedFuzzySort(search, items, opts) {
  return fuzzysort
    .go(search, items, opts)
    .sort(firstBy('score', 'desc').thenBy('target'))
    .map(r => r.obj);
}
