# Performance

Mustermann is designed so that as much work as possible happens at object-creation time, keeping matching and expansion fast at request time. This document explains what that means in practice for single patterns, for `Mustermann::Set`, and for URL expansion.

## Pattern objects

Pattern objects are immutable once created. To avoid redundant compilation, `Mustermann.new` may return the same instance for the same arguments as long as that instance has not been garbage collected:

```ruby
Mustermann.new("/:name").equal? Mustermann.new("/:name") # may be true
```

Do not rely on object identity — the guarantee is that arguments producing equal patterns may reuse an existing object, not that they always will.

### Which pattern types use an AST?

The regex optimizations described in the next section apply only to pattern types that compile from an abstract syntax tree. That covers `sinatra` (the default), `rails`, `hybrid`, `template`, and `flask`. It does not cover `identity`, `shell`, `simple`, or `regexp`.

## Single-pattern matching

### Bounded character classes

The first and most important performance measure is the default capture character class. A named segment such as `/:name` compiles to `(?<name>[^\/\?#]+)`: it cannot match a `/`, `?`, or `#`. This means segments are naturally isolated — they can never greedily consume a path separator or a query-string delimiter.

```ruby
Mustermann.new("/:a/:b").to_regexp
# => /\A(?-mix:\/(?<a>[^\/\?#]+)\/(?<b>[^\/\?#]+))\Z/
```

Because `[^\/\?#]` already stops at `/`, there is no ambiguity between `:a` and `:b`. The regex engine matches in a single forward pass with no backtracking.

### Look-ahead for adjacent captures

When two captures share the same character class and no literal separator stands between them — for instance `/:a:b?` — the first capture could greedily consume everything, leaving nothing for the second. In this case Mustermann inserts a negative look-ahead into the first capture's repetition:

```ruby
Mustermann.new("/:a:b?").to_regexp
# => /\A(?-mix:\/(?<a>(?:(?!(?:(?!)[^\/\?#])+?$)[^\/\?#])+)(?:(?<b>[^\/\?#]+))?)\Z/
#                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                           look-ahead: each char of :a must
#                           not start a sequence satisfying :b$
```

The look-ahead says: at each position within `:a`, check that the remaining input is not already a valid match for what comes after. This prevents `:a` from consuming characters that belong to `:b`, avoiding the O(n²) backtracking that a naive NFA engine would otherwise require when `:b` fails to match.

This transformation is performed automatically by the AST transformer. It fires whenever a capture is immediately followed by an optional capture (or a group ending in a capture) that shares the same character domain, without a separator literal between them.

For the much more common case — captures separated by `/` literals — look-ahead is not needed and is not inserted.

### Atomic groups

An *atomic group* `(?>...)` tells the regex engine to commit to the match it has found so far and never backtrack into it. Ruby's Oniguruma/Onigmo engine supports this syntax.

Mustermann emits atomic groups for captures that are immediately followed by a path separator (`/`). Every Mustermann capture character class — Sinatra's `[^\/\?#]+`, template's `[\w\-\.~%]+`, and so on — excludes `/`, so the greedy match naturally stops at the right boundary. Committing atomically simply tells the engine not to second-guess that result:

```ruby
Mustermann.new("/:a/:b/:c").to_regexp
# => /\A(?-mix:\/(?<a>(?>[^\/\?#]+))\/(?<b>(?>[^\/\?#]+))\/(?<c>[^\/\?#]+))\Z/
#                   ^^^^^                  ^^^^^
#                   :a and :b are atomic (each followed by "/")
#                   :c is not atomic (nothing follows it)
```

The last capture in a chain is not atomicized because end-of-array does not always mean end-of-pattern: template expressions nest captures inside inner arrays, and atomicizing a capture inside `{name}bar` would commit to consuming `bar`, preventing the literal from matching.

For patterns involving adjacent captures or optional format segments (e.g. `/:file(.:ext)`), the look-ahead transformer (see above) fires instead. The head capture of a `with_look_ahead` node is always made atomic, because the look-ahead constraint already limits exactly how far the capture can extend — no backtracking is needed or useful:

```ruby
Mustermann.new("/:id(.:format)", type: :rails).to_regexp
# => /\A(?-mix:\/(?<id>(?>(?:(?!...)[^\/\?#])+))(?:\.(?<format>[^\/\?#]+))?)$/
#                      ^^^^
#                      :id is atomic (look-ahead head)
```

On a failing input like `/` + `"a" * 10_000 + "/" + "a" * 5_000 + "/"` (one trailing slash that makes the overall pattern fail), patterns with atomic groups run measurably faster because the engine does not re-examine characters already committed.

### Splats are non-greedy

Splat captures (`*` or `/*name`) compile to `.*?` (non-greedy). This ensures they consume as little as possible, letting any following literal or named segment match first:

```ruby
Mustermann.new("/*path/:name").to_regexp
# => /\A(?-mix:\/(?<path>.*?)\/(?<name>[^\/\?#]+))\Z/
```

Non-greedy quantifiers also reduce unnecessary backtracking compared to greedy `.*`.

### URI encoding alternatives

