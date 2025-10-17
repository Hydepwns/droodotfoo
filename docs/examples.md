# Examples

This page collects small, focused examples demonstrating core features.

## Terminal Commands

```elixir
# Navigate to Spotify section
Droodotfoo.Terminal.Commands.execute(state, [":spotify"]) 
```

## HTTP via HttpClient

```elixir
{:ok, %{status: 200, body: body}} = Droodotfoo.Core.HttpClient.get("https://api.example.com")
```

## ENS Resolution

```elixir
{:ok, name} = Droodotfoo.Web3.ENS.reverse_lookup("0x1234...abcd")
```
