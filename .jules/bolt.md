## 2025-02-12 - [Anti-pattern] shrinkWrap: true in Scrollable Views
**Learning:** Using `shrinkWrap: true` in a `ListView` or `GridView` inside a `SingleChildScrollView` forces the list to calculate the total height of all its children upfront, defeating lazy loading and causing performance degradation as the list grows.
**Action:** Replace `SingleChildScrollView` + `ListView(shrinkWrap: true)` with a `CustomScrollView` and `SliverList`/`SliverGrid` to restore lazy loading and improve scroll performance.