Literal characters in patterns match both the raw character and its percent-encoded forms. A space in a pattern becomes `(?: |%20|+|%2B|%2b)`, a dot becomes `(?:\.|%2E|%2e)`, and so on. This is precomputed at pattern-creation time and does not add per-match overhead beyond the extra alternatives in the NFA. In the trie-based matcher (see below), a need for URI escaping is completely eliminated by these using different edges for raw and encoded characters.

## Set matching: linear vs. trie

`Mustermann::Set` maintains a routing table — each pattern is associated with one or more values, and `set.match(string)` finds the first pattern that matches and returns both the captures and the value.

Two matching strategies are available: **linear** and **trie**. A caching wrapper can be layered on top of either (only caching matches that haven't been garbage collected yet, so it comes with no noticeable memory overhead).

### Linear matching

The linear matcher iterates through patterns in insertion order and tries each one:

```
Input: "/users/42"

Pattern 1: /posts/:slug  → no match
Pattern 2: /users/:id    → match! params: {id: "42"}
Pattern 3: ...           → not reached
```

This is `O(n)` in the number of patterns. For small routing tables (fewer than ~50 routes) the constant factor is low enough that linear scanning is often the fastest option, because there is no trie-construction overhead and no pointer chasing through tree nodes.

### Trie matching

The trie matcher builds a prefix tree from the AST of every pattern. During matching it walks the input string one character at a time, following the edge that matches the current character. At each node it considers two kinds of edges:

- **Static edges** — keyed by an exact character (e.g. `/`, `u`, `s`…). Shared prefixes are traversed once regardless of how many patterns start with them.
- **Dynamic edges** — keyed by a compiled regexp fragment (e.g. `(?<id>[^\/\?#]+)` for a named segment). When a static edge does not match, every dynamic edge at the current node is tried against the remaining input.

```
Input: "/users/42"

Trie root
  └─ '/'
      ├─ 'p' → 'o' → 's' → 't' → 's' → '/' → [dynamic: :slug]  ← skipped
      ├─ 'u' → 's' → 'e' → 'r' → 's' → '/' → [dynamic: :id]    ← matched
      └─ ...
```

Once the static prefix `/users/` has been confirmed, only the patterns that share that prefix compete for the dynamic segment. For large routing tables the total work grows logarithmically rather than linearly with the number of routes.

The trie is built during `Set#add` from the pattern's AST nodes. Splat segments (`.*?`) and non-separator dynamic segments are compiled to regex fragments and stored as dynamic edges; separators and literal characters become static edges.

### Choosing between them

`Mustermann::Set` switches from linear to trie automatically based on the `use_trie:` option:

| Value | Behavior |
|-------|----------|
| `false` | Always use linear matching. |
| `true` | Always use trie matching. |
| Integer `n` (default: `50`) | Use linear until the set contains `n` or more patterns, then switch permanently to trie. |

```ruby
# Force trie from the first pattern
set = Mustermann::Set.new(use_trie: true)

# Keep linear always (e.g. for a tiny router)
set = Mustermann::Set.new(use_trie: false)

# Switch after 20 patterns instead of the default 50
set = Mustermann::Set.new(use_trie: 20)
```

For most applications the default threshold of 50 is appropriate: small apps benefit from the lower constant cost of linear, large apps get sub-linear trie dispatch.

If you want, you can see what the performance looks like with the included `bench/set.rb` script:

```sh
bundle exec ruby bench/set.rb
bundle exec ruby bench/set.rb --trie true
bundle exec ruby bench/set.rb --no-trie
bundle exec ruby bench/set.rb --routes 10,50,100,500 --nesting 2 --trie 20
```

### Caching

A `Cache` layer can be wrapped around either matcher. It stores the result of each `match` call keyed by the input string object, using `ObjectSpace::WeakKeyMap` (if available) so that entries are evicted automatically when the string is no longer referenced elsewhere.

```ruby
set = Mustermann::Set.new(use_cache: true)  # default
set = Mustermann::Set.new(use_cache: false) # disable
```

The cache is transparent: `set.match(string)` returns the same `Set::Match` object on repeated calls with the same string instance without re-running the trie or linear scan. Adding a new pattern clears the cache entirely.

The cache is most valuable when the same path strings are looked up repeatedly in a long-running process (e.g. a Rack application handling many requests for the same resource). It has no benefit for one-shot scripts or benchmarks that generate unique strings for every call.

### Thread safety

Matching and expansion on a set are **thread-safe** once the set has been built. The internal trie and cache are read-only after construction.

**Adding patterns is not thread-safe.** The recommended practice is to populate the set (and the Router built on top of it) during application startup, before requests begin, and then treat it as read-only.

## URL expansion

`Mustermann::Expander` (used internally by `Set#expand` and `Router#path_for`) generates URLs from a parameter hash. Like pattern compilation, the bulk of the work happens once at expander-creation time:

- Each pattern's named segments and their optional combinations are enumerated upfront.
- At expansion time, the expander selects the first pattern whose required keys are all present in the supplied hash and fills them in.

Trade-offs:

- **Memory grows with optional combinations.** A pattern like `"/(:foo/)?:bar?"` has four possible expansions (both present, only foo, only bar, neither). The expander stores all of them. `"/:foo/:bar"` has only one.
- **Capture constraints, type casting, and greediness are ignored** during expansion. The expander produces a valid URL string without re-running match logic.
- **Partial expansion is not yet supported.** All required segments must be supplied.
