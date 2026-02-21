# How to update

# Export the identity

```
> age-plugin-yubikey --slot 1 --identity > identity
```

# Decrypt

```
> agenix -d tailscale-golink.key.age -i identity
age: waiting on yubikey plugin...
tskey-auth-kyppQBLAsE11CNTRL-Qu7ZbfdhfzFwB8Dijo5QzFdKja4PcR7H
```

## Modify

```
> agenix -e tailscale-golink.key.age -i identity
```