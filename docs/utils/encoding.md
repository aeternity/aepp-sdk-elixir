# Utils.Encoding

#### `binary_to_base58c(prefix, payload) :: String.t()`

Encode a given binary payload to a base58check string with a given prefix

| Param | Type | Description |
| --- | --- | --- |
| prefix | `String.t()` | Arbitrary string prefix |
| payload | `binary()` | Payload to be encoded |

***Example:***
```elixir
iex> Utils.Encoding.binary_to_base58c("ak", <<200, 90, 234, 160, 66, 120, 244, 87, 88, 94, 87, 208, 13, 42, 126, 71, 172, 2, 81, 252, 214, 24, 155, 227, 26, 49, 210, 31, 106, 147, 200, 81>>)
"ak_2XEob1Ub1DWCzeMLm1CWQKrUBsVfF9zLZBDaUXiu6Lr1qLn55n"
```
___

#### `base58c_to_binary(base58c_string) :: binary()`

Decode a given base58check string to binary

| Param | Type | Description |
| --- | --- | --- |
| base58c_string | `String.t()` | Base58check string to be decoded |

***Example:***
```elixir
iex> Utils.Encoding.base58c_to_binary("ak_2XEob1Ub1DWCzeMLm1CWQKrUBsVfF9zLZBDaUXiu6Lr1qLn55n")
<<200, 90, 234, 160, 66, 120, 244, 87, 88, 94, 87, 208, 13, 42, 126, 71, 172, 2, 81, 252, 214, 24, 155, 227, 26, 49, 210, 31, 106, 147, 200, 81>>

```
