# Netomox pseudo-model
Wrapper module for [Netomox DSL](https://github.com/corestate55/netomox/blob/develop/dsl.md).

Netomox DSL is designed to define data according to RFC 8345 topology model.
The DSL has context about 'parent' object is.
It makes some complexity especially in  cases to fully automated model data building,
like that [bf-l2trial](../bf_l2trial/info.md) and [bf-l3trial](../bf_l3trial/info.md).

Issues:
* Too deep nested blocks.
* Redundant API call for DSL object operation.
* Methods/functions defined in external of DSL object scope are restricted.
  Because `#register` method of each DSL object is evaluated with DSL object scope.
  (using `#instance_eval` for evaluation DSL block.)

So, this 'pseud-model' used to resolve the issues.
It is wrapping Netomox-DSL.
It construct data model context-less.
Therefore, there is no validation and security checks but simple.
It can avoid complexity from using `#instance_eval`.


# Usage

## DataBuilderBase

Inherit `DataBuilderBase` at your own data builder.
It makes to single network-layer (with dummy parent (`networks`)).

Then it can use several variables and methods to build model data.

* Variables (private)
  * `@nodes` : Array of `PNodes`.
  * `@links` : Array of `PLinks`.
  * `@nodes` and `@links` are combined with layer object with `#inherit`.
    These are standalone (context-less) objects before combined.
* Methods (public)
  * `#interpret` : Combining all pseudo-model data to construct Netomox-DSL instance.
    It calls Netomox-DSL corresponding each pseud-model object
    and returns `Netomox::DSL::networks` instance as translation of itself.
  * `#topo_data` : Generate RFC8345 data.
  * `#dump` : debug print.
* Methods (private)
  * `#add_link` : Create `PLink` instance and add it into `@links`.
  * `#add_node_if_new` : Add node into `@nodes` if `@nodes` does not includes the node.
  * `#find_node` : Find node from `@nodes` (`PNode` identifies it by its node name.)
  * `#find_or_new_node` : If node is in `@nodes`, use it. Or If is not, then create new node instance.

## Pseudo Objects
* `PNetworks` (pseudo `Netomox::DSL::Networks`)
* `PNetwork` (pseudo `Netomox::DSL::Network`)
* `PNode` (pseudo `Netomox::DSL::Node`)
* `PTermPoint` (pseudo `Netomox::DSL::TermPoint`)
* `PLink` (pseudo `Netomox::DSL::Link`)
